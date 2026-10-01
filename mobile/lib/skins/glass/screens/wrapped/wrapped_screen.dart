import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/physics.dart' show SpringSimulation;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' hide ShortcutRegistry;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';
import 'package:manhwamaniacs/features/library/models/annual.dart';
import 'package:manhwamaniacs/features/library/providers/numbers_providers.dart';
import 'package:manhwamaniacs/features/library/utils/wrapped_cards.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/glass_motion_recorder.dart' show GlassMotionEntry;
import 'package:manhwamaniacs/skins/glass/icons/phosphor.g.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/parts/share/share_side.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/progress.dart' show GlassSpinner;
import 'package:manhwamaniacs/skins/glass/screens/system/not_found.dart';
import 'package:manhwamaniacs/skins/glass/screens/wrapped/podium.dart' show landMs;
import 'package:manhwamaniacs/skins/glass/screens/wrapped/story_math.dart';
import 'package:manhwamaniacs/skins/glass/screens/wrapped/wrapped_card_face.dart';
import 'package:manhwamaniacs/skins/glass/screens/wrapped/wrapped_frame.dart';
import 'package:manhwamaniacs/skins/glass/screens/wrapped/wrapped_origin.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/wrapped/share_card.dart';
import 'package:manhwamaniacs/skins/glass/wrapped/wrapped_copy.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// Wrapped (`annual`, glass 9.2.3): a takeover story of up to twelve cards in one 360 x 640 frame. A non-numeric year is the not-found lens.
class GlassWrappedScreen extends ConsumerWidget {
  const GlassWrappedScreen({super.key, required this.yearParam});
  final String? yearParam;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = int.tryParse(yearParam ?? '');
    if (year == null) return GlassNotFound(location: '/library/statistics/annual/${yearParam ?? ''}');
    final async = ref.watch(annualProvider(year));
    return ColoredBox(
      color: const Color(0xFF000000),
      child: async.when(
        loading: () => _Message(year: year, busy: true, title: 'Putting your year together'),
        error: (e, _) => e is NetworkError || e is TimeoutError
            ? _Message(year: year, title: 'Wrapped needs a connection', action: 'Try again', onAction: () => ref.invalidate(annualProvider(year)))
            : _Message(year: year, title: "Couldn't put your year together", action: 'Try again', onAction: () => ref.invalidate(annualProvider(year))),
        data: (load) => notEnoughData(load.data)
            ? _Message(year: year, title: 'Not enough reading this year for a recap yet. Come back after a few chapters.', footnote: '${load.data.recordedDays} days recorded so far', action: 'Close', onAction: () => _close(ref))
            : _Story(annual: load.data, offline: load.offline),
      ),
    );
  }
}

void _close(WidgetRef ref) {
  final r = ref.read(skinRouterProvider);
  if (r.canPop()) {
    r.pop();
  } else {
    r.go(Routes.numbers());
  }
}

class _Message extends ConsumerWidget {
  const _Message({required this.year, required this.title, this.busy = false, this.footnote, this.action, this.onAction});
  final int year;
  final String title;
  final bool busy;
  final String? footnote;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              GlassLabel('$year', role: gt.typeDisplay, color: gt.colorLabel1),
              const SizedBox(height: 16),
              if (busy) const GlassSpinner(size: 64, label: 'Putting your year together'),
              if (busy) const SizedBox(height: 16),
              GlassLabel(title, role: gt.typeTitle3, color: gt.colorLabel1, maxLines: 4, textAlign: TextAlign.center),
              if (footnote != null) ...[const SizedBox(height: 8), GlassLabel(footnote!, role: gt.typeFootnote, color: gt.colorLabel2, textAlign: TextAlign.center)],
              if (action != null) ...[const SizedBox(height: 24), GlassButton(label: action!, onPressed: onAction)],
            ],),
          ),
        ),
      );
}

class _Story extends ConsumerStatefulWidget {
  const _Story({required this.annual, required this.offline});
  final Annual annual;
  final bool offline;

  @override
  ConsumerState<_Story> createState() => _StoryState();
}

