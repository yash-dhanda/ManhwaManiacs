import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/sources/providers/source_progress_provider.dart';

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

/// The viewer's own finished chapter keys of one series (glass 9.3, the spoiler guard): the local progress rows marked
/// `completed` (they work offline) merged with [completedThisSessionProvider].
final finishedChaptersProvider = Provider.family<Set<String>, ({String sourceId, String seriesKey})>((ref, k) {
  final prefix = '${k.sourceId}:${k.seriesKey}:';
  final out = <String>{};
  for (final e in ref.watch(sourceProgressProvider).entries) {
    if (e.value.completed && e.key.startsWith(prefix)) out.add(e.key.substring(prefix.length));
  }
  for (final id in ref.watch(completedThisSessionProvider)) {
    if (id.startsWith(prefix)) out.add(id.substring(prefix.length));
  }
  return out;
}, name: 'finishedChapters',);

/// [isGuarded] for another member's reaction on [chapterKey], from the viewer's own progress.
bool guardedFor(Set<String> finished, {required String chapterKey, required bool isOwn, required bool? sealed}) =>
    isGuarded(isOwn: isOwn, sealed: sealed, completedLocally: finished.contains(chapterKey), completedThisSession: false);
