// Throwaway device gate (stack-decision 1): mobile/25 replaces it with the
// "Glass calibration" page and deletes skins/glass/gate/.
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:manhwamaniacs/core/diagnostics/performance_monitor.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_display_mode.dart';
import 'package:manhwamaniacs/skins/glass/glass/liquid.dart';
import 'package:manhwamaniacs/skins/glass/icons/glass_icon.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart';

enum GateEngine { liquid, frost }

/// T3 dock (glass 2.4.3). refractiveIndex 1.2 is the package default.
const _t3 = LiquidGlassSettings(
  thickness: 24,
  blur: 10,
  saturation: 1.8,
  glassColor: Color(0x0FFFFFFF),
  lightIntensity: 0.40,
  chromaticAberration: 0,
);

/// T4 sheet (glass 2.4.3).
const _t4 = LiquidGlassSettings(
  thickness: 40,
  blur: 22,
  saturation: 1.8,
  glassColor: Color(0x851C1C22),
  lightIntensity: 0.30,
  chromaticAberration: 0.35,
);

/// 44 pt on iOS, 48 dp on Android.
double _minHit() => defaultTargetPlatform == TargetPlatform.android ? 48 : 44;

const _railCount = 8;
const _postersPerRail = 24;
const _mono = TextStyle(fontFamily: 'GoogleSansCodeMM', fontSize: 12, height: 16 / 12, color: Color(0xFFF5F5F5));
TextStyle _sans(double size, double line, {FontWeight w = FontWeight.w400, Color c = const Color(0xFFF5F5F5)}) => TextStyle(
      fontFamily: 'GoogleSansFlexMM',
      fontSize: size,
      height: line / size,
      fontWeight: w,
      color: c,
      fontVariations: [ui.FontVariation('wght', w.value.toDouble())],
    );

class GlassGateScreen extends ConsumerStatefulWidget {
  /// [ready] and [initialEngine] exist for tests: fragment shaders do not run in `flutter_tester`.
  const GlassGateScreen({super.key, this.ready, this.initialEngine = GateEngine.liquid});

  final Future<void>? ready;
  final GateEngine initialEngine;

  @override
  ConsumerState<GlassGateScreen> createState() => _GlassGateScreenState();
}

