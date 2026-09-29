import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/utils/text_fold.dart';
import 'package:manhwamaniacs/features/ocr/models/ocr_search_result.dart';
import 'package:manhwamaniacs/features/ocr/models/page_text.dart';

/// Where a dialogue hit wants the reader to land.
class DialogueJump {
  const DialogueJump({
    required this.sourceId,
    required this.seriesKey,
    required this.chapterKey,
    required this.q,
    this.page,
    this.box,
  });

  final String sourceId;
  final String seriesKey;
  final String chapterKey;
  final String q;
  final int? page;
  final OcrBox? box;
}

class DialogueJumpNotifier extends Notifier<DialogueJump?> {
  @override
  DialogueJump? build() => null;

  void set(DialogueJump jump) => state = jump;

  /// The matching jump once; a later call (or a different chapter) gets null.
  DialogueJump? take(String sourceId, String seriesKey, String chapterKey) {
    final j = state;
    if (j == null ||
        j.sourceId != sourceId ||
        j.seriesKey != seriesKey ||
        j.chapterKey != chapterKey) {
      return null;
    }
    state = null;
    return j;
  }
}

final dialogueJumpProvider =
    NotifierProvider<DialogueJumpNotifier, DialogueJump?>(
        DialogueJumpNotifier.new,);

/// First page whose text holds every whitespace-separated term of [q],
/// case-insensitive, diacritics folded; null when none does.
int? findMatchPage(List<PageText> pages, String q) {
  final terms = foldDiacritics(q)
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty);
  if (terms.isEmpty) return null;
  for (final p in pages) {
    final text = foldDiacritics(p.text).toLowerCase();
    if (terms.every(text.contains)) return p.page;
  }
  return null;
}
