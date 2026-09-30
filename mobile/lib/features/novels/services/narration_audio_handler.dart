import 'package:audio_service/audio_service.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_chapter_provider.dart';

/// Rewind and fast-forward step (lock screen and notification).
const Duration kNarrationSkip = Duration(seconds: 15);

/// What the lock screen and the notification ask of the player; the narration controller
/// implements it.
abstract interface class NarrationCommands {
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> seekBy(Duration delta);
  Future<void> skipToNext();
  Future<void> stop();
}

/// The lock-screen handler (cinematic 8.16.10): one for the app, created once in `main()` and
/// reaching the tree as `audioHandlerProvider.overrideWithValue(handler)`. It holds no player; the
/// narration controller attaches itself as [NarrationCommands] and publishes state through
/// [showItem] and [publish].
class NarrationAudioHandler extends BaseAudioHandler with SeekHandler {
  NarrationCommands? _commands;

  void attach(NarrationCommands commands) => _commands = commands;

  void detach(NarrationCommands commands) {
    if (identical(_commands, commands)) _commands = null;
  }

  void showItem(MediaItem item) => mediaItem.add(item);

  /// Publishes the player's state: the controls, the compact indices and the system actions the
  /// lock screen shows.
  void publish({
    required bool playing,
    required AudioProcessingState processing,
    required Duration position,
    Duration buffered = Duration.zero,
    double speed = 1,
  }) {
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.rewind,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.fastForward,
          MediaControl.skipToNext,
        ],
        systemActions: const {MediaAction.seek, MediaAction.seekForward, MediaAction.seekBackward},
        androidCompactActionIndices: const [0, 1, 2],
        processingState: processing,
        playing: playing,
        updatePosition: position,
        bufferedPosition: buffered,
        speed: speed,
      ),
    );
  }

  /// Nothing is narrating: removes the notification and the lock-screen card.
  void clear() {
    playbackState.add(PlaybackState());
    mediaItem.add(null);
  }

  @override
  Future<void> play() async => _commands?.play();

  @override
  Future<void> pause() async => _commands?.pause();

  @override
  Future<void> seek(Duration position) async => _commands?.seek(position);

  @override
  Future<void> rewind() async => _commands?.seekBy(-kNarrationSkip);

  @override
  Future<void> fastForward() async => _commands?.seekBy(kNarrationSkip);

  @override
  Future<void> skipToNext() async => _commands?.skipToNext();

  @override
  Future<void> stop() async {
    await _commands?.stop();
    clear();
  }
}

/// The lock-screen card's item: `Chapter 12 · The Tower`, the book as the album, `Read by Iris`
/// as the artist, the cover (through the cover proxy at `?w=512`) with the auth headers, and the
/// audio's duration.
MediaItem narrationMediaItem({
  required NovelChapterKey key,
  required String bookTitle,
  required int totalMs,
  double? chapterNumber,
  String chapterTitle = '',
  String? narratorName,
  Uri? artUri,
  Map<String, String>? artHeaders,
}) {
  final number = chapterNumber == null ? null : 'Chapter ${_number(chapterNumber)}';
  final title = [
    if (number != null) number,
    if (chapterTitle.isNotEmpty && chapterTitle != number) chapterTitle,
  ].join(' · ');
  return MediaItem(
    id: '${key.sourceId}:${key.seriesKey}:${key.chapterKey}',
    title: title.isEmpty ? (chapterTitle.isEmpty ? bookTitle : chapterTitle) : title,
    album: bookTitle,
    artist: narratorName == null || narratorName.isEmpty ? 'Narrated' : 'Read by $narratorName',
    duration: Duration(milliseconds: totalMs),
    artUri: artUri,
    artHeaders: artHeaders,
  );
}

String _number(double n) => n == n.roundToDouble() ? n.round().toString() : n.toString();
