import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/progress.dart';
import 'package:manhwamaniacs/skins/glass/primitives/spring_value.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:motor/motor.dart';

/// glass 7.5 chip kinds.
enum GlassChipKind { filter, choice, count, input, assist, tag }

/// One chip. Chips live in scrolling rows, so a selected chip's glass, the assist chip's rim and the
/// choice droplet are content twins (glass 2.4.1 rule 1): the same capsule, rim and inner light with no
/// backdrop read. Visual 32 tall inside the hit (6 px vertical hit padding on iOS for 44, 8 on Android for
/// 48). Chip text uses the 1.5 clamp.
class GlassChip extends ConsumerWidget {
  const GlassChip({
    super.key,
    required this.label,
    this.kind = GlassChipKind.filter,
    this.selected = false,
    this.onPressed,
    this.onRemove,
    this.leading,
    this.count,
    this.loading = false,
    this.error,
    this.enabled = true,
    this.inChoiceGroup = false,
    this.forceStates = GlassWidgetStates.none,
    this.onLink,
    this.semanticsLabel,
  });

  final String label;
  final GlassChipKind kind;
  final bool selected;
  final VoidCallback? onPressed;

  /// `input`: the trailing x.
  final VoidCallback? onRemove;
  final IconData? leading;

  /// `count`: "Pinned 4".
  final int? count;
  final bool loading;

  /// The reason, when the chip is in error (its glyph becomes a warning and the tooltip explains).
  final String? error;
  final bool enabled;

  /// The choice droplet draws the selected state, so the chip itself only sets its label weight.
  final bool inChoiceGroup;
  final GlassWidgetStates forceStates;

  /// `tag`: a link.
  final VoidCallback? onLink;
  final String? semanticsLabel;

