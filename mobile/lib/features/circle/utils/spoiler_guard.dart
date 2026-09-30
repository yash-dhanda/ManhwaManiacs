import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether another member's reaction on a chapter stays hidden (cinematic 9.3.3). The viewer's own
/// reaction is never guarded; a chapter completed locally or this session unseals; otherwise the
/// server's `sealed`, and when that is unknown (offline included) hide.
bool isGuarded({required bool isOwn, required bool? sealed, required bool completedLocally, required bool completedThisSession}) {
  if (isOwn || completedLocally || completedThisSession) return false;
  return sealed ?? true;
}

/// `source:series:chapter`, the key of [completedThisSessionProvider].
String chapterId(String sourceId, String seriesKey, String chapterKey) => '$sourceId:$seriesKey:$chapterKey';

class CompletedThisSession extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  /// Fed by the manga engine's `chapterCompleted` and the novel reader's completion signal.
  void markCompleted(String sourceId, String seriesKey, String chapterKey) => state = {...state, chapterId(sourceId, seriesKey, chapterKey)};
}

final completedThisSessionProvider = NotifierProvider<CompletedThisSession, Set<String>>(CompletedThisSession.new, name: 'completedThisSession');
