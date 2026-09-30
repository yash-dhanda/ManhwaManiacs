import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manhwamaniacs/features/reader/models/bookmark.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_menu.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_text_field.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_row.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_swipe_row.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

String _num(double n) => n == n.roundToDouble() ? '${n.round()}' : '$n';

/// `CH 14 · 62% IN` for a novel, `CH 14 · PAGE 7` for a manga bookmark.
String bookmarkFolio(Bookmark b) {
  final ch = b.chapterNumber == null ? 'CHAPTER' : 'CH ${_num(b.chapterNumber!)}';
  if (b.mediaType.isNovel) {
    final pct = b.positionPercent;
    return pct == null ? '$ch · PARAGRAPH ${b.anchorIndex}' : '$ch · $pct% IN';
  }
  return '$ch · PAGE ${b.anchorIndex}';
}

const _months = ['JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE', 'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'];

/// `Saved 28 September`.
String bookmarkSaved(Bookmark b) {
  final d = b.createdAt.toLocal();
  final m = _months[d.month - 1];
  return 'Saved ${d.day} ${m[0]}${m.substring(1).toLowerCase()}';
}

/// One bookmark as a marginal note (cinematic 8.13): the folio, for a novel the passage as a pull
/// quote with a 2 px `spot` left rule, the reader's note (or `Add a note`), the saved date, and for a
/// stale anchor the line saying it opens at the nearest spot. The note edits in place on a ruled
/// textarea and saves on focus loss, `done` and Ctrl/Cmd + Enter.
class MarginalNote extends StatefulWidget {
  const MarginalNote({
    super.key,
    required this.bookmark,
    required this.editing,
    required this.onOpen,
    required this.onEdit,
    required this.onSaveNote,
    required this.onRemove,
    required this.onOpenSeries,
    required this.swipe,
    this.focusNode,
  });

  final Bookmark bookmark;
  final bool editing, swipe;
  final VoidCallback onOpen, onEdit, onRemove, onOpenSeries;

  /// Called with the trimmed note when editing ends.
  final ValueChanged<String> onSaveNote;
  final FocusNode? focusNode;

  @override
  State<MarginalNote> createState() => _MarginalNoteState();
}

class _MarginalNoteState extends State<MarginalNote> {
  late final TextEditingController _ctl = TextEditingController(text: widget.bookmark.note ?? '');
  final _field = FocusNode(debugLabel: 'note-field');
  bool _saved = false;

  @override
  void didUpdateWidget(MarginalNote old) {
    super.didUpdateWidget(old);
    if (widget.editing && !old.editing) {
      _saved = false;
      _ctl.text = widget.bookmark.note ?? '';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _field.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _ctl.dispose();
    _field.dispose();
    super.dispose();
  }

  void _save() {
    if (_saved || !widget.editing) return;
    _saved = true;
    widget.onSaveNote(_ctl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final b = widget.bookmark;
    final note = b.note?.trim() ?? '';
    final novel = b.mediaType.isNovel;
    final snippet = b.snippet?.trim();
    final body = Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      CineRoleText(bookmarkFolio(b), c.typeFolio, color: c.colorInk60),
      if (novel && snippet != null && snippet.isNotEmpty) ...[
        SizedBox(height: c.space2),
        Container(
          decoration: BoxDecoration(border: Border(left: BorderSide(color: c.colorSpot, width: 2))),
          padding: EdgeInsets.only(left: c.space3),
          child: CineLit(snippet, CineFace.newsreader, 17, 25, italic: true, color: c.colorInk80, maxLines: 4, overflow: TextOverflow.ellipsis),
        ),
      ],
      SizedBox(height: c.space2),
      if (widget.editing)
        CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.enter, control: true): _save,
            const SingleActivator(LogicalKeyboardKey.enter, meta: true): _save,
          },
          child: Focus(
            onFocusChange: (has) {
              if (!has) _save();
            },
            child: CineTextField(
              key: const Key('note-editor'),
              label: 'Note',
              controller: _ctl,
              focusNode: _field,
              ruled: true,
              minLines: 1,
              maxLines: 6,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
            ),
          ),
        )
      else if (note.isNotEmpty)
        CineRoleText(note, c.typeBody)
      else
        CineButton(label: 'Add a note', variant: CineButtonVariant.quiet, size: CineButtonSize.sm, onPressed: widget.onEdit),
      if (b.anchorStale) ...[
        SizedBox(height: c.space2),
        CineRoleText('The text here changed. This opens at the nearest spot.', c.typeCaption, color: c.colorInfo),
      ],
      SizedBox(height: c.space2),
      Wrap(spacing: c.space2, runSpacing: c.space1, crossAxisAlignment: WrapCrossAlignment.center, children: [
        CineRoleText(bookmarkSaved(b), c.typeCaption, color: c.colorInk45),
        if (note.isNotEmpty && !widget.editing) CineButton(label: 'Edit note', variant: CineButtonVariant.quiet, size: CineButtonSize.sm, onPressed: widget.onEdit),
        CineButton(label: 'Remove', variant: CineButtonVariant.quiet, size: CineButtonSize.sm, onPressed: widget.onRemove),
      ],),
    ],);
    final row = CineRowShell(
      minHeight: 96,
      focusNode: widget.focusNode,
      onTap: widget.editing ? null : widget.onOpen,
      menu: [
        CineMenuEntry<Object?>(label: 'Edit note', onSelected: widget.onEdit),
        CineMenuEntry<Object?>(label: 'Remove', destructive: true, onSelected: widget.onRemove),
        CineMenuEntry<Object?>(label: 'Open series', onSelected: widget.onOpenSeries),
      ],
      semanticLabel: '${bookmarkFolio(b)}${note.isEmpty ? '' : ', $note'}',
      child: body,
    );
    if (!widget.swipe || widget.editing) return row;
    return CineSwipeRow(id: 'bm-${b.clientId}', kind: CineSwipeKind.remove, onCommit: widget.onRemove, child: row);
  }
}
