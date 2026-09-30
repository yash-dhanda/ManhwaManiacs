import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/primitives/chip.dart';
import 'package:manhwamaniacs/skins/glass/primitives/chip_row.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/text_area.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

const int kAskMin = 3, kAskMax = 600;

const List<String> kAskExamples = [
  'A murim regressor who comes back stronger',
  'Magic academy, but the lead is already strong',
  'Something slow and political, not a power fantasy',
];

/// The Ask box (glass 9.1.2): a content-layer text area (3 lines growing to 6), 3 to 600 characters, the always-visible counter, and
/// a 0.5 px `machineRim` while focused or thinking. Enter from a hardware keyboard asks, Shift+Enter breaks a line.
class AskBox extends StatefulWidget {
  const AskBox(
      {super.key,
      required this.controller,
      required this.focusNode,
      required this.thinking,
      required this.onSubmit,
      this.onChanged,});
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool thinking;
  final ValueChanged<String> onSubmit;
  final VoidCallback? onChanged;

  @override
  State<AskBox> createState() => _AskBoxState();
}

class _AskBoxState extends State<AskBox> {
  bool _focused = false;

  void _f() {
    if (_focused != widget.focusNode.hasFocus && mounted) {
      setState(() => _focused = widget.focusNode.hasFocus);
    }
  }

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_f);
    widget.controller.addListener(_c);
  }

  void _c() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_f);
    widget.controller.removeListener(_c);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.controller.text.characters.length;
    final lit = _focused || widget.thinking;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            GlassTextArea(
              controller: widget.controller,
              focusNode: widget.focusNode,
              label: 'Ask for something to read',
              hint: 'A revenge story with a competent lead, no harem',
              maxLength: kAskMax,
              showCounter: false,
              submitOnEnter: true,
              imeAction: TextInputAction.newline,
              onSubmit: widget.onSubmit,
              onChanged: (_) => widget.onChanged?.call(),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: gt.curveColorShift.duration,
                  curve: gt.curveColorShift.curve,
                  margin: const EdgeInsets.only(top: 22),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                          color: lit
                              ? gt.colorMachineRim
                              : const Color(0x00000000),
                          width: 0.5,),),
                ),
              ),
            ),
          ],
        ),
        Padding(
            padding: const EdgeInsets.only(top: 4),
            child: GlassText('$n / $kAskMax',
                role: gt.typeMono,
                size: 13,
                height: 16,
                color: n >= kAskMax * 0.95 ? gt.colorWarning : gt.colorLabel3,),),
      ],
    );
  }
}

/// The example chips: a tap fills the box and asks.
class AskExamples extends StatelessWidget {
  const AskExamples({super.key, required this.onPick});
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) => GlassChipRow(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          for (final e in kAskExamples)
            GlassChip(
                label: e,
                kind: GlassChipKind.assist,
                onPressed: () => onPick(e),),
        ],
      );
}
