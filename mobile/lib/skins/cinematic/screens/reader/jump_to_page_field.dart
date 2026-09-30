import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// `07 / 40` under the ruler (cinematic 8.14.3): a button that turns into a number field. The IME
/// action jumps through [onJump]; the back gesture or `Esc` cancels and hands focus back to
/// [returnFocus].
class PageCounterField extends StatefulWidget {
  const PageCounterField({super.key, required this.page, required this.pageCount, required this.onJump, this.returnFocus});

  final int page, pageCount;
  final ValueChanged<int> onJump;

  /// Where focus goes when the field closes.
  final FocusNode? returnFocus;

  @override
  State<PageCounterField> createState() => PageCounterFieldState();
}

class PageCounterFieldState extends State<PageCounterField> {
  bool _editing = false;
  final TextEditingController _text = TextEditingController();
  final FocusNode _focus = FocusNode();

  bool get editing => _editing;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus && _editing) _close();
    });
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Opens the field (the `g` key and a tap).
  void beginEdit() {
    setState(() {
      _editing = true;
      _text.text = '${widget.page}';
      _text.selection = TextSelection(baseOffset: 0, extentOffset: _text.text.length);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _close() {
    if (!mounted) return;
    setState(() => _editing = false);
    widget.returnFocus?.requestFocus();
  }

  void _submit(String value) {
    final n = int.tryParse(value.trim());
    if (n != null) widget.onJump(n.clamp(1, widget.pageCount));
    _close();
  }

  String _pad(int n) => widget.pageCount >= 10 && n < 10 ? '0$n' : '$n';

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final label = '${_pad(widget.page)} / ${widget.pageCount}';
    if (_editing) {
      return SizedBox(
        width: 96,
        height: cineHitMin(context),
        child: CallbackShortcuts(
          bindings: {const SingleActivator(LogicalKeyboardKey.escape): _close},
          child: TextField(
            controller: _text,
            focusNode: _focus,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: _submit,
            style: CineText.style(context, c.typeFolioLg).copyWith(color: c.colorInk100),
            cursorColor: c.colorSpot,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              suffixText: ' / ${widget.pageCount}',
              suffixStyle: CineText.style(context, c.typeFolioLg).copyWith(color: c.colorInk60),
              border: UnderlineInputBorder(borderSide: BorderSide(color: c.colorInk100)),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: c.colorInk100)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: c.colorSpot)),
            ),
          ),
        ),
      );
    }
    return CinePressable(
      onTap: beginEdit,
      builder: (context, st) => ConstrainedBox(
        constraints: BoxConstraints(minHeight: cineHitMin(context), minWidth: cineHitMin(context)),
        child: Semantics(
          button: true,
          label: 'Page ${widget.page} of ${widget.pageCount}',
          hint: 'Jump to a page',
          excludeSemantics: true,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: 1,
            child: CineRoleText(label, c.typeFolioLg, color: st.hovered ? c.colorSpot : c.colorInk100),
          ),
        ),
      ),
    );
  }
}
