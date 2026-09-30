import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

class _DottedPainter extends CustomPainter {
  const _DottedPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 4) {
      canvas.drawLine(Offset(x, 0.5), Offset(x + 2, 0.5), p);
    }
  }

  @override
  bool shouldRepaint(_DottedPainter o) => o.color != color;
}

/// The field's underline: 1 px `rule.2` (hover `ink.45`), 2 px `spot` drawn from the left on focus
/// (240 ms), 2 px `proof` on error, dotted when disabled.
class CineFieldUnderline extends StatefulWidget {
  const CineFieldUnderline({super.key, required this.focused, this.hovered = false, this.error = false, this.disabled = false});
  final bool focused, hovered, error, disabled;

  @override
  State<CineFieldUnderline> createState() => _CineFieldUnderlineState();
}

class _CineFieldUnderlineState extends State<CineFieldUnderline> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: CineDur.line, value: widget.focused ? 1 : 0);
  }

  @override
  void didUpdateWidget(CineFieldUnderline old) {
    super.didUpdateWidget(old);
    if (old.focused != widget.focused) {
      if (CineMotion.reduced(context)) {
        _c.value = widget.focused ? 1 : 0;
      } else {
        _c.animateTo(widget.focused ? 1 : 0, curve: CineCurves.settle, duration: widget.focused ? CineDur.line : CineDur.beat);
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    if (widget.disabled) return SizedBox(height: 1, width: double.infinity, child: CustomPaint(painter: _DottedPainter(c.colorRule2)));
    return SizedBox(
      height: 2,
      width: double.infinity,
      child: Stack(children: [
        Align(
          alignment: Alignment.topCenter,
          child: AnimatedContainer(duration: c.durBeat, height: 1, color: widget.hovered ? c.colorInk45 : c.colorRule2),
        ),
        if (widget.error)
          Positioned.fill(child: ColoredBox(color: c.colorProof))
        else
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, __) => Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(widthFactor: _c.value, child: ColoredBox(color: c.colorSpot)),
              ),
            ),
          ),
      ],),
    );
  }
}

/// The editorial field (cinematic 7.3): no box, a kicker label, a 1 px underline and a helper or
/// error line. Callers set keyboard type, autofill and capitalisation per field.
/// The value's type role: `ui` (the default) or `field` (Bodoni Moda Italic, the profile name).
enum CineFieldSize { ui, field }

class CineTextField extends StatefulWidget {
  const CineTextField({
    super.key,
    required this.label,
    this.controller,
    this.focusNode,
    this.hint,
    this.helperText,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.enabled = true,
    this.loading = false,
    this.success = false,
    this.successHold,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.minLines,
    this.inputFormatters,
    this.textAlign = TextAlign.start,
    this.numeric = false,
    this.suffixText,
    this.trailing,
    this.ruled = false,
    this.initialValue,
    this.size = CineFieldSize.ui,
  });

  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hint, helperText, errorText, suffixText, initialValue;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool autocorrect, enableSuggestions, obscureText, enabled, loading, success, numeric, ruled;
  final TextCapitalization textCapitalization;
  final CineFieldSize size;

  /// Overrides the 1600 ms `holdSuccess` (mobile/07's Setup passes `CineDur.holdConnected`).
  final Duration? successHold;
  final ValueChanged<String>? onChanged, onSubmitted;
  final int maxLines;
  final int? minLines;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign textAlign;

  /// A widget at the right end (the password field's Show / Hide).
  final Widget? trailing;

  @override
  State<CineTextField> createState() => _CineTextFieldState();
}

