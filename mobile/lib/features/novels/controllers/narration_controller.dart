import 'dart:async';

import 'package:audio_service/audio_service.dart' show AudioProcessingState;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/logging/app_logger.dart';
import 'package:manhwamaniacs/features/novels/models/novel_audio.dart';
import 'package:manhwamaniacs/features/novels/models/novel_audio_format.dart';
import 'package:manhwamaniacs/features/novels/providers/listen_session_outbox_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/listen_settings_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/narration_audio_handler_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_chapter_provider.dart';
import 'package:manhwamaniacs/features/novels/services/narration_audio_handler.dart';
import 'package:manhwamaniacs/features/novels/services/narration_player.dart';
import 'package:manhwamaniacs/features/novels/utils/listen_sessions.dart';
import 'package:manhwamaniacs/features/novels/utils/shake_detector.dart';
import 'package:manhwamaniacs/features/novels/utils/sleep_timer.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/skin_audio.dart';

/// What the player is doing, in the terms every screen shows.
enum NarrationStatus {
  idle,

  /// `503 audio_preparing`: the server is converting the chapter for this device.
  preparing,
  loading,
  paused,
  playing,
  buffering,

  /// Reached the chapter's end.
  completed,
  failed,
}

/// One chapter to read aloud, with everything the lock screen and the transcript need.
class NarrationTarget {
  NarrationTarget({
    required this.key,
    required this.audio,
    required this.paragraphs,
    required this.bookTitle,
    this.file,
    this.chapterNumber,
    this.chapterTitle = '',
    this.narratorName,
    this.coverUrl,
  });

  final NovelChapterKey key;
  final NovelAudio audio;

  /// The text on screen, which the timing map is checked against.
  final List<String> paragraphs;
  final String bookTitle;

  /// A saved narration's playback file; null streams from the server.
  final String? file;
  final double? chapterNumber;
  final String chapterTitle;
  final String? narratorName;

  /// The cover through the cover proxy (absolute URL, `?w=512` applied by the caller).
  final String? coverUrl;

  /// Whether the page should follow along: the server vouches for the text AND every range fits.
  late final bool followsText = audio.followsText(paragraphs);
}

class NarrationState {
  const NarrationState({
    this.target,
    this.status = NarrationStatus.idle,
    this.speed = 1.0,
    this.failure,
    this.revision = 0,
  });

  final NarrationTarget? target;
  final NarrationStatus status;
  final double speed;

  /// Why a load failed, for the caption.
  final String? failure;

  /// Bumps on every new chapter session so a listener can tell chapter 13 from a replay of 12.
  final int revision;

  NovelChapterKey? get key => target?.key;

  /// Narration is on the phone's mind: playing, or paused inside the reader (State B holds).
  bool get active => switch (status) {
        NarrationStatus.idle || NarrationStatus.completed || NarrationStatus.failed => false,
        _ => true,
      };

  bool get isPlaying => status == NarrationStatus.playing || status == NarrationStatus.buffering;

  /// The page follows the voice: audio present AND the text matches.
  bool get highlightSafe => target?.followsText ?? false;

  NarrationState copyWith({
    NarrationTarget? target,
    bool clearTarget = false,
    NarrationStatus? status,
    double? speed,
    String? failure,
    bool clearFailure = false,
    int? revision,
  }) =>
      NarrationState(
        target: clearTarget ? null : (target ?? this.target),
        status: status ?? this.status,
        speed: speed ?? this.speed,
        failure: clearFailure ? null : (failure ?? this.failure),
        revision: revision ?? this.revision,
      );
}

/// A chapter's audio ended.
class NarrationEnded {
  const NarrationEnded({required this.key, required this.sleepStop});
  final NovelChapterKey key;

  /// The sleep timer stopped playback here: no post-play card.
  final bool sleepStop;
}

/// The reply of a probe request for a streamed chapter.
typedef NarrationProbeResult = ({int status, Duration? retryAfter});
typedef NarrationProbe = Future<NarrationProbeResult> Function(String url, Map<String, String> headers);

