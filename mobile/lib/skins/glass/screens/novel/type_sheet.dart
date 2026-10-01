import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/services.dart' show TextInputAction;
import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/features/novels/models/glass_novel_prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/text_field.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_sheet_route.dart';
import 'package:manhwamaniacs/skins/glass/routes/sheet_registry.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/paper_frame.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/papers.dart';

/// The novel reader's `?sheet=` ids (glass 8.0.3): `contents`, `type`, `note` (and `recommend`, `mobile/43`'s).
const String kNovelSheetContents = 'contents', kNovelSheetType = 'type', kNovelSheetNote = 'note', kNovelSheetRecommend = 'recommend';

/// The Aa sheet (H): `?sheet=type`, a `medium` sheet (52 %) so the page updates live above it. Glass `GlassSheetPage` on
/// `smooth_sheets` 1.2.0.
GlassSheetPage<void> novelTypeSheetPage(WidgetBuilder body) => GlassSheetPage<void>(
      key: const ValueKey('sheet:type'),
      title: 'Type and page',
      builder: body,
    );

/// The Contents sheet (I): `?sheet=contents`, `large`, painted in the paper colours.
GlassSheetPage<void> novelContentsSheetPage(GlassPaper paper, WidgetBuilder body) => GlassSheetPage<void>(
      key: const ValueKey('sheet:contents'),
      title: 'Contents',
      detents: const [GlassDetent.large],
      opening: GlassDetent.large,
      builder: (context) => PaperScope(paper: paper, colors: paperColors(paper), child: Builder(builder: body)),
    );

/// The one-line note sheet (F4): `?sheet=note`, saved through the same bookmark upsert.
GlassSheetPage<void> novelNoteSheetPage(Future<bool> Function(String note) onSave) => GlassSheetPage<void>(
      key: const ValueKey('sheet:note'),
      title: 'Add note',
      detents: const [GlassDetent.medium],
      builder: (context) => _NoteBody(onSave: onSave),
    );

class _NoteBody extends StatefulWidget {
  const _NoteBody({required this.onSave});
  final Future<bool> Function(String note) onSave;

  @override
  State<_NoteBody> createState() => _NoteBodyState();
}

class _NoteBodyState extends State<_NoteBody> {
  final TextEditingController _text = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final ok = await widget.onSave(_text.text.trim());
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) await Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) => Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassTextField(controller: _text, label: 'Note', onSheet: true, autofocus: true, textInputAction: TextInputAction.done, onSubmitted: (_) => _save()),
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerRight, child: GlassButton(label: 'Save', loading: _saving, onPressed: _save, variant: GlassButtonVariant.primary)),
            ],
          ),
        ),
      );
}

/// Registers the reader's sheet ids in `mobile/29`'s `?sheet=` registry. The reader claims them while mounted and presents its own (with
/// the book in hand); elsewhere they open a short notice, since they need a chapter.
void registerGlassNovelSheets() {
  for (final (id, title) in const [(kNovelSheetContents, 'Contents'), (kNovelSheetType, 'Type and page'), (kNovelSheetNote, 'Add note')]) {
    if (glassSheetRegistered(id)) continue;
    registerGlobalSheet(
      id,
      GlassSheetSpec(
        title: title,
        detents: const [GlassDetent.medium],
        builder: (context) => const Padding(padding: EdgeInsets.all(24), child: Text('Open a chapter of a novel to use this.')),
      ),
    );
  }
}
