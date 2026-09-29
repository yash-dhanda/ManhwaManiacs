import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/a11y/folio.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/cine_icon.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

enum CineButtonVariant { primary, split, secondary, quiet, destructive, onArt, play, link }

enum CineButtonSize { lg, md, sm }

String _lowerFirst(String s) => s.isEmpty ? s : '${s[0].toLowerCase()}${s.substring(1)}';

/// The button family (cinematic 7.1): square, no ripple, no shadow. Loading keeps the label's box
/// and runs a 2 px `spot` segment along the inside bottom edge.
class CineButton extends StatefulWidget {
  const CineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = CineButtonVariant.primary,
    this.size = CineButtonSize.md,
    this.icon,
    this.leadingGlyph,
    this.folio,
    this.loadingLabel,
    this.loading = false,
    this.selected = false,
    this.errorText,
    this.toggle = false,
    this.disabledReason,
    this.focusNode,
  });

  final String label;
  final VoidCallback? onPressed;
  final CineButtonVariant variant;
  final CineButtonSize size;
  final CineIconRole? icon;

  /// A Phosphor codepoint (`CineGlyph.check`) for leading glyphs no icon role names.
  final int? leadingGlyph;
  final String? folio;
  final String? loadingLabel;
  final bool loading;
  final bool selected;
  final String? errorText;

  /// A toggle ("Following"): exposes `toggled` and swaps to the selected look when [selected].
  final bool toggle;

  /// Shown in a tooltip when the disabled state is not obvious.
  final String? disabledReason;
  final FocusNode? focusNode;

  @override
  State<CineButton> createState() => _CineButtonState();
}

class _CineButtonState extends State<CineButton> with SingleTickerProviderStateMixin {
  Timer? _errorTimer, _loadTimer;
  bool _errorOn = false, _loadingLabel = false, _hoverRule = false;
  late final AnimationController _rule;

  @override
  void initState() {
    super.initState();
    _rule = AnimationController(vsync: this);
    _syncLoading();
    if (widget.errorText != null) _flashError();
  }

  @override
  void didUpdateWidget(CineButton old) {
    super.didUpdateWidget(old);
    if (old.loading != widget.loading) _syncLoading();
    if (old.errorText != widget.errorText && widget.errorText != null) _flashError();
  }

