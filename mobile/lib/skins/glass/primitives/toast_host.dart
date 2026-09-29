import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/overlay_queue.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';

/// The one place toasts are drawn (glass 7.12): an `OverlayPortal` host the Glass root places once
/// (`mobile/29`; the gallery places it now). Phones: top-centre at safe-top + 60. Tablet and desktop frames:
/// bottom-left, 24 px beside the sidebar (88 up while a bottom bar shows). Inside the readers: top-centre at 60.
class GlassToastHost extends ConsumerStatefulWidget {
  const GlassToastHost({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<GlassToastHost> createState() => _GlassToastHostState();
}

class _GlassToastHostState extends ConsumerState<GlassToastHost> {
  final OverlayPortalController _portal = OverlayPortalController(debugLabel: 'GlassToastHost');
  FocusNode? _prevFocus;
  bool _requested = false;
  bool _showingFlag = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  /// `Alt+N` moves focus to the newest toast; `Esc` (handled by the toast) returns it.
  bool _onKey(KeyEvent e) {
    if (e is! KeyDownEvent || e.logicalKey != LogicalKeyboardKey.keyN || !HardwareKeyboard.instance.isAltPressed) return false;
    final list = ref.read(glassToastProvider);
    if (list.isEmpty) return false;
    final cur = FocusManager.instance.primaryFocus;
    if (!list.any((t) => t.focus == cur)) _prevFocus = cur;
    list.last.focus.requestFocus();
    return true;
  }

  void _sync(List<GlassToastEntry> list, bool visible) {
    scheduleMicrotask(() {
      if (!mounted) return;
      if (list.isNotEmpty && !_portal.isShowing) {
        _portal.show();
      } else if (list.isEmpty && _portal.isShowing) {
        _portal.hide();
      }
      final q = ref.read(overlayQueueProvider.notifier);
      q.setPhone(GlassFrame.of(context) == GlassFrameKind.phone);
      if (list.isNotEmpty && !_requested) {
        _requested = true;
        q.requestSlot(OverlayKind.toast);
      } else if (list.isEmpty && _requested) {
        _requested = false;
        q.release(OverlayKind.toast);
      }
      final show = list.isNotEmpty && visible;
      if (show != _showingFlag) {
        _showingFlag = show;
        ref.read(glassToastShowingProvider.notifier).state = show;
      }
      final cur = FocusManager.instance.primaryFocus;
      if (cur == null && _prevFocus != null && _prevFocus!.context != null) {
        _prevFocus!.requestFocus();
        _prevFocus = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(glassToastProvider);
    final visible = ref.watch(overlaySlotVisibleProvider(OverlayKind.toast));
    ref.watch(overlayQueueProvider.select((s) => s.phone));
    _sync(list, visible);
    return OverlayPortal(controller: _portal, overlayChildBuilder: _layer, child: widget.child);
  }

  Widget _layer(BuildContext context) {
    final list = ref.watch(glassToastProvider);
    final visible = ref.watch(overlaySlotVisibleProvider(OverlayKind.toast));
    final reader = ref.watch(glassReaderActiveProvider);
    final bottomBar = ref.watch(glassBottomBarProvider);
    final sidebar = ref.watch(glassSidebarEdgeProvider);
    final phone = GlassFrame.of(context) == GlassFrameKind.phone;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final children = <Widget>[
      // The older one sits behind the newest, 8 px down and scaled to 0.94.
      for (var i = 0; i < list.length; i++)
        GlassToastView(key: ValueKey(list[i].id), entry: list[i], present: visible && !list[i].leaving, rank: list.length - 1 - i),
    ];
    final stack = Stack(alignment: Alignment.topCenter, clipBehavior: Clip.none, children: children);
    if (reader || phone) {
      return Positioned.fill(
        child: Align(alignment: Alignment.topCenter, child: Padding(padding: EdgeInsets.only(top: reader ? 60 : top + 60), child: stack)),
      );
    }
    return Positioned.fill(
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(padding: EdgeInsets.only(left: sidebar + 24, bottom: (bottomBar ? 88 : 24) + bottom), child: stack),
      ),
    );
  }
}
