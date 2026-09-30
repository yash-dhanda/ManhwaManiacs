import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/error/not_available.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/ai/utils/ai_state.dart';
import 'package:manhwamaniacs/features/downloads/models/download_chapter_state.dart';
import 'package:manhwamaniacs/features/downloads/providers/series_download_status_provider.dart';
import 'package:manhwamaniacs/features/library/utils/cover_url.dart';
import 'package:manhwamaniacs/features/ocr/controllers/ocr_run_controller.dart';
import 'package:manhwamaniacs/features/ocr/providers/ocr_providers.dart';
import 'package:manhwamaniacs/features/recap/models/recap_models.dart';
import 'package:manhwamaniacs/features/recap/models/recap_origin.dart';
import 'package:manhwamaniacs/features/recap/providers/recap_providers.dart';
import 'package:manhwamaniacs/features/recap/recap_setting.dart';
import 'package:manhwamaniacs/features/recap/utils/recap_countdown.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/navigation.dart' show ReaderEntry;
import 'package:manhwamaniacs/skins/cinematic/parts/quick_look_builders.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_announce.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_not_available_notice.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_notice.dart' show CineNoticeAction;
import 'package:manhwamaniacs/skins/cinematic/primitives/set_heading.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/recap/continue_to.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_kit.dart' show DelayedShow, LeaderDial, TypedText;
import 'package:manhwamaniacs/skins/cinematic/screens/discover/dialogue/scan/dialogue_scan_block.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/recap/cast_list.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/recap/cover_band.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/recap/recap_actions.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/recap/recap_keys.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/recap/recap_slate.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/recap/recap_text.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// `/recap/:sourceId/:seriesKey?to=:chapterKey` (cinematic 9.1.5): the "Previously on" takeover,
/// a title card whose recap streams word by word.
class RecapScreen extends ConsumerStatefulWidget {
  const RecapScreen({super.key, required this.sourceId, required this.seriesKey, required this.to, required this.origin});

  final String sourceId, seriesKey, to;
  final RecapOrigin origin;

  @override
  ConsumerState<RecapScreen> createState() => _RecapScreenState();
}

class _RecapScreenState extends ConsumerState<RecapScreen> {
  final _scroll = ScrollController();
  final _heading = FocusNode(debugLabel: 'recap-heading');
  late final AppLifecycleListener _lifecycle;
  CountdownState _cd = const CountdownState();
  Timer? _tick;
  int _touches = 0;
  bool _screenReader = false, _exited = false, _announced = false, _announcedCountdown = false, _scanned = false;

