import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/cine_icon.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_tooltip.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

enum CineIconButtonVariant { bare, onArt, ruled, badged }

/// The icon-only button (cinematic 7.2). [label] is required: it becomes the semantics label and
/// the tooltip.
class CineIconButton extends StatefulWidget {
  const CineIconButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.role,
    this.codepoint,
    this.variant = CineIconButtonVariant.bare,
    this.selected = false,
    this.loading = false,
    this.errorReason,
    this.count,
    this.shortcut,
  }) : assert(role != null || codepoint != null, 'give a role or a codepoint');

  final String label;
  final VoidCallback? onPressed;
  final CineIconRole? role;
  final int? codepoint;
  final CineIconButtonVariant variant;
  final bool selected;
  final bool loading;

  /// The tooltip's reason while the glyph is `proof` (2000 ms).
  final String? errorReason;

  /// The badge count for `badged`.
  final int? count;
  final List<LogicalKeyboardKey>? shortcut;

  @override
  State<CineIconButton> createState() => _CineIconButtonState();
}

class _CineIconButtonState extends State<CineIconButton> {
  Timer? _err;
  bool _errorOn = false;

  @override
  void initState() {
    super.initState();
    if (widget.errorReason != null) _flash();
  }

  @override
  void didUpdateWidget(CineIconButton old) {
    super.didUpdateWidget(old);
    if (old.errorReason != widget.errorReason && widget.errorReason != null) _flash();
  }

  void _flash() {
    _err?.cancel();
    _errorOn = true;
    _err = Timer(CineDur.holdError, () {
      if (mounted) setState(() => _errorOn = false);
    });
  }

  @override
  void dispose() {
    _err?.cancel();
    super.dispose();
  }

  Widget _glyph(Color color, double size, {bool fill = false}) {
    final w = fill ? CineIconWeight.fill : null;
    return widget.role != null
        ? CineIcon(widget.role!, size: size, weight: w, color: color)
        : CineGlyphIcon(widget.codepoint!, size: size, weight: w, color: color);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final v = widget.variant;
    final disabled = widget.onPressed == null;
    final enabled = !disabled && !widget.loading;
    final reduced = CineMotion.reduced(context);
    final onArt = v == CineIconButtonVariant.onArt;
    final size = onArt ? 40.0 : (v == CineIconButtonVariant.ruled ? 36.0 : 36.0);
    final glyphSize = (v == CineIconButtonVariant.bare || v == CineIconButtonVariant.badged) ? 24.0 : 20.0;

    Widget button = CinePressable(
      enabled: enabled,
      onTap: () {
        cineFeedback(context, HapticEvent.tapSecondary);
        widget.onPressed?.call();
      },
      builder: (context, st) {
        final err = _errorOn && widget.errorReason != null;
        final color = disabled
            ? c.colorInk30
            : err
                ? c.colorProof
                : (st.hovered || onArt || widget.selected ? c.colorInk100 : c.colorInk60);
        final d = reduced ? Duration.zero : (st.pressed ? c.durTick : c.durBeat);
        Widget visual = AnimatedContainer(
          duration: d,
          curve: st.pressed ? c.easeSet : c.easeSettle,
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: st.pressed ? c.colorPaper3 : (onArt ? c.colorOnart : null),
            border: v == CineIconButtonVariant.ruled
                ? Border.all(color: c.colorRule2)
                : (st.hovered && !disabled ? Border.all(color: c.colorInk30) : null),
          ),
          child: AnimatedSwitcher(
            duration: reduced ? Duration.zero : c.durSnap,
            child: widget.loading
                ? const CineLeaderDial(key: ValueKey('dial'), size: 16, showAfter: Duration.zero)
                : Transform.translate(
                    key: ValueKey(widget.selected),
                    offset: Offset(0, st.pressed ? 1 : 0),
                    child: _glyph(color, glyphSize, fill: widget.selected),
                  ),
          ),
        );
        if (widget.selected) {
          visual = Stack(clipBehavior: Clip.none, children: [
            visual,
            Positioned(
              left: 0,
              right: 0,
              bottom: -6,
              height: 2,
              child: CineRuleDraw(kind: CineRuleKind.spot, draw: !reduced),
            ),
          ],);
        }
        if (v == CineIconButtonVariant.badged && (widget.count ?? 0) > 0) {
          visual = Stack(clipBehavior: Clip.none, children: [
            visual,
            Positioned(
              right: -4,
              top: -2,
              child: Container(
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                color: c.colorSpot,
                child: CineLit(widget.count! > 99 ? '99+' : '${widget.count}', CineFace.plexMono, 10, 12, color: const Color(0xFF000000)),
              ),
            ),
          ],);
        }
        return visual;
      },
    );

    button = Semantics(
      button: true,
      enabled: !disabled,
      selected: widget.selected,
      label: widget.label,
      value: widget.loading ? 'Loading' : null,
      excludeSemantics: true,
      onTap: enabled ? widget.onPressed : null,
      child: button,
    );
    final tip = _errorOn && widget.errorReason != null ? widget.errorReason! : widget.label;
    return CineTooltip(message: tip, shortcut: widget.shortcut, excludeFromSemantics: true, child: button);
  }
}
