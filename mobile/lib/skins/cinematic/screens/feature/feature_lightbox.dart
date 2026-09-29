import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_states.dart';

/// The cover Lightbox (§7.30): contain fit on `colorLightbox`, pinch to zoom
/// (1x to 4x), double tap 1x/2.5x, drag down past 120 px (or fling) to dismiss,
/// `x`, back and Esc close. TODO(mobile/06): the Hero match and Arm timings.
Future<void> showCoverLightbox(BuildContext context,
    {required String imageUrl, required String title,}) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      transitionDuration: MediaQuery.disableAnimationsOf(context)
          ? const Duration(milliseconds: 150)
          : const Duration(milliseconds: 480),
      reverseTransitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, a, b) =>
          FadeTransition(opacity: a, child: _Lightbox(url: imageUrl, title: title)),
    ),
  );
}

class _Lightbox extends StatefulWidget {
  const _Lightbox({required this.url, required this.title});
  final String url;
  final String title;

  @override
  State<_Lightbox> createState() => _LightboxState();
}

class _LightboxState extends State<_Lightbox> {
  final _ctl = TransformationController();
  double _dy = 0;
  Offset _tap = Offset.zero;
  bool _chip = false;

  bool get _atRest => _ctl.value.getMaxScaleOnAxis() <= 1.001;

  void _doubleTap() {
    if (_atRest) {
      _ctl.value = Matrix4.identity()
        ..translateByDouble(-_tap.dx * 1.5, -_tap.dy * 1.5, 0, 1)
        ..scaleByDouble(2.5, 2.5, 1, 1);
      setState(() => _chip = true);
      Future<void>.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _chip = false);
      });
    } else {
      _ctl.value = Matrix4.identity();
    }
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = cineOf(context);
    final fade = (1 - (_dy.abs() / 400)).clamp(0.0, 1.0);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.of(context).maybePop(),
      },
      child: Focus(
        autofocus: true,
        child: Stack(
          children: [
            Positioned.fill(
                child:
                    ColoredBox(color: t.colorLightbox.withValues(alpha: t.colorLightbox.a * fade)),),
            GestureDetector(
              onDoubleTapDown: (d) => _tap = d.localPosition,
              onDoubleTap: _doubleTap,
              onVerticalDragUpdate: (d) {
                if (_atRest) setState(() => _dy += d.delta.dy);
              },
              onVerticalDragEnd: (d) {
                if (_dy.abs() > 120 || (d.primaryVelocity ?? 0).abs() > 800) {
                  Navigator.of(context).maybePop();
                } else {
                  setState(() => _dy = 0);
                }
              },
              child: Transform.translate(
                offset: Offset(0, _dy),
                child: InteractiveViewer(
                  transformationController: _ctl,
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                      child: Image.network(widget.url,
                          fit: BoxFit.contain, errorBuilder: (c, e, s) => const SizedBox(),),),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              right: 8,
              child: Semantics(
                button: true,
                label: 'Close',
                child: IconButton(
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
            Positioned(
              left: 16,
              bottom: MediaQuery.paddingOf(context).bottom + 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: t.colorPaper1,
                child: Text('${widget.title} · COVER', style: kickerStyle(context)),
              ),
            ),
            if (_chip)
              Positioned(
                top: MediaQuery.paddingOf(context).top + 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: t.colorPaper1,
                  child: Text('250%', style: kickerStyle(context)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