class _GlassGateScreenState extends ConsumerState<GlassGateScreen> {
  final _vScroll = ScrollController();
  final _rails = List.generate(_railCount, (_) => ScrollController());
  final _minimize = GlassTabBarMinimizeController(behavior: GlassBarMinimizeBehavior.onScrollDown);
  late GateEngine _engine = widget.initialEngine;
  late final Future<void> _ready = widget.ready ?? ensureLiquidGlassReady();
  int _tab = 0;
  bool _flinging = false;
  PerformanceMonitor? _monitor;
  bool _startedMonitor = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final m = ref.read(performanceMonitorProvider);
      _startedMonitor = !m.isRunning;
      m.start();
      setState(() => _monitor = m);
      try {
        final info = await ref.read(readerDisplayModeProvider).describe();
        if (info.activeRefreshRate > 0) m.setTargetRefreshRate(info.activeRefreshRate);
      } catch (_) {
        // No platform channel (tests, desktop): keep the 60 Hz budget.
      }
    });
  }

  @override
  void dispose() {
    if (_startedMonitor) _monitor?.stop();
    _vScroll.dispose();
    for (final c in _rails) {
      c.dispose();
    }
    _minimize.dispose();
    super.dispose();
  }

  bool get _liquid => _engine == GateEngine.liquid;

  /// 10 s: five 2 s legs of the page, and every rail scrolls with it.
  Future<void> _autoFling() async {
    if (_flinging) return;
    setState(() => _flinging = true);
    for (var leg = 0; leg < 5 && mounted; leg++) {
      final toEnd = leg.isEven;
      await Future.wait([
        for (final c in [_vScroll, ..._rails])
          if (c.hasClients)
            c.animateTo(toEnd ? c.position.maxScrollExtent : 0, duration: const Duration(seconds: 2), curve: Curves.easeInOut),
      ]);
    }
    if (mounted) setState(() => _flinging = false);
  }

  void _openSheet() {
    if (_liquid) {
      GlassModalSheet.show<void>(
        context: context,
        // detents: medium and large (the package default)
        settings: _t4,
        builder: (_) => const _SheetRows(),
      );
    } else {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: const Color(0x66000000),
        builder: (_) => const _FrostSheet(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Theme(
      data: ThemeData(useMaterial3: true, brightness: Brightness.dark, scaffoldBackgroundColor: Colors.black),
      child: FutureBuilder<void>(
        future: _ready,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const ColoredBox(color: Colors.black);
          return GlassAccessibilityScope(
            reduceMotion: MediaQuery.disableAnimationsOf(context),
            reduceTransparency: false,
            child: Scaffold(
              backgroundColor: Colors.black,
              body: BackdropGroup(
                child: Stack(
                  children: [
                    NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        if (n.depth == 0 && n.metrics.axis == Axis.vertical) _minimize.handleNotification(n);
                        return false;
                      },
                      child: CustomScrollView(
                        controller: _vScroll,
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(24, top + 56, 24, 12),
                              child: Semantics(header: true, child: Text('Glass device gate', style: _sans(28, 34, w: FontWeight.w600))),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _EngineSwitch(engine: _engine, onChanged: (e) => setState(() => _engine = e)),
                                  ),
                                  const SizedBox(width: 12),
                                  _Capsule(label: _flinging ? 'Flinging' : 'Auto-fling', onTap: _autoFling, width: 112),
                                ],
                              ),
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 96, child: _Checkerboard())),
                          SliverList.builder(
                            itemCount: _railCount,
                            itemBuilder: (_, i) => _Rail(index: i, controller: _rails[i]),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 120)),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16 + _minHit() + 8,
                      top: top + 8,
                      child: Align(alignment: Alignment.centerLeft, child: _Readout(monitor: _monitor, liquid: _liquid)),
                    ),
                    Positioned(top: top + 4, right: 16, child: _Capsule(label: 'Sheet', onTap: _openSheet, width: 44, square: true)),
                    Positioned(left: 0, right: 0, bottom: MediaQuery.viewPaddingOf(context).bottom, child: _bar()),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static const _roles = [GlassIconRole.home, GlassIconRole.library, GlassIconRole.sources];
  static const _labels = ['Home', 'Library', 'Sources', 'You'];

  Widget _bar() {
    if (!_liquid) {
      return AnimatedBuilder(
        animation: _minimize,
        builder: (_, __) => _FrostBar(selected: _tab, minimized: _minimize.minimized, onSelect: (i) => setState(() => _tab = i)),
      );
    }
    final bar = GlassTabBar.minimizable(
      tabs: [
        for (var i = 0; i < 4; i++)
          GlassTab(
            icon: i < 3 ? GlassIcon(_roles[i], size: 24) : const _YouDot(),
            activeIcon: i < 3 ? GlassIcon(_roles[i], size: 24, selected: true) : const _YouDot(),
            label: _labels[i],
            semanticLabel: _labels[i],
          ),
      ],
      selectedIndex: _tab,
      onTabSelected: (i) => setState(() => _tab = i),
      minimizeController: _minimize,
      onMinimizedTabTap: _minimize.expand,
      horizontalPadding: 16,
      verticalPadding: 12,
      // barHeight 64 and minimizedBarHeight 50 are the package defaults.
      settings: _t3,
      quality: GlassQuality.premium,
    );
    // GlassTabBar has no focus handling: overlay keyboard targets (pointer-transparent).
    return Stack(
      children: [
        bar,
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _minimize,
            builder: (_, __) => _minimize.minimized
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        for (var i = 0; i < 4; i++)
                          Expanded(child: _TabFocus(key: ValueKey('tab-$i'), label: _labels[i], onActivate: () => setState(() => _tab = i))),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

/// Keyboard target for a LIQUID tab: focusable, Enter/Space activates, visible ring.
class _TabFocus extends StatefulWidget {
  const _TabFocus({super.key, required this.label, required this.onActivate});
  final String label;
  final VoidCallback onActivate;
  @override
  State<_TabFocus> createState() => _TabFocusState();
}

class _TabFocusState extends State<_TabFocus> {
  bool _focused = false;
  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: FocusableActionDetector(
          onShowFocusHighlight: (v) => setState(() => _focused = v),
          actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onActivate())},
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: _minHit(), minWidth: _minHit()),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: _focused ? const Color(0xCCFFFFFF) : Colors.transparent, width: 2),
              ),
            ),
          ),
        ),
      );
}

class _YouDot extends StatelessWidget {
  const _YouDot();
  @override
  Widget build(BuildContext context) => Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x33FFFFFF)),
        child: Text('Y', style: _sans(14, 16, w: FontWeight.w600)),
      );
}

/// Readout pill: `FPS 119 · JANK 1.2 % · WORST 14 MS · LIQUID`.
class _Readout extends StatelessWidget {
  const _Readout({required this.monitor, required this.liquid});
  final PerformanceMonitor? monitor;
  final bool liquid;

