/// The Glass narration host (glass 8.16, items A1, A6, C5): what every listen surface (the listen row, the accessories, the full player,
/// the reader's entries) reads and calls. Playback itself is `mobile/15`'s skin-neutral [NarrationController]; this file adds the
/// chapter navigation that works without the reader mounted, the narrator voice, the Undo for a stop, and the bridge the novel reader
/// asks for "Play from here".
library;

import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/network/api_image.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/library/utils/cover_url.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/novels/models/novel_cast.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_audio_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_cast_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_chapter_provider.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/listen/listen_common.dart';
import 'package:manhwamaniacs/skins/glass/listen/post_play_card.dart';
import 'package:manhwamaniacs/skins/glass/listen/voice_hue.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart' show glassFire;
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/listen_bridge.dart';
import 'package:manhwamaniacs/skins/glass/shell/accessory_controller.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// The words for a failed listen write (glass 8.0.10): `audio_convert_failed`, `narration_unavailable`, else the server's own.
String listenErrorText(AppError e) {
  if (e is ApiError) {
    switch (e.code) {
      case 'audio_convert_failed':
        return "This chapter's audio couldn't be prepared.";
      case 'narration_unavailable':
        return "Narration of new chapters isn't available right now.";
      case 'audio_preparing':
        return 'Preparing audio';
    }
  }
  return e.userMessage;
}

/// The owner is an admin account (`is_admin` on `GET /auth/me`): only they render, cast and cancel (glass 8.13).
final glassIsOwnerProvider = Provider<bool>((ref) {
  final auth = ref.watch(authControllerProvider);
  return auth is AuthAuthenticated && auth.user.isAdmin;
}, name: 'glassIsOwner',);

/// The voice a chapter is narrated in: its name ("Default voice" when automatic), its [voiceHue] and the server's record.
@immutable
class GlassNarrator {
  const GlassNarrator({required this.name, required this.hue, this.voice});
  final String name;
  final Color hue;
  final NovelVoice? voice;

  String get initial => name.isEmpty ? '?' : name.characters.first.toUpperCase();

  @override
  bool operator ==(Object other) => other is GlassNarrator && other.name == name && other.hue == hue && other.voice?.voiceId == voice?.voiceId;

  @override
  int get hashCode => Object.hash(name, hue, voice?.voiceId);
}

const Color _kDefaultVoiceHue = Color(0xFF8F7EFF);

final glassNarratorProvider = Provider.autoDispose.family<GlassNarrator, NovelChapterKey>((ref, key) {
  final id = ref.watch(novelAttributionProvider(key)).valueOrNull?.narratorVoiceId;
  final voices = ref.watch(novelVoicesProvider).valueOrNull ?? const <NovelVoice>[];
  final voice = id == null ? null : voices.where((v) => v.voiceId == id).firstOrNull;
  return GlassNarrator(name: voice?.name ?? 'Default voice', hue: voice == null ? _kDefaultVoiceHue : voiceHue(voice.pitchHz), voice: voice);
}, name: 'glassNarrator',);

/// "Chapter 12" / "Ch 12" for a narration target.
String glassChapterWord(NarrationTarget t, {bool short = false}) {
  final n = t.chapterNumber;
  if (n == null) return t.chapterTitle.isEmpty ? t.bookTitle : t.chapterTitle;
  final num = n == n.roundToDouble() ? n.round().toString() : n.toString();
  return '${short ? 'Ch' : 'Chapter'} $num';
}

/// The accessory's line, "Chapter 12 · Aurora" (the voice's name); [short] gives the row's "Ch 12 · Aurora".
String glassNarratingLine(NarrationTarget t, String voiceName, {bool short = false}) => '${glassChapterWord(t, short: short)} · $voiceName';

/// The book (and chapter) a global `?sheet=` of the listen family (`voices`, `cast`, `audiobook`) is about: the location's novel reader
/// or book page, else the chapter that is narrating. Read when the sheet builds.
typedef GlassListenScope = ({String sourceId, String seriesKey, String? chapterKey});

