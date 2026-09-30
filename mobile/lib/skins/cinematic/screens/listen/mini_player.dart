import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/novels/providers/saved_audio_provider.dart';
import 'package:manhwamaniacs/features/novels/utils/narration_timing.dart';
import 'package:manhwamaniacs/features/novels/utils/sleep_timer.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/cine_icon.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_icon_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_menu.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/listen/audio_save_state.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/listen/listen_common.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The mini player (cinematic 8.16.2): a 56 px bar above the novel's bottom bar in the stock
/// colours with a 1 px top rule (stock muted at 30 %).
///
/// A 36 px round play button (stock ink fill, the glyph in the page colour) with four states
/// (play, pause, preparing, failed), the kicker `CHAPTER 12 · READ BY IRIS` over a 2 px progress
/// rule (played part stock ink, buffered part at 35 %), the `-18:40` folio and an overflow. A tap
/// on the centre opens the full player; a sideways swipe (72 px or 600 px/s) changes chapter; a
/// 450 ms press toggles `Keep player visible`.
class CineMiniPlayer extends ConsumerStatefulWidget {
  const CineMiniPlayer({
    super.key,
    required this.stock,
    required this.chapterKey,
    required this.chapterLabel,
    required this.pinned,
    required this.onOpen,
    required this.onTogglePinned,
    required this.onNextChapter,
    required this.onPreviousChapter,
    required this.onSleep,
    required this.onVoices,
    this.narratorName,
    this.chapterNumber,
    this.chapterTitle,
    this.seriesTitle,
    this.playFocus,
    this.showVoices = true,
  });

  final CineStockColors stock;
  final NovelChapterRefAlias chapterKey;

  /// `CHAPTER 12`.
  final String chapterLabel;
  final String? narratorName, chapterTitle, seriesTitle;
  final double? chapterNumber;
  final bool pinned;
  final VoidCallback onOpen, onTogglePinned, onNextChapter, onPreviousChapter, onSleep, onVoices;
  final FocusNode? playFocus;
  final bool showVoices;

  @override
  ConsumerState<CineMiniPlayer> createState() => _CineMiniPlayerState();
}

typedef NovelChapterRefAlias = ({String sourceId, String seriesKey, String chapterKey});

class _CineMiniPlayerState extends ConsumerState<CineMiniPlayer> {
  final VelocityTracker _velocity = VelocityTracker.withKind(PointerDeviceKind.touch);
  Offset? _down;
  final GlobalKey _overflow = GlobalKey();

  NarrationController get _n => ref.read(narrationControllerProvider.notifier);

  void _onPlay(NarrationState s) {
    if (s.status == NarrationStatus.failed) {
      cineFeedback(context, HapticEvent.listenToggle);
      unawaited(_n.retry());
      return;
    }
    if (s.status == NarrationStatus.loading || s.status == NarrationStatus.preparing) return;
    cineFeedback(context, HapticEvent.listenToggle);
    unawaited(_n.toggle());
  }

  void _swipeEnd(PointerUpEvent e) {
    final start = _down;
    _down = null;
    if (start == null) return;
    final d = e.position - start;
    final v = _velocity.getVelocity().pixelsPerSecond.dx;
    if (d.dy.abs() > d.dx.abs()) return;
    if (d.dx.abs() >= 72 || v.abs() >= 600) {
      cineFeedback(context, HapticEvent.chapterNext, sound: SoundEvent.chapterNext);
      d.dx < 0 ? widget.onNextChapter() : widget.onPreviousChapter();
    }
  }

