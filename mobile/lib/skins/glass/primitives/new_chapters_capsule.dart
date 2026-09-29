import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/semantics.dart' show CustomSemanticsAction;

import 'package:flutter/physics.dart' show SpringSimulation;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/overlay_queue.dart';
import 'package:manhwamaniacs/skins/glass/primitives/sheet_scaffold.dart' show GlassCloseButton;
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The global new-chapters notification (glass 7.30): what the capsule shows. A newer [id] shows it again after a
/// dismissal.
class GlassNewChaptersSpec {
  const GlassNewChaptersSpec({required this.id, required this.chapters, required this.series, this.covers = const [], this.onView});
  final int id;
  final int chapters;
  final int series;
  final List<Widget> covers;
  final VoidCallback? onView;

  String get text => '$chapters new chapter${chapters == 1 ? '' : 's'} in $series series';
}

final glassNewChaptersProvider = StateProvider<GlassNewChaptersSpec?>((ref) => null);

/// The id the user dismissed (a newer notification shows again).
final glassNewChaptersDismissedProvider = StateProvider<int>((ref) => -1);

/// The app-update capsule (Android, the APK channel): "A new version is ready" + "Update".
class GlassAppUpdateSpec {
  const GlassAppUpdateSpec({required this.onUpdate});
  final VoidCallback onUpdate;
}

final glassAppUpdateProvider = StateProvider<GlassAppUpdateSpec?>((ref) => null);

/// The `glassRegular` capsule that drops in like a toast but stays until acted on: a stack of up to 3 covers, the
/// text, a "View" plain button and the toast close button; a swipe up or the close button dismisses it until a newer
/// notification arrives.
class GlassNewChaptersCapsule extends ConsumerWidget {
  const GlassNewChaptersCapsule({super.key, required this.spec, required this.onDismiss});
  final GlassNewChaptersSpec spec;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final covers = spec.covers.take(3).toList();
    final content = Padding(
      padding: const EdgeInsets.only(left: 12, right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (covers.isNotEmpty)
            SizedBox(
              width: 28.0 + 16 * (covers.length - 1),
              height: 36,
              child: Stack(children: [
                for (var i = covers.length - 1; i >= 0; i--)
                  Positioned(left: 16.0 * i, top: 0, width: 28, height: 36, child: ClipRSuperellipse(borderRadius: BorderRadius.circular(6), child: covers[i])),
              ]),
            ),
          if (covers.isNotEmpty) const SizedBox(width: 10),
          Flexible(child: GlassText(spec.text, role: gt.typeCallout, onGlass: true, maxScale: 1.5)),
          const SizedBox(width: 4),
          GlassButton(label: 'View', variant: GlassButtonVariant.plain, size: GlassButtonSize.small, onPressed: spec.onView),
          GlassCloseButton(key: const ValueKey('glass-capsule-close'), label: 'Dismiss', visual: 24, glyphSize: 16, filled: false, onTap: onDismiss),
        ],
      ),
    );
    return _CapsuleSurface(label: spec.text, tier: GlassTierId.t3, onDismiss: onDismiss, child: content);
  }
}

/// "A new version is ready" + "Update" (glass 7.30). Android only: iOS updates through SideStore.
class GlassAppUpdateCapsule extends ConsumerWidget {
  const GlassAppUpdateCapsule({super.key, required this.spec, this.onDismiss});
  final GlassAppUpdateSpec spec;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) => _CapsuleSurface(
        label: 'A new version is ready',
        tier: GlassTierId.t3,
        onDismiss: onDismiss,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: GlassText('A new version is ready', role: gt.typeCallout, onGlass: true, maxScale: 1.5)),
              const SizedBox(width: 8),
              GlassButton(label: 'Update', variant: GlassButtonVariant.plain, size: GlassButtonSize.small, onPressed: spec.onUpdate),
            ],
          ),
        ),
      );
}

