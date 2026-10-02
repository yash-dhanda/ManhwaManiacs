import 'dart:async';

import 'package:flutter/material.dart' show InputDecoration, TextField, TextSelectionTheme, TextSelectionThemeData;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/keycap.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/progress.dart';
import 'package:manhwamaniacs/skins/glass/primitives/text_field.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';

/// glass 7.4 variants. The orb that morphs into the bottom field is the dock's (`mobile/29`).
enum GlassSearchVariant { bottom, page, filter, sidebar }

/// What the field shows besides typing: results, no results and error are the screen's; the field itself
/// changes its magnifier for a spinner (searching) or a `wifi-slash` (offline).
enum GlassSearchStatus { idle, searching, offline, error }

const String kGlassSearchPlaceholder = 'Search series, sources and dialogue';

/// The search fields (glass 7.4).
class GlassSearchField extends ConsumerStatefulWidget {
  const GlassSearchField({
    super.key,
    this.variant = GlassSearchVariant.page,
    this.controller,
    this.focusNode,
    this.onQuery,
    this.onSubmitted,
    this.onCancel,
    this.onCollapse,
    this.onOpenPalette,
    this.placeholder = kGlassSearchPlaceholder,
    this.status = GlassSearchStatus.idle,
    this.ridesKeyboard = true,
    this.twin,
    this.forceStates = GlassWidgetStates.none,
  });

  final GlassSearchVariant variant;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  /// Debounced 300 ms; the IME search action fires it at once.
  final ValueChanged<String>? onQuery;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onCancel;

  /// `bottom`: dragging down dismisses the keyboard first, then calls this past 80 px projected.
  final VoidCallback? onCollapse;

  /// `sidebar`: the command palette (`mobile/29`).
  final VoidCallback? onOpenPalette;
  final String placeholder;
  final GlassSearchStatus status;

  /// `bottom`: `Padding(bottom: viewInsets.bottom)` so it rides on top of the keyboard.
  final bool ridesKeyboard;
  final GlassTwin? twin;
  final GlassWidgetStates forceStates;

  @override
  ConsumerState<GlassSearchField> createState() => _GlassSearchFieldState();
}