GlassListenScope? glassListenScopeFor(List<String> segments, NovelChapterKey? narrating) {
  if (segments.length >= 4 && segments[0] == 'novels') return (sourceId: segments[1], seriesKey: segments[2], chapterKey: segments[3]);
  if (segments.length >= 4 && segments[0] == 'sources' && segments[2] == 'series') return (sourceId: segments[1], seriesKey: segments[3], chapterKey: null);
  if (segments.length >= 3 && (segments[0] == 'read-all' || segments[0] == 'recap')) return (sourceId: segments[1], seriesKey: segments[2], chapterKey: null);
  return narrating == null ? null : (sourceId: narrating.sourceId, seriesKey: narrating.seriesKey, chapterKey: narrating.chapterKey);
}

final glassListenScopeProvider = Provider.autoDispose<GlassListenScope?>((ref) {
  final narrating = ref.watch(narrationControllerProvider.select((s) => s.key));
  final segments = ref.watch(skinRouterProvider).routerDelegate.currentConfiguration.uri.pathSegments;
  return glassListenScopeFor(segments, narrating);
}, name: 'glassListenScope',);

/// Where the player sheet grows from (the row's or the accessory's rect), read once when `?sheet=player` opens.
Rect? glassPlayerOrigin;

/// Whether the listen row was hidden for this session (D2); the accessory keeps its own flag in [glassAccessoryProvider].
final glassListenRowHiddenProvider = StateProvider<bool>((ref) => false, name: 'glassListenRowHidden');
final glassListenRowPinnedProvider = StateProvider<bool>((ref) => false, name: 'glassListenRowPinned');

/// What the surfaces call. Every method works with no reader mounted.
class GlassNarrationActions {
  GlassNarrationActions(this._ref);
  final Ref _ref;

  NarrationController get _n => _ref.read(narrationControllerProvider.notifier);
  NarrationState get state => _ref.read(narrationControllerProvider);

  void _toast(GlassToastSpec spec) => _ref.read(glassToastProvider.notifier).show(spec);

  /// Builds a target for [key]; null when the chapter has no audio.
  Future<NarrationTarget?> buildTarget(
    NovelChapterKey key, {
    List<String>? paragraphs,
    String? bookTitle,
    double? chapterNumber,
    String? chapterTitle,
  }) async {
    final playable = await _ref.read(playableNovelAudioProvider(key).future);
    if (playable == null) return null;
    var paras = paragraphs, title = chapterTitle ?? '', number = chapterNumber;
    if (paras == null) {
      final c = await _ref.read(resolvedNovelChapterProvider(key).future);
      paras = c.paragraphs;
      title = c.title;
      number = c.chapterNumber;
    }
    var book = bookTitle;
    if (book == null || book.isEmpty) {
      try {
        book = (await _ref.read(sourceSeriesDetailProvider((sourceId: key.sourceId, seriesId: key.seriesKey)).future)).series.title;
      } catch (_) {
        book = '';
      }
    }
    String? narrator;
    try {
      final attr = await _ref.read(novelAttributionProvider(key).future).timeout(const Duration(milliseconds: 400));
      final voices = await _ref.read(novelVoicesProvider.future).timeout(const Duration(milliseconds: 400));
      narrator = attr.narratorVoiceId == null ? null : voices.where((v) => v.voiceId == attr.narratorVoiceId).firstOrNull?.name;
    } catch (_) {
      narrator = null;
    }
    final base = _ref.read(apiBaseUrlProvider);
    return NarrationTarget(
      key: key,
      audio: playable.audio,
      file: playable.file?.path,
      paragraphs: paras,
      bookTitle: book,
      chapterNumber: number,
      chapterTitle: title,
      narratorName: narrator,
      coverUrl: coverUrlAtWidth(sourceSeriesCoverUrl(base, key.sourceId, key.seriesKey), 512),
    );
  }

