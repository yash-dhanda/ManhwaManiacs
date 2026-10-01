import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/glass_motion_recorder.dart' show GlassMotionEntry;
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/reveal_slots.dart';
import 'package:manhwamaniacs/skins/glass/primitives/revealed_headings.dart';

/// The units a run animates, and the wrap groups that keep Latin words on one line while letting CJK runs
/// break between graphemes (glass 10.1).
class RevealPlan {
  RevealPlan(this.text) {
    final chars = text.characters.toList();
    final graphemes = chars.where((c) => c.trim().isNotEmpty).length;
    perWord = graphemes > 60;
    var word = <String>[];
    void flush() {
      if (word.isEmpty) return;
      words.add(word);
      word = [];
    }

    for (final c in chars) {
      if (c.trim().isEmpty) {
        flush();
        spaces.add(words.length);
        continue;
      }
      if (_isCjk(c)) {
        // A CJK grapheme is its own wrap unit: lines may break between graphemes.
        flush();
        words.add([c]);
      } else {
        word.add(c);
      }
    }
    flush();
    unitCount = perWord ? words.length : graphemes;
  }

  final String text;
  final List<List<String>> words = [];

  /// Indices into [words] that were preceded by a space.
  final List<int> spaces = [];
  late final bool perWord;
  late final int unitCount;

  static bool _isCjk(String g) {
    final c = g.runes.first;
    return (c >= 0x3040 && c <= 0x30FF) || (c >= 0x3400 && c <= 0x4DBF) || (c >= 0x4E00 && c <= 0x9FFF) || (c >= 0xAC00 && c <= 0xD7AF) || (c >= 0xFF00 && c <= 0xFFEF);
  }
}

/// The heading reveal (glass 10.1, 15.7): each grapheme a droplet settling. Opacity 0 to 1 over
/// `curveFadeIn`, translate +0.40 em to 0, blur 12 px to 0 and scale 0.96 to 1 on the `letter` spring, 24 ms
/// per grapheme (spaces take no time), a 30 degree glint 120 ms after the last letter settles. Above 60
/// graphemes it animates per word at 40 ms per word. It starts at first visibility (25 % of the heading
/// inside the nearest scrollable), at most two run at once, once per session per profile, and completes
/// at once on a tap, on scrolling off-screen or on a route pushed over it (focus does not complete it).
class LetterReveal extends ConsumerStatefulWidget {
  const LetterReveal(
    this.text, {
    super.key,
    required this.role,
    this.revealKey,
    this.screenId = '',
    this.color,
    this.onGlass = false,
    this.wght,
    this.maxLines,
    this.textAlign = TextAlign.start,
    this.headingLevel,
    this.maxScale,
  });

  final String text;
  final GlassTypeRole role;

  /// The heading's key within its screen; null for the hero title and chapter seams, which play whenever
  /// their text changes or they enter the viewport.
  final String? revealKey;
  final String screenId;
  final Color? color;
  final bool onGlass;
  final int? wght;
  final int? maxLines;
  final TextAlign textAlign;
  final int? headingLevel;
  final double? maxScale;

  @override
  ConsumerState<LetterReveal> createState() => _LetterRevealState();
}

enum _Phase { hidden, queued, running, done }