class _CapsuleSurface extends StatelessWidget {
  const _CapsuleSurface({required this.label, required this.tier, required this.child, this.onDismiss});
  final String label;
  final GlassTierId tier;
  final Widget child;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: label,
        onDismiss: onDismiss,
        customSemanticsActions: {if (onDismiss != null) const CustomSemanticsAction(label: 'Dismiss'): onDismiss!},
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, minHeight: 48),
          child: GlassHost(
            child: Stack(
              children: [
                Positioned.fill(child: SkinGlass(tier: tier, shape: GlassShape.superellipse(24), layer: GlassLayerKind.hud, debugLabel: 'GlassCapsule', child: const SizedBox.shrink())),
                Center(widthFactor: 1, heightFactor: 1, child: child),
              ],
            ),
          ),
        ),
      );
}

/// Places the two capsules by the overlay queue (glass 7.30, 15.7). Phones: the top band under the nav row (safe-top +
/// 60), new chapters before the app update. Tablet and desktop frames: the new-chapters capsule top-centre of the
/// content column, 12 px below the toolbar row (top 72), max width 480, sharing one queue with toasts; the app-update
/// capsule bottom-centre of the content column, waiting while a bottom bar shows. The Glass root places it once
/// (`mobile/29`); screens hide it inside readers and on Updates by clearing [glassNewChaptersProvider].
class GlassCapsuleHost extends ConsumerStatefulWidget {
  const GlassCapsuleHost({super.key, required this.child, this.androidOnlyUpdate = true});
  final Widget child;

  /// The APK channel only shows on Android.
  final bool androidOnlyUpdate;

  @override
  ConsumerState<GlassCapsuleHost> createState() => _GlassCapsuleHostState();
}

class _GlassCapsuleHostState extends ConsumerState<GlassCapsuleHost> {
  final OverlayPortalController _portal = OverlayPortalController(debugLabel: 'GlassCapsuleHost');
  bool _newReq = false, _updReq = false;

  bool get _android => defaultTargetPlatform == TargetPlatform.android;

  void _sync(GlassNewChaptersSpec? news, int dismissed, GlassAppUpdateSpec? upd) {
    final wantNews = news != null && news.id > dismissed;
    final wantUpd = upd != null && (!widget.androidOnlyUpdate || _android);
    scheduleMicrotask(() {
      if (!mounted) return;
      final q = ref.read(overlayQueueProvider.notifier);
      q.setPhone(GlassFrame.of(context) == GlassFrameKind.phone);
      if (wantNews != _newReq) {
        _newReq = wantNews;
        wantNews ? q.requestSlot(OverlayKind.newChapters) : q.release(OverlayKind.newChapters);
      }
      if (wantUpd != _updReq) {
        _updReq = wantUpd;
        wantUpd ? q.requestSlot(OverlayKind.appUpdate) : q.release(OverlayKind.appUpdate);
      }
      final any = wantNews || wantUpd;
      if (any && !_portal.isShowing) {
        _portal.show();
      } else if (!any && _portal.isShowing) {
        _portal.hide();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final news = ref.watch(glassNewChaptersProvider);
    final dismissed = ref.watch(glassNewChaptersDismissedProvider);
    final upd = ref.watch(glassAppUpdateProvider);
    ref.watch(overlayQueueProvider.select((s) => s.phone));
    _sync(news, dismissed, upd);
    return OverlayPortal(controller: _portal, overlayChildBuilder: _layer, child: widget.child);
  }

  Widget _layer(BuildContext context) {
    final news = ref.watch(glassNewChaptersProvider);
    final dismissed = ref.watch(glassNewChaptersDismissedProvider);
    final upd = ref.watch(glassAppUpdateProvider);
    final showNews = ref.watch(overlaySlotVisibleProvider(OverlayKind.newChapters)) && news != null && news.id > dismissed;
    final showUpd = ref.watch(overlaySlotVisibleProvider(OverlayKind.appUpdate)) && upd != null && (!widget.androidOnlyUpdate || _android);
    final sidebar = ref.watch(glassSidebarEdgeProvider);
    final phone = GlassFrame.of(context) == GlassFrameKind.phone;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final size = MediaQuery.sizeOf(context);
    Widget newsW() => _FallIn(
          key: const ValueKey('glass-new-chapters'),
          present: showNews,
          child: news == null ? const SizedBox.shrink() : GlassNewChaptersCapsule(spec: news, onDismiss: () => ref.read(glassNewChaptersDismissedProvider.notifier).state = news.id),
        );
    Widget updW() => _FallIn(
          key: const ValueKey('glass-app-update'),
          present: showUpd,
          child: upd == null ? const SizedBox.shrink() : GlassAppUpdateCapsule(spec: upd),
        );
    if (phone) {
      return Positioned.fill(
        child: Align(alignment: Alignment.topCenter, child: Padding(padding: EdgeInsets.only(top: top + 60), child: Stack(alignment: Alignment.topCenter, children: [updW(), newsW()]))),
      );
    }
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(left: sidebar, right: 0, top: 72, child: Align(alignment: Alignment.topCenter, child: newsW())),
          Positioned(left: sidebar, right: 0, bottom: 24 + bottom, child: Align(alignment: Alignment.bottomCenter, child: updW())),
          if (size.width < 0) const SizedBox.shrink(),
        ],
      ),
    );
  }
}