  /// Reads [key] aloud from [startMs]; false when it has no audio.
  Future<bool> startChapter(NovelChapterKey key, {int startMs = 0, bool play = true, List<String>? paragraphs, String? bookTitle, double? chapterNumber, String? chapterTitle}) async {
    final t = await buildTarget(key, paragraphs: paragraphs, bookTitle: bookTitle, chapterNumber: chapterNumber, chapterTitle: chapterTitle);
    if (t == null) return false;
    await _n.start(t, startMs: startMs, play: play);
    return true;
  }

  Future<void> toggle() => _n.toggle();

  /// The neighbouring chapter of the one narrating, when it has audio (`next` true: the following one).
  Future<NovelChapterKey?> neighbour({required bool next}) async {
    final key = state.key;
    if (key == null) return null;
    NovelChapterNeighbours n;
    try {
      n = await _ref.read(novelChapterNeighboursProvider(key).future);
    } catch (_) {
      return null;
    }
    final k = next ? n.nextChapterKey : n.previousChapterKey;
    return k == null ? null : (sourceId: key.sourceId, seriesKey: key.seriesKey, chapterKey: k);
  }

  /// The reader's novel controller, when mounted, moves the page; the host moves the voice.
  Future<void> changeChapter({required bool next}) async {
    final target = await neighbour(next: next);
    if (target == null) return;
    await startChapter(target);
  }

  /// A downward drag past 40 px or the menu's "Hide": stops with the toast "Stopped reading aloud" and an Undo that resumes at the same
  /// position (10 s draining rim, glass 7.12).
  Future<void> stopWithUndo() async {
    final t = state.target;
    if (t == null) return;
    final at = _n.position.value;
    await _n.stop();
    _toast(GlassToastSpec('Stopped reading aloud', undo: () => unawaited(_n.start(t, startMs: at))));
  }

  /// Pauses first, then hides with an Undo that resumes (`Semantics(onDismiss:)`).
  Future<void> pauseWithUndo(VoidCallback hide) async {
    final was = state.isPlaying;
    if (was) await _n.pause();
    hide();
    if (was) _toast(GlassToastSpec('Paused', undo: () => unawaited(_n.play())));
  }

  /// Opens `?sheet=player` over the current location, growing from [from].
  void openPlayer([Rect? from]) {
    glassPlayerOrigin = from;
    openSheet('player');
  }

  /// Adds `?sheet=[id]` (and [extra] companions such as `character` and `gender`) to the current location.
  void openSheet(String id, {Map<String, String> extra = const {}}) {
    final router = _ref.read(skinRouterProvider);
    final uri = router.routerDelegate.currentConfiguration.uri;
    router.go(uri.replace(queryParameters: {...uri.queryParameters, ...extra, 'sheet': id}).toString());
  }

  /// The notification was tapped: the playing chapter's reader, unless it is already the top route (A6).
  void openPlayingChapter() {
    final key = state.key;
    if (key == null) return;
    final router = _ref.read(skinRouterProvider);
    final path = router.routerDelegate.currentConfiguration.uri.path;
    final target = Routes.novel(key.sourceId, key.seriesKey, key.chapterKey);
    if (path == Uri.parse(target).path) return;
    router.push(Routes.novel(key.sourceId, key.seriesKey, key.chapterKey, const {'listen': '1'}));
  }
}

final glassNarrationActionsProvider = Provider<GlassNarrationActions>(GlassNarrationActions.new, name: 'glassNarrationActions');

/// C5: the reader's bridge, with the narrator and cover the lock screen needs.
class GlassNarrationHost extends NarrationListenBridge {
  GlassNarrationHost(this._r, this._c) : super(_r, _c);
  final Ref _r;
  final GlassListenContext _c;

  @override
  Future<void> playFrom(int para) async {
    final actions = _r.read(glassNarrationActionsProvider);
    final playable = await _r.read(playableNovelAudioProvider(_c.key).future);
    if (playable == null) return;
    final seg = playable.audio.segments.where((s) => s.paragraph >= para).firstOrNull;
    await actions.startChapter(_c.key, startMs: seg?.startMs ?? 0, paragraphs: _c.paragraphs, bookTitle: _c.bookTitle, chapterNumber: _c.chapterNumber, chapterTitle: _c.chapterTitle);
  }
}