  /// The visual width of a chip for [label] (used by the choice group to place its droplet).
  static double widthOf(
    BuildContext context, {
    required String label,
    required GlassChipKind kind,
    bool hasLeading = false,
    int? count,
    bool legible = false,
    bool selected = false,
  }) {
    final hit = GlassFrame.hitMin(context);
    if (kind == GlassChipKind.tag) {
      final st = roleStyle(context, gt.typeCaption1, legible: legible, maxScale: 1.5).copyWith(letterSpacing: 0.08 * 12);
      return measureText(context, label.toUpperCase(), st).width + 16;
    }
    final st = roleStyle(context, gt.typeSubhead, legible: legible, wght: selected ? 600 : 460, maxScale: 1.5);
    var w = 24 + measureText(context, label, st).width + (hasLeading ? 22 : 0);
    if (selected && kind == GlassChipKind.filter && !hasLeading) w += 22;
    if (count != null) {
      final mono = roleStyle(context, gt.typeMono, legible: legible, maxScale: 1.5);
      w += 6 + measureText(context, '$count', mono).width;
    }
    if (kind == GlassChipKind.input) w += 24;
    return math.max(w, hit);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final legible = ref.watch(glassA11yProvider.select((a) => a.legible));
    final hit = GlassFrame.hitMin(context);
    final isTag = kind == GlassChipKind.tag;
    final disabled = !enabled || forceStates.disabled;
    final err = error != null || forceStates.error;
    final isSelected = selected || forceStates.selected;
    final hasLeading = leading != null;
    final visualH = isTag ? 24.0 : 32.0;
    final width = widthOf(context, label: label, kind: kind, hasLeading: hasLeading, count: count, legible: legible, selected: isSelected);
    final size = Size(width, visualH);

    if (isTag) {
      final tag = Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: gt.colorFill4, borderRadius: BorderRadius.circular(12)),
        child: GlassLabel(label, role: gt.typeCaption1, extraTrackingEm: 0.08, upper: true, color: gt.colorLabel2),
      );
      if (onLink == null) return Semantics(label: label, child: ExcludeSemantics(child: tag));
      return GlassPressable(
        material: GlassMaterial.content,
        sink: 0.96,
        onTap: onLink,
        semanticsLabel: label,
        builder: (context, info) => Container(
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: info.states.hovered ? gt.colorFill3 : gt.colorFill4, borderRadius: BorderRadius.circular(12)),
          child: GlassLabel(label, role: gt.typeCaption1, extraTrackingEm: 0.08, upper: true, color: gt.colorLabel2),
        ),
      );
    }

    final glassy = isSelected && kind == GlassChipKind.filter;
    return GlassPressable(
      material: glassy ? GlassMaterial.glass : GlassMaterial.content,
      growth: GlassGrowth.light,
      sink: 0.96,
      onTap: disabled || loading ? null : onPressed,
      enabled: !disabled,
      loading: loading,
      forceStates: forceStates,
      haptic: HapticEvent.select,
      semanticsLabel: semanticsLabel ?? (count != null ? '$label, $count' : label),
      semanticsSelected: kind == GlassChipKind.choice ? null : isSelected,
      checked: kind == GlassChipKind.choice || inChoiceGroup ? isSelected : null,
      inGroup: kind == GlassChipKind.choice || inChoiceGroup,
      tooltip: err ? error : null,
      builder: (context, info) {
        final hov = info.states.hovered && !disabled;
        final Color labelColor = disabled ? gt.colorLabel4 : gt.colorLabel1;
        final wght = isSelected ? 600 : 460;
        Widget lead = const SizedBox.shrink();
        if (err) {
          lead = Padding(padding: const EdgeInsets.only(right: 6), child: GlyphIcon(GlassGlyph.warningCircle, size: 16, color: gt.colorDanger));
        } else if (isSelected && kind == GlassChipKind.filter) {
          lead = Padding(
            padding: const EdgeInsets.only(right: 6),
            child: SpringValue(
              value: 1,
              spring: gt.springTick,
              builder: (context, v, _) => Transform.scale(scale: v.clamp(0.0, 1.25), child: GlyphIcon(GlassGlyph.check, size: 16, color: labelColor)),
            ),
          );
        } else if (hasLeading) {
          lead = Padding(padding: const EdgeInsets.only(right: 6), child: Icon(leading, size: 16, color: labelColor));
        }
        final content = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            lead,
            Flexible(child: GlassLabel(label, role: gt.typeSubhead, wght: wght, color: labelColor, onGlass: glassy)),
            if (count != null) ...[
              const SizedBox(width: 6),
              if (loading) const GlassSpinner(size: 12) else GlassLabel('$count', role: gt.typeMono, color: gt.colorLabel2),
            ],
            if (kind == GlassChipKind.input) const SizedBox(width: 24),
          ],
        );

        Widget body;
        if (glassy) {
          body = SkinGlass(size: size, tier: GlassTierId.t2, twin: GlassTwin.onGlass, glow: info.glow, debugLabel: 'GlassChip', child: Center(child: content));
        } else if (kind == GlassChipKind.assist) {
          body = Container(
            width: size.width,
            height: size.height,
            alignment: Alignment.center,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x38FFFFFF), width: 0.5)),
            child: content,
          );
        } else if (inChoiceGroup) {
          body = SizedBox(width: size.width, height: size.height, child: Center(child: content));
        } else {
          body = Container(
            width: size.width,
            height: size.height,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: hov ? gt.colorFill3 : gt.colorFill2, borderRadius: BorderRadius.circular(16)),
            child: content,
          );
        }
        if (kind == GlassChipKind.input) {
          body = SizedBox(
            width: size.width,
            height: size.height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                body,
                Positioned(
                  right: -(hit - 24) / 2 + 2,
                  top: (size.height - hit) / 2,
                  width: hit,
                  height: hit,
                  child: GlassPressable(
                    material: GlassMaterial.content,
                    sink: 0.92,
                    shape: const GlassShape.circle(),
                    minHit: false,
                    onTap: onRemove,
                    semanticsLabel: 'Remove $label',
                    tooltip: 'Remove $label',
                    builder: (context, info) => Center(child: GlyphIcon(GlassGlyph.x, size: 16, color: gt.colorLabel2)),
                  ),
                ),
              ],
            ),
          );
        }
        return body;
      },
    );
  }
}

/// A removable chip that shrinks on `springDismiss` before it calls [onRemoved]; its siblings close the gap
/// on `springSnappy` (wrap the row in an `AnimatedSize`, as [GlassChipRow] does).
class GlassRemovableChip extends ConsumerStatefulWidget {
  const GlassRemovableChip({super.key, required this.label, required this.onRemoved, this.leading});
  final String label;
  final VoidCallback onRemoved;
  final IconData? leading;

  @override
  ConsumerState<GlassRemovableChip> createState() => _GlassRemovableChipState();
}