class _GlassSearchFieldState extends ConsumerState<GlassSearchField> {
  late final FocusNode _node = widget.focusNode ?? FocusNode(debugLabel: 'GlassSearchField');
  late final TextEditingController _c = widget.controller ?? TextEditingController();
  Timer? _debounce;
  double _drag = 0;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _node.addListener(() {
      if (mounted && _node.hasFocus != _focused) setState(() => _focused = _node.hasFocus);
    });
    _c.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (widget.focusNode == null) _node.dispose();
    if (widget.controller == null) _c.dispose();
    super.dispose();
  }

  void _changed(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => widget.onQuery?.call(v));
  }

  void _submit(String v) {
    _debounce?.cancel();
    widget.onQuery?.call(v);
    widget.onSubmitted?.call(v);
  }

  /// Focuses the field, or reopens the keyboard when the field already has focus (a plain requestFocus is a no-op then).
  void _wake() {
    final editable = _node.context?.findAncestorStateOfType<EditableTextState>();
    if (editable != null) {
      editable.requestKeyboard();
    } else {
      _node.requestFocus();
    }
  }

  Widget _lead(bool onGlass) {
    switch (widget.status) {
      case GlassSearchStatus.searching:
        return const GlassSpinner();
      case GlassSearchStatus.offline:
        return GlassBacking(size: 28, child: GlyphIcon(GlassGlyph.wifiSlash, size: 20, color: gt.colorWarning));
      case GlassSearchStatus.idle:
      case GlassSearchStatus.error:
        return GlyphIcon(GlassGlyph.magnifyingGlass, size: 20, color: onGlass ? gt.colorOnGlass : gt.colorLabel2);
    }
  }

  double _hintRoom = double.infinity;

  /// The placeholder, shortened by whole words (and a dangling "and"/"or"/comma) until it fits the field: "Search series, sources
  /// and dialogue" reads "Search series, sources" on a narrow field instead of ending in "…".
  String _fittedHint(TextStyle style) {
    var words = widget.placeholder.split(' ');
    String join() => words.join(' ').replaceAll(RegExp(r'[,;:]$'), '');
    while (words.length > 1 && measureText(context, join(), style).width > _hintRoom) {
      words = words.sublist(0, words.length - 1);
      while (words.length > 1 && const {'and', 'or', '&'}.contains(words.last)) {
        words = words.sublist(0, words.length - 1);
      }
    }
    return join();
  }

  Widget _input(bool onGlass) {
    final legible = ref.watch(glassA11yProvider.select((a) => a.legible));
    final base = roleStyle(context, gt.typeBody, legible: legible, onGlass: onGlass, maxScale: 1.5);
    return LayoutBuilder(builder: (context, box) {
      _hintRoom = box.maxWidth;
      return TextSelectionTheme(
      data: TextSelectionThemeData(cursorColor: gt.colorIris400, selectionColor: const Color(0x667563F2)),
      // The styles are already scaled and capped (roleStyle): the field must not scale them again.
      child: MediaQuery.withNoTextScaling(child: TextField(
        controller: _c,
        focusNode: _node,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.search,
        keyboardAppearance: Brightness.dark,
        cursorColor: gt.colorIris400,
        autocorrect: false,
        style: base.copyWith(color: onGlass ? gt.colorOnGlass : gt.colorLabel1),
        decoration: InputDecoration.collapsed(hintText: _fittedHint(base), hintStyle: base.copyWith(color: gt.colorLabel2)),
        onChanged: _changed,
        onSubmitted: _submit,
      ),),
    );
    },);
  }

  Widget _clear() {
    final hit = GlassFrame.hitMin(context);
    return SizedBox(
      width: hit,
      height: hit,
      child: GlassPressable(
        material: GlassMaterial.content,
        sink: 0.92,
        shape: const GlassShape.circle(),
        minHit: false,
        onTap: () {
          _c.clear();
          _debounce?.cancel();
          widget.onQuery?.call('');
        },
        semanticsLabel: 'Clear search',
        tooltip: 'Clear search',
        builder: (context, info) => Center(child: GlyphIcon(GlassGlyph.x, size: 16, color: gt.colorLabel2)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.variant;
    final helper = widget.status == GlassSearchStatus.offline
        ? 'Offline: searching this device only'
        : widget.status == GlassSearchStatus.error
            ? "Couldn't search"
            : null;
    Widget field;
    switch (v) {
      case GlassSearchVariant.bottom:
      case GlassSearchVariant.page:
        final h = v == GlassSearchVariant.bottom ? 50.0 : 56.0;
        field = LayoutBuilder(
          builder: (context, c) {
            final cancel = v == GlassSearchVariant.bottom;
            final w = c.hasBoundedWidth ? c.maxWidth : 320.0;
            // A plain tap target, not a GlassPressable: the pressable won the gesture arena on pointer-up, so taps never reached
            // the TextField and a focused field with its keyboard down could not get it back.
            Widget glassFor(double width) => GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  excludeFromSemantics: true,
                  onTap: _wake,
                  child: SkinGlass(
                    size: Size(width, h),
                    tier: GlassTierId.t3,
                    twin: widget.twin,
                    debugLabel: 'GlassSearchField',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _lead(true),
                          const SizedBox(width: 10),
                          Expanded(child: _input(true)),
                          if (_c.text.isNotEmpty) _clear(),
                        ],
                      ),
                    ),
                  ),
                );
            Widget row = cancel
                ? Row(
                    children: [
                      Expanded(child: LayoutBuilder(builder: (context, cc) => glassFor(cc.maxWidth))),
                      const SizedBox(width: 8),
                      GlassButton(
                        label: 'Cancel',
                        variant: GlassButtonVariant.plain,
                        size: GlassButtonSize.small,
                        onPressed: () {
                          _node.unfocus();
                          widget.onCancel?.call();
                        },
                      ),
                    ],
                  )
                : glassFor(w);
            if (v == GlassSearchVariant.bottom) {
              row = GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragStart: (_) => _drag = 0,
                onVerticalDragUpdate: (d) => _drag += d.delta.dy,
                onVerticalDragEnd: (d) {
                  // Only a real pull down dismisses: an upward or jittery drag keeps the keyboard.
                  final p = project(_drag, d.velocity.pixelsPerSecond.dy);
                  if (p <= 24) return;
                  _node.unfocus();
                  if (p > 80) widget.onCollapse?.call();
                },
                child: row,
              );
            }
            return row;
          },
        );
      case GlassSearchVariant.filter:
        field = GlassWell(
          focused: _focused || widget.forceStates.focused,
          hovered: widget.forceStates.hovered,
          minHeight: GlassFrame.hitMin(context),
          padding: const EdgeInsets.only(left: 14),
          child: Row(
            children: [
              _lead(false),
              const SizedBox(width: 10),
              Expanded(child: _input(false)),
              if (_c.text.isNotEmpty) _clear() else const SizedBox(width: 14),
            ],
          ),
        );
      case GlassSearchVariant.sidebar:
        field = GlassPressable(
          material: GlassMaterial.content,
          sink: 0.98,
          onTap: widget.onOpenPalette,
          enabled: widget.onOpenPalette != null,
          semanticsLabel: 'Search',
          forceStates: widget.forceStates,
          builder: (context, info) => Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: info.states.hovered ? gt.colorFill2 : gt.colorFill3, borderRadius: BorderRadius.circular(18)),
            child: Row(
              children: [
                GlyphIcon(GlassGlyph.magnifyingGlass, size: 16, color: gt.colorLabel2),
                const SizedBox(width: 8),
                Expanded(child: GlassLabel('Search', role: gt.typeSubhead, color: gt.colorLabel2)),
                GlassKeycaps.shortcut(context, const SingleActivator(LogicalKeyboardKey.keyK, meta: true)),
              ],
            ),
          ),
        );
    }
    field = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        field,
        if (helper != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: GlassLabel(helper, role: gt.typeFootnote, color: widget.status == GlassSearchStatus.error ? gt.colorDanger : gt.colorLabel3),
          ),
      ],
    );
    if (v == GlassSearchVariant.bottom && widget.ridesKeyboard) {
      field = Padding(padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom), child: field);
    }
    return Semantics(container: true, label: 'Search', textField: false, child: field);
  }
}