class _StoryState extends ConsumerState<_Story> with TickerProviderStateMixin, WidgetsBindingObserver {
  late final List<WrappedCard> _cards = wrappedCards(widget.annual, profileShares: (widget.annual.circle ?? const []).isNotEmpty);
  int _index = 0;
  bool _paused = false;
  bool _pressed = false;
  bool _resumed = true;
  bool _keyboard = false;
  bool _closing = false;
  ShareSpec? _share;
  double _dx = 0; // the top card's drag offset
  double _dy = 0;
  double _settleFrom = 0;
  double _settleTo = 0;
  int _settleDir = 0;
  late final AnimationController _settle = AnimationController(vsync: this, animationBehavior: AnimationBehavior.preserve, duration: const Duration(milliseconds: 615));
  late final AnimationController _auto = AnimationController(vsync: this, animationBehavior: AnimationBehavior.preserve, duration: const Duration(milliseconds: 6000));
  late final AnimationController _flip = AnimationController(vsync: this, animationBehavior: AnimationBehavior.preserve, duration: const Duration(milliseconds: 436));
  late final AnimationController _closeC = AnimationController(vsync: this, animationBehavior: AnimationBehavior.preserve, duration: const Duration(milliseconds: 558));
  late final AnimationController _fade = AnimationController(vsync: this, animationBehavior: AnimationBehavior.preserve, duration: const Duration(milliseconds: 200), value: 1);
  final FocusNode _focus = FocusNode(debugLabel: 'wrapped');
  final Object _token = Object();
  late final ShortcutRegistry _shortcuts = ref.read(shortcutRegistryProvider.notifier);
  final GlobalKey<GlassShareSideState> _sideKey = GlobalKey();
  // A press becomes a hold at 450 ms (a timer, so the threshold follows the frame clock in tests too).
  Timer? _holdTimer;
  bool _held = false;
  Offset _downPos = Offset.zero;
  bool _dragged = false;
  GlassMotionEntry? _stackEntry;
  Rect? _originRect;

