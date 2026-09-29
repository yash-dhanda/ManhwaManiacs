import 'package:flutter/material.dart' show InputDecoration, TextField, TextSelectionTheme, TextSelectionThemeData;
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart' show SemanticsValidationResult;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/progress.dart';
import 'package:manhwamaniacs/skins/glass/primitives/text_field.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';

/// The text area (glass 7.3): `minLines: 3` (about 96 px), growing to 8 lines on `springSnappy`, then
/// scrolling; a counter in `caption1` from 80 % of [maxLength], `warning` at 95 %. With [submitOnEnter]
/// (the AI prompt) `Enter` from a hardware keyboard submits and `Shift+Enter` inserts a newline.
class GlassTextArea extends ConsumerStatefulWidget {
  const GlassTextArea({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.enabled = true,
    this.loading = false,
    this.maxLength,
    this.onChanged,
    this.onSubmit,
    this.submitOnEnter = false,
    this.errorTrigger = 0,
    this.forceStates = GlassWidgetStates.none,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final String? helper;
  final String? error;
  final bool enabled;
  final bool loading;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmit;
  final bool submitOnEnter;
  final int errorTrigger;
  final GlassWidgetStates forceStates;

  @override
  ConsumerState<GlassTextArea> createState() => _GlassTextAreaState();
}

class _GlassTextAreaState extends ConsumerState<GlassTextArea> {
  late final FocusNode _node = widget.focusNode ?? FocusNode(debugLabel: 'GlassTextArea');
  late final TextEditingController _c = widget.controller ?? TextEditingController();
  bool _focused = false;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _node.addListener(() {
      if (_node.hasFocus != _focused && mounted) setState(() => _focused = _node.hasFocus);
    });
    _c.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(GlassTextArea old) {
    super.didUpdateWidget(old);
    if (widget.errorTrigger > old.errorTrigger) {
      glassFire(ref, HapticEvent.error);
      if (widget.error != null) announceAssertive(context, widget.error!);
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _node.dispose();
    if (widget.controller == null) _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inHost = GlassHost.of(context);
    final legible = ref.watch(glassA11yProvider.select((a) => a.legible));
    final hasError = widget.error != null || widget.forceStates.error;
    final disabled = !widget.enabled || widget.forceStates.disabled;
    final base = roleStyle(context, gt.typeBody, legible: legible, onGlass: inHost, maxScale: 1.5);
    final len = _c.text.characters.length;
    final max = widget.maxLength;
    final showCounter = max != null && len >= max * 0.8;
    final warn = max != null && len >= max * 0.95;

    Widget field = TextSelectionTheme(
      data: TextSelectionThemeData(cursorColor: gt.colorIris400, selectionColor: const Color(0x667563F2)),
      child: TextField(
        controller: _c,
        focusNode: _node,
        enabled: !disabled,
        minLines: 3,
        maxLines: 8,
        keyboardType: TextInputType.multiline,
        textInputAction: widget.submitOnEnter ? TextInputAction.send : TextInputAction.newline,
        keyboardAppearance: Brightness.dark,
        cursorColor: gt.colorIris400,
        cursorWidth: 2,
        style: base.copyWith(color: gt.colorLabel1),
        decoration: InputDecoration.collapsed(hintText: widget.hint, hintStyle: base.copyWith(color: inHost ? gt.colorLabel2 : gt.colorLabel3)),
        onChanged: widget.onChanged,
        maxLength: max,
        buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
      ),
    );
    if (widget.submitOnEnter) {
      field = Focus(
        onKeyEvent: (n, e) {
          if (e is KeyDownEvent && (e.logicalKey == LogicalKeyboardKey.enter || e.logicalKey == LogicalKeyboardKey.numpadEnter) && !HardwareKeyboard.instance.isShiftPressed) {
            widget.onSubmit?.call(_c.text);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: field,
      );
    }

    Widget well = GlassWell(
      focused: _focused || widget.forceStates.focused,
      hovered: _hovered || widget.forceStates.hovered,
      error: hasError,
      minHeight: 96,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Stack(
        children: [
          AnimatedSize(
            duration: Duration(milliseconds: gt.springSnappy.ms),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topLeft,
            child: Padding(padding: EdgeInsets.only(bottom: showCounter ? 18 : 0), child: field),
          ),
          if (widget.loading) const Positioned(right: 0, top: 0, child: GlassSpinner(size: 16)),
          if (showCounter)
            Positioned(
              right: 0,
              bottom: 0,
              child: GlassLabel('$len / $max', role: gt.typeCaption1, color: warn ? gt.colorWarning : gt.colorLabel3),
            ),
        ],
      ),
    );
    well = MouseRegion(onEnter: (_) => setState(() => _hovered = true), onExit: (_) => setState(() => _hovered = false), child: well);
    well = GlassShake(trigger: widget.errorTrigger, amplitude: 6, child: well);
    well = Opacity(opacity: disabled ? 0.4 : 1, child: well);

    return Semantics(
      container: true,
      textField: true,
      multiline: true,
      enabled: !disabled,
      label: widget.label,
      hint: hasError ? widget.error : widget.helper,
      validationResult: hasError ? SemanticsValidationResult.invalid : SemanticsValidationResult.none,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.label != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GlassLabel(widget.label!, role: gt.typeFootnote, wght: 600, color: inHost ? gt.colorOnGlass : gt.colorLabel2),
            ),
          well,
          GlassFieldMessage(text: hasError ? (widget.error ?? "That doesn't look right") : widget.helper, error: hasError),
        ],
      ),
    );
  }
}
