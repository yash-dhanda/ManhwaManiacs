import 'dart:async';

import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/slider.dart';
import 'package:manhwamaniacs/skins/glass/primitives/text_field.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

// TODO(mobile/35): mobile/35 builds the reader's go-to popover; when it lands, render that one here with the novel's slider and
// field (percent, or page in paged mode) and delete this local copy.

/// The go-to popover (E6): `glassThick`, 280 wide, blooming above the bottom capsule on `springMorph`; a slider 0-100 % (`detent.tick`
/// every 5 %) and a number field with "%" after it; Go (tinted) or `TextInputAction.go` jumps. In paged mode the slider steps by page
/// and the field takes a page number. It rises by the keyboard height on `springSnappy`. An anchored picker: no `?sheet=`.
class NovelGoToPopover extends ConsumerStatefulWidget {
  const NovelGoToPopover({super.key, required this.value, required this.onGo, required this.onClose, this.pages, required this.lb});

  /// The current percent (1-100) or, paged, the current page (1-based).
  final int value;

  /// Paged mode: the page count; null for percent.
  final int? pages;
  final ValueChanged<int> onGo;
  final VoidCallback onClose;
  final double lb;

  @override
  ConsumerState<NovelGoToPopover> createState() => _NovelGoToPopoverState();
}

class _NovelGoToPopoverState extends ConsumerState<NovelGoToPopover> with SingleTickerProviderStateMixin {
  late final AnimationController _bloom;
  late final TextEditingController _field = TextEditingController(text: '${widget.value}');
  late double _v = widget.value.toDouble();
  int _lastDetent = -1;

  bool get _paged => widget.pages != null;
  int get _max => widget.pages ?? 100;

  @override
  void initState() {
    super.initState();
    _bloom = AnimationController(vsync: this);
    unawaited(GlassMotion.play(MotionName.bloom, controller: _bloom, target: 1));
  }

  @override
  void dispose() {
    _bloom.dispose();
    _field.dispose();
    super.dispose();
  }

  void _slide(double v) {
    final step = _paged ? 1 : 5;
    final d = (v / step).round();
    if (d != _lastDetent) {
      _lastDetent = d;
      glassFire(ref, HapticEvent.detentTick);
    }
    setState(() {
      _v = v;
      _field.text = '${v.round()}';
    });
  }

  void _go([String? text]) {
    final n = double.tryParse((text ?? _field.text).trim());
    if (n == null) return;
    widget.onGo(n.round().clamp(_paged ? 1 : 0, _max));
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedPadding(
      duration: Duration(milliseconds: glassTokens.springSnappy.ms),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: keyboard),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.85, end: 1).animate(_bloom),
        alignment: Alignment.bottomCenter,
        child: FadeTransition(
          opacity: _bloom.drive(Tween(begin: 0, end: 1)),
          child: Semantics(
            scopesRoute: true,
            explicitChildNodes: true,
            label: _paged ? 'Go to a page' : 'Go to a percentage',
            child: SizedBox(
              width: 280,
              child: SkinGlass(
                tier: GlassTierId.t4,
                lb: widget.lb,
                layer: GlassLayerKind.overlays,
                debugLabel: 'novel go-to popover',
                shape: const GlassShape.superellipse(26),
                child: GlassHost(
                  child: Material(
                    type: MaterialType.transparency,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GlassText(_paged ? 'Go to a page' : 'Go to a percentage', role: gt.typeHeadline, onGlass: true, maxScale: 1.3),
                          const SizedBox(height: 8),
                          GlassSlider(
                            value: _v.clamp(_paged ? 1 : 0, _max.toDouble()).toDouble(),
                            min: _paged ? 1 : 0,
                            max: _max.toDouble(),
                            divisions: _paged ? (_max - 1).clamp(1, 1000) : 100,
                            label: _paged ? 'Page' : 'Percent',
                            onChanged: _slide,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: GlassTextField(
                                  controller: _field,
                                  label: _paged ? 'Page' : 'Percent',
                                  onSheet: true,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                                  textInputAction: TextInputAction.go,
                                  onSubmitted: _go,
                                ),
                              ),
                              if (!_paged) Padding(padding: const EdgeInsets.only(left: 8), child: GlassText('%', role: gt.typeBody, onGlass: true)),
                              const SizedBox(width: 8),
                              GlassButton(label: 'Go', onPressed: _go, variant: GlassButtonVariant.primary, size: GlassButtonSize.small),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