/// Asks for the first byte. A `503 audio_preparing` reads its `Retry-After`; anything else is the
/// status. Never throws: a network error is a status of 0.
final narrationProbeProvider = Provider<NarrationProbe>((ref) {
  final dio = ref.watch(dioProvider);
  return (url, headers) async {
    try {
      final r = await dio.get<List<int>>(
        url,
        options: Options(
          headers: {...headers, 'Range': 'bytes=0-0'},
          responseType: ResponseType.bytes,
          validateStatus: (_) => true,
        ),
      );
      final ra = int.tryParse(r.headers.value('retry-after') ?? '');
      return (status: r.statusCode ?? 0, retryAfter: ra == null ? null : Duration(seconds: ra));
    } catch (_) {
      return (status: 0, retryAfter: null);
    }
  };
},
    name: 'narrationProbe',);

/// How many times a `503 audio_preparing` is retried before it counts as a failure.
const int kNarrationPrepareRetries = 40;

/// The app's narration: one `just_audio` player (the one the lock-screen handler wraps), the
/// chapter it plays, the highlight's clock, the sleep timer, the shake to extend and the listen
/// sessions (cinematic 8.16). Skin-neutral: the legacy player bar and the Cinematic mini player
/// and reading room are both views over it.
class NarrationController extends Notifier<NarrationState> with WidgetsBindingObserver implements NarrationCommands {
  NarrationPlayer? _player;
  final List<StreamSubscription<Object?>> _subs = [];
  NarrationAudioHandler? _handler;
  late final ListenSessionTracker _sessions;
  late final SleepTimer _sleep;
  late final ShakeDetector _shake;
  final StreamController<NarrationEnded> _ended = StreamController<NarrationEnded>.broadcast();
  int _loadToken = 0;
  bool _playWhenReady = false;
  bool _completedHandled = false;
  bool _observing = false;

  /// The playhead in milliseconds. High frequency: listen to it, never `setState` from it.
  final ValueNotifier<int> position = ValueNotifier<int>(0);

  /// The buffered position in milliseconds, for the mini player's 35 % rule.
  final ValueNotifier<int> buffered = ValueNotifier<int>(0);

  /// The active segment index (`-1` none), only while [NarrationState.highlightSafe].
  final ValueNotifier<int> segment = ValueNotifier<int>(-1);

  /// The lock screen's next-chapter button and the mini player's swipe: the reader sets this to
  /// its novel controller's `next()`.
  VoidCallback? onSkipNext;

  /// Haptic and toast hooks the mounted reader wires (the controller owns no `BuildContext`).
  void Function(NarrationFeedback)? onFeedback;

  /// A chapter's audio ended (the reader shows the post-play card, or the sleep timer stopped it).
  Stream<NarrationEnded> get ended => _ended.stream;

  ValueListenable<SleepState> get sleepState => _sleep.state;