class _LetterRevealState extends ConsumerState<LetterReveal> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  final ValueNotifier<double> _t = ValueNotifier(0);
  late Set<String> _revealed;
  late String _profile;
  _Phase _phase = _Phase.hidden;
  late RevealPlan _plan = RevealPlan(widget.text);
  ScrollPosition? _position;
  Animation<double>? _secondary;
  GlassMotionEntry? _entry;
  Object? _slotId;

  String? get _key => widget.revealKey == null ? null : '$_profile:${widget.screenId}:${widget.revealKey}';

  @override
  void initState() {
    super.initState();
    _ticker.isActive; // create the ticker while the element is active
    _revealed = ref.read(revealedHeadingsProvider);
    _profile = glassProfileIdOf(ref);
    final k = _key;
    if (k != null && _revealed.contains(k)) _phase = _Phase.done;
    _slotId = Object();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final pos = Scrollable.maybeOf(context)?.position;
    if (pos != _position) {
      _position?.removeListener(_onScroll);
      _position = pos;
      _position?.addListener(_onScroll);
    }
    final sec = ModalRoute.of(context)?.secondaryAnimation;
    if (sec != _secondary) {
      _secondary?.removeStatusListener(_onRoute);
      _secondary = sec;
      _secondary?.addStatusListener(_onRoute);
    }
  }

  @override
  void didUpdateWidget(LetterReveal old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) {
      // Live text: the old letters leave together, the new wave starts (the AnimatedSwitcher path).
      _plan = RevealPlan(widget.text);
      _stopEverything();
      _phase = _Phase.hidden;
      WidgetsBinding.instance.addPostFrameCallback((_) => _check());
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_onScroll);
    _secondary?.removeStatusListener(_onRoute);
    _stopEverything();
    _ticker.dispose();
    _t.dispose();
    super.dispose();
  }

  void _stopEverything() {
    glassRevealSlots.withdraw(_slotId ??= Object());
    if (_ticker.isActive) _ticker.stop();
    final e = _entry;
    _entry = null;
    if (e != null) GlassMotion.recorder.end(e);
  }

  /// The position notifies before the frame lays the new offset out, so the check runs after it too.
  void _onScroll() {
    _check();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _onRoute(AnimationStatus s) {
    if (s == AnimationStatus.forward) _complete();
  }

  /// The fraction of the heading inside the nearest scrollable's viewport (1 outside any scroll view).
  double _visibleFraction() {
    // An element that is being unmounted has no render object to ask.
    if (!(context as Element).debugIsActive && !context.mounted) return 0;
    RenderObject? ro;
    try {
      ro = context.findRenderObject();
    } catch (_) {
      return 0;
    }
    final box = ro;
    if (box is! RenderBox || !box.attached || !box.hasSize) return 0;
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) return 1;
    RenderObject? vb;
    try {
      vb = scrollable.context.findRenderObject();
    } catch (_) {
      return 0;
    }
    if (vb is! RenderBox || !vb.attached || !vb.hasSize) return 0;
    final r = box.localToGlobal(Offset.zero) & box.size;
    final v = vb.localToGlobal(Offset.zero) & vb.size;
    final i = r.intersect(v);
    if (i.width <= 0 || i.height <= 0 || r.height == 0 || r.width == 0) return 0;
    return (i.width * i.height) / (r.width * r.height);
  }

  void _check() {
    if (!mounted) return;
    final frac = _visibleFraction();
    switch (_phase) {
      case _Phase.hidden:
        if (frac >= 0.25) _request();
      case _Phase.queued:
        if (frac <= 0) {
          glassRevealSlots.withdraw(_slotId!);
          _phase = _Phase.hidden;
        }
      case _Phase.running:
        if (frac <= 0) _complete();
      case _Phase.done:
        break;
    }
  }

  void _request() {
    if (ref.read(glassMotionPrefsProvider).reduced) {
      _finishAt();
      return;
    }
    _phase = _Phase.queued;
    glassRevealSlots.acquire(_slotId!, _start);
  }

  void _finishAt() {
    final k = _key;
    if (k != null) _revealed.add(k);
    if (mounted) setState(() => _phase = _Phase.done);
  }

  void _start() {
    if (!mounted) {
      glassRevealSlots.release(_slotId!);
      return;
    }
    // A waiter that is no longer visible completes at once.
    if (_visibleFraction() <= 0) {
      _phase = _Phase.done;
      final k = _key;
      if (k != null) _revealed.add(k);
      glassRevealSlots.release(_slotId!);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
      return;
    }
    final k = _key;
    if (k != null) _revealed.add(k);
    _phase = _Phase.running;
    _t.value = 0;
    final total = revealDuration(_plan.unitCount, perUnitMs: _plan.perWord ? 40 : 24);
    _entry = GlassMotion.recorder.begin(MotionName.letterReveal.label, total.inMilliseconds);
    _total = total.inMilliseconds.toDouble();
    unawaited(_ticker.start());
    // A slot handed over while another reveal is torn down arrives mid-frame, when the tree is locked.
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  double _total = 0;

  void _onTick(Duration elapsed) {
    final ms = elapsed.inMicroseconds / 1000;
    if (ms >= _total) {
      _complete();
      return;
    }
    _t.value = ms;
  }

  void _complete() {
    if (_phase == _Phase.done) return;
    final wasActive = _phase == _Phase.running || _phase == _Phase.queued;
    _stopEverything();
    _phase = _Phase.done;
    final k = _key;
    if (k != null) _revealed.add(k);
    if (wasActive) glassRevealSlots.release(_slotId!);
    if (mounted) setState(() {});
  }

  TextStyle _style(bool legible) {
    final s = roleStyle(context, widget.role, onGlass: widget.onGlass, legible: legible, wght: widget.wght, maxScale: widget.maxScale ?? double.infinity);
    return s.copyWith(color: widget.color ?? (widget.onGlass ? gt.colorOnGlass : gt.colorLabel1));
  }

  @override
  Widget build(BuildContext context) {
    final legible = ref.watch(glassA11yProvider.select((a) => a.legible));
    final reduced = ref.watch(glassReducedProvider);
    final style = _style(legible);
    final plain = Text(widget.text, style: style, maxLines: widget.maxLines, textAlign: widget.textAlign, textScaler: TextScaler.noScaling, overflow: widget.maxLines == null ? null : TextOverflow.ellipsis);

    Widget body;
    if (_phase == _Phase.done || reduced) {
      body = AnimatedDefaultTextStyle(style: style, duration: gt.curveColorShift.duration, curve: gt.curveColorShift.curve, child: plain);
    } else {
      final run = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (_) => _complete(),
        child: _Run(plan: _plan, style: style, t: _t, active: _phase == _Phase.running, textAlign: widget.textAlign),
      );
      final maxLines = widget.maxLines;
      // The letter run cannot ellipsize: a heading longer than [maxLines] shows settled (with its ellipsis) from the first frame,
      // so it never flashes a third line that then collapses.
      body = maxLines == null
          ? run
          : LayoutBuilder(builder: (context, c) {
              final p = TextPainter(text: TextSpan(text: widget.text, style: style), textDirection: TextDirection.ltr, textScaler: TextScaler.noScaling, maxLines: maxLines)
                ..layout(maxWidth: c.maxWidth);
              final over = p.didExceedMaxLines;
              p.dispose();
              return over ? plain : run;
            },);
    }
    return Semantics(header: true, headingLevel: widget.headingLevel, label: widget.text, child: ExcludeSemantics(child: body));
  }
}

