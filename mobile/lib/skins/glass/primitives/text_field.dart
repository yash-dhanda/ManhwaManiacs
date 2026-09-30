
import 'package:flutter/material.dart' show InputDecoration, TextField, TextSelectionTheme, TextSelectionThemeData;
import 'package:flutter/semantics.dart' show SemanticsValidationResult;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/glass/focus_ring.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/progress.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';

/// What a text field is for (glass 7.3): the keyboard, the autofill hints and the leading and trailing parts.
enum GlassFieldKind { text, password, url, number }

/// The well every form field sits in: a content-layer capsule, never glass (glass 7.3). `fill3` on black,
/// `fill2` on a solid sheet, `wellOnGlass` inside T4/T5 glass (read from [GlassHost]); the focus ring, the
/// hover brightening and the `errorRing` (1.5 px `danger`).
class GlassWell extends ConsumerWidget {
  const GlassWell({
    super.key,
    required this.child,
    this.focused = false,
    this.hovered = false,
    this.error = false,
    this.onSheet = false,
    this.minHeight = 50,
    this.forceFocusRing = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final Widget child;
  final bool focused;
  final bool hovered;
  final bool error;

  /// On a solid sheet the well is `fill2`.
  final bool onSheet;
  final double minHeight;
  final bool forceFocusRing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inHost = GlassHost.of(context);
    Color fill = inHost ? gt.colorWellOnGlass : (onSheet ? gt.colorFill2 : gt.colorFill3);
    if ((focused || hovered) && !inHost) fill = gt.colorFill2;
    if ((focused || hovered) && inHost) fill = const Color(0x73000000);
    const shape = GlassShape.superellipse(14);
    return GlassFocusRing(
      shape: shape,
      forceVisible: forceFocusRing || focused,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: fill,
            shape: RoundedSuperellipseBorder(
              borderRadius: BorderRadius.circular(14),
              side: error ? BorderSide(color: gt.colorDanger, width: 1.5) : BorderSide.none,
            ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// The message under a field: `footnote`, led by a warning glyph when it is an error.
class GlassFieldMessage extends ConsumerWidget {
  const GlassFieldMessage({super.key, required this.text, this.error = false});
  final String? text;
  final bool error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inHost = GlassHost.of(context);
    return AnimatedSize(
      duration: Duration(milliseconds: gt.springSnappy.ms),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topLeft,
      child: text == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: 6),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: gt.curveFadeIn.duration,
                curve: gt.curveFadeIn.curve,
                builder: (context, o, child) => Opacity(opacity: o, child: child),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (error) ...[
                      Padding(padding: const EdgeInsets.only(top: 1), child: GlyphIcon(GlassGlyph.warningCircle, size: 16, color: gt.colorDanger)),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: GlassLabel(
                        text!,
                        role: gt.typeFootnote,
                        color: error ? gt.colorDanger : (inHost ? gt.colorOnGlass : gt.colorLabel3),
                        maxLines: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// A form field (glass 7.3): text, password, url or number. See the states there.
class GlassTextField extends ConsumerStatefulWidget {
  const GlassTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.kind = GlassFieldKind.text,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.enabled = true,
    this.loading = false,
    this.validating = false,
    this.reachable = false,
    this.onChanged,
    this.onSubmitted,
    this.autofillHints,
    this.errorTrigger = 0,
    this.username = false,
    this.onSheet = false,
    this.forceStates = GlassWidgetStates.none,
    this.semanticsLabel,
    this.textInputAction,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.keyboardType,
    this.counter,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final GlassFieldKind kind;
  final String? label;
  final String? hint;
  final String? helper;

  /// The message, when the field is invalid.
  final String? error;
  final bool enabled;
  final bool loading;

  /// url: a spinner while validating, a `success` check when [reachable].
  final bool validating;
  final bool reachable;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;

  /// Every increase shakes the field (6 px), fires the `error` haptic and announces [error].
  final int errorTrigger;

  /// A username: no capitalisation, autocorrect or suggestions.
  final bool username;
  final bool onSheet;
  final GlassWidgetStates forceStates;
  final String? semanticsLabel;

  /// Overrides the kind's IME action (Login's username moves on with `next`).
  final TextInputAction? textInputAction;
  final bool autofocus;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;

  /// Overrides the kind's keyboard (an email field).
  final TextInputType? keyboardType;

  /// A `mono` counter under the field's trailing edge ("24/30"); null draws none.
  final String? counter;

  @override
  ConsumerState<GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends ConsumerState<GlassTextField> {
  late final FocusNode _node = widget.focusNode ?? FocusNode(debugLabel: 'GlassTextField');
  late final TextEditingController _controller = widget.controller ?? TextEditingController();
  bool _focused = false;
  bool _hovered = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocus);
  }

  void _onFocus() {
    if (_node.hasFocus != _focused) setState(() => _focused = _node.hasFocus);
  }

  @override
  void didUpdateWidget(GlassTextField old) {
    super.didUpdateWidget(old);
    if (widget.errorTrigger > old.errorTrigger) {
      glassFire(ref, HapticEvent.error);
      if (widget.error != null) announceAssertive(context, widget.error!);
    }
  }

  @override
  void dispose() {
    _node.removeListener(_onFocus);
    if (widget.focusNode == null) _node.dispose();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  Iterable<String>? get _hints => widget.autofillHints ??
      switch (widget.kind) {
        GlassFieldKind.password => const [AutofillHints.password],
        GlassFieldKind.url => const [AutofillHints.url],
        _ => widget.username ? const [AutofillHints.username] : null,
      };

  @override
  Widget build(BuildContext context) {
    final inHost = GlassHost.of(context);
    final legible = ref.watch(glassA11yProvider.select((a) => a.legible));
    final kind = widget.kind;
    final number = kind == GlassFieldKind.number;
    final hasError = widget.error != null || widget.forceStates.error;
    final disabled = !widget.enabled || widget.forceStates.disabled;
    final loading = widget.loading || widget.forceStates.loading;
    final role = number ? gt.typeMono : gt.typeBody;
    final base = roleStyle(context, role, legible: legible, size: number ? 13 : null, height: number ? 18 : null, onGlass: inHost, maxScale: 1.5);
    final text = base.copyWith(color: gt.colorLabel1);
    final hint = base.copyWith(color: inHost ? gt.colorLabel2 : gt.colorLabel3);
    final hit = GlassFrame.hitMin(context);

    Widget? leading;
    if (kind == GlassFieldKind.url) leading = Padding(padding: const EdgeInsets.only(right: 10), child: GlyphIcon(GlassGlyph.globe, size: 20, color: gt.colorLabel2));
    Widget? trailing;
    if (loading || (kind == GlassFieldKind.url && widget.validating)) {
      trailing = const Padding(padding: EdgeInsets.only(left: 10), child: GlassSpinner());
    } else if (kind == GlassFieldKind.url && widget.reachable) {
      trailing = Padding(padding: const EdgeInsets.only(left: 10), child: GlyphIcon(GlassGlyph.check, size: 16, color: gt.colorSuccess));
    } else if (kind == GlassFieldKind.password) {
      trailing = SizedBox(
        width: hit,
        child: GlassPressable(
          material: GlassMaterial.content,
          sink: 0.92,
          shape: const GlassShape.circle(),
          onTap: () => setState(() => _obscure = !_obscure),
          semanticsLabel: 'Show password',
          toggled: !_obscure,
          tooltip: 'Show password',
          builder: (context, info) => Center(child: GlyphIcon(_obscure ? GlassGlyph.eye : GlassGlyph.eyeSlash, color: GlassColors.g800)),
        ),
      );
    }

    final field = TextSelectionTheme(
      data: TextSelectionThemeData(cursorColor: gt.colorIris400, selectionColor: const Color(0x667563F2)),
      child: TextField(
        controller: _controller,
        focusNode: _node,
        enabled: !disabled,
        obscureText: kind == GlassFieldKind.password && _obscure,
        autofocus: widget.autofocus,
        textCapitalization: widget.textCapitalization,
        inputFormatters: widget.inputFormatters,
        keyboardType: widget.keyboardType ?? switch (kind) {
          GlassFieldKind.password => TextInputType.visiblePassword,
          GlassFieldKind.url => TextInputType.url,
          GlassFieldKind.number => const TextInputType.numberWithOptions(decimal: true),
          GlassFieldKind.text => TextInputType.text,
        },
        textInputAction: widget.textInputAction ?? (kind == GlassFieldKind.url || number ? TextInputAction.go : TextInputAction.done),
        textAlign: number ? TextAlign.center : TextAlign.start,
        autofillHints: _hints,
        autocorrect: !(widget.username || kind == GlassFieldKind.url || kind == GlassFieldKind.password),
        enableSuggestions: !(widget.username || kind == GlassFieldKind.url || kind == GlassFieldKind.password),
        keyboardAppearance: Brightness.dark,
        cursorColor: gt.colorIris400,
        style: text,
        decoration: InputDecoration.collapsed(hintText: widget.hint, hintStyle: hint),
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
      ),
    );

    Widget well = GlassWell(
      focused: _focused || widget.forceStates.focused,
      hovered: _hovered || widget.forceStates.hovered,
      error: hasError,
      onSheet: widget.onSheet,
      minHeight: number ? hit : 50,
      padding: EdgeInsets.only(left: number ? 8 : 16, right: trailing is SizedBox ? 4 : (number ? 8 : 16)),
      child: Row(
        children: [
          if (leading != null) leading,
          Expanded(child: field),
          if (trailing != null) trailing,
        ],
      ),
    );
    if (number) {
      well = SizedBox(
        width: 96,
        child: Focus(
          onKeyEvent: (n, e) {
            if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
              _controller.clear();
              widget.onChanged?.call('');
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: well,
        ),
      );
    }
    well = MouseRegion(onEnter: (_) => setState(() => _hovered = true), onExit: (_) => setState(() => _hovered = false), child: well);
    well = GlassShake(trigger: widget.errorTrigger, amplitude: 6, child: well);
    well = Opacity(opacity: disabled ? 0.4 : 1, child: well);

    final labelColor = inHost ? gt.colorOnGlass : gt.colorLabel2;
    return Semantics(
      container: true,
      textField: true,
      enabled: !disabled,
      label: widget.semanticsLabel ?? widget.label,
      hint: hasError ? widget.error : widget.helper,
      validationResult: hasError ? SemanticsValidationResult.invalid : SemanticsValidationResult.none,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.label != null) Padding(padding: const EdgeInsets.only(bottom: 6), child: GlassLabel(widget.label!, role: gt.typeFootnote, wght: 600, color: labelColor)),
          well,
          GlassFieldMessage(text: hasError ? (widget.error ?? "That doesn't look right") : widget.helper, error: hasError),
          if (widget.counter != null) Padding(padding: const EdgeInsets.only(top: 4), child: Align(alignment: Alignment.centerRight, child: GlassLabel(widget.counter!, role: gt.typeMono, color: gt.colorLabel2))),
        ],
      ),
    );
  }
}
