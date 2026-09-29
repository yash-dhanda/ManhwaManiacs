import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// The index field (§7.4): Bodoni Moda Italic while empty, Roman once it holds
/// a query; a `spot` cursor; a rule that becomes a 2 px `spot` underline on
/// focus. The typed hint sits behind the field while it is empty and unfocused.
class IndexField extends StatefulWidget {
  const IndexField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.onChanged,
    required this.onSubmitted,
    this.onClear,
    this.compact = false,
    this.semanticsLabel,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback? onClear;
  final bool compact;
  final String? semanticsLabel;

  @override
  State<IndexField> createState() => _IndexFieldState();
}

class _IndexFieldState extends State<IndexField> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_rebuild);
    widget.controller.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_rebuild);
    widget.controller.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    final focused = widget.focusNode.hasFocus;
    final empty = widget.controller.text.isEmpty;
    final role = widget.compact ? t.typeTitle : t.typeField;
    final base = cineText(context, role);
    // Roman once there is a query.
    final style = empty || widget.compact
        ? base
        : base.copyWith(fontStyle: FontStyle.normal);
    final label = widget.semanticsLabel ?? widget.hint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          alignment: Alignment.centerLeft,
          children: [
            if (empty && !focused && !widget.compact)
              IgnorePointer(
                child: ExcludeSemantics(
                  child: TypedText(
                    widget.hint,
                    style: base.copyWith(color: t.colorInk45),
                    maxLines: 1,
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    container: true,
                    child: TextField(
                      controller: widget.controller,
                      focusNode: widget.focusNode,
                      style: style,
                      cursorColor: t.colorSpot,
                      cursorWidth: 3,
                      cursorRadius: Radius.zero,
                      textInputAction: TextInputAction.search,
                      autocorrect: false,
                      enableSuggestions: false,
                      onChanged: widget.onChanged,
                      onSubmitted: widget.onSubmitted,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: CineSpace.s3),
                        // The label doubles as the hint and as the semantics
                        // label; it only paints where a hint would.
                        labelText: label,
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        labelStyle: base.copyWith(
                          color: (widget.compact || focused) ? t.colorInk45 : const Color(0x00000000),
                        ),
                      ),
                    ),
                  ),
                ),
                if (!empty && widget.onClear != null)
                  QuietButton('Clear', onPressed: widget.onClear),
              ],
            ),
          ],
        ),
        Stack(
          children: [
            Container(height: 1, color: t.colorRule2),
            AnimatedContainer(
              duration: cineReduced(context) ? CineDur.reduced : CineDur.line,
              curve: CineCurves.settle,
              height: 2,
              width: focused ? MediaQuery.sizeOf(context).width : 0,
              color: t.colorSpot,
            ),
          ],
        ),
      ],
    );
  }
}
