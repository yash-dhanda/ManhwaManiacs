import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/a11y/folio.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// One slug: a word (uppercase Archivo), an optional raised count.
class CineSlug {
  const CineSlug(this.id, this.label, {this.count, this.disabled = false, this.removable = false});
  final String id;
  final String label;
  final int? count;
  final bool disabled;

  /// A removable token: the label and an `x` in a 1 px square box.
  final bool removable;
}

/// Slug lines (cinematic 7.5): filter chips set as running heads. Single-select slides a 2 px
/// `spot` underline between chips (Rule slide, 320 ms); multi-select draws one per chip (240 ms).
class CineSlugLines extends StatefulWidget {
  const CineSlugLines({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
    this.multi = false,
    this.loading = false,
    this.onRemove,
  });

  final List<CineSlug> items;
  final Set<String> selected;
  final ValueChanged<String> onChanged;
  final bool multi, loading;
  final ValueChanged<String>? onRemove;

  @override
  State<CineSlugLines> createState() => _CineSlugLinesState();
}

class _CineSlugLinesState extends State<CineSlugLines> {
  final _stack = GlobalKey();
  final Map<String, GlobalKey> _keys = {};
  Rect? _under;

  GlobalKey _key(String id) => _keys.putIfAbsent(id, GlobalKey.new);

  void _measure() {
    if (!mounted || widget.multi) return;
    final id = widget.selected.isEmpty ? null : widget.selected.first;
    final chip = id == null ? null : _keys[id]?.currentContext?.findRenderObject() as RenderBox?;
    final stack = _stack.currentContext?.findRenderObject() as RenderBox?;
    Rect? r;
    if (chip != null && chip.attached && stack != null && stack.attached) {
      final o = stack.globalToLocal(chip.localToGlobal(Offset.zero));
      r = Rect.fromLTWH(o.dx + 12, o.dy + chip.size.height / 2 + 12, (chip.size.width - 24).clamp(0.0, 9999), 2);
    }
    if (r != _under) setState(() => _under = r);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    final reduced = CineMotion.reduced(context);
    final hit = cineHitMin(context);
    final children = <Widget>[];
    for (var i = 0; i < widget.items.length; i++) {
      if (i > 0) children.add(ExcludeSemantics(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: CineLit('·', CineFace.archivo, 12, 16, color: c.colorInk30))));
      children.add(_chip(context, c, widget.items[i], hit));
    }
    final row = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Stack(key: _stack, clipBehavior: Clip.none, children: [
        Row(children: children),
        if (!widget.multi && _under != null)
          AnimatedPositioned(
            key: const Key('slug-underline'),
            duration: reduced ? Duration.zero : c.durColumn,
            curve: c.easeSettle,
            left: _under!.left,
            top: _under!.top,
            width: _under!.width,
            height: 2,
            child: ColoredBox(color: c.colorSpot),
          ),
      ],),
    );
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (r) => const LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0x00FFFFFF)], stops: [0, 0.94, 1]).createShader(r),
      child: row,
    );
  }

  Widget _chip(BuildContext context, CineTokens c, CineSlug s, double hit) {
    final selected = widget.selected.contains(s.id);
    final multi = widget.multi;
    final reduced = CineMotion.reduced(context);
    final spoken = folioLabel(s.label, count: widget.loading ? null : s.count);

    Widget visual(CinePressState st) {
      final color = s.disabled ? c.colorInk30 : (selected || st.hovered ? c.colorInk100 : c.colorInk45);
      final label = CineLit(s.label, CineFace.archivo, 12, 16, upper: true, wght: 600, wdth: 75, tracking: 0.10, color: color);
      final count = s.count == null && !widget.loading
          ? null
          : Transform.translate(offset: const Offset(0, -4.2), child: CineLit(widget.loading ? '–' : '${s.count}', CineFace.plexMono, 10, 12, color: c.colorInk45));
      Widget line = Row(mainAxisSize: MainAxisSize.min, children: [label, if (count != null) ...[const SizedBox(width: 2), count]]);
      if (s.removable) {
        line = Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(border: Border.all(color: c.colorRule2)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [label, const SizedBox(width: 6), CineGlyphIcon(CineGlyph.x, size: 12, color: color)]),
        );
      }
      Widget box = Padding(padding: EdgeInsets.symmetric(horizontal: s.removable ? 0 : 12), child: line);
      box = ConstrainedBox(constraints: BoxConstraints(minWidth: 44, minHeight: hit), child: Center(widthFactor: 1, child: box));
      if (multi && selected && !s.removable) {
        box = Stack(clipBehavior: Clip.none, children: [
          box,
          Positioned(
            left: 12,
            right: 12,
            top: hit / 2 + 12,
            height: 2,
            child: CineRuleDraw(kind: CineRuleKind.spot, draw: !reduced),
          ),
        ],);
      }
      return AnimatedContainer(duration: reduced ? Duration.zero : c.durTick, transform: Matrix4.translationValues(0, st.pressed ? 1 : 0, 0), child: box);
    }

    void tap() {
      cineFeedback(context, HapticEvent.select, sound: SoundEvent.select);
      if (s.removable) {
        widget.onRemove?.call(s.id);
      } else {
        widget.onChanged(s.id);
      }
    }

    return KeyedSubtree(
      key: _key(s.id),
      child: Semantics(
        button: multi || s.removable,
        inMutuallyExclusiveGroup: multi ? null : true,
        checked: multi ? null : selected,
        toggled: multi ? selected : null,
        enabled: !s.disabled,
        label: s.removable ? 'Remove $spoken' : spoken,
        excludeSemantics: true,
        onTap: s.disabled ? null : tap,
        child: CinePressable(hit: false, enabled: !s.disabled, onTap: tap, builder: (_, st) => visual(st)),
      ),
    );
  }
}
