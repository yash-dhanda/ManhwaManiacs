import 'package:audio_service/audio_service.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:manhwamaniacs/features/novels/providers/novel_chapter_provider.dart';
import 'package:manhwamaniacs/skins/skin.dart' show SkinId;

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

  /// The Glass lock screen's previous-chapter button.
  Future<void> skipToPrevious();
  Future<void> stop();
}

/// Which buttons the lock screen and the notification carry (one per skin, glass 12.6).
enum NarrationControlSet {
  /// `[rewind, play/pause, fastForward, skipToNext]`, compact `[0, 1, 2]`.
  cinematic,

  /// `[skipToPrevious, rewind, play/pause, fastForward, skipToNext]`, compact `[1, 2, 3]`.
  glass;

  List<MediaControl> controls({required bool playing}) {
    final pp = playing ? MediaControl.pause : MediaControl.play;
    return switch (this) {
      NarrationControlSet.cinematic => [MediaControl.rewind, pp, MediaControl.fastForward, MediaControl.skipToNext],
      NarrationControlSet.glass => [MediaControl.skipToPrevious, MediaControl.rewind, pp, MediaControl.fastForward, MediaControl.skipToNext],
    };
  }

  List<int> get compactIndices => switch (this) {
        NarrationControlSet.cinematic => const [0, 1, 2],
        NarrationControlSet.glass => const [1, 2, 3],
      };
}

/// The lock-screen handler (cinematic 8.16.10): one for the app, created once in `main()` and
/// reaching the tree as `audioHandlerProvider.overrideWithValue(handler)`. It holds no player; the
/// narration controller attaches itself as [NarrationCommands] and publishes state through
/// [showItem] and [publish].
class NarrationAudioHandler extends BaseAudioHandler with SeekHandler {
  NarrationCommands? _commands;

  /// The skin's button set; the controller sets it from the active skin when it attaches.
  NarrationControlSet controlSet = NarrationControlSet.cinematic;

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
        controls: controlSet.controls(playing: playing),
        systemActions: const {MediaAction.seek, MediaAction.seekForward, MediaAction.seekBackward},
        androidCompactActionIndices: controlSet.compactIndices,
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
  Future<void> skipToPrevious() async => _commands?.skipToPrevious();

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

/// `AudioService.init`'s config (A3). It runs once per process before `runApp`, so the notification accent is the boot skin's:
/// Glass `iris600` `#7563F2`, otherwise Cinematic's `#F4D03F`. A skin switch inside the process keeps the colour until the next cold start.
AudioServiceConfig narrationAudioServiceConfig(SkinId bootSkin) => AudioServiceConfig(
      androidNotificationChannelId: 'com.manhwamaniacs.reader.listen',
      androidNotificationChannelName: 'Listen',
      androidNotificationIcon: 'drawable/ic_stat_mm',
      notificationColor: bootSkin == SkinId.glass ? const Color(0xFF7563F2) : const Color(0xFFF4D03F),
      fastForwardInterval: kNarrationSkip,
      rewindInterval: kNarrationSkip,
    );