  @override
  NarrationState build() {
    final settings = ref.read(listenSettingsValueProvider);
    try {
      _handler = ref.read(audioHandlerProvider);
      _handler!.attach(this);
    } catch (_) {
      // No handler in this tree (a test, or a build without audio_service): foreground only.
      _handler = null;
    }
    _sessions = ListenSessionTracker(
      onClosed: (s) => unawaited(ref.read(listenSessionOutboxControllerProvider).save(s)),
      now: ref.read(narrationClockProvider),
      timer: ref.read(narrationTimerProvider),
    );
    _sleep = SleepTimer(
      setVolume: (v) => unawaited(_player?.setVolume(v)),
      pause: () async => pause(),
      onFadeStart: () => onFeedback?.call(NarrationFeedback.sleepFade),
    );
    _shake = ShakeDetector(onShake: _onShake, source: ref.read(accelerometerSourceProvider));
    _sleep.state.addListener(_onSleepState);
    try {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    } catch (_) {}
    ref.onDispose(() {
      _sleep.state.removeListener(_onSleepState);
      _shake.dispose();
      _sleep.dispose();
      _sessions
        ..close()
        ..dispose();
      final h = _handler;
      if (h != null) {
        h.detach(this);
        h.clear();
      }
      if (_observing) WidgetsBinding.instance.removeObserver(this);
      unawaited(_disposePlayer());
      unawaited(_ended.close());
      position.dispose();
      buffered.dispose();
      segment.dispose();
    });
    return NarrationState(speed: settings.speed);
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final outbox = ref.read(listenSessionOutboxControllerProvider);
    switch (state) {
      case AppLifecycleState.detached:
        _sessions.close();
      case AppLifecycleState.paused:
        // A session still playing in the background stays open and is sent when it closes.
        unawaited(outbox.flush());
      case AppLifecycleState.resumed:
        unawaited(outbox.flush());
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  // ── Loading ───────────────────────────────────────────────────────────────

  /// Read [target] aloud from [startMs], replacing whatever was playing.
  Future<void> start(NarrationTarget target, {int startMs = 0, bool play = true}) async {
    final token = ++_loadToken;
    _sessions.close();
    await _disposePlayer();
    if (token != _loadToken) return;
    _playWhenReady = play;
    _completedHandled = false;
    position.value = startMs;
    buffered.value = 0;
    segment.value = -1;
    state = NarrationState(
      target: target,
      status: NarrationStatus.loading,
      speed: ref.read(listenSettingsValueProvider).speed,
      revision: state.revision + 1,
    );
    _publishItem(target);
    _publish();
    unawaited(_load(target, token, startMs));
  }

  /// Load again after a failure.
  Future<void> retry() async {
    final t = state.target;
    if (t == null) return;
    await start(t, startMs: position.value);
  }

  Future<void> _load(NarrationTarget target, int token, int startMs) async {
    final headers = _headers();
    String? url;
    if (target.file == null) {
      url = _fileUrl(target.key);
      final probe = ref.read(narrationProbeProvider);
      for (var attempt = 0;; attempt++) {
        final r = await probe(url, headers);
        if (token != _loadToken) return;
        if (r.status >= 200 && r.status < 300) break;
        if (r.status == 503 && attempt < kNarrationPrepareRetries) {
          state = state.copyWith(status: NarrationStatus.preparing);
          _publish();
          final wait = r.retryAfter ?? const Duration(seconds: 3);
          await Future<void>.delayed(wait < const Duration(seconds: 1) ? const Duration(seconds: 1) : (wait > const Duration(seconds: 30) ? const Duration(seconds: 30) : wait));
          if (token != _loadToken) return;
          continue;
        }
        _fail(token, r.status == 0 ? "Audio couldn't be loaded." : 'The server answered ${r.status}.');
        return;
      }
    }
    final player = ref.read(narrationPlayerFactoryProvider)();
    try {
      if (target.file != null) {
        await player.setFilePath(target.file!);
      } else {
        await player.setUrl(url!, headers);
      }
      if (token != _loadToken) {
        await player.dispose();
        return;
      }
      await player.setSpeed(state.speed);
      if (startMs > 0) await player.seek(Duration(milliseconds: startMs));
    } catch (e, st) {
      appLogger.w('Narration failed to load', e, st);
      await player.dispose();
      if (token == _loadToken) _fail(token, "Audio couldn't be loaded.");
      return;
    }
    if (token != _loadToken) {
      await player.dispose();
      return;
    }
    _player = player;
    _subs
      ..add(player.positionStream.listen(_onPosition))
      ..add(player.bufferedStream.listen((d) => buffered.value = d.inMilliseconds))
      ..add(player.stateStream.listen(_onPlayerState));
    state = state.copyWith(status: NarrationStatus.paused, clearFailure: true);
    _publish();
    if (_playWhenReady) await play();
  }

  void _fail(int token, String message) {
    if (token != _loadToken) return;
    state = state.copyWith(status: NarrationStatus.failed, failure: message);
    _publish();
  }

  Map<String, String> _headers() {
    final token = ref.read(authTokenStoreProvider).token;
    final profile = ref.read(dioProvider).options.headers['X-Profile-Id'];
    return {
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      if (profile != null) 'X-Profile-Id': '$profile',
    };
  }

  /// `GET /novels/audio/file`, in the container this phone plays.
  String _fileUrl(NovelChapterKey key) {
    final base = ref.read(apiBaseUrlProvider);
    final trimmed = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final query = Uri(
      queryParameters: novelAudioFileQuery(
        sourceId: key.sourceId,
        seriesKey: key.seriesKey,
        chapterKey: key.chapterKey,
        format: novelAudioFormatFor(defaultTargetPlatform),
      ),
    ).query;
    return '$trimmed/novels/audio/file?$query';
  }

  Future<void> _disposePlayer() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    final p = _player;
    _player = null;
    // Released, not left playing: undisposed, the audio outlives the reader and on iOS keeps the
    // audio session active and silences everything else on the phone.
    if (p != null) await p.dispose();
  }

  // ── Player events ─────────────────────────────────────────────────────────

  void _onPosition(Duration d) {
    final t = state.target;
    if (t == null) return;
    final ms = d.inMilliseconds;
    position.value = ms;
    if (!state.highlightSafe) return;
    final i = t.audio.segmentAt(ms);
    if (i != segment.value) {
      segment.value = i;
      _sessions.voiceChanged(i < 0 ? null : t.audio.segments[i].voice);
    }
    _publishPlayback();
  }

  void _onPlayerState(({bool playing, NarrationProcessing processing}) s) {
    final t = state.target;
    if (t == null) return;
    final NarrationStatus status;
    if (s.processing == NarrationProcessing.completed) {
      status = NarrationStatus.completed;
    } else if (s.playing) {
      status = s.processing == NarrationProcessing.ready ? NarrationStatus.playing : NarrationStatus.buffering;
    } else {
      status = s.processing == NarrationProcessing.loading ? NarrationStatus.loading : NarrationStatus.paused;
    }
    if (status == state.status) return;
    final wasPlaying = state.isPlaying;
    state = state.copyWith(status: status);
    if (state.isPlaying && !wasPlaying) {
      _sessions.play(t.key, voice: _currentVoice());
    } else if (!state.isPlaying && wasPlaying && status != NarrationStatus.completed) {
      _sessions.pause();
    }
    if (status == NarrationStatus.completed) unawaited(_onCompleted(t));
    _publish();
  }

  String? _currentVoice() {
    final t = state.target;
    final i = segment.value;
    return t == null || i < 0 || i >= t.audio.segments.length ? null : t.audio.segments[i].voice;
  }

  Future<void> _onCompleted(NarrationTarget t) async {
    if (_completedHandled) return;
    _completedHandled = true;
    segment.value = -1;
    _sessions.close();
    final stop = _sleep.onChapterBoundary() == SleepBoundary.stop;
    if (!_ended.isClosed) _ended.add(NarrationEnded(key: t.key, sleepStop: stop));
    if (stop) await _idleSession();
  }

  Future<void> _idleSession() => ref.read(narrationSessionProvider)(AudioSessionState.idle);

  // ── Commands ──────────────────────────────────────────────────────────────

  bool get isPlaying => state.isPlaying;

  /// `p`, the mini player's button and the lock screen's play.
  @override
  Future<void> play() async {
    final p = _player;
    if (p == null) {
      _playWhenReady = true;
      return;
    }
    if (state.status == NarrationStatus.completed) {
      _completedHandled = false;
      await p.seek(Duration.zero);
    }
    await ref.read(narrationSessionProvider)(AudioSessionState.narration);
    unawaited(p.play());
  }

  @override
  Future<void> pause() async {
    _playWhenReady = false;
    await _player?.pause();
  }

  Future<void> toggle() => isPlaying ? pause() : play();

  @override
  Future<void> seek(Duration position) async {
    final t = state.target;
    final total = t?.audio.totalMs ?? 0;
    final ms = position.inMilliseconds.clamp(0, total > 0 ? total : position.inMilliseconds);
    this.position.value = ms;
    if (t != null && state.highlightSafe) segment.value = t.audio.segmentAt(ms);
    await _player?.seek(Duration(milliseconds: ms));
    _publishPlayback();
  }

  @override
  Future<void> seekBy(Duration delta) => seek(Duration(milliseconds: position.value) + delta);

  /// A tap on a transcript sentence.
  Future<void> seekToSegment(int index) async {
    final t = state.target;
    if (t == null || index < 0 || index >= t.audio.segments.length) return;
    await seek(Duration(milliseconds: t.audio.segments[index].startMs));
  }

  /// The first sentence of [paragraph] (or the next paragraph that has one).
  Future<void> seekToParagraph(int paragraph) async {
    final t = state.target;
    if (t == null) return;
    final i = t.audio.segments.indexWhere((s) => s.paragraph >= paragraph);
    if (i >= 0) await seekToSegment(i);
  }

  /// `[` and `]`: the previous or next sentence.
  Future<void> stepSentence(int delta) async {
    final t = state.target;
    if (t == null || t.audio.segments.isEmpty) return;
    final now = segment.value < 0 ? t.audio.segmentAt(position.value) : segment.value;
    final at = now < 0 ? (delta > 0 ? -1 : t.audio.segments.length) : now;
    await seekToSegment((at + delta).clamp(0, t.audio.segments.length - 1));
  }

  Future<void> setSpeed(double speed) async {
    final v = normaliseListenSpeed(speed);
    state = state.copyWith(speed: v);
    await _player?.setSpeed(v);
    await ref.read(listenSettingsProvider.notifier).put({'speed': v});
    _publishPlayback();
  }

  @override
  Future<void> skipToNext() async => onSkipNext?.call();

  /// Leaving the reader: stops, releases the player, closes the session and removes the
  /// notification.
  @override
  Future<void> stop() async {
    _loadToken++;
    _playWhenReady = false;
    _sessions.close();
    _sleep.cancel();
    await _disposePlayer();
    position.value = 0;
    segment.value = -1;
    state = NarrationState(speed: state.speed, revision: state.revision);
    _handler?.clear();
    await _idleSession();
  }

  /// A voice sample is about to play: pauses narration and answers the call that resumes it.
  Future<Future<void> Function()> pauseForSample() async {
    final was = isPlaying;
    if (was) await pause();
    return () async {
      if (was && state.target != null) await play();
    };
  }

  // ── Sleep timer and shake ─────────────────────────────────────────────────

  void setSleep(SleepChoice choice) => _sleep.set(choice);

  void _onSleepState() {
    final wanted = ref.read(listenSettingsValueProvider).shakeToExtend && (_sleep.state.value.inLastMinute || _sleep.state.value.fading);
    _shake.setListening(wanted);
  }

  void _onShake() {
    if (_sleep.extend()) onFeedback?.call(NarrationFeedback.shakeExtended);
  }

  /// Whether the accelerometer is subscribed (the fake-stream test reads this).
  bool get shakeListening => _shake.listening;

  // ── Lock screen ───────────────────────────────────────────────────────────

  void _publishItem(NarrationTarget t) {
    final h = _handler;
    if (h == null) return;
    final token = ref.read(authTokenStoreProvider).token;
    final art = t.coverUrl;
    h.showItem(
      narrationMediaItem(
        key: t.key,
        bookTitle: t.bookTitle,
        totalMs: t.audio.totalMs,
        chapterNumber: t.chapterNumber,
        chapterTitle: t.chapterTitle,
        narratorName: t.narratorName,
        artUri: art == null ? null : Uri.tryParse(art),
        artHeaders: token == null || token.isEmpty ? null : _headers(),
      ),
    );
  }

  void _publish() => _publishPlayback();

  void _publishPlayback() {
    final h = _handler;
    if (h == null) return;
    final s = state;
    if (s.target == null || s.status == NarrationStatus.idle) return;
    h.publish(
      playing: s.isPlaying,
      processing: switch (s.status) {
        NarrationStatus.idle => AudioProcessingState.idle,
        NarrationStatus.preparing || NarrationStatus.loading => AudioProcessingState.loading,
        NarrationStatus.buffering => AudioProcessingState.buffering,
        NarrationStatus.completed => AudioProcessingState.completed,
        NarrationStatus.failed => AudioProcessingState.error,
        _ => AudioProcessingState.ready,
      },
      position: Duration(milliseconds: position.value),
      buffered: Duration(milliseconds: buffered.value),
      speed: s.speed,
    );
  }
}

/// The one narration for the app.
final narrationControllerProvider = NotifierProvider<NarrationController, NarrationState>(NarrationController.new, name: 'narrationController');

/// True while narration plays or is paused inside the reader: `skin_audio.dart` suppresses UI cues
/// and holds audio-session State B for exactly this span.
final narrationActiveProvider = Provider<bool>((ref) => ref.watch(narrationControllerProvider.select((s) => s.active)), name: 'narrationActive');

/// What the controller asks the mounted reader to signal.
enum NarrationFeedback { sleepFade, shakeExtended }

/// The accelerometer, replaceable in tests.
final accelerometerSourceProvider = Provider<AccelerometerSource>((ref) => platformAccelerometer, name: 'accelerometerSource');

/// The wall clock and timer behind the listen sessions, replaceable in tests.
final narrationClockProvider = Provider<DateTime Function()>((ref) => DateTime.now, name: 'narrationClock');

final narrationTimerProvider = Provider<Timer Function(Duration, void Function())>((ref) => Timer.new, name: 'narrationTimer');

/// Moves the process-wide audio session between its states (State B while narrating, State A
/// otherwise); replaceable in tests.
final narrationSessionProvider = Provider<Future<void> Function(AudioSessionState)>((ref) => SkinAudio.instance.request, name: 'narrationSession');
