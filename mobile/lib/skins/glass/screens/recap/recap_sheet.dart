import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/network/network_connectivity.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_status_provider.dart';
import 'package:manhwamaniacs/features/ocr/controllers/ocr_run_controller.dart';
import 'package:manhwamaniacs/features/ocr/providers/ocr_providers.dart';
import 'package:manhwamaniacs/features/recap/background_recaps.dart';
import 'package:manhwamaniacs/features/recap/models/recap_models.dart';
import 'package:manhwamaniacs/features/recap/providers/recap_providers.dart';
import 'package:manhwamaniacs/features/recap/recap_cache.dart';
import 'package:manhwamaniacs/features/recap/recap_deck.dart';
import 'package:manhwamaniacs/features/recap/sse.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/features/sources/utils/series_content_kind.dart';
import 'package:manhwamaniacs/skins/back_parent.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/ai/machine_badge.dart';
import 'package:manhwamaniacs/skins/glass/primitives/ai/thinking_orbit.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/typed_headline.dart';
import 'package:manhwamaniacs/skins/glass/screens/recap/compact_recap.dart';
import 'package:manhwamaniacs/skins/glass/screens/recap/recap_deck.dart';
import 'package:manhwamaniacs/skins/glass/screens/recap/recap_footer.dart';
import 'package:manhwamaniacs/skins/glass/screens/recap/recap_states.dart';
import 'package:manhwamaniacs/skins/glass/transitions/dive.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';
import 'package:manhwamaniacs/skins/skins.dart';

enum RecapPhaseG { opening, writing, ready, problem }

/// The recap deck sheet's content (glass 9.1.3; route `recap`): header, the deck (or the compact card), the spoiler-guard footer and the
/// pinned actions. `GET /ai/recap?shape=deck&scope=` streams through `deckReducer`; a cached deck opens at once; closing the sheet
/// while it writes hands the stream to `backgroundRecapsProvider.keepAlive` (60 s from the request).
class RecapSheet extends ConsumerStatefulWidget {
  const RecapSheet(
      {super.key,
      required this.sourceId,
      required this.seriesKey,
      this.to,
      this.scope = 'series',});
  final String sourceId, seriesKey;
  final String? to;
  final String scope;

  @override
  ConsumerState<RecapSheet> createState() => _RecapSheetState();
}

class _RecapSheetState extends ConsumerState<RecapSheet> {
  final GlobalKey<RecapDeckViewState> _deckKey = GlobalKey();
  DeckState _deck = const DeckState();
  RecapPhaseG _phase = RecapPhaseG.opening;
  RecapProblem _problem = RecapProblem.error;
  String? _reason;
  DateTime? _savedAt;
  CancelToken? _cancel;
  // Closed when the source stream ends; handed to keepAlive on dispose.
  // ignore: close_sinks
  StreamController<SseEvent>? _bridge;
  StreamSubscription<SseEvent>? _sub;
  DateTime? _startedAt;
  bool _ocrTried = false;
  bool _offline = false;
  String? _title;

  String get _to => widget.to ?? '';
  bool get _compact => widget.scope == 'chapter';
  RecapKey get _key => RecapKey(widget.sourceId, widget.seriesKey, _to);
  String get _cacheKey =>
      recapCacheKey(widget.sourceId, widget.seriesKey, _to, widget.scope);
  late final BackgroundRecaps _bg;
  late final RecapCache _cache;

  @override
  void initState() {
    super.initState();
    _bg = ref.read(backgroundRecapsProvider);
    _cache = ref.read(recapCacheProvider);
    HardwareKeyboard.instance.addHandler(_onKey);
    unawaited(_start());
  }

