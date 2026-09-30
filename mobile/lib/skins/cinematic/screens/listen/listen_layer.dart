import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/novels/models/novel_cast.dart';
import 'package:manhwamaniacs/features/novels/providers/listen_settings_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_cast_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_chapter_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/listen/audiobook_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/listen/cast_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/listen/listen_common.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/listen/mini_player.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/listen/post_play_card.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/listen/reading_room.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/listen/sleep_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/listen/speed_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// Everything Listen draws over the novel reader (cinematic 8.16): the mini player above the
/// bottom bar, the reading room, `Back to the voice` on the page and the post-play card. The
/// reader owns the narration itself, the page decorations and the follow-along scroll; this layer
/// owns the overlays and the sheets they open.
///
/// The mini player rides with the chrome and lingers 5000 ms after the chrome hides unless
/// pinned (`Keep player visible`); the linger waits while focus is inside the player and never
/// runs out while a screen reader runs.
class ListenLayer extends ConsumerStatefulWidget {
  const ListenLayer({
    super.key,
    required this.ui,
    required this.chapter,
    required this.stock,
    required this.chromeVisible,
    required this.barBottom,
    required this.safeBottom,
    required this.seriesTitle,
    required this.chapterLabel,
    required this.chapterTitle,
    required this.duo,
    required this.hasNext,
    required this.hasPrevious,
    required this.onNext,
    required this.onPrevious,
    required this.onAdvance,
    required this.followDecoupled,
    required this.onBackToVoice,
    this.chapterNumber,
    this.nextLabel,
    this.coverUrl,
    this.lingerFor = const Duration(milliseconds: 5000),
  });

  final ListenUi ui;
  final NovelChapterKey chapter;
  final CineStockColors stock;

  /// The chrome (top and bottom bars) is showing.
  final bool chromeVisible;

  /// Where the mini player sits: above the bottom bar with the chrome, on the safe edge without.
  final double barBottom, safeBottom;
  final String seriesTitle, chapterLabel, chapterTitle;
  final double? chapterNumber;
  final String? coverUrl, nextLabel;
  final Color duo;
  final bool hasNext, hasPrevious;
  final VoidCallback onNext, onPrevious;

  /// The post-play card finished (or `Play now`): swap to the next chapter and keep listening.
  final VoidCallback onAdvance;

  /// The page stopped following the voice: show `Back to the voice`.
  final ValueListenable<bool> followDecoupled;
  final VoidCallback onBackToVoice;
  final Duration lingerFor;

  @override
  ConsumerState<ListenLayer> createState() => _ListenLayerState();
}

class _ListenLayerState extends ConsumerState<ListenLayer> {
  final FocusScopeNode _miniScope = FocusScopeNode(debugLabel: 'mini-player');
  final FocusNode _playFocus = FocusNode(debugLabel: 'mini-play');
  BuildContext? _miniContext;
  StreamSubscription<NarrationEnded>? _endedSub;
  Timer? _linger;
  bool _lingering = false;
  bool _card = false;
  Rect? _source;
  late final NarrationController _n =
      ref.read(narrationControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    widget.ui
      ..collapse = _collapse
      ..addListener(_uiChanged);
    _endedSub = _n.ended.listen(_onEnded);
    ref.listenManual<NarrationState>(narrationControllerProvider, (prev, next) {
      // A new chapter's session or a manual play hides a card left from the last one.
      if (_card && (next.revision != prev?.revision || next.isPlaying)) {
        setState(() => _card = false);
      }
      // A session that just began shows the player for the linger, chrome or not.
      if (next.revision != prev?.revision &&
          next.target != null &&
          !widget.chromeVisible) {
        _startLinger();
      }
    });
  }

  @override
  void didUpdateWidget(ListenLayer old) {
    super.didUpdateWidget(old);
    if (old.chromeVisible && !widget.chromeVisible) _startLinger();
    if (!old.chromeVisible && widget.chromeVisible) {
      _linger?.cancel();
      _lingering = false;
    }
    if (old.ui != widget.ui) {
      old.ui
        ..collapse = null
        ..removeListener(_uiChanged);
      widget.ui
        ..collapse = _collapse
        ..addListener(_uiChanged);
    }
  }

  @override
  void dispose() {
    widget.ui
      ..collapse = null
      ..removeListener(_uiChanged);
    unawaited(_endedSub?.cancel());
    _linger?.cancel();
    _miniScope.dispose();
    _playFocus.dispose();
    super.dispose();
  }

  void _uiChanged() {
    if (mounted) setState(() {});
  }

  void _startLinger() {
    _linger?.cancel();
    _lingering = true;
    _linger = Timer(widget.lingerFor, _lingerDone);
    if (mounted) setState(() {});
  }

  void _lingerDone() {
    if (!mounted) return;
    // Waits while focus is inside the player, and never runs out for a screen reader.
    if (_miniScope.hasFocus || MediaQuery.accessibleNavigationOf(context)) {
      _linger = Timer(const Duration(seconds: 1), _lingerDone);
      return;
    }
    setState(() => _lingering = false);
  }

  void _onEnded(NarrationEnded e) {
    if (e.sleepStop || !widget.hasNext) return;
    if (mounted) setState(() => _card = true);
  }

  Rect? _miniRect() {
    final box = _miniContext?.findRenderObject();
    final mine = context.findRenderObject();
    if (box is! RenderBox || mine is! RenderBox || !box.hasSize) return null;
    return mine.globalToLocal(box.localToGlobal(Offset.zero)) & box.size;
  }

  void _openRoom() {
    _source = _miniRect();
    cineFeedback(context, HapticEvent.sheetDetent);
    widget.ui.setRoomOpen(true);
  }

  final GlobalKey<ReadingRoomState> _roomKey = GlobalKey();