  Future<void> _more() async {
    final box = _overflow.currentContext?.findRenderObject() as RenderBox?;
    final anchor = box == null ? anchorRect(context) : box.localToGlobal(Offset.zero) & box.size;
    final key = widget.chapterKey;
    final saveState = ref.read(savedAudioStateProvider(key));
    final saveCaption = audioSaveCaption(saveState) ?? 'Save audio to this device';
    final tap = audioSaveTap(context, ref, key, saveState, chapterNumber: widget.chapterNumber, title: widget.chapterTitle, seriesTitle: widget.seriesTitle);
    final hasScope = ref.read(audioSaveAvailableProvider);
    final pick = await showCineMenu<String>(
      context,
      anchor: anchor,
      entries: [
        CineMenuEntry<String>(label: 'Keep player visible', value: 'pin', checked: widget.pinned),
        const CineMenuEntry<String>(label: 'Sleep timer…', value: 'sleep'),
        if (widget.showVoices) const CineMenuEntry<String>(label: 'Voices…', value: 'voices'),
        if (hasScope) CineMenuEntry<String>(label: saveCaption, value: 'save', disabled: tap == null),
      ],
    );
    if (!mounted) return;
    switch (pick) {
      case 'pin':
        widget.onTogglePinned();
      case 'sleep':
        widget.onSleep();
      case 'voices':
        widget.onVoices();
      case 'save':
        tap?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final s = ref.watch(narrationControllerProvider);
    final stock = widget.stock;
    final total = s.target?.audio.totalMs ?? 0;
    final kicker = dotted([widget.chapterLabel, widget.narratorName == null || widget.narratorName!.isEmpty ? null : 'READ BY ${widget.narratorName!.toUpperCase()}']);
    final loading = s.status == NarrationStatus.loading || s.status == NarrationStatus.preparing;
    final failed = s.status == NarrationStatus.failed;
    final playing = s.isPlaying;
    final n = ref.read(narrationControllerProvider.notifier);
    final rule = Border(top: BorderSide(color: stock.muted.withValues(alpha: 0.3)));

    return Semantics(
      container: true,
      label: 'Now reading aloud, ${widget.chapterLabel.toLowerCase()}${widget.narratorName == null ? '' : ', read by ${widget.narratorName}'}',
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (e) {
          _velocity.addPosition(e.timeStamp, e.position);
          _down = e.position;
        },
        onPointerMove: (e) => _velocity.addPosition(e.timeStamp, e.position),
        onPointerUp: _swipeEnd,
        onPointerCancel: (_) => _down = null,
        child: Container(
          key: const Key('mini-player'),
          height: kMiniPlayerHeight,
          decoration: BoxDecoration(color: stock.page, border: rule),
          padding: EdgeInsets.symmetric(horizontal: c.space2),
          child: Row(
            children: [
              _PlayButton(stock: stock, playing: playing, loading: loading, failed: failed, focusNode: widget.playFocus, onTap: () => _onPlay(s)),
              SizedBox(width: c.space2),
              Expanded(
                child: CinePressable(
                  hit: false,
                  expand: true,
                  onTap: widget.onOpen,
                  onLongPress: () {
                    cineFeedback(context, HapticEvent.longpressOpen);
                    widget.onTogglePinned();
                  },
                  builder: (context, st) => Semantics(
                    button: true,
                    label: 'Open the reading room',
                    excludeSemantics: true,
                    onTap: widget.onOpen,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CineRoleText(kicker, c.typeKicker, color: stock.muted, maxLines: 1, overflow: TextOverflow.ellipsis),
                        SizedBox(height: c.space1),
                        ValueListenableBuilder<int>(
                          valueListenable: n.position,
                          builder: (context, ms, _) => ValueListenableBuilder<int>(
                            valueListenable: n.buffered,
                            builder: (context, buf, _) => _ProgressRule(stock: stock, played: total <= 0 ? 0 : ms / total, buffered: total <= 0 ? 0 : buf / total),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: c.space2),
              ValueListenableBuilder<int>(
                valueListenable: n.position,
                builder: (context, ms, _) {
                  final sleep = n.sleepState.value.countdown;
                  return Semantics(
                    label: sleep != null ? 'Sleep timer, $sleep left. ${remainingSpoken(total, ms)}' : remainingSpoken(total, ms),
                    excludeSemantics: true,
                    child: ValueListenableBuilder<SleepState>(
                      valueListenable: n.sleepState,
                      builder: (context, sl, _) => CineRoleText(sl.countdown ?? remainingFolio(total, ms), c.typeFolio, color: sl.armed ? c.colorSpot : stock.muted),
                    ),
                  );
                },
              ),
              CineIconButton(key: _overflow, label: 'More', role: CineIconRole.overflow, onPressed: () => unawaited(_more())),
            ],
          ),
        ),
      ),
    );
  }
}

/// Whether a downloads scope exists (the save row is built only then).
final audioSaveAvailableProvider = Provider<bool>((ref) => ref.watch(downloadsStoreProvider) != null, name: 'audioSaveAvailable');

class _ProgressRule extends StatelessWidget {
  const _ProgressRule({required this.stock, required this.played, required this.buffered});
  final CineStockColors stock;
  final double played, buffered;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 2,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: stock.muted.withValues(alpha: 0.2))),
            Positioned.fill(child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: buffered.clamp(0.0, 1.0), child: ColoredBox(key: const Key('mini-buffered'), color: stock.muted.withValues(alpha: 0.35)))),
            Positioned.fill(child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: played.clamp(0.0, 1.0), child: ColoredBox(key: const Key('mini-played'), color: stock.ink))),
          ],
        ),
      );
}

/// The 36 px round play button: stock ink fill, the glyph in the page colour; a 16 px leader dial
/// while preparing or loading; `!` in `proof` when it failed (a tap retries). Its touch target
/// grows to 44 / 48.
class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.stock, required this.playing, required this.loading, required this.failed, required this.onTap, this.focusNode});
  final CineStockColors stock;
  final bool playing, loading, failed;
  final VoidCallback onTap;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final label = failed ? 'Audio could not be loaded. Try again' : (loading ? 'Preparing the audio' : (playing ? 'Pause' : 'Play'));
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: CinePressable(
        round: true,
        focusNode: focusNode,
        onTap: loading ? null : onTap,
        builder: (context, st) => Container(
          key: const Key('mini-play'),
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: failed ? null : stock.ink, border: failed ? Border.all(color: c.colorProof) : null),
          child: failed
              ? CineRoleText('!', c.typeTitle, color: c.colorProof)
              : loading
                  ? CineLeaderDialOnInk(color: stock.page)
                  : CineIcon(playing ? CineIconRole.pause : CineIconRole.play, size: 20, weight: CineIconWeight.fill, color: stock.page),
        ),
      ),
    );
  }
}

/// A 16 px dial that draws in [color] (the leader dial's sweep is fixed to `ink`, so on the ink
/// fill of the play button a small ring in the page colour stands in).
class CineLeaderDialOnInk extends StatefulWidget {
  const CineLeaderDialOnInk({super.key, required this.color});
  final Color color;

  @override
  State<CineLeaderDialOnInk> createState() => _CineLeaderDialOnInkState();
}

class _CineLeaderDialOnInkState extends State<CineLeaderDialOnInk> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        value: 'Loading',
        child: ExcludeSemantics(
          child: SizedBox(
            width: 16,
            height: 16,
            child: AnimatedBuilder(animation: _c, builder: (_, __) => CustomPaint(painter: _RingPainter(widget.color, _c.value))),
          ),
        ),
      );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.color, this.t);
  final Color color;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(1, 1, size.width - 2, size.height - 2);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = color.withValues(alpha: 0.3);
    canvas.drawArc(r, 0, math.pi * 2, false, ring);
    canvas.drawArc(r, -math.pi / 2 + t * math.pi * 2, math.pi * 0.8, false, ring..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.t != t || o.color != color;
}
