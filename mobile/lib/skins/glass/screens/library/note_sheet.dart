import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/downloads/providers/bookmark_outbox_provider.dart';
import 'package:manhwamaniacs/features/library/providers/bookmarks_provider.dart';
import 'package:manhwamaniacs/features/reader/models/bookmark.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/text_field.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_sheet_route.dart';
import 'package:manhwamaniacs/skins/glass/routes/sheet_registry.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/library_common.dart' show sheetParams;

/// `?sheet=note&bookmark={clientId}` (medium): a one-line note field saved through the note upsert of the bookmark outbox.
final GlassSheetSpec glassNoteSheetSpec = GlassSheetSpec(
  title: 'Add note',
  builder: (context) => GlassNoteBody(clientId: sheetParams(context)['bookmark'] ?? ''),
  detents: const [GlassDetent.medium],
  opening: GlassDetent.medium,
);

class GlassNoteBody extends ConsumerStatefulWidget {
  const GlassNoteBody({super.key, required this.clientId});
  final String clientId;

  @override
  ConsumerState<GlassNoteBody> createState() => _GlassNoteBodyState();
}

class _GlassNoteBodyState extends ConsumerState<GlassNoteBody> {
  final TextEditingController _c = TextEditingController();
  Bookmark? _b;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final list = ref.read(bookmarksProvider).valueOrNull?.bookmarks ?? const <Bookmark>[];
      final b = list.where((x) => x.clientId == widget.clientId).firstOrNull;
      if (!mounted) return;
      setState(() {
        _b = b;
        _c.text = b?.note ?? '';
      });
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final b = _b;
    if (b == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(bookmarkOutboxControllerProvider).setNote(b, _c.text.trim());
    } on BookmarkDeletedElsewhere {
      if (!mounted) return;
      showGlassToast(ref, const GlassToastSpec('That bookmark was removed on another device'));
      Navigator.of(context).pop();
      return;
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = "Couldn't save the note";
        });
      }
      return;
    }
    if (!mounted) return;
    ref.invalidate(bookmarksProvider);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          GlassTextField(controller: _c, label: 'Note', hint: 'Why this spot matters', onSheet: true, autofocus: true, error: _error, onSubmitted: (_) => unawaited(_save())),
          const SizedBox(height: 16),
          GlassButton(label: 'Save', variant: GlassButtonVariant.primary, size: GlassButtonSize.large, fullWidth: true, loading: _busy, onPressed: _b == null ? null : () => unawaited(_save())),
        ],),
      );
}
