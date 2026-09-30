import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manhwamaniacs/skins/cinematic/a11y/folio.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// What the folio reads (a tap cycles them).
enum NovelFolioMode { chapter, book, timeLeft }

/// The progress folio of the bottom bar (cinematic 8.15.3): `42% · 6 MIN LEFT`. A tap cycles
/// chapter %, book %, time left; a 450 ms press (or `g`, through [NovelProgressFolioState.beginEdit])
/// turns it into a number field (`42 %`, `TextInputType.number`): IME done jumps to that paragraph
/// bucket, `Esc` or the back gesture cancels.
class NovelProgressFolio extends StatefulWidget {
  const NovelProgressFolio({
    super.key,
    required this.stock,
    required this.chapterPercent,
    required this.minutesLeft,
    required this.onGoTo,
    this.bookPercent,
    this.onEditingChanged,
  });

  final CineStockColors stock;
  final int chapterPercent;
  final int? bookPercent;
  final int minutesLeft;

  /// A percent (1-100) typed in the field.
  final ValueChanged<int> onGoTo;
  final ValueChanged<bool>? onEditingChanged;

  @override
  State<NovelProgressFolio> createState() => NovelProgressFolioState();
}

class NovelProgressFolioState extends State<NovelProgressFolio> {
  NovelFolioMode _mode = NovelFolioMode.chapter;
  bool _editing = false;
  final TextEditingController _text = TextEditingController();
  final FocusNode _focus = FocusNode(debugLabel: 'novel go-to percent');

  bool get editing => _editing;

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void beginEdit() {
    if (_editing) return;
    setState(() {
      _editing = true;
      _text.text = '${widget.chapterPercent}';
      _text.selection = TextSelection(baseOffset: 0, extentOffset: _text.text.length);
    });
    widget.onEditingChanged?.call(true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void cancelEdit() {
    if (!_editing) return;
    setState(() => _editing = false);
    widget.onEditingChanged?.call(false);
  }

  void _submit(String v) {
    final n = int.tryParse(v.trim());
    setState(() => _editing = false);
    widget.onEditingChanged?.call(false);
    if (n != null) widget.onGoTo(n.clamp(1, 100));
  }

  String get _label {
    final chapter = '${widget.chapterPercent}%';
    switch (_mode) {
      case NovelFolioMode.chapter:
        return '$chapter · ${widget.minutesLeft} MIN LEFT';
      case NovelFolioMode.book:
        return widget.bookPercent == null ? chapter : 'BOOK ${widget.bookPercent}%';
      case NovelFolioMode.timeLeft:
        return '${widget.minutesLeft} MIN LEFT';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final stock = widget.stock;
    final hit = cineHitMin(context);
    if (_editing) {
      return SizedBox(
        height: hit,
        width: 132,
        child: Focus(
          onKeyEvent: (node, e) {
            if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
              cancelEdit();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) => cancelEdit(),
            child: Center(
              child: Semantics(
                textField: true,
                label: 'Go to percent of this chapter',
                child: TextField(
                  key: const Key('novel-progress-field'),
                  controller: _text,
                  focusNode: _focus,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  textAlign: TextAlign.center,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                  style: CineText.style(context, c.typeFolio).copyWith(color: stock.ink),
                  cursorColor: stock.ink,
                  decoration: InputDecoration(
                    isDense: true,
                    suffixText: ' %',
                    suffixStyle: CineText.style(context, c.typeFolio).copyWith(color: stock.muted),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: stock.muted)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: c.colorSpot)),
                  ),
                  onSubmitted: _submit,
                  onTapOutside: (_) => cancelEdit(),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Semantics(
      button: true,
      label: folioLabel(_label),
      hint: 'Tap to change what this shows. Press and hold to go to a percent.',
      excludeSemantics: true,
      onTap: _cycle,
      onLongPress: beginEdit,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _cycle,
        onLongPress: beginEdit,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: hit, minWidth: hit),
          child: Center(child: CineRoleText(_label, c.typeFolio, color: stock.muted)),
        ),
      ),
    );
  }

  void _cycle() => setState(() => _mode = NovelFolioMode.values[(_mode.index + 1) % NovelFolioMode.values.length]);
}