  @override
  Widget build(BuildContext context) {
    final m = monitor;
    Widget pill(String text) => Semantics(
          label: 'Performance readout: $text',
          excludeSemantics: true,
          child: DecoratedBox(
            decoration: BoxDecoration(color: const Color(0x99000000), borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: FittedBox(fit: BoxFit.scaleDown, child: Text(text, style: _mono, maxLines: 1)),
            ),
          ),
        );
    final mode = liquid ? 'LIQUID' : 'FROST';
    if (m == null) return pill('FPS -- · JANK -- % · WORST -- MS · $mode');
    return AnimatedBuilder(
      animation: m,
      builder: (_, __) {
        final s = m.snapshot;
        if (!s.hasData) return pill('FPS -- · JANK -- % · WORST -- MS · $mode');
        return pill('FPS ${s.fps.round()} · JANK ${s.jankPercent.toStringAsFixed(1)} % · WORST ${s.worstFrameMs.round()} MS · $mode');
      },
    );
  }
}

/// A 44 pt (or wider) capsule button with visible keyboard focus.
class _Capsule extends StatelessWidget {
  const _Capsule({required this.label, required this.onTap, required this.width, this.square = false});
  final String label;
  final VoidCallback onTap;
  final double width;
  final bool square;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: SizedBox(
          width: square ? _minHit() : width,
          height: _minHit(),
          child: Material(
            color: const Color(0x2EFFFFFF),
            shape: const StadiumBorder(),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: onTap,
              focusColor: const Color(0x66FFFFFF),
              child: Center(
                child: Text(square ? 'Sheet' : label, style: _sans(square ? 11 : 13, 16, w: FontWeight.w600), maxLines: 1),
              ),
            ),
          ),
        ),
      );
}

class _EngineSwitch extends StatelessWidget {
  const _EngineSwitch({required this.engine, required this.onChanged});
  final GateEngine engine;
  final ValueChanged<GateEngine> onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: 'Glass engine',
        child: DecoratedBox(
          decoration: BoxDecoration(color: const Color(0x1FFFFFFF), borderRadius: BorderRadius.circular(22)),
          child: Row(
            children: [
              for (final e in GateEngine.values)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: e == engine,
                    label: e.name.toUpperCase(),
                    excludeSemantics: true,
                    child: SizedBox(
                      height: _minHit(),
                      child: Material(
                        color: e == engine ? const Color(0x47FFFFFF) : Colors.transparent,
                        shape: const StadiumBorder(),
                        child: InkWell(
                          customBorder: const StadiumBorder(),
                          focusColor: const Color(0x66FFFFFF),
                          onTap: () => onChanged(e),
                          child: Center(child: Text(e.name.toUpperCase(), style: _sans(13, 16, w: FontWeight.w600))),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
}

class _Rail extends StatelessWidget {
  const _Rail({required this.index, required this.controller});
  final int index;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text('Rail ${index + 1}', style: _sans(13, 16, w: FontWeight.w600, c: const Color(0xA3FFFFFF))),
            ),
            SizedBox(
              height: 180,
              child: ListView.separated(
                controller: controller,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _postersPerRail,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, j) => _Poster(rail: index, poster: j),
              ),
            ),
          ],
        ),
      );
}

class _Poster extends StatelessWidget {
  const _Poster({required this.rail, required this.poster});
  final int rail;
  final int poster;

  @override
  Widget build(BuildContext context) {
    final Widget face;
    if (rail == 3) {
      face = const ColoredBox(color: Colors.white);
    } else if (rail == 6 && poster.isOdd) {
      face = const _Checkerboard();
    } else {
      final hue = ((rail * 45 + poster * 15) % 360).toDouble();
      face = DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              HSLColor.fromAHSL(1, hue, 0.70, 0.50).toColor(),
              HSLColor.fromAHSL(1, (hue + 40) % 360, 0.80, 0.25).toColor(),
            ],
          ),
        ),
      );
    }
    return ExcludeSemantics(child: SizedBox(width: 120, height: 180, child: ClipRRect(borderRadius: BorderRadius.circular(12), child: face)));
  }
}

/// 16 px black-and-white squares, to see refraction bend.
class _Checkerboard extends StatelessWidget {
  const _Checkerboard();
  @override
  Widget build(BuildContext context) => const ExcludeSemantics(child: CustomPaint(painter: _CheckerPainter(), size: Size.infinite));
}

class _CheckerPainter extends CustomPainter {
  const _CheckerPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);
    final white = Paint()..color = Colors.white;
    for (var y = 0; y * 16 < size.height; y++) {
      for (var x = 0; x * 16 < size.width; x++) {
        if ((x + y).isEven) canvas.drawRect(Rect.fromLTWH(x * 16.0, y * 16.0, 16, 16), white);
      }
    }
  }

  @override
  bool shouldRepaint(_CheckerPainter old) => false;
}