class _GlassRemovableChipState extends ConsumerState<GlassRemovableChip> with SingleTickerProviderStateMixin {
  late final SingleMotionController _c = SingleMotionController(motion: SpringMotion(springOf(gt.springDismiss)), vsync: this, initialValue: 1);
  bool _removing = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _remove() async {
    if (_removing) return;
    _removing = true;
    if (ref.read(glassMotionPrefsProvider).reduced) {
      widget.onRemoved();
      return;
    }
    await GlassMotion.playMotor(MotionName.drain, _c, 0);
    if (mounted) widget.onRemoved();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, child) => Opacity(
          opacity: _c.value.clamp(0.0, 1.0),
          child: Align(alignment: Alignment.centerLeft, widthFactor: _c.value.clamp(0.0, 1.0), child: Transform.scale(scale: _c.value.clamp(0.0, 1.0), child: child)),
        ),
        child: GlassChip(label: widget.label, kind: GlassChipKind.input, leading: widget.leading, onRemove: _remove),
      );
}

/// Single-select chips under one shared droplet (`glassFilm` clear capsule, drawn as its content twin).
/// The droplet slides between chips on `springTab`, stretching `scaleX = 1 + min(|v| / 2000, 0.25)` and
/// `scaleY = 1 / sqrt(scaleX)`; it can be caught mid-flight (glass 7.5).
class GlassChoiceChips<T> extends ConsumerStatefulWidget {
  const GlassChoiceChips({super.key, required this.options, required this.selected, required this.onSelected, required this.labelOf});
  final List<T> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final String Function(T) labelOf;

  @override
  ConsumerState<GlassChoiceChips<T>> createState() => _GlassChoiceChipsState<T>();
}

class _GlassChoiceChipsState<T> extends ConsumerState<GlassChoiceChips<T>> with TickerProviderStateMixin {
  static const double gap = 8;
  late final SingleMotionController _x = SingleMotionController(motion: SpringMotion(springOf(gt.springTab)), vsync: this);
  late final SingleMotionController _w = SingleMotionController(motion: SpringMotion(springOf(gt.springTab)), vsync: this);
  bool _placed = false;
  T? _last;

  @override
  void dispose() {
    _x.dispose();
    _w.dispose();
    super.dispose();
  }

  List<double> _widths(BuildContext context, bool legible) => [
        for (final o in widget.options) GlassChip.widthOf(context, label: widget.labelOf(o), kind: GlassChipKind.choice, legible: legible, selected: o == widget.selected),
      ];

  @override
  Widget build(BuildContext context) {
    final legible = ref.watch(glassA11yProvider.select((a) => a.legible));
    final reduced = ref.watch(glassReducedProvider);
    final widths = _widths(context, legible);
    final idx = math.max(0, widget.options.indexOf(widget.selected));
    var x = 0.0;
    final lefts = <double>[];
    for (final w in widths) {
      lefts.add(x);
      x += w + gap;
    }
    final total = x - gap;
    if (!_placed) {
      _placed = true;
      _last = widget.selected;
      _x.value = lefts[idx];
      _w.value = widths[idx];
    } else if (_last != widget.selected) {
      _last = widget.selected;
      if (reduced) {
        _x.stop();
        _w.stop();
        _x.value = lefts[idx];
        _w.value = widths[idx];
      } else {
        GlassMotion.playMotor(MotionName.tabDroplet, _x, lefts[idx], withVelocity: _x.velocity);
        _w.motion = SpringMotion(springOf(gt.springTab));
        _w.animateTo(widths[idx], withVelocity: _w.velocity);
      }
    } else if (!_x.isAnimating) {
      _x.value = lefts[idx];
      _w.value = widths[idx];
    }
    final hit = GlassFrame.hitMin(context);
    return SizedBox(
      width: total,
      height: math.max(32.0, hit),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([_x, _w]),
            builder: (context, _) {
              final sx = (1 + math.min(_x.velocity.abs() / 2000, 0.25)).toDouble();
              final sy = (1 / math.sqrt(sx)).toDouble();
              return Positioned(
                left: _x.value,
                top: (math.max(32.0, hit) - 32) / 2,
                width: math.max(_w.value, 1.0),
                height: 32,
                child: IgnorePointer(
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.diagonal3Values(sx, sy, 1),
                    child: SkinGlass(size: Size(math.max(_w.value, 1.0), 32), tier: GlassTierId.t1, twin: GlassTwin.onGlass, debugLabel: 'GlassChoiceDroplet', materialize: false, child: const SizedBox.expand()),
                  ),
                ),
              );
            },
          ),
          for (var i = 0; i < widget.options.length; i++)
            Positioned(
              left: lefts[i],
              top: 0,
              child: GlassChip(
                label: widget.labelOf(widget.options[i]),
                kind: GlassChipKind.choice,
                selected: widget.options[i] == widget.selected,
                inChoiceGroup: true,
                onPressed: () => widget.onSelected(widget.options[i]),
              ),
            ),
        ],
      ),
    );
  }
}