class _CineTextFieldState extends State<CineTextField> {
  late final TextEditingController _ctl = widget.controller ?? TextEditingController(text: widget.initialValue);
  late final FocusNode _node = widget.focusNode ?? FocusNode();
  bool _focused = false, _hover = false, _check = false;
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocus);
    if (widget.success) _flashSuccess();
  }

  void _onFocus() => setState(() => _focused = _node.hasFocus);

  void _flashSuccess() {
    _checkTimer?.cancel();
    _check = true;
    _checkTimer = Timer(widget.successHold ?? CineDur.holdSuccess, () {
      if (mounted) setState(() => _check = false);
    });
  }

  @override
  void didUpdateWidget(CineTextField old) {
    super.didUpdateWidget(old);
    if (!old.success && widget.success) _flashSuccess();
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _node.removeListener(_onFocus);
    if (widget.focusNode == null) _node.dispose();
    if (widget.controller == null) _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final role = widget.numeric ? c.typeFolioLg : (widget.size == CineFieldSize.field ? c.typeField : c.typeUi);
    final error = widget.errorText != null;
    final disabled = !widget.enabled;
    var text = CineText.style(context, role).copyWith(color: disabled ? c.colorInk30 : c.colorInk100);
    if (!widget.numeric && widget.size == CineFieldSize.ui) text = text.copyWith(fontSize: 16);
    final reduced = CineMotion.reduced(context);
    final fade = reduced ? Duration.zero : c.durSnap;
    // A one-line field carries its 12 / 16 px of air inside the TextField, so its semantics node
    // is the full 48 px tap target rather than the 20 px of text.
    final tall = !widget.ruled && (widget.maxLines == 1 || widget.obscureText);

    Widget field = MediaQuery.withClampedTextScaling(
      maxScaleFactor: role.cap,
      child: TextField(
        controller: _ctl,
        focusNode: _node,
        enabled: widget.enabled,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        autofillHints: widget.autofillHints,
        autocorrect: widget.autocorrect,
        enableSuggestions: widget.enableSuggestions,
        textCapitalization: widget.textCapitalization,
        inputFormatters: widget.inputFormatters,
        textAlign: widget.textAlign,
        minLines: widget.minLines,
        maxLines: widget.obscureText ? 1 : widget.maxLines,
        style: text,
        cursorColor: c.colorSpot,
        cursorRadius: Radius.zero,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        decoration: tall
            ? InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.only(top: 12, bottom: 16),
                hintText: widget.hint,
                hintStyle: text.copyWith(color: c.colorInk45),
              )
            : InputDecoration.collapsed(hintText: widget.hint, hintStyle: text.copyWith(color: c.colorInk45)),
      ),
    );
    if (widget.ruled) {
      final lineH = (text.fontSize ?? 16) * (text.height ?? 1.3);
      field = Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _RuledPainter(lineH, c.colorRule1))),
        field,
      ],);
    }

    final trailing = <Widget>[
      if (widget.suffixText != null) ...[SizedBox(width: c.space2), CineRoleText(widget.suffixText!, c.typeUi, color: c.colorInk45)],
      AnimatedSwitcher(
        duration: fade,
        child: widget.loading
            ? const Padding(padding: EdgeInsets.only(left: 8), child: CineLeaderDial(key: ValueKey('dial'), size: 16, showAfter: Duration.zero))
            : (_check
                ? Padding(padding: const EdgeInsets.only(left: 8), child: CineGlyphIcon(CineGlyph.check, size: 16, color: c.colorSet, key: const ValueKey('check')))
                : const SizedBox.shrink(key: ValueKey('none'))),
      ),
      if (widget.trailing != null) widget.trailing!,
    ];

    final line = error ? '‸ ${widget.errorText}' : widget.helperText;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Semantics(
        textField: true,
        label: widget.label,
        hint: widget.errorText,
        enabled: widget.enabled,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExcludeSemantics(child: CineRoleText(widget.label, c.typeKicker, color: _focused ? c.colorInk100 : c.colorInk45)),
            SizedBox(height: c.space2),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: tall ? EdgeInsets.zero : const EdgeInsets.only(top: 12, bottom: 16),
                child: Row(children: [Expanded(child: field), ...trailing]),
              ),
            ),
            CineFieldUnderline(focused: _focused, hovered: _hover, error: error, disabled: disabled),
            if (line != null) ...[
              SizedBox(height: c.space2),
              ExcludeSemantics(child: CineRoleText(line, c.typeCaption, color: error ? c.colorProof : c.colorInk45)),
            ],
          ],
        ),
      ),
    );
  }
}

class _RuledPainter extends CustomPainter {
  const _RuledPainter(this.lineHeight, this.color);
  final double lineHeight;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var y = lineHeight; y <= size.height + 0.5; y += lineHeight) {
      canvas.drawLine(Offset(0, y - 0.5), Offset(size.width, y - 0.5), p);
    }
  }

  @override
  bool shouldRepaint(_RuledPainter o) => o.lineHeight != lineHeight || o.color != color;
}