  RecapKey get _key => RecapKey(widget.sourceId, widget.seriesKey, widget.to);
  String get _seriesId => '${widget.sourceId}:${widget.seriesKey}';

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onStateChange: (s) {
      if (s == AppLifecycleState.resumed) {
        _resume(PauseReason.hidden);
      } else {
        _pause(PauseReason.hidden);
      }
    },);
    _scroll.addListener(() {
      if (_scroll.hasClients && _scroll.position.userScrollDirection == ScrollDirection.forward && _cd.started && !_cd.finished) {
        setState(() => _cd = RecapCountdown.reset(_cd));
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _heading.requestFocus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenReader = MediaQuery.accessibleNavigationOf(context);
  }

  @override
  void dispose() {
    _tick?.cancel();
    _lifecycle.dispose();
    _scroll.dispose();
    _heading.dispose();
    super.dispose();
  }

  // --- countdown ---------------------------------------------------------------------------

  void _pause(PauseReason r) {
    if (!mounted || _cd.pausedBy.contains(r)) return;
    setState(() => _cd = RecapCountdown.pause(_cd, r));
  }

  void _resume(PauseReason r) {
    if (!mounted || !_cd.pausedBy.contains(r)) return;
    setState(() => _cd = RecapCountdown.resume(_cd, r));
  }

  void _maybeStartCountdown(RecapStreamState st) {
    if (_cd.started || st.phase != RecapPhase.done || _screenReader) return;
    if (!ref.read(recapAutoContinueProvider)) return;
    // A finger already down or a pointer over the text pauses it from the start.
    setState(() => _cd = RecapCountdown.start(_cd));
    _tick ??= Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      if (_cd.running) {
        setState(() => _cd = RecapCountdown.tick(_cd, 100));
        if (_cd.finished) {
          _tick?.cancel();
          _exit(); // recap.countdown.end: no haptic, no cue
        }
      }
    });
    if (!_announcedCountdown) {
      _announcedCountdown = true;
      final n = _chapterNumberLabel(ref.read(sourceSeriesDetailProvider((sourceId: widget.sourceId, seriesId: widget.seriesKey))).valueOrNull);
      cineAnnounce(context, 'Continuing to chapter ${n.isEmpty ? 'next' : n} in 12 seconds. Press Space to pause.');
    }
  }

  // --- leaving -----------------------------------------------------------------------------

  /// The recap's way into the reader (or back), by its origin.
  void _exit() {
    if (_exited || !mounted) return;
    _exited = true;
    _tick?.cancel();
    switch (widget.origin.entry) {
      case RecapEntry.reader:
        closeRecap(context);
      case RecapEntry.wipe:
      case RecapEntry.dip:
        final wipe = widget.origin.entry == RecapEntry.wipe;
        if (wipe) cineFeedback(context, HapticEvent.readerEnter, sound: SoundEvent.readerEnter);
        openReaderAt(context, ref, widget.sourceId, widget.seriesKey, widget.to, entry: wipe ? ReaderEntry.wipe : ReaderEntry.dip, replace: true);
    }
  }

  void _close() => closeRecap(context);

  void _skipSeries(String title) {
    final settings = ref.read(recapSettingProvider.notifier);
    unawaited(settings.skip(_seriesId));
    ref.read(cineToastsProvider.notifier).undo('Recaps are off for $title.', onUndo: () {
      unawaited(settings.allow(_seriesId));
      cineFeedback(context, HapticEvent.undo, sound: SoundEvent.undo);
    },);
  }

  KeyEventResult _onKey(RecapStreamState st, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) {
      _exit();
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.keyS) {
      _exit();
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.escape) {
      _close();
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.space) {
      if (st.phase == RecapPhase.loading || st.phase == RecapPhase.streaming || (st.phase == RecapPhase.done && !_cd.started)) {
        ref.read(recapStreamProvider(_key).notifier).completeNow();
      }
      if (_cd.started) setState(() => _cd = RecapCountdown.toggleSpace(_cd));
      return KeyEventResult.handled;
    }
    final modifiers = {
      LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.shiftRight, LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.controlRight,
      LogicalKeyboardKey.altLeft, LogicalKeyboardKey.altRight, LogicalKeyboardKey.metaLeft, LogicalKeyboardKey.metaRight,
    };
    if (!modifiers.contains(k)) _pause(PauseReason.key);
    return KeyEventResult.ignored;
  }

  // --- helpers -----------------------------------------------------------------------------

  String _chapterNumberLabel(SourceSeriesDetailData? d) {
    final n = d?.chapters.where((c) => c.id == widget.to).firstOrNull?.number;
    if (n == null) return '';
    return n == n.roundToDouble() ? n.toInt().toString() : n.toString();
  }

  String _deck(RecapRange? r) {
    final label = r?.label;
    if (label == null) return '';
    return r!.single ? 'Chapter $label, as a recap.' : 'Chapters $label, as a recap.';
  }

  String _footnote(RecapStreamState st, RecapRange? range) {
    final label = range?.label;
    final what = st.meta?.sourcedFrom == 'text' ? 'text' : 'dialogue';
    final b = StringBuffer(label == null ? '' : 'Recap written from the $what of chapter${range!.single ? '' : 's'} $label.');
    b.write('${b.isEmpty ? '' : ' '}AI-written; it can be wrong.');
    final days = staleDays(st.generatedAt ?? st.meta?.generatedAt, ref.read(clockProvider)().toUtc());
    if (days != null) b.write(' Recap written $days day${days == 1 ? '' : 's'} ago.');
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final st = ref.watch(recapStreamProvider(_key));
    ref.listen<RecapStreamState>(recapStreamProvider(_key), (prev, next) {
      if (next.phase == RecapPhase.done && prev?.phase != RecapPhase.done) {
        if (!_announced) {
          _announced = true;
          cineAnnounce(context, RecapText.plain(next.words));
        }
        _maybeStartCountdown(next);
      }
      if (next.phase == RecapPhase.none && next.reason == 'first_chapter') WidgetsBinding.instance.addPostFrameCallback((_) => _exit());
    });
    final detail = ref.watch(sourceSeriesDetailProvider((sourceId: widget.sourceId, seriesId: widget.seriesKey)));
    final data = detail.valueOrNull;
    final title = data?.series.title ?? widget.seriesKey;
    final wide = MediaQuery.sizeOf(context).width >= 600;
    final twoCol = MediaQuery.sizeOf(context).width >= 900;
    final chNo = _chapterNumberLabel(data);
    final chLabel = chNo.isEmpty ? '' : 'CH $chNo';
    final avail = ref.watch(recapAvailabilityProvider(_key)).valueOrNull;
    final range = st.meta?.range ?? RecapRange(fromNumber: avail?.fromNumber, toNumber: avail?.toNumber);

    final err = detail.error;
    final gone = err is AppError ? notAvailableKind(err) : null;
    if (gone != null) {
      return Scaffold(backgroundColor: c.colorPaper0, body: SafeArea(child: Padding(padding: EdgeInsets.all(c.space4), child: CineNotAvailableNotice(kind: gone))));
    }
    if (st.phase == RecapPhase.none && st.reason == 'not_found') {
      return Scaffold(backgroundColor: c.colorPaper0, body: SafeArea(child: Padding(padding: EdgeInsets.all(c.space4), child: const CineNotAvailableNotice(kind: NotAvailableKind.series))));
    }

    final actions = RecapActions(
      chapterLabel: chLabel,
      wide: wide,
      seconds: _cd.started ? _cd.seconds : null,
      fraction: _cd.remainingMs / kRecapCountdownMs,
      onContinue: _exit,
      onSkipSeries: () => _skipSeries(title),
      onClose: _close,
      onPointer: (on) => on ? _pause(PauseReason.pointerContinue) : _resume(PauseReason.pointerContinue),
    );

    final cover = sourceSeriesCoverUrl(ref.read(apiBaseUrlProvider), widget.sourceId, widget.seriesKey);
    final pad = wide ? c.space8 : c.space4;
    final showActions = st.phase != RecapPhase.none && st.phase != RecapPhase.error;

    Widget hover(Widget child, PauseReason pointer, PauseReason focus) => MouseRegion(
          onEnter: (_) => _pause(pointer),
          onExit: (_) => _resume(pointer),
          child: Focus(onFocusChange: (f) => f ? _pause(focus) : _resume(focus), skipTraversal: false, child: child),
        );

    Widget body() {
      switch (st.phase) {
        case RecapPhase.none:
          return _slate(st, title, chLabel, range);
        case RecapPhase.error:
          return RecapSlate(
            kicker: 'CORRECTION',
            error: true,
            headline: "The recap couldn't be written.",
            primary: CineNoticeAction('Try again', () => unawaited(ref.read(recapStreamProvider(_key).notifier).retry())),
            quiet: CineNoticeAction('Continue', _exit),
          );
        case RecapPhase.loading:
          return Padding(
            padding: EdgeInsets.only(top: c.space4),
            child: Row(children: [
              Expanded(child: TypedText('Writing the recap…', style: CineText.style(context, c.typePull).copyWith(color: c.colorInk100))),
              SizedBox(width: c.space3),
              const DelayedShow(child: LeaderDial(size: 24)),
            ],),
          );
        case RecapPhase.streaming:
        case RecapPhase.done:
          final text = hover(
            RecapText(words: st.words, cast: [for (final m in st.meta?.cast ?? const <RecapCast>[]) m.name], complete: st.phase == RecapPhase.done, wide: wide),
            PauseReason.pointerText,
            PauseReason.focusText,
          );
          final cast = st.meta == null || st.meta!.cast.isEmpty
              ? null
              : hover(RecapCastList(cast: st.meta!.cast), PauseReason.pointerCast, PauseReason.focusCast);
          final foot = Padding(
            padding: EdgeInsets.only(top: c.space4),
            child: CineRoleText(_footnote(st, range), c.typeCaption, color: c.colorInk60),
          );
          final main = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: text), if (st.phase == RecapPhase.done) foot]);
          if (twoCol && cast != null) {
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 6, child: main),
              SizedBox(width: c.space6),
              Expanded(flex: 2, child: cast),
            ],);
          }
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [main, if (cast != null) ...[SizedBox(height: c.space6), cast]]);
      }
    }

    final scroll = CustomScrollView(controller: _scroll, slivers: [
      SliverToBoxAdapter(child: RecapCoverBand(url: cover, duo: data?.series.ambient?.duo, title: title)),
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(pad, c.space4, pad, c.space6),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (st.phase != RecapPhase.none && st.phase != RecapPhase.error)
              SetHeading('PREVIOUSLY ON', id: 'recap-kicker', style: CineText.style(context, c.typeKicker).copyWith(color: c.colorInk60), cap: c.typeKicker.cap, level: null, trigger: SetTrigger.signal),
            SizedBox(height: c.space2),
            SetHeading(
              title,
              id: 'recap-$_seriesId',
              style: CineText.style(context, c.typeHeadline).copyWith(color: c.colorInk100),
              cap: c.typeHeadline.cap,
              level: 1,
              trigger: SetTrigger.signal,
              focusNode: _heading,
            ),
            if (_deck(range).isNotEmpty) ...[SizedBox(height: c.space2), CineRoleText(_deck(range), c.typeDeck, color: c.colorInk60)],
            SizedBox(height: c.space5),
            body(),
            if (showActions && wide) ...[SizedBox(height: c.space6), actions],
            if (showActions && !wide) SizedBox(height: c.space6),
          ],),
        ),
      ),
    ],);

    final top = MediaQuery.viewPaddingOf(context).top + 8;
    return RecapKeys(
      onKey: (e) => _onKey(st, e),
      child: Listener(
        onPointerDown: (e) {
          if (e.kind == PointerDeviceKind.touch && ++_touches == 1) _pause(PauseReason.touch);
        },
        onPointerUp: (e) {
          if (e.kind == PointerDeviceKind.touch && _touches > 0 && --_touches == 0) _resume(PauseReason.touch);
        },
        onPointerCancel: (e) {
          if (e.kind == PointerDeviceKind.touch && _touches > 0 && --_touches == 0) _resume(PauseReason.touch);
        },
        child: Scaffold(
          backgroundColor: c.colorPaper0,
          body: Column(children: [
            Expanded(
              child: Stack(children: [
                Positioned.fill(child: scroll),
                Positioned(
                  top: top,
                  right: 16,
                  child: CineButton(
                    key: const Key('recap-skip'),
                    label: 'Skip recap →',
                    variant: CineButtonVariant.onArt,
                    size: CineButtonSize.sm,
                    onPressed: _exit,
                  ),
                ),
              ],),
            ),
            if (showActions && !wide)
              DecoratedBox(
                decoration: BoxDecoration(color: c.colorPaper0, border: Border(top: BorderSide(color: c.colorRule1))),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(c.space4, c.space3, c.space4, c.space3 + MediaQuery.viewPaddingOf(context).bottom),
                  child: actions,
                ),
              ),
          ],),
        ),
      ),
    );
  }

  /// The static slates of D11: no dialogue, unavailable, rate limited, offline.
  Widget _slate(RecapStreamState st, String title, String chLabel, RecapRange range) {
    final reason = st.reason ?? 'unknown';
    final cont = CineNoticeAction(chLabel.isEmpty ? 'Continue' : 'Continue  │  $chLabel', _exit);
    final quiet = CineNoticeAction('Close', _close);
    final pickUp = 'Pick up where you left off${chLabel.isEmpty ? '.' : ': chapter ${chLabel.substring(3)}.'}';
    switch (reason) {
      case 'no_dialogue':
        final extra = _scanExtra(range);
        return RecapSlate(
          kicker: 'NO RECAP FOR THIS ONE',
          headline: "The dialogue in these chapters hasn't been read yet, so there's nothing to recap.",
          primary: cont,
          quiet: quiet,
          extra: extra,
        );
      case 'rate_limited':
        return RecapSlate(
          kicker: 'RECAP UNAVAILABLE',
          headline: pickUp,
          retryAfter: Duration(seconds: st.retryAfter ?? 12),
          primary: cont,
          quiet: quiet,
        );
      case 'offline':
        return RecapSlate( kicker: 'OFFLINE EDITION', headline: pickUp, primary: cont, quiet: quiet);
      default:
        return RecapSlate( kicker: 'RECAP UNAVAILABLE', headline: pickUp, primary: cont, quiet: quiet);
    }
  }

  /// `Scan saved chapters` for the saved manga chapters of the range, when on-device OCR runs, then
  /// the scan block inline and, once it is done, `Try the recap again`.
  List<Widget> _scanExtra(RecapRange range) {
    if (!ref.watch(ocrFeatureVisibleProvider)) return const [];
    final detail = ref.watch(sourceSeriesDetailProvider((sourceId: widget.sourceId, seriesId: widget.seriesKey))).valueOrNull;
    final status = ref.watch(seriesChapterDownloadStatusProvider((sourceId: widget.sourceId, seriesKey: widget.seriesKey))).valueOrNull ?? const {};
    if (detail == null) return const [];
    final lo = range.fromNumber, hi = range.toNumber;
    final saved = [
      for (final ch in detail.chapters)
        if (status[ch.id]?.state == DownloadChapterState.complete && (hi == null || ch.number == null || (ch.number! <= hi && ch.number! >= (lo ?? 0)))) ch,
    ];
    if (saved.isEmpty) return const [];
    final run = ref.watch(ocrRunControllerProvider);
    final done = _scanned && !run.isBusy;
    return [
      if (!done)
        CineButton(
          key: const Key('recap-scan'),
          label: 'Scan saved chapters',
          variant: CineButtonVariant.secondary,
          loading: run.isBusy,
          onPressed: run.isBusy
              ? null
              : () {
                  setState(() => _scanned = true);
                  unawaited(() async {
                    for (final ch in saved) {
                      await ref.read(ocrRunControllerProvider.notifier).runChapter(
                        id: (sourceId: widget.sourceId, seriesKey: widget.seriesKey, chapterKey: ch.id),
                        chapterNumber: ch.number,
                      );
                    }
                  }());
                },
        ),
      const DialogueScanBlock(),
      if (done)
        CineButton(
          key: const Key('recap-retry'),
          label: 'Try the recap again',
          variant: CineButtonVariant.secondary,
          onPressed: () {
            ref.invalidate(recapAvailabilityProvider(_key));
            unawaited(ref.read(recapStreamProvider(_key).notifier).retry());
          },
        ),
    ];
  }
}