class _Run extends StatelessWidget {
  const _Run({required this.plan, required this.style, required this.t, required this.active, required this.textAlign});
  final RevealPlan plan;
  final TextStyle style;
  final ValueNotifier<double> t;
  final bool active;
  final TextAlign textAlign;

  static final Cubic _fade = gt.curveFadeIn.curve as Cubic;

  @override
  Widget build(BuildContext context) {
    final spring = springOf(gt.springLetter);
    final sim = SpringSimulation(spring, 0, 1, 0);
    final em = style.fontSize ?? 16;
    final perMs = plan.perWord ? 40.0 : 24.0;
    final lastStart = (plan.unitCount - 1) * perMs;
    final glintStart = lastStart + 345 + 120;
    return LayoutBuilder(
      builder: (context, c) => ValueListenableBuilder<double>(
        valueListenable: t,
        builder: (context, ms, _) {
          var unit = 0;
          Widget letter(String g, int u) {
            Widget text() => Text(g, style: style, textScaler: TextScaler.noScaling);
            if (!active) return Opacity(opacity: 0, child: text());
            final dt = ms - u * perMs;
            if (dt <= 0) return Opacity(opacity: 0, child: text());
            final v = sim.x(dt / 1000);
            final opacity = _fade.transform((dt / 180).clamp(0.0, 1.0));
            final blur = 12 * (1 - v).clamp(0.0, 1.0);
            Widget w = Transform.translate(offset: Offset(0, 0.4 * em * (1 - v)), child: Transform.scale(scale: 0.96 + 0.04 * v, child: text()));
            if (blur > 0.05) w = ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur), child: w);
            return Opacity(opacity: opacity.clamp(0.0, 1.0), child: w);
          }

          double measure(String t) {
            final p = TextPainter(text: TextSpan(text: t, style: style), textDirection: TextDirection.ltr, textScaler: TextScaler.noScaling)..layout();
            final w = p.width;
            p.dispose();
            return w;
          }

          final spaceW = measure(' ');
          final maxW = c.hasBoundedWidth ? c.maxWidth : double.infinity;
          final children = <Widget>[];
          for (var wi = 0; wi < plan.words.length; wi++) {
            final word = plan.words[wi];
            final startsAt = unit;
            final trailingSpace = plan.spaces.contains(wi + 1);
            final tooWide = word.length > 1 && measure(word.join()) > maxW - spaceW;
            if (tooWide) {
              // A word wider than the line may break between graphemes rather than overflow.
              for (final g in word) {
                children.add(letter(g, plan.perWord ? startsAt : unit));
                if (!plan.perWord) unit++;
              }
              if (plan.perWord) unit++;
              continue;
            }
            final letters = <Widget>[];
            for (final g in word) {
              letters.add(letter(g, plan.perWord ? startsAt : unit));
              if (!plan.perWord) unit++;
            }
            if (plan.perWord) unit++;
            final row = Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: letters);
            children.add(trailingSpace ? Padding(padding: EdgeInsets.only(right: spaceW), child: row) : row);
          }
          Widget wrap = Wrap(
            alignment: switch (textAlign) {
              TextAlign.center => WrapAlignment.center,
              TextAlign.end || TextAlign.right => WrapAlignment.end,
              _ => WrapAlignment.start,
            },
            crossAxisAlignment: WrapCrossAlignment.center,
            children: children,
          );
          if (active && ms >= glintStart) {
            final p = ((ms - glintStart) / 500).clamp(0.0, 1.0);
            wrap = ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (rect) {
                // A band 40 % of the heading wide, rotated 30 degrees, sweeping left to right once.
                final a = -0.2 + 1.4 * p;
                return LinearGradient(
                  colors: const [Color(0x00FFFFFF), Color(0x2EFFFFFF), Color(0x00FFFFFF)],
                  stops: [(a - 0.2).clamp(0.0, 1.0), a.clamp(0.0, 1.0), (a + 0.2).clamp(0.0, 1.0)],
                  transform: const GradientRotation(math.pi / 6),
                ).createShader(rect);
              },
              child: wrap,
            );
          }
          return wrap;
        },
      ),
    );
  }
}