class _SheetRows extends StatelessWidget {
  const _SheetRows();
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        child: Column(
          children: [
            for (var i = 1; i <= 30; i++)
              SizedBox(
                height: 56,
                child: Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Text('Row $i', style: _sans(17, 22)))),
              ),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// FROST twin: BackdropGroup + BackdropFilter.grouped with a painted rim.
// ---------------------------------------------------------------------------

/// Frosted panel of glass 2.4.2 `frosted` (+6 blur over the variant): blur, then
/// saturate 1.8 via ImageFilter.compose with a luma-weighted ColorFilter.matrix.
// Saturation 1.8 (CSS saturate(): luma 0.2126/0.7152/0.0722).
const ColorFilter _saturate18 = ColorFilter.matrix(<double>[
  0.2126 + 0.7874 * 1.8, 0.7152 - 0.7152 * 1.8, 0.0722 - 0.0722 * 1.8, 0, 0,
  0.2126 - 0.2126 * 1.8, 0.7152 + 0.2848 * 1.8, 0.0722 - 0.0722 * 1.8, 0, 0,
  0.2126 - 0.2126 * 1.8, 0.7152 - 0.7152 * 1.8, 0.0722 + 0.9278 * 1.8, 0, 0,
  0, 0, 0, 1, 0,
]);

class _FrostPanel extends StatelessWidget {
  const _FrostPanel({required this.radius, required this.sigma, required this.fill, required this.specular, required this.child});
  final BorderRadius radius;
  final double sigma;
  final Color fill;
  final double specular;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final px = 1 / MediaQuery.devicePixelRatioOf(context);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter.grouped(
        filter: ui.ImageFilter.compose(outer: _saturate18, inner: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma)),
        child: CustomPaint(
          foregroundPainter: _RimPainter(radius: radius, specular: specular, stroke: px),
          child: ColoredBox(color: fill, child: child),
        ),
      ),
    );
  }
}

class _RimPainter extends CustomPainter {
  const _RimPainter({required this.radius, required this.specular, required this.stroke});
  final BorderRadius radius;
  final double specular;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = radius.toRRect(Offset.zero & size);
    // Inner light: inset 1 1 white at S x 0.35, inset -1 -1 black at 0.35.
    final shape = Path()..addRRect(rrect);
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawPath(Path.combine(PathOperation.difference, shape, shape.shift(const Offset(1, 1))), Paint()..color = Colors.white.withValues(alpha: specular * 0.35));
    canvas.drawPath(Path.combine(PathOperation.difference, shape, shape.shift(const Offset(-1, -1))), Paint()..color = Colors.black.withValues(alpha: 0.35));
    canvas.restore();
    // Rim: 1 physical px, 135 degrees.
    final rim = rrect.deflate(stroke / 2);
    canvas.drawRRect(
      rim,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(size.width, size.height),
          [
            Colors.white.withValues(alpha: specular),
            Colors.white.withValues(alpha: 0.06),
            Colors.white.withValues(alpha: 0.02),
            Colors.white.withValues(alpha: specular * 0.55),
          ],
          const [0, 0.35, 0.65, 1],
        ),
    );
  }

  @override
  bool shouldRepaint(_RimPainter old) => old.specular != specular || old.stroke != stroke || old.radius != radius;
}

class _FrostBar extends StatelessWidget {
  const _FrostBar({required this.selected, required this.minimized, required this.onSelect});
  final int selected;
  final bool minimized;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final h = minimized ? 50.0 : 64.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: h,
        child: _FrostPanel(
          radius: BorderRadius.circular(h / 2),
          sigma: 16, // T3 blur 10 + 6
          fill: const Color(0x0FFFFFFF),
          specular: 0.40,
          child: Row(
            children: [
              for (var i = 0; i < 4; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == selected,
                    label: _GlassGateScreenState._labels[i],
                    excludeSemantics: true,
                    child: InkWell(
                      key: ValueKey('tab-$i'),
                      focusColor: const Color(0x66FFFFFF),
                      customBorder: const StadiumBorder(),
                      onTap: () => onSelect(i),
                      child: Center(
                        child: IconTheme(
                          data: IconThemeData(color: i == selected ? Colors.white : const Color(0xA3FFFFFF)),
                          child: i < 3 ? GlassIcon(_GlassGateScreenState._roles[i], size: 24, selected: i == selected) : const _YouDot(),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FrostSheet extends StatelessWidget {
  const _FrostSheet();
  @override
  Widget build(BuildContext context) => BackdropGroup(
        child: DraggableScrollableSheet(
          minChildSize: 0.5,
          maxChildSize: 0.94,
          snap: true,
          snapSizes: const [0.5, 0.94],
          expand: false,
          builder: (context, controller) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _FrostPanel(
              radius: const BorderRadius.vertical(top: Radius.circular(40)),
              sigma: 28, // T4 blur 22 + 6
              fill: const Color(0x851C1C22),
              specular: 0.30,
              child: ListView.builder(
                controller: controller,
                itemExtent: 56,
                itemCount: 30,
                itemBuilder: (_, i) => Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Text('Row ${i + 1}', style: _sans(17, 22))),
                ),
              ),
            ),
          ),
        ),
      );
}