  void _collapse() {
    final state = _roomKey.currentState;
    if (state == null) {
      widget.ui.setRoomOpen(false);
      return;
    }
    unawaited(state.collapse());
  }

  void _closed() {
    widget.ui.setRoomOpen(false);
    // Focus returns to the mini player.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _playFocus.requestFocus();
    });
  }

  Future<void> _togglePinned() async {
    final s = ref.read(listenSettingsValueProvider);
    await ref
        .read(listenSettingsProvider.notifier)
        .put({'keepPlayerVisible': !s.keepPlayerVisible});
    if (!mounted) return;
    // ignore: deprecated_member_use
    unawaited(SemanticsService.announce(
        !s.keepPlayerVisible
            ? 'Player kept visible'
            : 'Player hides with the chrome',
        Directionality.of(context),),);
  }

  void _sheetSpeed() => unawaited(showSpeedSheet(context, stock: widget.stock));
  void _sheetSleep() => unawaited(showSleepSheet(context, stock: widget.stock));
  void _sheetVoices() => unawaited(showCastSheet(context,
      chapter: widget.chapter, stock: widget.stock, onReNarrate: _reNarrate,),);

  void _reNarrate() {
    Navigator.of(context).maybePop();
    unawaited(
      showAudiobookSheet(
        context,
        sourceId: widget.chapter.sourceId,
        seriesKey: widget.chapter.seriesKey,
        seriesTitle: widget.seriesTitle,
        currentChapterKey: widget.chapter.chapterKey,
        initialQuickPick: 'revoice',
        stock: widget.stock,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(narrationControllerProvider);
    final settings = ref.watch(listenSettingsValueProvider);
    final mine = s.key == widget.chapter && s.target != null;
    if (!mine) return const SizedBox.shrink();
    final attr =
        ref.watch(novelAttributionProvider(widget.chapter)).valueOrNull ??
            NovelAttribution.none;
    final voices =
        ref.watch(novelVoicesProvider).valueOrNull ?? const <NovelVoice>[];
    final narrator = attr.narratorVoiceId == null
        ? null
        : voices
            .where((v) => v.voiceId == attr.narratorVoiceId)
            .firstOrNull
            ?.name;
    final pinned = settings.keepPlayerVisible;
    final showMini =
        !widget.ui.roomOpen && (widget.chromeVisible || pinned || _lingering);
    final miniBottom =
        widget.chromeVisible ? widget.barBottom : widget.safeBottom;
    widget.ui.cardShowing = _card && widget.hasNext;
    final card = _card && widget.hasNext
        ? PostPlayCard(
            nextLabel: widget.nextLabel ?? 'Next chapter',
            countdown: settings.autoPlayNext,
            onPlayNow: () {
              setState(() => _card = false);
              cineFeedback(context, HapticEvent.chapterNext,
                  sound: SoundEvent.chapterNext,);
              widget.onAdvance();
            },
            onCancel: () => setState(() => _card = false),
          )
        : null;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (showMini)
          Positioned(
            key: const ValueKey('listen-mini'),
            left: 0,
            right: 0,
            bottom: miniBottom,
            child: FocusScope(
              node: _miniScope,
              child: Builder(
                builder: (miniContext) {
                  _miniContext = miniContext;
                  return CineMiniPlayer(
                    stock: widget.stock,
                    chapterKey: widget.chapter,
                    chapterLabel: widget.chapterLabel,
                    chapterNumber: widget.chapterNumber,
                    chapterTitle: widget.chapterTitle,
                    seriesTitle: widget.seriesTitle,
                    narratorName: narrator,
                    pinned: pinned,
                    playFocus: _playFocus,
                    onOpen: _openRoom,
                    onTogglePinned: () => unawaited(_togglePinned()),
                    onNextChapter: () =>
                        widget.hasNext ? widget.onNext() : null,
                    onPreviousChapter: () =>
                        widget.hasPrevious ? widget.onPrevious() : null,
                    onSleep: _sheetSleep,
                    onVoices: _sheetVoices,
                  );
                },
              ),
            ),
          ),
        if (showMini && card != null)
          Positioned(
            key: const ValueKey('listen-card'),
            left: 16,
            right: 16,
            bottom: miniBottom + kMiniPlayerHeight + 8,
            child: ColoredBox(color: widget.stock.page, child: card),
          ),
        if (showMini)
          Positioned(
            key: const ValueKey('listen-back-to-voice'),
            left: 0,
            right: 0,
            bottom:
                miniBottom + kMiniPlayerHeight + (card == null ? 12 : 12 + 140),
            child: ValueListenableBuilder<bool>(
              valueListenable: widget.followDecoupled,
              builder: (context, off, _) => off && s.highlightSafe
                  ? Center(
                      child: ColoredBox(
                        color: widget.stock.page,
                        child: CineButton(
                            key: const Key('back-to-the-voice-page'),
                            label: 'Back to the voice ↓',
                            variant: CineButtonVariant.quiet,
                            size: CineButtonSize.sm,
                            onPressed: widget.onBackToVoice,),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        if (widget.ui.roomOpen)
          Positioned.fill(
            key: const ValueKey('listen-room'),
            child: ReadingRoom(
              key: _roomKey,
              chapter: widget.chapter,
              seriesTitle: widget.seriesTitle,
              chapterTitle: widget.chapterTitle,
              coverUrl: widget.coverUrl,
              duo: widget.duo,
              sourceRect: _source,
              footer: card,
              onCollapsed: _closed,
              onSpeed: _sheetSpeed,
              onVoices: _sheetVoices,
              onSleep: _sheetSleep,
              onPrevious: widget.hasPrevious ? widget.onPrevious : null,
              onNext: widget.hasNext ? widget.onNext : null,
            ),
          ),
      ],
    );
  }
}
