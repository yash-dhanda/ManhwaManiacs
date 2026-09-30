import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/splash/glass_mark.dart';

/// True only when all 36 Glass preview frames (`mobile/assets/skin_previews/glass/000.png` to `035.png`) exist; `mobile/39`
/// captures them. While false the Glass card shows the neutral mark centred on the brand aurora.
const bool kGlassPreviewFramesBundled = false;

/// The looping preview of a skin (glass 8.7, step 2): precaches and plays `assets/skin_previews/{skin}/000.png` to `035.png`, one
/// frame every 166 ms through a `Ticker` with `gaplessPlayback`, only while visible. Under reduced motion it shows frame 0 with a
/// plain "Play preview" that plays the loop once. `mobile/39` reuses it.
class GlassSkinPreviewLoop extends ConsumerStatefulWidget {
  const GlassSkinPreviewLoop({super.key, required this.skin, this.height = 180, this.frameCount = 36});
  final String skin;
  final double height;
  final int frameCount;

  @override
  ConsumerState<GlassSkinPreviewLoop> createState() => _GlassSkinPreviewLoopState();
}

class _GlassSkinPreviewLoopState extends ConsumerState<GlassSkinPreviewLoop> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  int _frame = 0;
  bool _once = false;
  static const int _frameMs = 166;

  bool get _bundled => widget.skin == 'cinematic' || kGlassPreviewFramesBundled;

  String _path(int i) => 'assets/skin_previews/${widget.skin}/${i.toString().padLeft(3, '0')}.png';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bundled) {
      for (var i = 0; i < widget.frameCount; i++) {
        precacheImage(AssetImage(_path(i)), context, onError: (_, __) {});
      }
    }
    _sync();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _sync() {
    final reduced = ref.read(glassReducedProvider);
    final visible = TickerMode.valuesOf(context).enabled;
    if (!_bundled || reduced && !_once || !visible) {
      _ticker.stop();
      return;
    }
    if (!_ticker.isActive) _ticker.start();
  }

  void _onTick(Duration d) {
    final f = d.inMilliseconds ~/ _frameMs;
    final n = f % widget.frameCount;
    if (_once && f >= widget.frameCount) {
      _once = false;
      _ticker.stop();
      setState(() => _frame = 0);
      return;
    }
    if (n != _frame) setState(() => _frame = n);
  }

  void _playOnce() {
    _once = true;
    _ticker.stop();
    _ticker.start();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = ref.watch(glassReducedProvider);
    return SizedBox(
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_bundled)
            Image.asset(_path(reduced && !_once ? 0 : _frame), fit: BoxFit.cover, gaplessPlayback: true, errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF131317)))
          else
            DecoratedBox(
              decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [gt.colorAurora1.withValues(alpha: 0.35), gt.colorAurora2.withValues(alpha: 0.35), gt.colorAurora3.withValues(alpha: 0.35)])),
              child: const Center(child: GlassMark(height: 56)),
            ),
          if (reduced && _bundled && !_once)
            Positioned(
              right: 8,
              bottom: 8,
              child: GestureDetector(
                onTap: _playOnce,
                child: Semantics(button: true, label: 'Play preview', child: const Text('Play preview', style: TextStyle(color: Color(0xFFF5F7FA), fontSize: 13, decoration: TextDecoration.none))),
              ),
            ),
        ],
      ),
    );
  }
}
