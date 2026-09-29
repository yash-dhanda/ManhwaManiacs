import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/library/models/tag.dart';
import 'package:manhwamaniacs/features/library/providers/tags_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_confirm_dialog.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_galley.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_icon_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_text_field.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/sheet_route.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The tag sheet (cinematic 8.9): every tag of the profile as an inline-editable name with a
/// trailing delete, and `New tag`. Opened by `Manage tags…` on the shelf and by the series page's
/// `Tags…` → `Manage`. Tag `color` is kept as stored and never drawn.
Future<void> showTagSheet(BuildContext context) => showCineSheet<void>(
      context,
      kicker: 'TAGS',
      title: 'Your tags',
      builder: (_) => const TagSheetBody(),
    );

class TagSheetBody extends ConsumerStatefulWidget {
  const TagSheetBody({super.key});

  @override
  ConsumerState<TagSheetBody> createState() => _TagSheetBodyState();
}

class _TagSheetBodyState extends ConsumerState<TagSheetBody> {
  /// Rows being added (each has its own key so its field keeps focus).
  final List<Key> _drafts = [];

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final tags = ref.watch(tagsProvider);
    // The name fields are `TextField`s: a transparent `Material` keeps them working under a
    // navigator that has none above it.
    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: EdgeInsets.fromLTRB(c.space4, c.space2, c.space4, c.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            tags.when(
              loading: () => Column(
                children: [
                  for (var i = 0; i < 3; i++)
                    Padding(
                        padding: EdgeInsets.symmetric(vertical: c.space3),
                        child: CineGalleyLine(lineHeight: 24, index: i),),
                ],
              ),
              error: (e, _) => Padding(
                padding: EdgeInsets.symmetric(vertical: c.space3),
                child: Row(
                  children: [
                    Expanded(
                        child: CineRoleText(
                            "Couldn't load your tags.", c.typeCaption,
                            color: c.colorProof,),),
                    CineButton(
                        label: 'Retry',
                        variant: CineButtonVariant.quiet,
                        onPressed: () => ref.invalidate(tagsProvider),),
                  ],
                ),
              ),
              data: (list) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (list.isEmpty && _drafts.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: c.space4),
                      child: CineRoleText(
                          'No tags yet. Add one from a series page.', c.typeUi,
                          color: c.colorInk60,),
                    ),
                  for (final t in list)
                    TagRow(key: ValueKey('tag-${t.id}'), tag: t),
                  for (final k in _drafts)
                    TagRow(
                        key: k,
                        tag: null,
                        onDone: () => setState(() => _drafts.remove(k)),),
                ],
              ),
            ),
            SizedBox(height: c.space2),
            Align(
              alignment: Alignment.centerLeft,
              child: CineButton(
                label: 'New tag',
                variant: CineButtonVariant.quiet,
                leadingGlyph: CineGlyph.plus,
                onPressed: () => setState(() => _drafts.add(UniqueKey())),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One tag: the name as an underline field (the keyboard's done action saves, losing focus
/// reverts), a `check` for 1600 ms after a save, an error line, and a trailing delete.
class TagRow extends ConsumerStatefulWidget {
  const TagRow({super.key, required this.tag, this.onDone});

  /// Null for a row that is being added.
  final Tag? tag;
  final VoidCallback? onDone;

  @override
  ConsumerState<TagRow> createState() => _TagRowState();
}

class _TagRowState extends ConsumerState<TagRow> {
  late final TextEditingController _text =
      TextEditingController(text: widget.tag?.name ?? '');
  late final FocusNode _focus = FocusNode();
  String? _error;
  bool _saved = false;
  bool _busy = false;
  Timer? _savedTimer;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
    if (widget.tag == null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _focus.requestFocus());
    }
  }

  void _onFocus() {
    if (!_focus.hasFocus && !_busy) {
      if (widget.tag == null) {
        if (_text.text.trim().isEmpty) widget.onDone?.call();
      } else {
        _text.text = widget.tag!.name;
        if (_error != null) setState(() => _error = null);
      }
    }
  }

  @override
  void dispose() {
    _savedTimer?.cancel();
    _focus.removeListener(_onFocus);
    _focus.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit(String value) async {
    final name = value.trim();
    if (name.isEmpty || name == widget.tag?.name) {
      if (widget.tag == null) widget.onDone?.call();
      return;
    }
    _busy = true;
    final ctl = ref.read(tagsControllerProvider);
    final AppError? err = widget.tag == null
        ? await ctl.create(name)
        : await ctl.rename(widget.tag!.id, name);
    _busy = false;
    if (!mounted) return;
    if (err != null) {
      setState(() => _error = err.userMessage);
      return;
    }
    setState(() {
      _error = null;
      _saved = true;
    });
    if (widget.tag == null) {
      // The new tag arrives as its own row; this draft goes.
      widget.onDone?.call();
      return;
    }
    _savedTimer?.cancel();
    _savedTimer = Timer(CineDur.holdSuccess, () {
      if (mounted) setState(() => _saved = false);
    });
  }

  Future<void> _delete() async {
    final t = widget.tag;
    if (t == null) {
      widget.onDone?.call();
      return;
    }
    final ok = await showCineConfirm(
      context,
      title: 'Delete the tag ${t.name}? It comes off every series.',
      confirmLabel: 'Delete tag',
      destructive: true,
      filled: true,
    );
    if (!ok || !mounted) return;
    final err = await ref.read(tagsControllerProvider).delete(t.id);
    if (err != null && mounted) setState(() => _error = err.userMessage);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: CineTextField(
                label: 'Tag name',
                controller: _text,
                focusNode: _focus,
                textInputAction: TextInputAction.done,
                success: _saved,
                errorText: _error,
                onSubmitted: _submit,
              ),
            ),
            CineIconButton(
                label: 'Delete tag',
                role: CineIconRole.delete,
                onPressed: _delete,),
          ],
        ),
        SizedBox(height: c.space1),
      ],
    );
  }
}
