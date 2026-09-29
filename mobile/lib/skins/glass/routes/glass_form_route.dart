import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/glass/lb.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/lit.dart';
import 'package:manhwamaniacs/skins/glass/primitives/overlay_queue.dart';
import 'package:manhwamaniacs/skins/glass/primitives/recede.dart';
import 'package:manhwamaniacs/skins/glass/primitives/sheet_scaffold.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_sheet_route.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';

/// The field term of `Lb` under an overlay surface when the palette is unknown: dark, so the dim stays low.
const double kOverlayFieldTerm = 0.1;

/// The tablet and desktop forms of a sheet (glass 7.10, 15.3 item 16): the 440 px `panel` from the right, the
/// 560 px `window` blooming from its trigger, the 960 px `detailWindow` on a `materialThick` slab and the 420 px
/// `popover` anchored to its trigger. `dimSheet` sits behind all of them; `Esc`, a barrier tap and Android back close
/// them.
class GlassFormRoute<T> extends PopupRoute<T> {
  GlassFormRoute(this.page) : super(settings: page);
  final GlassSheetPage<T> page;

  GlassWideForm get form => page.wideForm!;

  @override
  Color? get barrierColor => GlassColors.dimSheet;
  @override
  bool get barrierDismissible => true;
  @override
  String? get barrierLabel => 'Dismiss';
  @override
  Duration get transitionDuration => Duration(milliseconds: form == GlassWideForm.panel ? 447 : 434);
  @override
  Duration get reverseTransitionDuration => Duration(milliseconds: form == GlassWideForm.panel ? 378 : 350);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) => _GlassFormPage<T>(route: this);
}

class _GlassFormPage<T> extends ConsumerStatefulWidget {
  const _GlassFormPage({required this.route});
  final GlassFormRoute<T> route;

  @override
  ConsumerState<_GlassFormPage<T>> createState() => _GlassFormPageState<T>();
}

class _GlassFormPageState<T> extends ConsumerState<_GlassFormPage<T>> {
  final FocusNode _title = FocusNode(debugLabel: 'GlassForm.title');
  VoidCallback? _unsuppress;
  GlassRecedeController? _recede;
  late final Animation<double> _t;

  GlassSheetPage<T> get page => widget.route.page;
  GlassWideForm get form => widget.route.form;

  @override
  void initState() {
    super.initState();
    _unsuppress = suppressLit();
    final r = widget.route;
    final reduced = ref.read(glassMotionPrefsProvider).reduced;
    final token = form == GlassWideForm.panel ? gt.springSheet : gt.springMorph;
    _t = reduced
        ? CurvedAnimation(parent: r.animation!, curve: Curves.linear)
        : CurvedAnimation(parent: r.animation!, curve: SpringCurve(token, settleMs: form == GlassWideForm.panel ? 447 : 434));
    if (form == GlassWideForm.detailWindow) {
      _recede = GlassRecedeScope.maybeOf(context);
      r.animation!.addListener(_recedePage);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _title.requestFocus());
  }

  void _recedePage() => _recede?.setWindowProgress(widget.route.animation!.value.clamp(0.0, 1.0));

  @override
  void dispose() {
    widget.route.animation?.removeListener(_recedePage);
    final r = _recede;
    if (r != null) WidgetsBinding.instance.addPostFrameCallback((_) => r.setWindowProgress(0));
    _unsuppress?.call();
    _title.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).maybePop();

  Widget _scaffold({bool shrink = false}) => ValueListenableBuilder<GlassSheetStatus>(
        valueListenable: page.status ?? ValueNotifier(GlassSheetStatus.ready),
        builder: (context, status, _) => GlassSheetScaffold(
          title: page.title,
          centerTitle: page.centerTitle,
          leading: page.leading,
          titleFocus: _title,
          status: status,
          onRetry: page.onRetry,
          errorText: page.errorText ?? "Couldn't load this",
          emptyText: page.emptyText ?? 'Nothing here yet',
          onClose: _close,
          showGrabber: false,
          shrink: shrink,
          body: Builder(builder: page.builder),
        ),
      );

  /// Glass behind the content (the content is not inside [SkinGlass], so [GlassHost] marks it).
  Widget _glassed(Widget content, {required double radius, GlassTierId tier = GlassTierId.t4}) => GlassHost(
        child: GlassLbBar(
          fieldTerm: kOverlayFieldTerm,
          builder: (context, lb) => Stack(
            children: [
              Positioned.fill(
                child: SkinGlass(key: const ValueKey('glass-form-surface'), tier: tier, lb: lb, shape: GlassShape.superellipse(radius), layer: GlassLayerKind.overlays, debugLabel: 'GlassForm', child: const SizedBox.shrink()),
              ),
              content,
            ],
          ),
        ),
      );

