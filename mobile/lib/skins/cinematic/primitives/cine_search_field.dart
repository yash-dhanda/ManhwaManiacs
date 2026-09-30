import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_text_field.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/typed_ticker.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

enum CineSearchVariant { indexField, compact }

/// The search field (cinematic 7.4). `index`: Bodoni Moda Italic, the empty placeholder typed at
/// 50 ms per grapheme as a visual layer; `compact`: `typeUi` with a leading glass.
class CineSearchField extends StatefulWidget {
  const CineSearchField({
    super.key,
    required this.semanticLabel,
    required this.placeholder,
    this.variant = CineSearchVariant.indexField,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitNow,
    this.onArrowDown,
    this.onArrowUp,
    this.autofocus = false,
  });

  /// e.g. "Search every source", "Search what a character said", "Search or jump".
  final String semanticLabel;
  final String placeholder;
  final CineSearchVariant variant;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;

  /// Enter: submit now, skipping the caller's 300 ms debounce.
  final ValueChanged<String>? onSubmitNow;
  final VoidCallback? onArrowDown, onArrowUp;
  final bool autofocus;

  @override
  State<CineSearchField> createState() => _CineSearchFieldState();
}

class _CineSearchFieldState extends State<CineSearchField> with SingleTickerProviderStateMixin {
  late final TextEditingController _ctl = widget.controller ?? TextEditingController();
  late final FocusNode _node = widget.focusNode ?? FocusNode();
  TypedTextTicker? _typer;
  int _typed = 0;
  bool _focused = false, _hover = false, _started = false;

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocus);
    _ctl.addListener(_onText);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (widget.variant == CineSearchVariant.indexField) {
      if (CineMotion.reduced(context)) {
        _typed = widget.placeholder.characters.length;
      } else {
        _typer = TypedTextTicker(
          length: widget.placeholder.characters.length,
          vsync: this,
          onCount: (n) {
            if (mounted) setState(() => _typed = n);
          },
        )..start();
      }
    }
  }

  void _onFocus() => setState(() => _focused = _node.hasFocus);

  void _onText() => setState(() {});

  @override
  void dispose() {
    _typer?.dispose();
    _node.removeListener(_onFocus);
    _ctl.removeListener(_onText);
    if (widget.focusNode == null) _node.dispose();
    if (widget.controller == null) _ctl.dispose();
    super.dispose();
  }

  KeyEventResult _key(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    if (e.logicalKey == LogicalKeyboardKey.escape) {
      if (_ctl.text.isNotEmpty) {
        _ctl.clear();
        widget.onChanged?.call('');
      } else {
        _node.unfocus();
      }
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.enter) {
      widget.onSubmitNow?.call(_ctl.text);
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.arrowDown && widget.onArrowDown != null) {
      widget.onArrowDown!();
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.arrowUp && widget.onArrowUp != null) {
      widget.onArrowUp!();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final index = widget.variant == CineSearchVariant.indexField;
    final role = index ? c.typeField : c.typeUi;
    final empty = _ctl.text.isEmpty;
    final base = CineText.style(context, role);
    // Roman once there is text, Italic while it is the prompt (7.4).
    final typedStyle = base.copyWith(color: c.colorInk100, fontStyle: index && !empty ? FontStyle.normal : base.fontStyle);
    final hintStyle = base.copyWith(color: _focused ? c.colorInk45 : const Color(0x00000000));
    final scaler = CineText.scaler(context, role);

    final field = Stack(alignment: Alignment.centerLeft, children: [
      MediaQuery.withClampedTextScaling(
        maxScaleFactor: role.cap,
        child: TextField(
          controller: _ctl,
          focusNode: _node,
          autofocus: widget.autofocus,
          textInputAction: TextInputAction.search,
          keyboardType: TextInputType.text,
          autocorrect: false,
          enableSuggestions: false,
          style: typedStyle,
          cursorColor: c.colorSpot,
          cursorWidth: index ? 3 : 2,
          cursorRadius: Radius.zero,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitNow,
          decoration: InputDecoration.collapsed(hintText: widget.placeholder, hintStyle: hintStyle),
        ),
      ),
      if (index && empty && !_focused)
        IgnorePointer(
          child: ExcludeSemantics(
            child: Text(widget.placeholder.characters.take(_typed).toString(), style: base.copyWith(color: c.colorInk45), textScaler: scaler, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
    ],);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _key,
        child: Semantics(
          textField: true,
          label: widget.semanticLabel,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: index ? 56 : cineHitMin(context)),
              child: Row(children: [
                if (!index) ...[CineGlyphIcon(CineGlyph.magnifyingGlass, color: c.colorInk60), SizedBox(width: c.space2)],
                Expanded(child: field),
                if (!empty)
                  CinePressable(
                    onTap: () {
                      _ctl.clear();
                      widget.onChanged?.call('');
                      _node.requestFocus();
                    },
                    builder: (_, st) => Padding(
                      padding: EdgeInsets.only(left: c.space2),
                      child: CineRoleText('Clear', c.typeLabel, color: st.hovered ? c.colorInk100 : c.colorInk60),
                    ),
                  ),
              ],),
            ),
            CineFieldUnderline(focused: _focused, hovered: _hover),
          ],),
        ),
      ),
    );
  }
}