  bool get _reduced => ref.read(glassReducedProvider);
  WrappedCard get _card => _cards[_index];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // The story's keys come straight off the keyboard while it is the current route, whatever holds focus (the share side,
    // a button the pointer just pressed), so Esc and the arrows always reach it.
    HardwareKeyboard.instance.addHandler(_hwKey);
    _originRect = ref.read(wrappedOriginProvider);
    _auto.addStatusListener((s) {
      if (s == AnimationStatus.completed) _go(1);
    });
    _settle.addListener(_onSettle);
    _flip.addStatusListener((s) {
      // A spring run back to 0 ends as `completed`, a timed one as `dismissed`: either way the card shows its front again.
      if ((s == AnimationStatus.dismissed || s == AnimationStatus.completed) && _flip.value <= 0.001 && _share != null) {
        setState(() => _share = null);
        _focus.requestFocus(); // the share side held focus: Esc and the arrows come back to the story
      }
      _syncAuto();
    });
    Future.microtask(_registerKeys);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _announce();
      _arrived();
      _syncAuto();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    _syncAuto();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _podiumTimer?.cancel();
    _holdTimer?.cancel();
    final s = _shortcuts;
    final t = _token;
    Future.microtask(() => s.unregister(t));
    for (final c in [_settle, _auto, _flip, _closeC, _fade]) {
      c.dispose();
    }
    HardwareKeyboard.instance.removeHandler(_hwKey);
    _focus.dispose();
    super.dispose();
  }

  void _registerKeys() {
    if (!mounted) return;
    ShortcutEntry e(String d, List<String> keys) => ShortcutEntry(group: 'Wrapped', activator: const SingleActivator(LogicalKeyboardKey.abort), description: d, onInvoke: () {}, keys: keys);
    _shortcuts.register(_token, [e('Previous or next card', ['←', '→']), e('Pause or play', ['Space']), e('Export', ['E']), e('Story or Post', ['1', '2']), e('Close', ['Esc'])]);
  }

  // -- auto-advance ---------------------------------------------------------------------------------------------------

  void _syncAuto() {
    if (!mounted) return;
    final run = autoAdvanceRuns(
      pressed: _pressed,
      paused: _paused,
      resumed: _resumed,
      shareOpen: _share != null,
      screenReader: ref.read(glassAssistiveProvider),
      last: _index >= _cards.length - 1,
    );
    if (run && !_auto.isAnimating && _settle.value == 0 || run && !_auto.isAnimating && !_settle.isAnimating) {
      _auto.forward();
    } else if (!run) {
      _auto.stop();
    }
  }

  // -- moving between cards -------------------------------------------------------------------------------------------

  void _announce() {
    if (!mounted) return;
    try {
      unawaited(SemanticsService.sendAnnouncement(View.of(context), cardLabel(_card, _index, _cards.length), Directionality.of(context)));
    } catch (_) {}
  }

  /// Moves one card (-1 or +1): the story stack settles on `springPage`; reduced motion cross-fades over 200 ms.
  void _go(int dir) {
    if (_closing || _share != null) return;
    if (_settle.isAnimating && _settleDir != 0) {
      // A press during the stack's settle lands the moving card at once, then moves on from there.
      _settle.stop();
      _finishSettle();
    }
    final next = _index + dir;
    if (next < 0 || next >= _cards.length) {
      if (dir > 0) _auto.stop();
      return;
    }
    glassFire(ref, HapticEvent.annualPage);
    glassSound(ref, SoundEvent.annualPage);
    if (_reduced) {
      _fade.value = 0;
      setState(() => _index = next);
      unawaited(_fade.forward());
      _afterMove();
      return;
    }
    final w = _frameW;
    _startSettle(from: _dx, to: -dir * w, dir: dir, velocity: 0);
  }

  double get _frameW => kWrappedFrame.width;

  void _startSettle({required double from, required double to, required int dir, required double velocity}) {
    _settleFrom = from;
    _settleTo = to;
    _settleDir = dir;
    _auto.stop();
    _stackEntry = GlassMotion.recorder.begin(MotionName.storyStack.label, 615);
    _settle.value = 0;
    unawaited(_settle.animateWith(SpringSimulation(springOf(GlassSprings.page), 0, 1, velocity.clamp(-20.0, 20.0))).then((_) {
      if (!mounted) return;
      _settle.value = 1;
      _finishSettle();
    }),);
  }

  void _onSettle() {
    if (!mounted) return;
    setState(() => _dx = _settleFrom + (_settleTo - _settleFrom) * _settle.value);
  }

  void _finishSettle() {
    final e = _stackEntry;
    if (e != null) GlassMotion.recorder.end(e);
    _stackEntry = null;
    if (_settleDir != 0) _index += _settleDir;
    setState(() {
      _dx = 0;
      _settleDir = 0;
      _settle.value = 0;
    });
    _afterMove();
  }

  Timer? _podiumTimer;

  /// Card arrival cues: the summary's shimmer sound (no haptic) and the podium's landing of #1.
  void _arrived() {
    _podiumTimer?.cancel();
    if (_card == WrappedCard.summary) {
      glassSound(ref, SoundEvent.annualSummary);
    } else if (_card == WrappedCard.topFive && !_reduced) {
      _podiumTimer = Timer(Duration(milliseconds: landMs(1).round()), () {
        if (!mounted || _card != WrappedCard.topFive) return;
        glassFire(ref, HapticEvent.annualPodium);
        glassSound(ref, SoundEvent.annualPodium);
      });
    }
  }

  void _afterMove() {
    _arrived();
    _auto.reset();
    _announce();
    _syncAuto();
  }

  // -- gestures -------------------------------------------------------------------------------------------------------

  void _tapDown(TapDownDetails d) {
    _held = false;
    _holdTimer?.cancel();
    _holdTimer = Timer(const Duration(milliseconds: 450), () => _held = true);
    _downPos = d.localPosition;
    _dragged = false;
    setState(() => _pressed = true);
    _syncAuto();
  }

  void _tapUp(TapUpDetails d, double width) {
    _holdTimer?.cancel();
    final held = _held ? const Duration(milliseconds: 450) : Duration.zero;
    final moved = (d.localPosition - _downPos).distance;
    setState(() => _pressed = false);
    if (!_dragged && isTap(held, moved)) _go(tapDirection(d.localPosition.dx, width));
    _syncAuto();
  }

  void _dragUpdate(DragUpdateDetails d) {
    if (_settle.isAnimating || _share != null) return;
    _dragged = true;
    setState(() {
      _dx = stackOffset(_dx + d.delta.dx, hasNext: _index < _cards.length - 1, hasPrev: _index > 0) == _dx + d.delta.dx ? _dx + d.delta.dx : _dx + d.delta.dx * kRubberBand;
      _pressed = true;
    });
  }

  void _dragEnd(DragEndDetails d) {
    setState(() => _pressed = false);
    final w = _frameW;
    final dir = commitDirection(_dx, d.velocity.pixelsPerSecond.dx, w, hasNext: _index < _cards.length - 1, hasPrev: _index > 0);
    if (dir == 0) {
      _startSettle(from: _dx, to: 0, dir: 0, velocity: 0);
    } else {
      glassFire(ref, HapticEvent.annualPage);
      glassSound(ref, SoundEvent.annualPage);
      _startSettle(from: _dx, to: -dir * w, dir: dir, velocity: d.velocity.pixelsPerSecond.dx / w);
    }
  }

  void _vDragUpdate(DragUpdateDetails d) {
    if (_share != null || _closing) return;
    if (d.delta.dy > 0 || _dy > 0) setState(() => _dy = math.max(0, _dy + d.delta.dy));
  }

  void _vDragEnd(DragEndDetails d) {
    if (closesOnRelease(_dy, d.velocity.pixelsPerSecond.dy)) {
      unawaited(_closeStory());
    } else {
      setState(() => _dy = 0);
    }
  }

  // -- close and share ------------------------------------------------------------------------------------------------

  Future<void> _closeStory() async {
    if (_closing) return;
    if (_share != null) {
      _closeShare();
      return;
    }
    setState(() => _closing = true);
    _auto.stop();
    final reduced = _reduced;
    if (_originRect == null || reduced) {
      _closeC.duration = const Duration(milliseconds: 200);
      await _closeC.forward();
      if (mounted) _close(ref);
      return;
    }
    await GlassMotion.play(MotionName.zoom, controller: _closeC, target: 1);
    if (mounted) _close(ref);
  }

  void _openShare(WrappedCard c) {
    final mature = ref.read(glassMatureSourcesProvider) ?? {for (final s in widget.annual.topSources) s.sourceId};
    final spec = ShareSpec.forCard(c, widget.annual, matureSources: mature);
    if (spec == null || _share != null) return;
    glassFire(ref, HapticEvent.shareLift);
    glassFire(ref, HapticEvent.shareFlip);
    glassSound(ref, SoundEvent.shareFlip);
    _auto.stop();
    _flipBack = false;
    setState(() => _share = spec);
    if (_reduced) {
      _flip.value = 1;
    } else {
      unawaited(GlassMotion.play(MotionName.cardFlip, controller: _flip, target: 1));
    }
  }

  bool _flipBack = false;

  void _closeShare() {
    if (_share == null) return;
    if (_reduced) {
      _flip.value = 0;
      setState(() => _share = null);
      _focus.requestFocus();
      _syncAuto();
    } else {
      _flipBack = true;
      unawaited(GlassMotion.play(MotionName.cardFlip, controller: _flip, target: 0).then((_) {
        // Settled on the front: the side is gone (whatever status the spring ended with).
        if (!mounted || _share == null || _flip.value > 0.5) return;
        setState(() => _share = null);
        _focus.requestFocus();
        _syncAuto();
      }),);
    }
  }

  bool _hwKey(KeyEvent e) {
    if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? true)) return false;
    return _key(_focus, e) == KeyEventResult.handled;
  }

  KeyEventResult _key(FocusNode n, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    if (!_keyboard) setState(() => _keyboard = true);
    final k = e.logicalKey;
    if (_share != null && _flip.value < 0.02 && _flipBack) {
      // Flipped back already (the spring's tail is still running below a pixel): the front is showing.
      _flip.stop();
      setState(() => _share = null);
      _syncAuto();
    }
    if (_share != null) {
      if (k == LogicalKeyboardKey.escape) {
        _closeShare();
        return KeyEventResult.handled;
      }
      if (k == LogicalKeyboardKey.digit1 || k == LogicalKeyboardKey.digit2) {
        _sideKey.currentState?.setFormat(k == LogicalKeyboardKey.digit1 ? ShareFormat.story : ShareFormat.post);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    if (k == LogicalKeyboardKey.arrowRight) {
      _go(1);
    } else if (k == LogicalKeyboardKey.arrowLeft) {
      _go(-1);
    } else if (k == LogicalKeyboardKey.space) {
      setState(() => _paused = !_paused);
      _syncAuto();
    } else if (k == LogicalKeyboardKey.keyE) {
      _openShare(_card);
    } else if (k == LogicalKeyboardKey.escape) {
      unawaited(_closeStory());
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  // -- build ----------------------------------------------------------------------------------------------------------

  ({String? name, String? title}) get _together {
    final m = (widget.annual.circle ?? const []).where((c) => c.finishedTogether.isNotEmpty).firstOrNull;
    return (name: m?.name, title: m?.finishedTogether.first);
  }

  Widget _face(int i, {required bool active}) {
    final c = _cards[i];
    final canShare = c != WrappedCard.together && shareEligible(c, widget.annual, matureSources: ref.read(glassMatureSourcesProvider) ?? {for (final s in widget.annual.topSources) s.sourceId}) != null;
    final t = _together;
    return WrappedCardFace(
      key: ValueKey('wrapped-card-${c.name}'),
      card: c,
      annual: widget.annual,
      active: active,
      reduced: _reduced,
      profileName: ref.read(activeProfileProvider)?.name ?? '',
      onExport: canShare ? () => _openShare(c) : null,
      reflow: _reflow,
      togetherName: t.name,
      togetherTitle: t.title,
    );
  }

  bool _reflow = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final safe = MediaQuery.paddingOf(context);
    final kind = GlassFrame.ofSize(size);
    final f = MediaQuery.textScalerOf(context).scale(17) / 17;
    _reflow = kind == GlassFrameKind.phone && largeText(f);
    final scale = frameScale(size, safe, kind);
    final fs = frameSize(scale);
    final origin = Offset((size.width - fs.width) / 2, kind == GlassFrameKind.phone ? safe.top + 16 + (size.height - 32 - safe.top - safe.bottom - fs.height) / 2 : (size.height - fs.height) / 2);
    final assistive = ref.watch(glassAssistiveProvider);
    final p = leaveProgress(_dx, _frameW);
    final beneathIndex = _dx < 0 ? _index + 1 : _index - 1;
    final showBeneath = _dx != 0 && beneathIndex >= 0 && beneathIndex < _cards.length;

    Widget card(int i, {required bool top}) => IgnorePointer(ignoring: !top, child: _face(i, active: top && _share == null));

    Widget stack(double w, double h) => Stack(clipBehavior: Clip.none, children: [
          if (showBeneath)
            Positioned.fill(
              child: Transform.scale(
                scale: beneathScaleAt(p),
                child: Stack(children: [card(beneathIndex, top: false), Positioned.fill(child: ColoredBox(color: const Color(0xFF000000).withValues(alpha: 1 - beneathBrightnessAt(p))))]),
              ),
            ),
          Positioned.fill(
            child: Transform.translate(
              offset: Offset(_dx, 0),
              child: FadeTransition(opacity: _fade, child: card(_index, top: true)),
            ),
          ),
        ],);

    // The buttons keep a real hitMin (44 iOS, 48 Android) at any frame scale: the 44 px visual sits centred in it.
    final hit = GlassFrame.hitMin(context) / (_reflow ? 1.0 : math.min(scale, 1.0));

    // The 360 x 640 frame contents (or the reflowing column at large text).
    Widget contents(double w, double h) => Stack(clipBehavior: Clip.none, children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: _tapDown,
              onTapUp: (d) => _tapUp(d, w),
              onTapCancel: () {
                setState(() => _pressed = false);
                _syncAuto();
              },
              onHorizontalDragUpdate: _dragUpdate,
              onHorizontalDragEnd: _dragEnd,
              onVerticalDragUpdate: _reflow ? null : _vDragUpdate,
              onVerticalDragEnd: _reflow ? null : _vDragEnd,
              child: stack(w, h),
            ),
          ),
          Positioned(left: 16, right: 16, top: 12, height: 4, child: IgnorePointer(child: _Capsules(count: _cards.length, index: _index, auto: _auto))),
          Positioned(
            left: 24 - (hit - 44) / 2,
            right: 24 - (hit - 44) / 2,
            top: 24 - (hit - 44) / 2,
            height: hit,
            child: Row(children: [
              if (assistive || _keyboard) ...[
                _RoundButton(label: 'Previous card', glyph: GlassGlyphIcon.left, hit: hit, onTap: () => _go(-1)),
                SizedBox(width: math.max(0, 52 - hit)),
                _RoundButton(label: 'Next card', glyph: GlassGlyphIcon.right, hit: hit, onTap: () => _go(1)),
              ],
              const Spacer(),
              _RoundButton(label: _paused ? 'Play' : 'Pause', glyph: _paused ? GlassGlyphIcon.play : GlassGlyphIcon.pause, hit: hit, onTap: () {
                setState(() => _paused = !_paused);
                _syncAuto();
              },),
              SizedBox(width: math.max(0, 52 - hit)),
              _RoundButton(label: 'Close', glyph: GlassGlyphIcon.close, hit: hit, onTap: () => unawaited(_closeStory())),
            ],),
          ),
        ],);

    final front = _reflow
        ? SizedBox(width: size.width - 32, height: size.height - 32 - safe.top - safe.bottom, child: ClipRRect(borderRadius: BorderRadius.circular(32), child: contents(size.width - 32, size.height)))
        : SizedBox(width: fs.width, height: fs.height, child: ClipRRect(borderRadius: BorderRadius.circular(32 * scale), child: FittedBox(child: SizedBox(width: kWrappedFrame.width, height: kWrappedFrame.height, child: MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling), child: contents(kWrappedFrame.width, kWrappedFrame.height))))));
    final framePx = _reflow ? Size(size.width - 32, size.height - 32 - safe.top - safe.bottom) : fs;
    final frameOrigin = _reflow ? Offset(16, safe.top + 16) : origin;

    final flipped = AnimatedBuilder(
      animation: Listenable.merge([_flip, _closeC]),
      builder: (context, _) {
        final t = _flip.value;
        final reduced = _reduced;
        Widget body;
        if (_share == null) {
          body = front;
        } else if (reduced) {
          body = t < 0.5 ? front : _shareSide(framePx);
        } else {
          final angle = math.pi * t;
          final lift = 1 - 0.08 * math.sin(math.pi * t);
          final m = Matrix4.identity()
            ..setEntry(3, 2, 1 / 1200)
            ..rotateY(angle)
            ..scaleByDouble(lift, lift, 1, 1);
          body = Transform(alignment: Alignment.center, transform: m, child: t < 0.5 ? front : Transform(alignment: Alignment.center, transform: Matrix4.rotationY(math.pi), child: _shareSide(framePx)));
        }
        // The close: shrink into the entry card, or fade.
        final c = _closeC.value;
        final o = _originRect;
        var opacity = 1.0;
        var dx = 0.0, dy = _dy, s = 1 - 0.3 * (_dy / 600).clamp(0.0, 1.0);
        if (_closing) {
          if (o == null || reduced) {
            opacity = 1 - c;
          } else {
            final to = o.center - (frameOrigin + Offset(framePx.width / 2, framePx.height / 2));
            dx = to.dx * c;
            dy = to.dy * c + _dy;
            s = 1 + (math.max(0.05, o.width / framePx.width) - 1) * c;
            opacity = 1 - 0.3 * c;
          }
        }
        return Opacity(opacity: opacity.clamp(0.0, 1.0), child: Transform.translate(offset: Offset(dx, dy), child: Transform.scale(scale: s, child: body)));
      },
    );

    return PopScope(
      canPop: _share == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeShare();
      },
      child: Focus(
        focusNode: _focus,
        autofocus: true,
        child: Listener(
          onPointerDown: (_) {
            if (_keyboard) setState(() => _keyboard = false);
          },
          child: Semantics(
            container: true,
            label: 'Wrapped ${widget.annual.year}',
            customSemanticsActions: {
              const CustomSemanticsAction(label: 'Previous card'): () => _go(-1),
              CustomSemanticsAction(label: _paused ? 'Play' : 'Pause'): () {
                setState(() => _paused = !_paused);
                _syncAuto();
              },
              const CustomSemanticsAction(label: 'Next card'): () => _go(1),
            },
            child: Stack(children: [
              Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: RadialGradient(center: const Alignment(0, -0.2), radius: 1.0, colors: [cardGround(widget.annual).withValues(alpha: 0.35), const Color(0xFF000000)])))),
              Positioned(
                left: frameOrigin.dx,
                top: frameOrigin.dy,
                width: framePx.width,
                height: framePx.height,
                child: Semantics(
                  container: true,
                  label: cardLabel(_card, _index, _cards.length),
                  child: Stack(children: [
                    if (!_reflow) Positioned.fill(child: SkinGlass(tier: GlassTierId.t5, shape: GlassShape.superellipse(32 * scale), size: framePx, layer: GlassLayerKind.overlays, debugLabel: 'wrapped-frame', child: const SizedBox.expand())),
                    flipped,
                  ],),
                ),
              ),
            ],),
          ),
        ),
      ),
    );
  }

  Widget _shareSide(Size frame) => SizedBox(
        width: frame.width,
        height: frame.height,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: GlassShareSide(key: _sideKey, spec: _share!, onClose: _closeShare),
        ),
      );
}

