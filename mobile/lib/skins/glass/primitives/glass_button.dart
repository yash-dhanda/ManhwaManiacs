import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/lit.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/progress.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// glass 7.1: the button variants. All capsules.
enum GlassButtonVariant { primary, secondary, plain, destructive, destructiveConfirm }

/// L 50 / 50, M 44 / `hitMin`, S 34 / `hitMin`.
enum GlassButtonSize { large, medium, small }

/// Visual heights, paddings and roles per size (glass 7.1). Heights are minimums: they grow with the text.
class GlassButtonMetrics {
  const GlassButtonMetrics._(this.minHeight, this.padH, this.role, this.wght);
  final double minHeight;
  final double padH;
  final GlassTypeRole role;
  final int? wght;

  static GlassButtonMetrics of(GlassButtonSize s, {bool destructiveConfirm = false}) => switch (s) {
        GlassButtonSize.large => GlassButtonMetrics._(50, 24, gt.typeHeadline, null),
        GlassButtonSize.medium => GlassButtonMetrics._(44, 20, gt.typeHeadline, null),
        GlassButtonSize.small => GlassButtonMetrics._(34, 14, gt.typeSubhead, 620),
      };
}

/// A button icon: Regular at rest and Fill when selected (the morph on `springTick`).
class GlassButtonIcon {
  const GlassButtonIcon(this.regular, {IconData? fill}) : fill = fill ?? regular;
  factory GlassButtonIcon.glyph(Glyph g) => GlassButtonIcon(g.regular, fill: g.fill);
  final IconData regular;
  final IconData fill;
}

