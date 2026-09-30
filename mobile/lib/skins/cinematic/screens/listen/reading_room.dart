import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/novels/models/novel_cast.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_cast_provider.dart';
import 'package:manhwamaniacs/features/novels/utils/narration_timing.dart';
import 'package:manhwamaniacs/features/novels/utils/sleep_timer.dart';
import 'package:manhwamaniacs/skins/cinematic/cine_grain.dart';
import 'package:manhwamaniacs/skins/cinematic/duotone.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/listen/listen_tiles.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/listen/transcript.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/listen/transport.dart';
import 'package:manhwamaniacs/skins/cinematic/scrim_head.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// "The reading room" (cinematic 8.16.3): the full player, a takeover inside the novel reader
/// route (an overlay state of the reader, not a route), so Android back collapses it first.
///
/// Motion: the background field runs the match cut from the mini player's rect to the full screen
/// over 480 ms `CineCurves.turn` (the mini player has no separate cover square, so its whole bar
/// is the source rect) and the content Rises (24 px and fade, 360 ms `settle`); collapse reverses
/// over 336 ms. A swipe down collapses it, finger-tracked, released with the `sheet` spring
/// (dismiss past 30 % of the height or faster than 800 px/s). Reduced motion: 200 ms cross-fades
/// both ways; the drag still collapses and finishes with a 150 ms fade.
///
/// Background: the series cover duotoned, blurred 24 px, at 15 % over black, with the vignette
/// and the grain on the art only, static under reduced motion.
class ReadingRoom extends ConsumerStatefulWidget {
  const ReadingRoom({
    super.key,
    required this.chapter,
    required this.seriesTitle,
    required this.chapterTitle,
    required this.duo,
    required this.onCollapsed,
    required this.onSpeed,
    required this.onVoices,
    required this.onSleep,
    required this.onPrevious,
    required this.onNext,
    this.coverUrl,
    this.sourceRect,
    this.footer,
    this.playFocus,
  });

  final ({String sourceId, String seriesKey, String chapterKey}) chapter;
  final String seriesTitle, chapterTitle;
  final String? coverUrl;
  final Color duo;

  /// The mini player's rect in the reader's coordinates, the match cut's source.
  final Rect? sourceRect;
  final VoidCallback onCollapsed, onSpeed, onVoices, onSleep;
  final VoidCallback? onPrevious, onNext;

  /// The post-play card, at the end of the transcript.
  final Widget? footer;
  final FocusNode? playFocus;

  @override
  ConsumerState<ReadingRoom> createState() => ReadingRoomState();
}