/// Progress capsules (y 12 to 16): `fill1` track, `label1` fill; past cards full, the current one growing over 6 s.
class _Capsules extends StatelessWidget {
  const _Capsules({required this.count, required this.index, required this.auto});
  final int count;
  final int index;
  final Animation<double> auto;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: auto,
        builder: (context, _) => Row(children: [
          for (var i = 0; i < count; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
                child: DecoratedBox(
                  decoration: BoxDecoration(color: gt.colorFill1, borderRadius: BorderRadius.circular(2)),
                  child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: i < index ? 1 : (i == index ? auto.value : 0), child: DecoratedBox(decoration: BoxDecoration(color: gt.colorLabel1, borderRadius: BorderRadius.circular(2)))),
                ),
              ),
            ),
        ],),
      );
}

enum GlassGlyphIcon { left, right, play, pause, close }

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.label, required this.glyph, required this.onTap, this.hit = 44});
  final String label;
  final double hit;
  final GlassGlyphIcon glyph;
  final VoidCallback onTap;

  IconData get _icon => switch (glyph) {
        GlassGlyphIcon.left => PhosphorRegular.caretLeft,
        GlassGlyphIcon.right => GlassGlyph.caretRight.regular,
        GlassGlyphIcon.play => GlassGlyph.play.fill,
        GlassGlyphIcon.pause => PhosphorRegular.pause,
        GlassGlyphIcon.close => GlassGlyph.x.regular,
      };

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ExcludeSemantics(
            child: SizedBox.square(
              dimension: hit,
              child: Center(child: Container(width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, color: gt.colorFill2), child: Icon(_icon, size: 20, color: gt.colorLabel1))),
            ),
          ),
        ),
      );
}
