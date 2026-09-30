import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/overlay_queue.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';

/// The floating capsule above the dock (glass 7.35): the base of the bulk toolbar and of `mobile/40`'s "Unsaved changes" bar. A
/// `glassRegular` (T3) capsule 52 tall, one live layer. While it shows it sets [glassBottomBarProvider] to [kind], which the
/// overlay queue and the shell read to hide the accessory. Put it as a direct child of a `Stack` that fills the screen.
///
/// Phone frame: in the accessory's slot, `safe-bottom + 21 + 64 + 8` above the bottom, inset 21 px. Tablet and desktop frames:
/// 24 px above the bottom, centred on the content column (whose leading edge is [glassSidebarEdgeProvider]), 720 px at most.
/// It materialises in (250 ms) and dematerialises out (350 ms); while the keyboard shows it dematerialises and ignores input.
class GlassFloatingBar extends ConsumerStatefulWidget {
  const GlassFloatingBar({super.key, required this.child, this.kind = GlassBottomBar.bulk, this.visible = true, this.debugLabel = 'GlassFloatingBar'});
  final Widget child;
  final GlassBottomBar kind;
  final bool visible;
  final String debugLabel;

  @override
  ConsumerState<GlassFloatingBar> createState() => _GlassFloatingBarState();
}

class _GlassFloatingBarState extends ConsumerState<GlassFloatingBar> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final StateController<GlassBottomBar> _bar;
  bool _keyboard = false;

  bool get _shown => widget.visible && !_keyboard;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 250), reverseDuration: const Duration(milliseconds: 350));
    _bar = ref.read(glassBottomBarProvider.notifier);
    _sync();
  }

  @override
  void didUpdateWidget(GlassFloatingBar old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (_shown) {
      _c.forward();
    } else {
      _c.reverse();
    }
    final want = widget.visible ? widget.kind : GlassBottomBar.none;
    Future.microtask(() {
      if (!mounted && want != GlassBottomBar.none) return;
      if (_bar.state != want) _bar.state = want;
    });
  }

  @override
  void dispose() {
    final bar = _bar;
    final mine = widget.kind;
    Future.microtask(() {
      try {
        if (bar.state == mine) bar.state = GlassBottomBar.none;
      } catch (_) {}
    });
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.viewInsetsOf(context).bottom > 0;
    if (kb != _keyboard) {
      _keyboard = kb;
      WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _sync() : null);
    }
    final reduced = ref.watch(glassMotionPrefsProvider.select((m) => m.reduced));
    final phone = GlassFrame.of(context) == GlassFrameKind.phone;
    final size = MediaQuery.sizeOf(context);
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final edge = ref.watch(glassSidebarEdgeProvider);
    final bottom = phone ? safeBottom + 21 + 64 + 8 : 24.0;
    final left = phone ? 21.0 : edge;
    final right = phone ? 21.0 : 0.0;
    final column = size.width - left - right;
    final width = phone ? column : math.min(720.0, column - 48);
    return Positioned(
      left: left,
      right: right,
      bottom: bottom,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          if (_c.isDismissed) return const SizedBox.shrink();
          final t = Curves.easeOut.transform(_c.value);
          return IgnorePointer(
            ignoring: !_shown,
            child: ExcludeSemantics(
              excluding: !_shown,
              child: Opacity(opacity: t, child: Transform.scale(scale: reduced ? 1 : 0.96 + 0.04 * t, child: child)),
            ),
          );
        },
        child: Center(
          child: SizedBox(
            width: width,
            height: 52,
            child: Stack(
              children: [
                Positioned.fill(child: SkinGlass(tier: GlassTierId.t3, debugLabel: widget.debugLabel, child: const SizedBox.shrink())),
                GlassHost(child: widget.child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
