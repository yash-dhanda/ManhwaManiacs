import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart' show CineColors;
import 'package:manhwamaniacs/skins/glass/tokens.g.dart' show GlassColors;

/// The phone the miniature is laid out on (logical px), and its aspect ratio for the hosts' frames.
const Size kSkinPreviewSize = Size(390, 844);
const double kSkinPreviewAspect = 390 / 844;

/// One there-and-back pass of the miniature's scroll.
const Duration kSkinPreviewCycle = Duration(seconds: 10);

/// How far down the miniature is scrolled (0 top, 1 bottom) at cycle phase [t]: a cosine there and back, so the motion is
/// continuous with no hard stops.
double skinPreviewDepth(double t) => (1 - math.cos(2 * math.pi * t)) / 2;

/// A live miniature of a skin's Home ('cinematic' or 'glass'): a real widget tree laid out on a 390 x 844 phone with its own
/// MediaQuery, scaled into the box by a [FittedBox] and scrolled by one [AnimationController] every vsync. No blur, grain or
/// shaders inside, no images to decode. The controller runs only while [play] is true, the route is visible ([TickerMode]),
/// the box is inside the screen and the app is in the foreground (no frames are scheduled in the background). [play] false shows
/// the top, still: hosts pass it for Reduce Motion. [once] plays one pass and calls [onDone].
class SkinPreview extends StatefulWidget {
  const SkinPreview({super.key, required this.skin, this.play = true, this.once = false, this.onDone, this.fit = BoxFit.contain});
  final String skin;
  final bool play, once;
  final VoidCallback? onDone;
  final BoxFit fit;

  @override
  State<SkinPreview> createState() => _SkinPreviewState();
}

class _SkinPreviewState extends State<SkinPreview> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: kSkinPreviewCycle)..addStatusListener(_status);
  ScrollPosition? _host;
  bool _onScreen = true;

  bool get _glass => widget.skin == 'glass';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkOnScreen();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _host?.removeListener(_checkOnScreen);
    _host = Scrollable.maybeOf(context)?.position;
    _host?.addListener(_checkOnScreen);
    _sync();
  }

  @override
  void didUpdateWidget(SkinPreview old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _host?.removeListener(_checkOnScreen);
    _c.dispose();
    super.dispose();
  }

  void _status(AnimationStatus s) {
    if (s == AnimationStatus.completed && widget.once) widget.onDone?.call();
  }

  void _checkOnScreen() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return;
    final top = box.localToGlobal(Offset.zero).dy;
    final on = top < MediaQuery.sizeOf(context).height && top + box.size.height > 0;
    if (on != _onScreen) {
      _onScreen = on;
      _sync();
    }
  }

  void _sync() {
    if (!widget.play) {
      _c
        ..stop()
        ..value = 0;
    } else if (!_onScreen) {
      _c.stop(); // keeps the phase
    } else if (!_c.isAnimating && !(widget.once && _c.isCompleted)) {
      widget.once ? _c.forward(from: 0) : _c.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = _glass ? GlassColors.g50 : CineColors.paper0;
    final mq = MediaQuery.maybeOf(context);
    final body = RepaintBoundary(child: _glass ? const _GlassBody() : const _CineBody());
    // The page scrolls between its fixed bars; the content is one cached layer that only moves.
    final page = ClipRect(
      child: AnimatedBuilder(
        animation: _c,
        child: body,
        builder: (_, child) => OverflowBox(
          alignment: Alignment(0, 2 * skinPreviewDepth(_c.value) - 1),
          minHeight: 0,
          maxHeight: double.infinity,
          child: child,
        ),
      ),
    );
    return ExcludeSemantics(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: ColoredBox(
            color: bg,
            child: ClipRect(
              child: FittedBox(
                fit: widget.fit,
                child: SizedBox.fromSize(
                  size: kSkinPreviewSize,
                  child: MediaQuery(
                    data: MediaQueryData(
                      size: kSkinPreviewSize,
                      devicePixelRatio: mq?.devicePixelRatio ?? 3,
                      padding: const EdgeInsets.only(top: 47, bottom: 34),
                      viewPadding: const EdgeInsets.only(top: 47, bottom: 34),
                      disableAnimations: true,
                    ),
                    child: DefaultTextStyle(
                      style: const TextStyle(decoration: TextDecoration.none, height: 1.25),
                      child: ColoredBox(
                        color: bg,
                        child: Column(children: [
                          if (_glass) const _GlassTop() else const _CineTop(),
                          Expanded(child: page),
                          if (_glass) const _GlassDock() else const _CineTabs(),
                        ],),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @visibleForTesting
  AnimationController get controller => _c;
}

TextStyle _t(String family, double size, double wght, Color color, {bool italic = false, double track = 0, double? height}) => TextStyle(
      fontFamily: family,
      fontSize: size,
      fontWeight: FontWeight.values[((wght / 100).round() - 1).clamp(0, 8)],
      fontVariations: [FontVariation('wght', wght)],
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      letterSpacing: track * size,
      height: height,
      color: color,
      decoration: TextDecoration.none,
    );

/// Painted cover art: two-colour gradients, no titles baked in.
const _art = [
  [Color(0xFF3B1E54), Color(0xFFD9775B)],
  [Color(0xFF0F3D4C), Color(0xFF7FD1C7)],
  [Color(0xFF4A1426), Color(0xFFE8B04E)],
  [Color(0xFF1C2541), Color(0xFF8E9AF2)],
  [Color(0xFF2D3A1F), Color(0xFFC9D27A)],
  [Color(0xFF3A1010), Color(0xFFFF8A65)],
];

class _Art extends StatelessWidget {
  const _Art(this.seed, {this.radius = 0});
  final int seed;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = _art[seed % _art.length];
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius == 0 ? null : BorderRadius.circular(radius),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: c),
      ),
      child: const SizedBox.expand(),
    );
  }
}

// --- Cinematic -------------------------------------------------------------------------------------------------------------

const _bodoni = 'BodoniModa', _archivo = 'Archivo', _news = 'Newsreader', _mono = 'IBMPlexMono';

TextStyle _kicker(Color c) => _t(_archivo, 12, 700, c, track: 0.16).copyWith(fontVariations: const [FontVariation('wght', 700), FontVariation('wdth', 62)]);

class _CineTop extends StatelessWidget {
  const _CineTop();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 47, 16, 0),
        height: 47 + 48,
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: CineColors.rule1))),
        child: Row(children: [
          Text('TONIGHT', style: _kicker(CineColors.ink100)),
          const Spacer(),
          Text('FRI 2 OCT', style: _t(_mono, 12, 500, CineColors.ink60)),
        ],),
      );
}