/// The one button of the Glass skin (glass 7.1). See the variants and states there; the widget owns the
/// content, [GlassPressable] owns the press physics, [SkinGlass] owns the material.
class GlassButton extends ConsumerStatefulWidget {
  const GlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = GlassButtonVariant.secondary,
    this.size = GlassButtonSize.medium,
    this.icon,
    this.loading = false,
    this.selected = false,
    this.errorText,
    this.errorTrigger = 0,
    this.overMedia = false,
    this.overContent = true,
    this.twin,
    this.role = GlassRole.chrome,
    this.disabledReason,
    this.forceStates = GlassWidgetStates.none,
    this.tooltip,
    this.semanticsLabel,
    this.fullWidth = false,
    this.lb = 1.0,
    this.debugLabel,
    this.onLongPress,
    this.focusNode,
  });

  final String label;
  final VoidCallback? onPressed;
  final GlassButtonVariant variant;
  final GlassButtonSize size;
  final GlassButtonIcon? icon;
  final bool loading;
  final bool selected;

  /// "Couldn't save": shown for 2 s each time [errorTrigger] increases, with a shake and the `error` haptic.
  final String? errorText;
  final int errorTrigger;
  final bool overMedia;
  final bool overContent;

  /// A button repeated per item takes [GlassTwin.content] (glass 2.4.1 rule 1).
  final GlassTwin? twin;
  final GlassRole role;
  final String? disabledReason;
  final GlassWidgetStates forceStates;
  final String? tooltip;
  final String? semanticsLabel;
  final bool fullWidth;
  final double lb;
  final String? debugLabel;
  final VoidCallback? onLongPress;
  final FocusNode? focusNode;

  @override
  ConsumerState<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends ConsumerState<GlassButton> with GlassLitState {
  bool _showError = false;
  Timer? _errTimer;
  final GlobalKey _wipeKey = GlobalKey();
  Offset? _touch;

  bool get _disabled => widget.onPressed == null || widget.forceStates.disabled;

  @override
  bool get isLit => widget.variant == GlassButtonVariant.primary && !_disabled;

  @override
  void didUpdateWidget(GlassButton old) {
    super.didUpdateWidget(old);
    if (widget.errorTrigger > old.errorTrigger && widget.errorText != null) {
      _errTimer?.cancel();
      setState(() => _showError = true);
      _errTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showError = false);
      });
    }
  }

  @override
  void dispose() {
    _errTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    syncLit();
    final v = widget.variant;
    final m = GlassButtonMetrics.of(widget.size);
    final legible = ref.watch(glassA11yProvider.select((a) => a.legible));
    final inHost = GlassHost.of(context);
    final states = widget.forceStates;
    final showError = _showError || states.error;
    final loading = widget.loading || states.loading;
    final selected = widget.selected || states.selected;
    final suppressed = GlassLit.suppressed;
    final baseWght = (m.wght ?? m.role.wght.round());

    final hasIcon = widget.icon != null || v == GlassButtonVariant.destructive || showError;
    final labelFor = showError ? (widget.errorText ?? "Couldn't do that") : widget.label;
    TextStyle style(String _) => roleStyle(context, m.role, onGlass: true, legible: legible, wght: baseWght + 40, maxScale: 1.5);
    Size measure(String t) => measureText(context, t, style(t));
    final shown = measure(labelFor);
    final base = measure(widget.label);
    final iconW = hasIcon ? (v == GlassButtonVariant.destructive || showError ? 28.0 : 20.0) + 8 : 0.0;
    final baseIconW = (widget.icon != null || v == GlassButtonVariant.destructive) ? (v == GlassButtonVariant.destructive ? 28.0 : 20.0) + 8 : 0.0;
    final contentW = math.max(shown.width + iconW, base.width + baseIconW);
    final height = math.max(m.minHeight, shown.height + 20);
    final isPlain = v == GlassButtonVariant.plain;
    final padH = isPlain ? 8.0 : m.padH;
    final hit = GlassFrame.hitMin(context);

    return LayoutBuilder(builder: (context, c) {
      var width = contentW + 2 * padH;
      if (widget.fullWidth && c.hasBoundedWidth) width = c.maxWidth;
      final size = Size(width, isPlain ? math.max(height, hit) : height);

      final tinted = v == GlassButtonVariant.primary && !_disabled && !suppressed;
      final finish = tinted ? GlassFinishKind.tinted : GlassFinishKind.regular;
      final tier = widget.overMedia && !tinted ? GlassTierId.t3 : GlassTierId.auto;
      final twin = widget.twin ?? (inHost && tinted ? GlassTwin.tinted : null);
      final onTint = v == GlassButtonVariant.primary && !_disabled && !suppressed;
      final labelColor = _disabled
          ? gt.colorLabel4
          : v == GlassButtonVariant.destructiveConfirm
              ? const Color(0xFF000000)
              : onTint
                  ? gt.colorOnTint
                  : isPlain
                      ? (inHost ? gt.colorOnGlass : gt.colorIris400)
                      : gt.colorOnGlass;

      return GlassPressable(
        material: GlassMaterial.glass,
        growth: GlassGrowth.medium,
        onTap: _disabled || loading ? null : widget.onPressed,
        onLongPress: widget.onLongPress,
        focusNode: widget.focusNode,
        enabled: !_disabled,
        loading: loading,
        selected: selected,
        error: showError,
        forceStates: states,
        haptic: v == GlassButtonVariant.primary ? HapticEvent.tapPrimary : null,
        sound: v == GlassButtonVariant.primary ? SoundEvent.tapPrimary : null,
        semanticsLabel: widget.semanticsLabel ?? labelFor,
        tooltip: widget.tooltip,
        disabledReason: widget.disabledReason,
        errorTrigger: widget.errorText == null ? 0 : widget.errorTrigger,
        errorAnnouncement: widget.errorText,
        builder: (context, info) {
          Widget wash = const SizedBox.shrink();
          if (selected) {
            wash = Positioned.fill(
              child: _SelectedWash(key: _wipeKey, origin: _touch ?? Offset(size.width / 2, size.height / 2), reduced: info.reduced),
            );
          }
          final hovered = info.states.hovered && !_disabled;
          final iconColor = showError
              ? gt.colorDanger
              : v == GlassButtonVariant.destructive
                  ? gt.colorDanger
                  : labelColor;

          Widget? leading;
          if (showError) {
            leading = GlassBacking(size: 28, child: GlyphIcon(GlassGlyph.warningCircle, size: 20, color: gt.colorDanger));
          } else if (v == GlassButtonVariant.destructive) {
            leading = GlassBacking(size: 28, child: GlyphIcon(GlassGlyph.trash, size: 20, color: gt.colorDanger));
          } else if (widget.icon != null) {
            final ic = widget.icon!;
            leading = AnimatedSwitcher(
              duration: Duration(milliseconds: gt.springTick.ms),
              transitionBuilder: (child, a) => ScaleTransition(scale: Tween(begin: 0.8, end: 1.0).animate(a), child: FadeTransition(opacity: a, child: child)),
              child: Icon(selected ? ic.fill : ic.regular, key: ValueKey(selected), size: 20, color: iconColor),
            );
          }

          final fadeOut = gt.curveFadeOut, fadeIn = gt.curveFadeIn;
          final labelWidget = AnimatedOpacity(
            opacity: loading ? 0 : 1,
            duration: loading ? fadeOut.duration : fadeIn.duration,
            curve: loading ? fadeOut.curve : fadeIn.curve,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[leading, const SizedBox(width: 8)],
                TweenAnimationBuilder<Color?>(
                  tween: ColorTween(end: hovered && !onTint && !isPlain ? const Color(0xFFFFFFFF) : labelColor),
                  duration: info.reduced ? Duration.zero : gt.curveColorShift.duration,
                  curve: gt.curveColorShift.curve,
                  builder: (context, col, _) => GlassText(
                    labelFor,
                    role: m.role,
                    onGlass: true,
                    wght: info.states.pressed ? baseWght + 40 : baseWght,
                    color: col,
                    maxScale: 1.5,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
          final content = Stack(
            alignment: Alignment.center,
            children: [
              labelWidget,
              AnimatedOpacity(
                opacity: loading ? 1 : 0,
                duration: loading ? fadeIn.duration : fadeOut.duration,
                child: GlassDots(color: labelColor),
              ),
            ],
          );

          if (isPlain) {
            return SizedBox.fromSize(size: size, child: Center(child: content));
          }
          if (v == GlassButtonVariant.destructiveConfirm) {
            return Container(
              width: size.width,
              height: size.height,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: gt.colorDanger, borderRadius: BorderRadius.circular(size.height / 2)),
              child: content,
            );
          }

          final surface = SkinGlass(
            size: size,
            tier: tier,
            finish: finish,
            twin: twin,
            lb: widget.lb,
            role: widget.role,
            overContent: widget.overContent,
            glow: info.glow,
            rimTint: selected ? gt.colorIris300 : null,
            debugLabel: widget.debugLabel ?? 'GlassButton',
            child: Stack(
              alignment: Alignment.center,
              children: [
                wash,
                Padding(padding: EdgeInsets.symmetric(horizontal: padH), child: _disabled ? const SizedBox.shrink() : content),
              ],
            ),
          );
          Widget body = _disabled
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(opacity: 0.4, child: surface),
                    IgnorePointer(child: content),
                  ],
                )
              : surface;
          if (onTint && widget.overContent && twin == null) {
            body = SizedBox.fromSize(size: size, child: GlassLitCaustic(pressed: info.states.pressed, child: body));
          }
          return body;
        },
      );
    },);
  }
}