/// Installs [GlassNarrationHost] as the reader's bridge (replaces `mobile/36`'s default).
GlassListenBridge glassNarrationHostFactory(Ref ref, GlassListenContext ctx) => GlassNarrationHost(ref, ctx);

/// The shell's listen layer, placed once inside the Glass root: publishes "Now narrating" to the accessory slot, owns the lock-screen
/// callbacks (previous and next chapter, haptic and toast feedback) and the notification tap (A6).
class GlassListenLayer extends ConsumerStatefulWidget {
  const GlassListenLayer({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<GlassListenLayer> createState() => _GlassListenLayerState();
}

class _GlassListenLayerState extends ConsumerState<GlassListenLayer> {
  StreamSubscription<bool>? _click;
  Timer? _throttle;
  late final NarrationController _narr = ref.read(narrationControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    _narr.onSkipNext = () {
      unawaited(ref.read(glassNarrationActionsProvider).changeChapter(next: true));
    };
    _narr.onSkipPrevious = () {
      unawaited(ref.read(glassNarrationActionsProvider).changeChapter(next: false));
    };
    _narr.onFeedback = _feedback;
    _narr.position.addListener(_tick);
    try {
      _click = AudioService.notificationClicked.where((c) => c).listen((_) => ref.read(glassNarrationActionsProvider).openPlayingChapter());
    } catch (_) {
      _click = null;
    }
    ref.listenManual(narrationControllerProvider, (_, __) => _publishSoon());
    _publishSoon();
  }

  void _feedback(NarrationFeedback f) {
    if (!mounted) return;
    switch (f) {
      case NarrationFeedback.sleepFade:
        glassFire(ref, HapticEvent.sleepFade);
      case NarrationFeedback.shakeExtended:
        glassFire(ref, HapticEvent.select);
        ref.read(glassToastProvider.notifier).show(const GlassToastSpec('Sleep timer +5 min'));
    }
  }

  void _tick() {
    _throttle ??= Timer(const Duration(milliseconds: 500), () {
      _throttle = null;
      if (mounted) _publish();
    });
  }

  /// Provider writes never happen inside a build: the layer mounts during one.
  void _publishSoon() => Future<void>.microtask(() {
        if (mounted) _publish();
      });

  void _publish() {
    final s = ref.read(narrationControllerProvider);
    final t = s.target;
    final acc = ref.read(glassAccessoryProvider.notifier);
    if (t == null || !s.active) {
      acc.setNarration(null);
      return;
    }
    final voice = ref.read(glassNarratorProvider(t.key));
    final actions = ref.read(glassNarrationActionsProvider);
    final total = t.audio.totalMs;
    acc.setNarration(
      GlassNarrationAccessory(
        title: glassNarratingLine(t, voice.name),
        playing: s.isPlaying,
        progress: total <= 0 ? 0 : (_narr.position.value / total).clamp(0.0, 1.0),
        onPlayPause: () => unawaited(actions.toggle()),
        openPlayer: actions.openPlayer,
        onNextChapter: () => unawaited(actions.changeChapter(next: true)),
        onPreviousChapter: () => unawaited(actions.changeChapter(next: false)),
        voiceSeed: voice.name,
        voiceHue: voice.hue,
        voiceInitial: voice.initial,
        onStop: () => unawaited(actions.stopWithUndo()),
        phase: switch (listenPhaseOf(s)) {
          ListenPhase.preparing || ListenPhase.buffering => 1,
          ListenPhase.failed => 2,
          _ => 0,
        },
      ),
    );
  }

  @override
  void dispose() {
    _throttle?.cancel();
    _narr.position.removeListener(_tick);
    unawaited(_click?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GlassPostPlayWatcher(child: widget.child);
}