class ReadingRoomState extends ConsumerState<ReadingRoom> with TickerProviderStateMixin {
  late final AnimationController _open = AnimationController(vsync: this, duration: const Duration(milliseconds: 480), reverseDuration: const Duration(milliseconds: 336));
  late final AnimationController _drag = AnimationController.unbounded(vsync: this);
  final FocusNode _done = FocusNode(debugLabel: 'reading-room-done');
  double _dy = 0;
  bool _closing = false;
  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _done.requestFocus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = CineMotion.reduced(context);
    if (!_open.isAnimating && _open.value == 0 && !_closing) {
      _reduced = reduced;
      _open.duration = reduced ? const Duration(milliseconds: 200) : const Duration(milliseconds: 480);
      _open.reverseDuration = reduced ? const Duration(milliseconds: 200) : const Duration(milliseconds: 336);
      unawaited(_open.forward());
    }
    _reduced = reduced;
  }

  @override
  void dispose() {
    _open.dispose();
    _drag.dispose();
    _done.dispose();
    super.dispose();
  }

  /// Collapse with the reverse match cut (or a cross-fade), then tell the reader.
  Future<void> collapse() async {
    if (_closing) return;
    _closing = true;
    await _open.reverse();
    if (mounted) widget.onCollapsed();
  }

  void _dragUpdate(DragUpdateDetails d) {
    if (_closing) return;
    setState(() => _dy = (_dy + d.delta.dy).clamp(0.0, double.infinity));
  }

  Future<void> _dragEnd(DragEndDetails d) async {
    if (_closing) return;
    final h = MediaQuery.sizeOf(context).height;
    final v = d.velocity.pixelsPerSecond.dy;
    if (_dy > h * 0.3 || v > 800) {
      _closing = true;
      if (_reduced) {
        _drag.value = 0;
        setState(() => _dy = 0);
        await _open.animateTo(0, duration: const Duration(milliseconds: 150));
      } else {
        final sim = SpringSimulation(CineSprings.sheet.description, _dy, h, v);
        _drag.value = _dy;
        _drag.addListener(() => setState(() => _dy = _drag.value));
        await _drag.animateWith(sim);
      }
      if (mounted) widget.onCollapsed();
    } else {
      final from = _dy;
      _drag.value = from;
      void tick() => setState(() => _dy = _drag.value);
      _drag.addListener(tick);
      await _drag.animateWith(SpringSimulation(CineSprings.sheet.description, from, 0, v));
      _drag.removeListener(tick);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final s = ref.watch(narrationControllerProvider);
    final n = ref.read(narrationControllerProvider.notifier);
    final size = MediaQuery.sizeOf(context);
    final tablet = size.shortestSide >= 600;
    final chapter = widget.chapter;
    final attr = ref.watch(novelAttributionProvider(chapter)).valueOrNull ?? NovelAttribution.none;
    final voices = ref.watch(novelVoicesProvider).valueOrNull ?? const <NovelVoice>[];
    final narrator = attr.narratorVoiceId == null ? null : voices.where((v) => v.voiceId == attr.narratorVoiceId).firstOrNull?.name;
    final others = attr.cast.length;
    final voicesValue = narrator == null ? (others == 0 ? 'AUTOMATIC' : '$others VOICES') : (others == 0 ? narrator.toUpperCase() : '${narrator.toUpperCase()} + $others');
    final words = s.target == null ? 0 : wordCountOf(s.target!.paragraphs);
    final total = s.target?.audio.totalMs ?? 0;
    final wpm = narrationWpm(words, total, s.speed);

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: 'Now reading aloud, ${widget.seriesTitle}',
      child: Focus(
        onKeyEvent: (node, e) {
          if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
            unawaited(collapse());
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: AnimatedBuilder(
          animation: _open,
          builder: (context, _) {
            final t = _reduced ? _open.value : CineCurves.turn.transform(_open.value);
            final full = Offset.zero & size;
            final from = widget.sourceRect ?? Rect.fromLTWH(0, size.height - 56, size.width, 56);
            final rect = _reduced ? full : Rect.lerp(from, full, t)!;
            final rise = _reduced ? 1.0 : CineCurves.settle.transform(((_open.value - 0.2) / 0.8).clamp(0.0, 1.0));
            final pull = (_dy / size.height).clamp(0.0, 1.0);
            return Stack(
              children: [
                Positioned.fromRect(
                  rect: rect.shift(Offset(0, _dy)),
                  child: Opacity(
                    opacity: _reduced ? _open.value : 1,
                    child: ClipRect(child: _Field(duo: widget.duo, coverUrl: widget.coverUrl, still: _reduced, active: _open.value > 0)),
                  ),
                ),
                Positioned.fill(
                  child: Transform.translate(
                    offset: Offset(0, _dy + 24 * (1 - rise)),
                    child: Opacity(
                      opacity: (rise * (1 - pull * 0.6)).clamp(0.0, 1.0),
                      child: SafeArea(
                        child: Column(
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onVerticalDragUpdate: _dragUpdate,
                              onVerticalDragEnd: _dragEnd,
                              child: _Head(seriesTitle: widget.seriesTitle, chapterTitle: widget.chapterTitle, doneFocus: _done, onDone: () => unawaited(collapse()), stale: s.target != null && !s.highlightSafe),
                            ),
                            Expanded(
                              child: NotificationListener<OverscrollNotification>(
                                onNotification: (o) {
                                  if (o.overscroll < 0 && o.dragDetails != null) {
                                    setState(() => _dy = (_dy - o.overscroll).clamp(0.0, double.infinity));
                                  }
                                  return false;
                                },
                                child: ListenTranscript(chapter: chapter, footer: widget.footer),
                              ),
                            ),
                            GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onVerticalDragUpdate: _dragUpdate,
                              onVerticalDragEnd: _dragEnd,
                              child: Stack(
                                children: [
                                  Positioned.fill(child: scrimSole(64, 24)),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: tablet ? size.width / 8 : c.space4, vertical: c.space2),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListenTransport(onPrevious: widget.onPrevious, onNext: widget.onNext, playFocus: widget.playFocus),
                                        SizedBox(height: c.space3),
                                        ValueListenableBuilder<SleepState>(
                                          valueListenable: n.sleepState,
                                          builder: (context, sl, _) => ListenTiles(
                                            speed: ListenTile(key: const Key('tile-speed'), kicker: 'SPEED', value: '${s.speed.toStringAsFixed(2)}×', caption: wpm == 0 ? null : '≈ $wpm WPM', onTap: widget.onSpeed),
                                            voices: ListenTile(key: const Key('tile-voices'), kicker: 'VOICES', value: voicesValue, onTap: widget.onVoices),
                                            sleep: ListenTile(key: const Key('tile-sleep'), kicker: 'SLEEP', value: sl.countdown ?? sl.choice.tileLabel, valueColor: sl.armed ? c.colorSpot : null, onTap: widget.onSleep),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The field behind the reading room: black with the series cover duotoned, blurred and at 15 %,
/// the vignette and the grain on the art only, paused off screen and static under reduced motion.
class _Field extends StatelessWidget {
  const _Field({required this.duo, required this.coverUrl, required this.still, required this.active});
  final Color duo;
  final String? coverUrl;
  final bool still, active;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return ColoredBox(
      color: const Color(0xFF000000),
      child: TickerMode(
        enabled: active && !still,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: 0.15,
              child: CineGrain(
                opacity: still ? 0 : 0.05,
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: c.blurCard, sigmaY: c.blurCard),
                  child: CineDuotone(duo: duo, child: CineImage(url: coverUrl)),
                ),
              ),
            ),
            IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(gradient: c.scrimVignette))),
          ],
        ),
      ),
    );
  }
}

class _Head extends StatelessWidget {
  const _Head({required this.seriesTitle, required this.chapterTitle, required this.doneFocus, required this.onDone, required this.stale});
  final String seriesTitle, chapterTitle;
  final FocusNode doneFocus;
  final VoidCallback onDone;
  final bool stale;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final tablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    return Padding(
      padding: EdgeInsets.fromLTRB(tablet ? MediaQuery.sizeOf(context).width / 8 : c.space4, c.space3, c.space2, c.space2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: CineRoleText('NOW READING ALOUD', c.typeKicker, color: c.colorInk60)),
              CineButton(label: 'Done', variant: CineButtonVariant.quiet, size: CineButtonSize.sm, focusNode: doneFocus, onPressed: onDone),
            ],
          ),
          SetHeading(
            seriesTitle,
            id: 'listen-series',
            style: CineText.style(context, c.typeHeadline),
            cap: c.typeHeadline.cap,
            level: 1,
            trigger: SetTrigger.mount,
          ),
          if (chapterTitle.isNotEmpty) CineRoleText(chapterTitle, c.typeDeck, color: c.colorInk60, maxLines: 2, overflow: TextOverflow.ellipsis),
          if (stale) Padding(padding: EdgeInsets.only(top: c.space1), child: CineRoleText('Highlight paused: the text changed.', c.typeCaption, color: c.colorInk60, key: const Key('highlight-paused'))),
        ],
      ),
    );
  }
}