  void _syncLoading() {
    _loadTimer?.cancel();
    _loadingLabel = false;
    if (widget.loading && widget.loadingLabel != null) {
      _loadTimer = Timer(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _loadingLabel = true);
      });
    }
  }

  void _flashError() {
    _errorTimer?.cancel();
    _errorOn = true;
    _errorTimer = Timer(CineDur.holdError, () {
      if (mounted) setState(() => _errorOn = false);
    });
  }

  @override
  void dispose() {
    _errorTimer?.cancel();
    _loadTimer?.cancel();
    _rule.dispose();
    super.dispose();
  }

  void _hover(bool on) {
    if (_hoverRule == on) return;
    _hoverRule = on;
    final reduced = CineMotion.reduced(context);
    if (reduced) {
      _rule.value = on ? 1 : 0;
    } else {
      _rule.animateTo(on ? 1 : 0, duration: on ? CineDur.line : CineDur.beat, curve: on ? CineCurves.settle : CineCurves.lift);
    }
  }

  bool get _primaryish => widget.variant == CineButtonVariant.primary || widget.variant == CineButtonVariant.split;

  void _tap() {
    final cb = widget.onPressed;
    if (cb == null || widget.loading) return;
    if (_primaryish) {
      cineFeedback(context, HapticEvent.tapPrimary, sound: SoundEvent.tapPrimary);
    } else {
      cineFeedback(context, HapticEvent.tapSecondary);
    }
    cb();
  }

  double _height() => switch (widget.size) { CineButtonSize.lg => 56, CineButtonSize.md => 48, CineButtonSize.sm => 32 };

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final v = widget.variant;
    if (v == CineButtonVariant.link) return _link(context, c);
    final enabled = widget.onPressed != null && !widget.loading;
    final disabled = widget.onPressed == null;
    final error = _errorOn && widget.errorText != null;
    final reflow = CineReflow.of(context);
    final label = (_loadingLabel && widget.loadingLabel != null) ? widget.loadingLabel! : widget.label;

    Widget core = CinePressable(
      enabled: enabled,
      round: v == CineButtonVariant.play,
      focusNode: widget.focusNode,
      onTap: _tap,
      onHover: _hover,
      builder: (context, st) => _visual(context, c, st, label, disabled: disabled, error: error, stack: reflow.stackSplit),
    );

    final semanticsLabel = v == CineButtonVariant.split && widget.folio != null && !disabled
        ? '${widget.label}, ${_lowerFirst(folioLabel(widget.folio!))}'
        : widget.label;
    core = Semantics(
      button: true,
      enabled: !disabled,
      selected: widget.selected,
      toggled: widget.toggle ? widget.selected : null,
      label: semanticsLabel,
      value: widget.loading ? 'Loading' : null,
      excludeSemantics: true,
      onTap: enabled ? _tap : null,
      child: core,
    );
    if (disabled && widget.disabledReason != null) {
      core = Tooltip(message: widget.disabledReason, child: core);
    }
    if (widget.errorText == null) return core;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        core,
        SizedBox(height: c.space2),
        Semantics(liveRegion: true, child: CineRoleText(widget.errorText!, c.typeCaption, color: c.colorProof)),
      ],
    );
  }

  Widget _link(BuildContext context, CineTokens c) {
    final style = CineText.style(context, c.typeBody).copyWith(color: c.colorInk100, decoration: TextDecoration.underline, decorationColor: c.colorInk100, decorationThickness: 1);
    final enabled = widget.onPressed != null;
    return CineFocusRing(
      hit: cineHitMin(context),
      onActivate: enabled ? _tap : null,
      child: Semantics(
        link: true,
        enabled: enabled,
        label: widget.label,
        excludeSemantics: true,
        onTap: enabled ? _tap : null,
        child: Text.rich(
          TextSpan(text: widget.label, style: style, recognizer: enabled ? (TapGestureRecognizer()..onTap = _tap) : null),
          textScaler: CineText.scaler(context, c.typeBody),
        ),
      ),
    );
  }

  Widget _visual(BuildContext context, CineTokens c, CinePressState st, String label, {required bool disabled, required bool error, required bool stack}) {
    final v = widget.variant;
    final reduced = CineMotion.reduced(context);
    final pressed = st.pressed;
    const black = Color(0xFF000000);
    late Color bg, fg;
    Color? border;
    var underline = false;
    switch (v) {
      case CineButtonVariant.primary:
      case CineButtonVariant.split:
        bg = disabled ? c.colorPaper3 : (error ? c.colorProof : (pressed ? c.colorInk80 : c.colorInk100));
        fg = disabled ? c.colorInk30 : black;
      case CineButtonVariant.secondary:
        final sel = widget.selected;
        bg = sel ? c.colorInk100 : (pressed ? c.colorPaper3 : (st.hovered ? c.colorPaper4 : const Color(0x00000000)));
        fg = disabled ? c.colorInk30 : (sel ? black : (error ? c.colorProof : c.colorInk100));
        border = disabled ? c.colorInk30 : (error ? c.colorProof : c.colorInk100);
      case CineButtonVariant.quiet:
      case CineButtonVariant.link:
        bg = const Color(0x00000000);
        fg = disabled ? c.colorInk30 : (error ? c.colorProof : c.colorInk60);
        underline = st.hovered && !disabled;
      case CineButtonVariant.destructive:
        bg = pressed ? c.colorProofWash : (st.hovered ? c.colorProofWash : const Color(0x00000000));
        fg = disabled ? c.colorInk30 : (pressed ? c.colorProofPress : c.colorProof);
        border = disabled ? c.colorInk30 : (pressed ? c.colorProofPress : c.colorProof);
      case CineButtonVariant.onArt:
        bg = c.colorOnart;
        fg = disabled ? c.colorInk30 : c.colorInk100;
        border = c.colorInk100.withValues(alpha: 0.4);
      case CineButtonVariant.play:
        bg = disabled ? c.colorPaper3 : (pressed ? c.colorInk80 : c.colorInk100);
        fg = disabled ? c.colorInk30 : black;
    }
    final dur = reduced ? Duration.zero : (pressed ? c.durTick : c.durBeat);
    final curve = pressed ? c.easeSet : c.easeSettle;

    if (v == CineButtonVariant.play) {
      final wide = MediaQuery.sizeOf(context).width >= 600;
      final d = widget.size == CineButtonSize.sm ? 36.0 : (wide ? 64.0 : 56.0);
      final glyph = widget.icon ?? CineIconRole.play;
      return AnimatedContainer(
        duration: dur,
        curve: curve,
        width: d,
        height: d,
        transform: Matrix4.translationValues(0, pressed ? 1 : 0, 0),
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: CineIcon(glyph, size: widget.size == CineButtonSize.sm ? 20 : 24, weight: CineIconWeight.fill, color: fg),
      );
    }

    final hpad = widget.size == CineButtonSize.sm ? c.space4 : c.space6;
    final showCheck = v == CineButtonVariant.secondary && widget.selected;
    Widget text(String t, {CineTextRole? role, Color? color}) => AnimatedSwitcher(
          duration: reduced ? Duration.zero : c.durBeat,
          child: CineRoleText(t, role ?? c.typeLabel, color: color ?? fg, key: ValueKey(t), maxLines: stack ? 2 : 1, overflow: TextOverflow.ellipsis),
        );
    final leading = <Widget>[
      if (showCheck) ...[CineGlyphIcon(CineGlyph.check, color: fg), SizedBox(width: c.space2)],
      if (!showCheck && widget.icon != null) ...[CineIcon(widget.icon!, size: 20, color: fg), SizedBox(width: c.space2)],
      if (!showCheck && widget.icon == null && widget.leadingGlyph != null) ...[CineGlyphIcon(widget.leadingGlyph!, color: fg), SizedBox(width: c.space2)],
    ];

    Widget body;
    if (v == CineButtonVariant.split && widget.folio != null && !disabled) {
      final folio = CineRoleText(widget.folio!, c.typeFolio, color: fg);
      if (stack) {
        body = Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisSize: MainAxisSize.min, children: [...leading, Flexible(child: text(label))]),
          SizedBox(height: c.space2),
          folio,
        ],);
      } else {
        body = Row(mainAxisSize: MainAxisSize.min, children: [
          ...leading,
          Flexible(child: text(label)),
          SizedBox(width: c.space4),
          Container(width: 1, height: 20, color: black),
          SizedBox(width: c.space4),
          folio,
        ],);
      }
    } else {
      body = Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [...leading, Flexible(child: text(label))]);
    }

    final minH = (v == CineButtonVariant.split && stack) ? 64.0 : _height();
    Widget box = AnimatedContainer(
      duration: dur,
      curve: curve,
      constraints: BoxConstraints(minHeight: minH),
      padding: EdgeInsets.symmetric(horizontal: v == CineButtonVariant.quiet ? c.space2 : hpad, vertical: stack && v == CineButtonVariant.split ? c.space2 : 0),
      transform: Matrix4.translationValues(0, pressed ? 1 : 0, 0),
      decoration: BoxDecoration(color: bg, border: border == null ? null : Border.all(color: border)),
      alignment: Alignment.center,
      child: underline
          ? Column(mainAxisSize: MainAxisSize.min, children: [body, SizedBox(height: c.space1), Container(height: 1, color: fg)])
          : body,
    );

    // Wash grounds re-provide ink tokens (2.1.1).
    if (v == CineButtonVariant.destructive && (st.hovered || pressed)) box = CineStock.wash(box);

    final stackChildren = <Widget>[
      box,
      if (widget.loading)
        const Positioned(left: 0, right: 0, bottom: 0, child: IgnorePointer(child: CineIndeterminateRule(track: false))),
      if (_primaryish && !disabled)
        Positioned(
          left: 0,
          right: 0,
          bottom: -6,
          height: 2,
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _rule,
              builder: (_, __) => Transform(alignment: Alignment.centerLeft, transform: Matrix4.diagonal3Values(_rule.value, 1, 1), child: ColoredBox(color: c.colorSpot)),
            ),
          ),
        ),
    ];
    return Stack(clipBehavior: Clip.none, children: stackChildren);
  }
}