  @override
  void dispose() {
    final running = _phase == RecapPhaseG.writing &&
        _bridge != null &&
        !_deck.finished &&
        _cancel != null &&
        _startedAt != null;
    unawaited(_sub?.cancel());
    if (running) {
      _bg.keepAlive(
        _cacheKey,
        events: _bridge!.stream,
        cancel: _cancel!,
        title: _title ?? widget.seriesKey,
        sourceId: widget.sourceId,
        seriesKey: widget.seriesKey,
        to: _to,
        scope: widget.scope,
        mature: false,
        startedAt: _startedAt!,
        deckSoFar: _deck,
      );
    } else {
      _cancel?.cancel();
    }
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  Future<void> _start() async {
    final cached = await _cache.readCachedRecap(_cacheKey);
    if (!mounted) return;
    if (cached != null) {
      unawaited(_checkOffline());
      setState(() {
        _deck = cached.deck;
        _savedAt = cached.savedAt;
        _phase = RecapPhaseG.ready;
      });
      return;
    }
    await _open();
  }

  Future<void> _checkOffline() async {
    var online = true;
    try {
      online = await ref.read(networkConnectivityProvider).isOnline();
    } catch (_) {}
    if (mounted && !online) setState(() => _offline = true);
  }

  Future<void> _open() async {
    setState(() {
      _phase = RecapPhaseG.opening;
      _deck = const DeckState();
      _savedAt = null;
    });
    _cancel?.cancel();
    final token = _cancel = CancelToken();
    _startedAt = ref.read(clockProvider)();
    final RecapOpen open;
    try {
      open = await ref
          .read(recapRepositoryProvider)
          .openDeck(_key, scope: widget.scope, cancel: token);
    } on DioException {
      return;
    }
    if (!mounted) return;
    switch (open) {
      case RecapNone(:final reason):
        _problemFor(reason);
      case DeckStream(:final events):
        final bridge = _bridge = StreamController<SseEvent>.broadcast();
        unawaited(events
            .listen(bridge.add,
                onError: bridge.addError,
                onDone: () => unawaited(bridge.close()),
                cancelOnError: false,)
            .asFuture<void>()
            .catchError((Object _) {}),);
        setState(() => _phase = RecapPhaseG.writing);
        _sub = bridge.stream
            .listen(_onEvent, onError: (Object _) => _problemFor('error'));
      case RecapStream():
        _problemFor('error');
    }
  }

  void _problemFor(String reason) {
    if (reason == 'first_chapter') {
      _close();
      return;
    }
    setState(() {
      _phase = RecapPhaseG.problem;
      _reason = switch (reason) {
        'ai_not_configured' => 'not_configured',
        'ai_budget_exhausted' => 'budget_exhausted',
        _ => reason,
      };
      _problem = switch (reason) {
        'no_dialogue' || 'no_source_text' => RecapProblem.noSourceText,
        'not_enough_read' || 'too_short' => RecapProblem.notEnoughRead,
        'not_configured' ||
        'ai_not_configured' ||
        'budget_exhausted' ||
        'ai_budget_exhausted' ||
        'rate_limited' =>
          RecapProblem.aiUnavailable,
        'offline' => RecapProblem.offline,
        _ => RecapProblem.error,
      };
    });
  }

  void _onEvent(SseEvent e) {
    if (!mounted) return;
    final next = deckReducer(_deck, e);
    setState(() => _deck = next);
    if (next.error != null) {
      _problemFor(next.error!.code);
    } else if (next.done != null) {
      setState(() => _phase = RecapPhaseG.ready);
      unawaited(_cache.save(_cacheKey, next));
    }
  }

  /// Space, arrows, Enter, `s` and Esc while this sheet is the top route (glass 8.0.6, group "Recap").
  bool _onKey(KeyEvent e) {
    if (e is! KeyDownEvent ||
        !mounted ||
        !(ModalRoute.of(context)?.isCurrent ?? true)) {
      return false;
    }
    if (FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<EditableText>() !=
        null) {
      return false;
    }
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.keyS) {
      unawaited(_continue());
      return true;
    }
    if (k == LogicalKeyboardKey.escape) {
      _close();
      return true;
    }
    return !_compact && (_deckKey.currentState?.handleKey(k) ?? false);
  }

  void _close() {
    if (mounted) skinBack(context, glass: true);
  }

  Future<void> _continue([String? chapterKey]) async {
    final novel =
        isNovelSource(ref.read(contentModeScopeProvider), widget.sourceId) ??
            false;
    final at = chapterKey ?? _to;
    final loc = novel
        ? Routes.novel(widget.sourceId, widget.seriesKey, at)
        : Routes.reader(widget.sourceId, widget.seriesKey, at);
    final box = context.findRenderObject() as RenderBox?;
    final from = box != null && box.attached
        ? box.localToGlobal(Offset.zero) & box.size
        : const Rect.fromLTWH(0, 0, 1, 1);
    final nav = Navigator.of(context);
    final ctx = nav.context;
    // The full page (a cold deep link) is the only route: keep it beneath the reader.
    if (nav.canPop()) nav.pop();
    if (ctx.mounted) await enterReader(ctx, ref, loc, fromRect: from);
  }

  SourceChapterSummary? _chapter(SourceSeriesDetailData? d, String key) =>
      d?.chapters.where((c) => c.id == key).firstOrNull;

  String _n(num? v) => v == null
      ? ''
      : (v == v.roundToDouble() ? v.toInt().toString() : v.toString());