class _CineTabs extends StatelessWidget {
  const _CineTabs();

  @override
  Widget build(BuildContext context) => Container(
        height: 56 + 34,
        padding: const EdgeInsets.only(bottom: 34),
        decoration: const BoxDecoration(color: CineColors.paper0, border: Border(top: BorderSide(color: CineColors.rule1))),
        child: Row(children: [
          for (final (i, l) in const ['TONIGHT', 'LIBRARY', 'DISCOVER', 'YOU'].indexed)
            Expanded(child: Center(child: Text(l, style: _kicker(i == 0 ? CineColors.spot : CineColors.ink60).copyWith(fontSize: 11)))),
        ],),
      );
}

class _CineHead extends StatelessWidget {
  const _CineHead(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 28, bottom: 14),
        padding: const EdgeInsets.only(top: 10),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: CineColors.rule2))),
        child: Text(label, style: _kicker(CineColors.ink60)),
      );
}

class _CineBody extends StatelessWidget {
  const _CineBody();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          AspectRatio(
            aspectRatio: 4 / 5,
            child: Stack(fit: StackFit.expand, children: [
              const _Art(0),
              const DecoratedBox(
                decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: [0.35, 1], colors: [Color(0x00000000), Color(0xE6000000)])),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 18,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('CHAPTER 143 · NEW', style: _kicker(CineColors.spot)),
                  const SizedBox(height: 8),
                  Text('The Lantern Courier', maxLines: 2, style: _t(_bodoni, 34, 700, CineColors.ink100, height: 1.05, track: -0.03)),
                  const SizedBox(height: 14),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: CineColors.spot,
                      child: Text('Continue', style: _t(_archivo, 15, 600, CineColors.paper0)),
                    ),
                    const SizedBox(width: 14),
                    Text('CH 143 · 9 MIN', style: _t(_mono, 12, 500, CineColors.ink80)),
                  ],),
                ],),
              ),
            ],),
          ),
          const _CineHead('PREVIOUSLY ON'),
          Text(
            'Mara reached the far bank with the last sealed letter, and the lighthouse went dark behind her.',
            style: _t(_news, 17, 400, CineColors.ink80, height: 1.4),
          ),
          const _CineHead('ON YOUR SHELF'),
          Row(children: [
            for (final (i, title) in const ['Paper Tiger', 'Ninth Moon', 'Saltglass'].indexed) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  AspectRatio(aspectRatio: 2 / 3, child: _Art(i + 1)),
                  const SizedBox(height: 8),
                  Text(title, maxLines: 1, style: _t(_news, 14, 500, CineColors.ink100)),
                  Text('CH ${[88, 12, 240][i]}', style: _t(_mono, 11, 500, CineColors.ink45)),
                ],),
              ),
            ],
          ],),
          const _CineHead('NEW THIS WEEK'),
          for (final (i, (title, line)) in const [('Iron Orchard', 'CH 57 · 2 H AGO'), ('The Quiet Fleet', 'CH 19 · 5 H AGO'), ('Hollow Crown', 'CH 101 · YESTERDAY')].indexed)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(border: i == 0 ? null : const Border(top: BorderSide(color: CineColors.rule1))),
              child: Row(children: [
                SizedBox(width: 48, height: 64, child: _Art(i + 3)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, maxLines: 1, style: _t(_archivo, 16, 600, CineColors.ink100)),
                    const SizedBox(height: 4),
                    Text(line, maxLines: 1, style: _t(_mono, 11, 500, CineColors.ink60)),
                  ],),
                ),
              ],),
            ),
        ],),
      );
}

