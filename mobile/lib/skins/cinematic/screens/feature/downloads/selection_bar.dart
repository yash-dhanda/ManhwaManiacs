import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_selection.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_states.dart';

/// The select-mode bar (§7.29, §8.19): count, quick picks with counts, Done
/// and `Download N`. `chapters` is in READING order (oldest first).
class SelectionBar extends StatelessWidget {
  const SelectionBar({
    super.key,
    required this.controller,
    required this.chapters,
    required this.onDownload,
    this.showWholeBook = false,
  });

  final ChapterSelectionController controller;
  final List<SelectableChapter> chapters;
  final VoidCallback onDownload;

  /// Novels only: the `WHOLE BOOK` quick pick.
  final bool showWholeBook;

  @override
  Widget build(BuildContext context) {
    final t = cineOf(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final saved = chapters.where((c) => c.isDownloaded).length;
        final unread = unreadUndownloadedKeys(chapters);
        final all = undownloadedKeys(chapters);
        final n = controller.count;
        Widget pick(String label, List<String> keys) => TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: t.colorInk80,
                textStyle: const TextStyle(fontSize: 12, letterSpacing: 1),
              ),
              onPressed: () => controller.replaceWith(keys),
              child: Text(label),
            );
        return Material(
          color: t.colorPaper2,
          child: Container(
            decoration: BoxDecoration(border: Border(top: BorderSide(color: t.colorRule2))),
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + MediaQuery.paddingOf(context).bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n == 0 ? 'Select chapters to download' : '$n SELECTED · $saved ALREADY SAVED',
                  key: const Key('selection-count'),
                  style: kickerStyle(context),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    pick('NEXT 10', nextUnreadUndownloadedKeys(chapters)),
                    pick('ALL UNREAD${superscript(unread.length)}', unread),
                    if (showWholeBook) pick('WHOLE BOOK', all),
                    pick('ALL${superscript(chapters.length)}', all),
                    pick('NONE', const []),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                      onPressed: controller.end,
                      child: const Text('Done'),
                    ),
                    const Spacer(),
                    FilledButton(
                      style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
                      onPressed: n == 0 ? null : onDownload,
                      child: Text('Download $n'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
