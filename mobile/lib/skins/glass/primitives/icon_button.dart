import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/badge.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart' show GlassButtonIcon;
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/progress.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';

/// glass 7.2 icon button kinds.
enum GlassIconButtonKind { nav, plain, row }

/// An icon-only control (glass 7.2): `nav` (a `glassThin` circle 44), `plain` (no background), `row`
/// (a `fill3` circle 32). All have a hit area of `hitMin` (44 iOS, 48 Android), a semantics label and a
/// tooltip. A toggle carries a constant label with `Semantics(toggled:)`.
class GlassIconButton extends ConsumerStatefulWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.kind = GlassIconButtonKind.plain,
    this.toggle,
    this.onColor,
    this.badge,
    this.loading = false,
    this.errorAction,
    this.errorTrigger = 0,
    this.onLongPress,
    this.forceStates = GlassWidgetStates.none,
    this.twin,
    this.tooltip,
    this.disabledReason,
    this.lb = 1.0,
    this.haptic,
  });

  final GlassButtonIcon icon;

  /// The semantics label and the tooltip. A constant-label toggle ("Favourite", "Pin source") keeps it
  /// whichever way it is set.
  final String label;
  final VoidCallback? onPressed;
  final GlassIconButtonKind kind;

  /// null: a plain button. true or false: a toggle in that state.
  final bool? toggle;

  /// The colour of the Fill glyph when a toggle is on: `iris400` (pin, follow), `streakCore` (favourite),
  /// `success` (downloaded).
  final Color? onColor;
  final int? badge;
  final bool loading;

  /// "save": on error the glyph swaps to a warning for 2 s and "Couldn't save" is announced.
  final String? errorAction;
  final int errorTrigger;
  final VoidCallback? onLongPress;
  final GlassWidgetStates forceStates;
  final GlassTwin? twin;
  final String? tooltip;
  final String? disabledReason;
  final double lb;
  final HapticEvent? haptic;

  @override
  ConsumerState<GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends ConsumerState<GlassIconButton> {
  bool _showError = false;
  Timer? _timer;

  @override
  void didUpdateWidget(GlassIconButton old) {
    super.didUpdateWidget(old);
    if (widget.errorTrigger > old.errorTrigger && widget.errorAction != null) {
      _timer?.cancel();
      setState(() => _showError = true);
      _timer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showError = false);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final k = widget.kind;
    final inHost = GlassHost.of(context);
    final onGlassSurface = k == GlassIconButtonKind.nav || inHost;
    final disabled = widget.onPressed == null || widget.forceStates.disabled;
    final loading = widget.loading || widget.forceStates.loading;
    final error = _showError || widget.forceStates.error;
    final on = widget.toggle ?? false;
    final selected = on || widget.forceStates.selected;
    final visual = k == GlassIconButtonKind.row ? 32.0 : (k == GlassIconButtonKind.nav ? 44.0 : GlassFrame.hitMin(context));
    final iconSize = k == GlassIconButtonKind.row ? 18.0 : 22.0;
    final material = k == GlassIconButtonKind.nav ? GlassMaterial.glass : GlassMaterial.content;
    final hit = GlassFrame.hitMin(context);

    return GlassPressable(
      material: material,
      growth: GlassGrowth.light,
      sink: 0.92,
      shape: const GlassShape.circle(),
      onTap: disabled || loading ? null : widget.onPressed,
      onLongPress: widget.onLongPress,
      longPressHaptic: widget.onLongPress != null ? HapticEvent.stackOpen : null,
      enabled: !disabled,
      loading: loading,
      selected: selected,
      error: error,
      forceStates: widget.forceStates,
      haptic: widget.haptic ?? (on ? HapticEvent.toggleOff : (widget.toggle == false ? HapticEvent.toggleOn : null)),
      semanticsLabel: widget.badge != null && widget.badge! > 0 ? '${widget.label}, ${widget.badge} new' : widget.label,
      toggled: widget.toggle,
      tooltip: widget.tooltip ?? widget.label,
      disabledReason: widget.disabledReason,
      errorTrigger: widget.errorAction == null ? 0 : widget.errorTrigger,
      errorAnnouncement: widget.errorAction == null ? null : "Couldn't ${widget.errorAction}",
      shakeAmplitude: 6,
      builder: (context, info) {
        final hov = info.states.hovered && !disabled;
        final pressed = info.states.pressed;
        final Color base = disabled ? GlassColors.g500 : (onGlassSurface ? gt.colorOnGlass : GlassColors.g800);
        Widget glyph;
        if (loading) {
          glyph = const GlassSpinner();
        } else if (error) {
          final g = GlyphIcon(GlassGlyph.warningCircle, size: iconSize, color: gt.colorDanger);
          glyph = onGlassSurface ? GlassBacking(size: 28, child: g) : g;
        } else {
          final colored = selected && widget.onColor != null;
          final useFill = selected || pressed;
          final icon = Icon(useFill ? widget.icon.fill : widget.icon.regular, size: iconSize, color: colored ? widget.onColor : base);
          glyph = colored && onGlassSurface ? GlassBacking(size: 28, child: icon) : icon;
          if (widget.toggle != null) glyph = GlassPop(trigger: on, peak: 1.12, child: glyph);
        }
        Widget core = SizedBox.square(dimension: visual, child: Center(child: glyph));
        if (k == GlassIconButtonKind.row) {
          core = DecoratedBox(decoration: BoxDecoration(color: gt.colorFill3, shape: BoxShape.circle), child: core);
        } else if (k == GlassIconButtonKind.plain && hov) {
          core = Stack(
            alignment: Alignment.center,
            children: [Container(width: 40, height: 40, decoration: BoxDecoration(color: gt.colorFill4, shape: BoxShape.circle)), core],
          );
        }
        if (k == GlassIconButtonKind.nav) {
          core = SkinGlass(
            size: Size.square(visual),
            tier: GlassTierId.t2,
            shape: const GlassShape.circle(),
            twin: widget.twin,
            lb: widget.lb,
            glow: info.glow,
            debugLabel: 'GlassIconButton',
            child: Center(child: glyph),
          );
        }
        final padded = k == GlassIconButtonKind.row ? SizedBox(width: math.max(hit, visual), height: math.max(hit, visual), child: Center(child: core)) : core;
        return GlassBadged(badge: widget.badge != null && widget.badge! > 0 ? GlassBadge.count(widget.badge!) : null, child: padded);
      },
    );
  }
}