/// Drops in from 60 px above on `springSnappy` while materialising and leaves upward on `springDismiss`.
class _FallIn extends ConsumerStatefulWidget {
  const _FallIn({super.key, required this.present, required this.child});
  final bool present;
  final Widget child;

  @override
  ConsumerState<_FallIn> createState() => _FallInState();
}

class _FallInState extends ConsumerState<_FallIn> with TickerProviderStateMixin {
  late final AnimationController _y = AnimationController.unbounded(vsync: this, value: -60);
  late final AnimationController _o = AnimationController(vsync: this);
  bool _in = false;
  bool _gone = true;

  @override
  void initState() {
    super.initState();
    _y.value;
    _o.value;
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void didUpdateWidget(_FallIn old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (!mounted) return;
    final reduced = ref.read(glassMotionPrefsProvider).reduced;
    if (widget.present && !_in) {
      _in = true;
      setState(() => _gone = false);
      if (reduced) {
        _y.value = 0;
        _o.animateTo(1, duration: const Duration(milliseconds: 150));
      } else {
        _o.animateTo(1, duration: gt.curveMaterialize.duration, curve: gt.curveMaterialize.curve);
        _y.animateWith(SpringSimulation(springOf(gt.springSnappy), _y.value, 0, _y.velocity));
      }
    } else if (!widget.present && _in) {
      _in = false;
      if (reduced) {
        _o.animateTo(0, duration: const Duration(milliseconds: 150)).whenComplete(() => _hide());
      } else {
        _o.animateTo(0, duration: const Duration(milliseconds: 240));
        _y.animateWith(SpringSimulation(springOf(gt.springDismiss), _y.value, -80, _y.velocity)).whenComplete(() => _hide());
      }
    }
  }

  void _hide() {
    if (mounted && !_in) setState(() => _gone = true);
  }

  @override
  void dispose() {
    _y.dispose();
    _o.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_gone) return const SizedBox.shrink();
    return GestureDetector(
      onVerticalDragUpdate: (d) {
        if (d.delta.dy < 0) _y.value += d.delta.dy;
      },
      onVerticalDragEnd: (d) {
        if (_y.value < -20 || d.velocity.pixelsPerSecond.dy < -400) {
          final spec = ref.read(glassNewChaptersProvider);
          if (spec != null && widget.key == const ValueKey('glass-new-chapters')) ref.read(glassNewChaptersDismissedProvider.notifier).state = spec.id;
        } else {
          _y.animateWith(SpringSimulation(springOf(gt.springSettle), _y.value, 0, d.velocity.pixelsPerSecond.dy));
        }
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_y, _o]),
        child: widget.child,
        builder: (context, child) => Opacity(opacity: _o.value.clamp(0.0, 1.0), child: Transform.translate(offset: Offset(0, _y.value), child: child)),
      ),
    );
  }
}