/// The 22 % `iris600` wash spreading from the touch point as a 200 ms radial wipe (glass 7.1 selected).
class _SelectedWash extends StatefulWidget {
  const _SelectedWash({super.key, required this.origin, required this.reduced});
  final Offset origin;
  final bool reduced;

  @override
  State<_SelectedWash> createState() => _SelectedWashState();
}

class _SelectedWashState extends State<_SelectedWash> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 200))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(painter: _WipePainter(origin: widget.origin, t: widget.reduced ? 1 : Curves.easeOut.transform(_c.value))),
        ),
      );
}

class _WipePainter extends CustomPainter {
  const _WipePainter({required this.origin, required this.t});
  final Offset origin;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final far = math.max(math.max(origin.dx, size.width - origin.dx), math.max(origin.dy, size.height - origin.dy)) * 1.5;
    canvas.drawCircle(origin, far * t, Paint()..color = gt.colorIris600.withValues(alpha: 0.22));
  }

  @override
  bool shouldRepaint(_WipePainter old) => old.t != t || old.origin != origin;
}

/// The download states of `inventory/mobile.md` 6c, as the progress button shows them.
enum GlassDownloadState { idle, queued, saving, complete, failed }

/// The progress button (glass 7.1): "Download" then "Queued", then `mono` "12/40" with the liquid level
/// following, then "Saved", or "Retry" led by a `danger` warning on the backing disc.
class GlassProgressButton extends ConsumerStatefulWidget {
  const GlassProgressButton({
    super.key,
    required this.state,
    required this.onPressed,
    this.done = 0,
    this.total = 0,
    this.queueProgress = 0.08,
    this.twin,
    this.forceStates = GlassWidgetStates.none,
  });

