import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_segmented_control.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_kit.dart' show TypedText;
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The three example asks: typed into the empty field one at a time (every 6 s) and offered as
/// chips that fill the field and submit.
const kAskExamples = [
  'A murim regressor who comes back stronger',
  'Magic academy, but the lead is already strong',
  'Something slow and political, not a power fantasy',
];

const kAskMin = 3, kAskMax = 600;

bool askValid(String text) {
  final n = text.trim().characters.length;
  return n >= kAskMin && n <= kAskMax;
}

/// The Ask block (cinematic 9.1.3): the index field in prompt mode (Bodoni Moda Italic, Roman once
/// typed) with its typed, cycling hint, `12 / 600`, the example chips, the quota folio, the
/// source toggle and `Ask the editors`. Enter submits, Shift+Enter inserts a newline.
class PicksAskBlock extends StatefulWidget {
  const PicksAskBlock({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onAsk,
    required this.everywhere,
    required this.onEverywhere,
    this.asking = false,
    this.disabled = false,
    this.remaining,
    this.caption,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onAsk;

  /// `FROM EVERYWHERE` (`POST /library/world/suggest`) or `FROM YOUR SOURCES` (`POST /library/suggest`).
  final bool everywhere;
  final ValueChanged<bool> onEverywhere;
  final bool asking, disabled;

  /// Asks left today; the folio shows from 10 down.
  final int? remaining;

  /// A line under the field while the desk is closed.
  final String? caption;

  @override
  State<PicksAskBlock> createState() => _PicksAskBlockState();
}

class _PicksAskBlockState extends State<PicksAskBlock> {
  Timer? _cycle;
  int _example = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
    widget.focusNode.addListener(_rebuild);
    _cycle = Timer.periodic(const Duration(seconds: 6), (_) {
      if (mounted) setState(() => _example = (_example + 1) % kAskExamples.length);
    });
  }

  @override
  void dispose() {
    _cycle?.cancel();
    widget.controller.removeListener(_rebuild);
    widget.focusNode.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  void _submit() {
    if (widget.disabled || widget.asking || !askValid(widget.controller.text)) return;
    widget.onAsk(widget.controller.text.trim());
  }

  void _chip(String text) {
    widget.controller.text = text;
    widget.controller.selection = TextSelection.collapsed(offset: text.length);
    widget.onAsk(text);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final tablet = MediaQuery.sizeOf(context).width >= 600;
    final empty = widget.controller.text.isEmpty;
    final field = CineText.style(context, c.typeField).copyWith(color: c.colorInk100, fontSize: tablet ? 32 : 28, height: tablet ? 40 / 32 : 36 / 28);
    final typed = field.copyWith(fontStyle: empty ? FontStyle.italic : FontStyle.normal);
    final n = widget.controller.text.characters.length;
    final valid = askValid(widget.controller.text);
    final remaining = widget.remaining;
    final folio = remaining != null && remaining <= 10 ? '$remaining ${remaining == 1 ? 'ASK' : 'ASKS'} LEFT TODAY' : null;
    final reduced = CineMotion.reduced(context);
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      Stack(alignment: Alignment.topLeft, children: [
        if (empty)
          IgnorePointer(
            child: ExcludeSemantics(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: c.space3),
                child: reduced
                    ? Text(kAskExamples[_example], style: field.copyWith(fontStyle: FontStyle.italic, color: c.colorInk45), textScaler: scaler)
                    : TypedText(kAskExamples[_example], key: ValueKey(_example), style: field.copyWith(fontStyle: FontStyle.italic, color: c.colorInk45)),
              ),
            ),
          ),
        Focus(
          canRequestFocus: false,
          onKeyEvent: (_, e) {
            if (e is KeyDownEvent && (e.logicalKey == LogicalKeyboardKey.enter || e.logicalKey == LogicalKeyboardKey.numpadEnter) && !HardwareKeyboard.instance.isShiftPressed) {
              _submit();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: TextField(
            key: const Key('ask-field'),
            controller: widget.controller,
            focusNode: widget.focusNode,
            enabled: !widget.disabled,
            style: typed,
            cursorColor: c.colorSpot,
            cursorWidth: 3,
            cursorRadius: Radius.zero,
            minLines: 1,
            maxLines: 4,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.send,
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: [LengthLimitingTextInputFormatter(kAskMax)],
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: c.space3),
              labelText: 'Describe what you feel like reading',
              hintText: kAskExamples.first,
              floatingLabelBehavior: FloatingLabelBehavior.never,
              labelStyle: typed.copyWith(color: const Color(0x00000000)),
              hintStyle: typed.copyWith(color: const Color(0x00000000)),
            ),
          ),
        ),
      ],),
      Stack(children: [
        Container(height: 1, color: c.colorRule2),
        AnimatedContainer(duration: reduced ? CineDur.reduced : CineDur.line, curve: CineCurves.settle, height: 2, width: widget.focusNode.hasFocus ? MediaQuery.sizeOf(context).width : 0, color: c.colorSpot),
      ],),
      Padding(
        padding: EdgeInsets.only(top: c.space1),
        child: Row(children: [
          if (folio != null) CineRoleText(folio, c.typeFolio, color: remaining == 0 ? c.colorInk60 : c.colorInk45),
          const Spacer(),
          Semantics(label: '$n of $kAskMax characters', excludeSemantics: true, child: CineRoleText('$n / $kAskMax', c.typeFolio, color: c.colorInk45)),
        ],),
      ),
      if (widget.caption != null) Padding(padding: EdgeInsets.only(top: c.space2), child: CineRoleText(widget.caption!, c.typeCaption, color: c.colorInk60)),
      SizedBox(height: c.space3),
      Wrap(spacing: c.space2, children: [
        for (final e in kAskExamples)
          CineButton(label: e, variant: CineButtonVariant.quiet, size: CineButtonSize.sm, onPressed: widget.disabled || widget.asking ? null : () => _chip(e)),
      ],),
      SizedBox(height: c.space3),
      CineSegmentedControl(labels: const ['FROM YOUR SOURCES', 'FROM EVERYWHERE'], index: widget.everywhere ? 1 : 0, onChanged: (i) => widget.onEverywhere(i == 1)),
      SizedBox(height: c.space4),
      Align(
        alignment: Alignment.centerLeft,
        child: CineButton(
          key: const Key('ask-button'),
          label: 'Ask the editors',
          leadingGlyph: CineGlyph.sparkle,
          loading: widget.asking,
          onPressed: widget.disabled || !valid ? null : _submit,
        ),
      ),
    ],);
  }
}