  Widget _slab(Widget content, {required double radius}) => ClipRSuperellipse(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: gt.glassMaterialThick.blur, sigmaY: gt.glassMaterialThick.blur),
          child: ColoredBox(key: const ValueKey('glass-detail-slab'), color: gt.glassMaterialThick.fill, child: content),
        ),
      );

  Rect? get _origin => page.originRect;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final sidebar = ref.watch(glassSidebarEdgeProvider);
    final reduced = ref.watch(glassMotionPrefsProvider.select((m) => m.reduced));

    Widget body;
    switch (form) {
      case GlassWideForm.panel:
        final w = math.min(440.0, size.width - 24);
        body = Positioned(
          right: 12,
          top: 12 + pad.top,
          bottom: 12 + pad.bottom,
          width: w,
          child: AnimatedBuilder(
            animation: _t,
            builder: (context, child) => reduced
                ? Opacity(opacity: _t.value.clamp(0.0, 1.0), child: Transform.translate(offset: Offset(16 * (1 - _t.value), 0), child: child))
                : Transform.translate(offset: Offset((1 - _t.value) * (w + 12), 0), child: child),
            child: _glassed(_scaffold(), radius: gt.radiusXl),
          ),
        );
      case GlassWideForm.window:
        final w = math.min(560.0, size.width - 24);
        final top = math.max(0.12 * size.height, 48.0);
        final maxH = math.min(0.8 * size.height, 880.0);
        final colLeft = sidebar;
        final centerX = colLeft + (size.width - colLeft) / 2;
        body = Positioned(
          left: centerX - w / 2,
          top: top,
          width: w,
          child: _bloom(
            anchor: Offset(centerX, top),
            reduced: reduced,
            child: ConstrainedBox(constraints: BoxConstraints(maxHeight: maxH), child: _glassed(_scaffold(shrink: true), radius: gt.radiusXxl, tier: GlassTierId.auto)),
          ),
        );
      case GlassWideForm.detailWindow:
        final w = math.min(960.0, size.width - 48);
        body = Positioned(
          left: (size.width - w) / 2,
          top: 24,
          width: w,
          height: size.height - 48,
          child: _bloom(anchor: Offset(size.width / 2, 24), reduced: reduced, child: _slab(_scaffold(), radius: gt.radiusXxl)),
        );
      case GlassWideForm.popover:
        const w = 420.0;
        final o = _origin ?? Rect.fromCenter(center: Offset(size.width / 2, size.height / 3), width: 44, height: 44);
        final left = (o.right - w).clamp(12.0, math.max(12.0, size.width - w - 12)).toDouble();
        final top = math.min(o.bottom + 8, size.height - 160);
        body = Positioned(
          left: left,
          top: top,
          width: w,
          child: _bloom(
            anchor: Offset(left + w - 20, top),
            reduced: reduced,
            child: ConstrainedBox(constraints: BoxConstraints(maxHeight: size.height - top - 12), child: _glassed(_scaffold(shrink: true), radius: gt.radiusXl)),
          ),
        );
    }

    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): _close},
      child: FocusScope(
        child: FocusTraversalGroup(
          child: GlassLitOverlay(
            child: Semantics(
              scopesRoute: true,
              namesRoute: true,
              explicitChildNodes: true,
              label: page.title,
              child: Stack(children: [body]),
            ),
          ),
        ),
      ),
    );
  }

  /// The bloom from the trigger: scale and translate from [_origin]'s centre to the window (fade under reduced).
  Widget _bloom({required Offset anchor, required bool reduced, required Widget child}) => AnimatedBuilder(
        animation: _t,
        child: child,
        builder: (context, child) {
          final t = _t.value;
          if (reduced) return Opacity(opacity: t.clamp(0.0, 1.0), child: child);
          final from = _origin?.center ?? anchor;
          final scale = 0.2 + 0.8 * t;
          final d = from - anchor;
          return Opacity(
            opacity: (t * 2).clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(d.dx * (1 - t), d.dy * (1 - t)),
              child: Transform.scale(key: const ValueKey('glass-form-bloom'), scale: scale, alignment: Alignment.topCenter, child: child),
            ),
          );
        },
      );
}