// --- Glass -----------------------------------------------------------------------------------------------------------------

const _flex = 'GoogleSansFlexMM';

class _GlassTop extends StatelessWidget {
  const _GlassTop();

  @override
  Widget build(BuildContext context) => Container(
        height: 47 + 56,
        padding: const EdgeInsets.fromLTRB(20, 47, 20, 0),
        decoration: BoxDecoration(
          gradient: RadialGradient(center: const Alignment(-0.6, -1.4), radius: 1.6, colors: [GlassColors.aurora2.withValues(alpha: 0.28), GlassColors.g50]),
        ),
        child: Row(children: [
          Text('Home', style: _t(_flex, 32, 700, GlassColors.label1, track: -0.02)),
          const Spacer(),
          const SizedBox.square(
            dimension: 36,
            child: DecoratedBox(
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [GlassColors.aurora1, GlassColors.aurora2, GlassColors.aurora3])),
            ),
          ),
        ],),
      );
}

class _GlassDock extends StatelessWidget {
  const _GlassDock();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 34),
        child: Container(
          height: 60,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: GlassColors.g150, borderRadius: BorderRadius.circular(30), border: Border.all(color: const Color(0x1FFFFFFF))),
          child: Row(children: [
            for (final (i, l) in const ['Home', 'Library', 'Search', 'You'].indexed)
              Expanded(
                child: Container(
                  alignment: Alignment.center,
                  decoration: i == 0 ? BoxDecoration(color: GlassColors.fill2, borderRadius: BorderRadius.circular(24)) : null,
                  child: Text(l, style: _t(_flex, 13, 600, i == 0 ? GlassColors.iris300 : GlassColors.label2)),
                ),
              ),
          ],),
        ),
      );
}

class _GlassTitle extends StatelessWidget {
  const _GlassTitle(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 28, 4, 12),
        child: Text(label, style: _t(_flex, 22, 650, GlassColors.label1, track: -0.01)),
      );
}

class _GlassBody extends StatelessWidget {
  const _GlassBody();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          AspectRatio(
            aspectRatio: 4 / 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Stack(fit: StackFit.expand, children: [
                const _Art(3),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xB3131317), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0x24FFFFFF))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Ninth Moon Atlas', maxLines: 1, style: _t(_flex, 24, 700, GlassColors.label1, track: -0.01)),
                      const SizedBox(height: 4),
                      Text('Chapter 42 · 12 min left', maxLines: 1, style: _t(_flex, 15, 450, GlassColors.label2)),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(color: GlassColors.iris500, borderRadius: BorderRadius.circular(20)),
                        child: Text('Continue', style: _t(_flex, 15, 650, GlassColors.onTint)),
                      ),
                    ],),
                  ),
                ),
              ],),
            ),
          ),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < 3; i++)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == 0 ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(color: i == 0 ? GlassColors.label1 : GlassColors.label4, borderRadius: BorderRadius.circular(3)),
              ),
          ],),
          const _GlassTitle('Continue reading'),
          Row(children: [
            for (final (i, (title, p)) in const [('Paper Tiger', 0.7), ('Saltglass', 0.35), ('Iron Orchard', 0.9)].indexed) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  AspectRatio(aspectRatio: 2 / 3, child: _Art(i, radius: 16)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: SizedBox(
                      height: 4,
                      child: Row(children: [
                        Expanded(flex: (p * 100).round(), child: const ColoredBox(color: GlassColors.iris500)),
                        Expanded(flex: 100 - (p * 100).round(), child: const ColoredBox(color: GlassColors.fill3)),
                      ],),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(title, maxLines: 1, style: _t(_flex, 14, 600, GlassColors.label1)),
                ],),
              ),
            ],
          ],),
          const _GlassTitle('New chapters'),
          Container(
            decoration: BoxDecoration(color: GlassColors.surface1, borderRadius: BorderRadius.circular(22)),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(children: [
              for (final (i, (title, line)) in const [('The Quiet Fleet', 'Chapter 19 · 2 h ago'), ('Hollow Crown', 'Chapter 101 · 5 h ago'), ('Lantern Courier', 'Chapter 143 · Yesterday')].indexed)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(border: i == 0 ? null : const Border(top: BorderSide(color: GlassColors.separator, width: 0.5))),
                  child: Row(children: [
                    SizedBox(width: 44, height: 58, child: _Art(i + 2, radius: 8)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(title, maxLines: 1, style: _t(_flex, 16, 600, GlassColors.label1)),
                        const SizedBox(height: 3),
                        Text(line, maxLines: 1, style: _t(_flex, 13, 450, GlassColors.label2)),
                      ],),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: GlassColors.iris500.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(12)),
                      child: Text('New', style: _t(_flex, 12, 650, GlassColors.iris300)),
                    ),
                  ],),
                ),
            ],),
          ),
        ],),
      );
}