  final GlassDownloadState state;
  final VoidCallback? onPressed;
  final int done;
  final int total;
  final double queueProgress;
  final GlassTwin? twin;
  final GlassWidgetStates forceStates;

  @override
  ConsumerState<GlassProgressButton> createState() => _GlassProgressButtonState();
}

class _GlassProgressButtonState extends ConsumerState<GlassProgressButton> {
  int _shake = 0;

  @override
  void didUpdateWidget(GlassProgressButton old) {
    super.didUpdateWidget(old);
    if (old.state == widget.state) return;
    switch (widget.state) {
      case GlassDownloadState.queued:
        glassFire(ref, HapticEvent.downloadStart);
      case GlassDownloadState.complete:
        glassFire(ref, HapticEvent.downloadDone);
        glassSound(ref, SoundEvent.downloadDone);
      case GlassDownloadState.failed:
        glassFire(ref, HapticEvent.downloadFail);
        glassSound(ref, SoundEvent.downloadFail);
        announceAssertive(context, "Couldn't save this chapter");
        _shake++;
      case GlassDownloadState.idle || GlassDownloadState.saving:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final legible = ref.watch(glassA11yProvider.select((a) => a.legible));
    final label = switch (s) {
      GlassDownloadState.idle => 'Download',
      GlassDownloadState.queued => 'Queued',
      GlassDownloadState.saving => '${widget.done}/${widget.total}',
      GlassDownloadState.complete => 'Saved',
      GlassDownloadState.failed => 'Retry',
    };
    final mono = s == GlassDownloadState.saving;
    final role = mono ? gt.typeMono : gt.typeSubhead;
    final st = roleStyle(context, role, onGlass: true, legible: legible, maxScale: 1.5);
    final w = math.max(measureText(context, label, st).width, measureText(context, 'Download', st).width) + 16 * 2 + 20 + 8;
    final size = Size(w.ceilToDouble(), 44);
    final level = switch (s) {
      GlassDownloadState.idle => 0.0,
      GlassDownloadState.queued => widget.queueProgress,
      GlassDownloadState.saving => widget.total == 0 ? 0.0 : widget.done / widget.total,
      GlassDownloadState.complete => 1.0,
      GlassDownloadState.failed => 0.0,
    };
    final fill = s == GlassDownloadState.complete ? gt.colorSuccess.withValues(alpha: 0.24) : null;
    final semValue = s == GlassDownloadState.saving ? '${widget.done} of ${widget.total} pages saved' : null;
    return GlassPressable(
      onTap: s == GlassDownloadState.queued || s == GlassDownloadState.saving ? null : widget.onPressed,
      enabled: widget.onPressed != null,
      forceStates: widget.forceStates,
      semanticsLabel: label,
      semanticsValue: semValue,
      errorTrigger: _shake,
      errorAnnouncement: null,
      builder: (context, info) {
        Widget lead = switch (s) {
          GlassDownloadState.idle => GlyphIcon(GlassGlyph.cloudArrowDown, size: 20, color: gt.colorOnGlass),
          GlassDownloadState.queued || GlassDownloadState.saving => const GlassSpinner(size: 20),
          GlassDownloadState.complete => const GlassCheckPop(size: 20),
          GlassDownloadState.failed => GlassBacking(size: 28, child: GlyphIcon(GlassGlyph.warningCircle, size: 20, color: gt.colorDanger)),
        };
        return SkinGlass(
          size: size,
          tier: GlassTierId.t2,
          twin: widget.twin,
          glow: info.glow,
          debugLabel: 'GlassProgressButton',
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(child: IgnorePointer(child: LiquidProgress(value: level, color: fill, stepped: info.reduced))),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  lead,
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: gt.curveFadeIn.duration,
                    child: GlassText(label, key: ValueKey(label), role: role, onGlass: true, maxScale: 1.5, maxLines: 1),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