  String? _startFrom(SourceSeriesDetailData? d) {
    final done = _deck.done;
    if (d == null || done == null || done.from == null || done.to == null) {
      return null;
    }
    final inRange = [
      for (final c in d.chapters)
        if (c.number != null &&
            c.number! >= done.from! &&
            c.number! <= done.to!)
          c,
    ]..sort((a, b) => a.number!.compareTo(b.number!));
    if (inRange.length < 3) return null;
    return lastThirdStart([for (final c in inRange) c.id]);
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref
        .watch(sourceSeriesDetailProvider(
            (sourceId: widget.sourceId, seriesId: widget.seriesKey),),)
        .valueOrNull;
    final title = detail?.series.title ?? widget.seriesKey;
    _title = title;
    final now = ref.read(clockProvider)();
    final chNo = _n(_chapter(detail, _to)?.number);
    final wide = GlassFrame.of(context) != GlassFrameKind.phone;
    final startKey = _startFrom(detail);
    final startCh =
        startKey == null ? null : _n(_chapter(detail, startKey)?.number);

    Widget body;
    switch (_phase) {
      case RecapPhaseG.opening:
        body = const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: ThinkingOrbit(size: 64)),);
      case RecapPhaseG.problem:
        body = _problemBody(detail);
      case RecapPhaseG.writing:
      case RecapPhaseG.ready:
        body = _compact
            ? CompactRecap(deck: _deck)
            : RecapDeckView(key: _deckKey, deck: _deck);
    }

    final writing =
        _phase == RecapPhaseG.writing || _phase == RecapPhaseG.opening;
    return Semantics(
      explicitChildNodes: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const MachineBadge(streaming: true),
              const SizedBox(width: 6),
              GlassText('PREVIOUSLY ON',
                  role: gt.typeCaption1, color: gt.colorMachine, onGlass: wide,),
            ],),
            const SizedBox(height: 4),
            Semantics(
                container: true, // TypedHeadline carries the one header node (G2)
                child: TypedHeadline('Previously on $title',
                    role: gt.typeTitle2,
                    placement: 'recap.deck',
                    headingLevel: 1,),),
            if (writing && _phase == RecapPhaseG.writing)
              Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(children: [
                    const ThinkingOrbit(),
                    const SizedBox(width: 8),
                    GlassText('Writing your recap',
                        role: gt.typeFootnote, color: gt.colorLabel2,),
                  ],),),
            const SizedBox(height: 12),
            Flexible(child: SingleChildScrollView(child: body)),
            if (_deck.done != null)
              Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: RecapFooter(
                      done: _deck.done!,
                      savedAt: _savedAt,
                      now: now,
                      onGlass: wide,
                      offline: _offline,),),
            if (_phase != RecapPhaseG.problem) ...[
              const SizedBox(height: 12),
              GlassButton(
                  label: chNo.isEmpty ? 'Continue' : 'Continue · Ch $chNo',
                  variant: GlassButtonVariant.primary,
                  size: GlassButtonSize.large,
                  fullWidth: true,
                  onPressed: () => unawaited(_continue()),),
              if (!_compact &&
                  startKey != null &&
                  startCh != null &&
                  startCh.isNotEmpty)
                GlassButton(
                    label: 'Start from Ch $startCh instead',
                    size: GlassButtonSize.large,
                    fullWidth: true,
                    onPressed: () => unawaited(_continue(startKey)),),
            ],
          ],
        ),
      ),
    );
  }

  Widget _problemBody(SourceSeriesDetailData? detail) {
    final ocr = ref.watch(ocrRunControllerProvider);
    String? extractLine;
    VoidCallback? extract;
    if (_problem == RecapProblem.noSourceText &&
        ref.watch(ocrFeatureVisibleProvider) &&
        !(isNovelSource(ref.watch(contentModeScopeProvider), widget.sourceId) ??
            false)) {
      extractLine = extractLineOf(ocr);
      final status = ref
              .watch(seriesChapterDownloadStatusProvider(
                  (sourceId: widget.sourceId, seriesKey: widget.seriesKey),),)
              .valueOrNull ??
          const {};
      final saved = [
        if (detail != null)
          for (final c in detail.chapters)
            if (status[c.id]?.state == DownloadChapterState.complete) c,
      ];
      if (saved.isNotEmpty) {
        extract = () {
          setState(() => _ocrTried = true);
          unawaited(() async {
            for (final c in saved) {
              await ref.read(ocrRunControllerProvider.notifier).runChapter(id: (
                sourceId: widget.sourceId,
                seriesKey: widget.seriesKey,
                chapterKey: c.id
              ), chapterNumber: c.number,);
            }
            if (mounted) unawaited(_open());
          }());
        };
      }
    }
    if (_ocrTried && !ocr.isBusy && extractLine == null) extract = null;
    return RecapProblemView(
      problem: _problem,
      reason: _reason,
      onContinue: () => unawaited(_continue()),
      onTryAgain: () => unawaited(_open()),
      onHowItWorks: () => unawaited(ref
          .read(skinRouterProvider)
          .push<void>(Routes.tonight({'sheet': 'how-it-works'})),),
      onExtract: extract,
      extractLine: extractLine,
    );
  }
}
