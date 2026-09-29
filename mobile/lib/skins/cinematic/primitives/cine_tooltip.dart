import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_keycap.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// Flutter's `Tooltip` in the skin's dress (cinematic 7.2): `paper.2`, 1 px `rule.2`, radius 0,
/// 500 ms wait, long-press on touch, and at once on hardware-keyboard focus.
class CineTooltip extends StatefulWidget {
  const CineTooltip({super.key, required this.message, required this.child, this.shortcut, this.excludeFromSemantics = false});
  final String message;
  final Widget child;
  final List<LogicalKeyboardKey>? shortcut;

  /// True when the wrapped control already carries the same label.
  final bool excludeFromSemantics;

  @override
  State<CineTooltip> createState() => _CineTooltipState();
}

class _CineTooltipState extends State<CineTooltip> {
  final _key = GlobalKey<TooltipState>();

  void _focus(bool has) {
    if (has && FocusManager.instance.highlightMode == FocusHighlightMode.traditional) {
      _key.currentState?.ensureTooltipVisible();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final style = CineText.style(context, c.typeCaption).copyWith(color: c.colorInk100);
    return Tooltip(
      key: _key,
      message: widget.shortcut == null ? widget.message : null,
      richMessage: widget.shortcut == null
          ? null
          : TextSpan(children: [
              TextSpan(text: '${widget.message}  '),
              WidgetSpan(alignment: PlaceholderAlignment.middle, child: CineKeycap(keys: widget.shortcut!)),
            ],),
      decoration: BoxDecoration(color: c.colorPaper2, border: Border.all(color: c.colorRule2)),
      textStyle: style,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      waitDuration: const Duration(milliseconds: 500),
      excludeFromSemantics: widget.excludeFromSemantics,
      triggerMode: TooltipTriggerMode.longPress,
      child: Focus(canRequestFocus: false, skipTraversal: true, onFocusChange: _focus, child: widget.child),
    );
  }
}
