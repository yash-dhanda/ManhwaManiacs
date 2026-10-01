import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/novels/services/narration_audio_handler.dart';

class _Commands implements NarrationCommands {
  final List<String> log = [];
  final List<Duration> seekBys = [];
  @override
  Future<void> play() async => log.add('play');
  @override
  Future<void> pause() async => log.add('pause');
  @override
  Future<void> seek(Duration position) async => log.add('seek ${position.inSeconds}');
  @override
  Future<void> seekBy(Duration delta) async => seekBys.add(delta);
  @override
  Future<void> skipToNext() async => log.add('next');
  @override
  Future<void> skipToPrevious() async => log.add('previous');
  @override
  Future<void> stop() async => log.add('stop');
}

void main() {
  const key = (sourceId: 'src', seriesKey: 'book', chapterKey: 'c12');

  test('the media item carries chapter, album, narrator, art and duration', () {
    final item = narrationMediaItem(
      key: key,
      bookTitle: 'Omniscient Reader',
      totalMs: 1120000,
      chapterNumber: 12,
      chapterTitle: 'The Tower',
      narratorName: 'Iris',
      artUri: Uri.parse('https://x/cover?w=512'),
      artHeaders: {'Authorization': 'Bearer t', 'X-Profile-Id': '3'},
    );
    expect(item.id, 'src:book:c12');
    expect(item.title, 'Chapter 12 · The Tower');
    expect(item.album, 'Omniscient Reader');
    expect(item.artist, 'Read by Iris');
    expect(item.artUri.toString(), 'https://x/cover?w=512');
    expect(item.artHeaders!['Authorization'], 'Bearer t');
    expect(item.artHeaders!['X-Profile-Id'], '3');
    expect(item.duration, const Duration(milliseconds: 1120000));
  });

  test('a chapter with no title and no narrator', () {
    final item = narrationMediaItem(key: key, bookTitle: 'B', totalMs: 1000, chapterNumber: 3.5);
    expect(item.title, 'Chapter 3.5');
    expect(item.artist, 'Narrated');
  });

  test('controls are rewind, play or pause, fast-forward, next; compact 0-2', () {
    final h = NarrationAudioHandler();
    h.publish(playing: false, processing: AudioProcessingState.ready, position: Duration.zero);
    var s = h.playbackState.value;
    expect(s.controls, [MediaControl.rewind, MediaControl.play, MediaControl.fastForward, MediaControl.skipToNext]);
    expect(s.androidCompactActionIndices, [0, 1, 2]);
    expect(s.systemActions, {MediaAction.seek, MediaAction.seekForward, MediaAction.seekBackward});
    h.publish(playing: true, processing: AudioProcessingState.ready, position: const Duration(seconds: 4), speed: 1.5);
    s = h.playbackState.value;
    expect(s.controls[1], MediaControl.pause);
    expect(s.playing, isTrue);
    expect(s.speed, 1.5);
    expect(s.updatePosition, const Duration(seconds: 4));
  });

  test('rewind and fast-forward seek by exactly 15 s; the rest pass through', () async {
    final h = NarrationAudioHandler();
    final c = _Commands();
    h.attach(c);
    await h.rewind();
    await h.fastForward();
    expect(c.seekBys, [const Duration(seconds: -15), const Duration(seconds: 15)]);
    await h.play();
    await h.pause();
    await h.seek(const Duration(seconds: 42));
    await h.skipToNext();
    expect(c.log, ['play', 'pause', 'seek 42', 'next']);
    await h.stop();
    expect(c.log.last, 'stop');
    expect(h.mediaItem.value, isNull);
    expect(h.playbackState.value.processingState, AudioProcessingState.idle);
  });

  test('commands with nothing attached do nothing', () async {
    final h = NarrationAudioHandler();
    await h.play();
    await h.rewind();
  });

  test('Glass control set: previous, rewind, play or pause, fast-forward, next; compact 1-3; plus 15 s seeks', () async {
    final h = NarrationAudioHandler()..controlSet = NarrationControlSet.glass;
    final c = _Commands();
    h.attach(c);
    h.publish(playing: true, processing: AudioProcessingState.ready, position: Duration.zero);
    final s = h.playbackState.value;
    expect(s.controls, [MediaControl.skipToPrevious, MediaControl.rewind, MediaControl.pause, MediaControl.fastForward, MediaControl.skipToNext]);
    expect(s.androidCompactActionIndices, [1, 2, 3]);
    expect(s.systemActions, {MediaAction.seek, MediaAction.seekForward, MediaAction.seekBackward});
    await h.skipToPrevious();
    await h.rewind();
    await h.fastForward();
    expect(c.log, ['previous']);
    expect(c.seekBys, [const Duration(seconds: -15), const Duration(seconds: 15)]);
  });
}
