import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart' show SpringCurve;
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';

/// `GoRouterState.extra` for the novel route when the book page opens it: `{'entry': 'book', 'plateRect': Rect, 'cover': ImageProvider,
/// 'paper': Color}` (glass 8.13 Book open; `mobile/36` reuses this page).
Map<String, Object?> bookOpenExtra({required Rect plateRect, ImageProvider? cover, Color? paper}) => {'entry': 'book', 'plateRect': plateRect, 'cover': cover, 'paper': paper};

bool isBookOpenExtra(Object? extra) => extra is Map && extra['entry'] == 'book' && extra['plateRect'] is Rect;

const Duration kBookOpenDuration = Duration(milliseconds: 615);

/// Book open (glass 4.10, 8.13): the plate rotates open on its spine to −78° on `springPage` while a paper layer expands from the plate's
/// rectangle to full screen; the novel route lands underneath. Reduced motion: a 200 ms cross-fade.
class GlassBookOpenPage<T> extends Page<T> {
  const GlassBookOpenPage({super.key, super.name, required this.child, required this.plateRect, this.cover, this.paper = const Color(0xFFF4EEE2), this.reduced = false});
  final Widget child;
  final Rect plateRect;
  final ImageProvider? cover;
  final Color paper;
  final bool reduced;

  @override
  Route<T> createRoute(BuildContext context) => PageRouteBuilder<T>(
        settings: this,
        transitionDuration: reduced ? const Duration(milliseconds: 200) : kBookOpenDuration,
        reverseTransitionDuration: reduced ? const Duration(milliseconds: 200) : kBookOpenDuration,
        pageBuilder: (context, a, s) => child,
        transitionsBuilder: (context, animation, secondary, child) {
          if (reduced) return FadeTransition(opacity: animation, child: child);
          final t = CurvedAnimation(parent: animation, curve: SpringCurve(GlassSprings.page, settleMs: kBookOpenDuration.inMilliseconds));
          return BookOpenTransition(t: t, plateRect: plateRect, cover: cover, paper: paper, child: child);
        },
      );
}

/// The frame of Book open at [t] (0 closed, 1 open).
class BookOpenTransition extends AnimatedWidget {
  const BookOpenTransition({super.key, required Animation<double> t, required this.plateRect, required this.child, this.cover, required this.paper}) : super(listenable: t);
  final Rect plateRect;
  final ImageProvider? cover;
  final Color paper;
  final Widget child;

  double get t => (listenable as Animation<double>).value;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final v = t.clamp(0.0, 1.0);
    final paperRect = Rect.lerp(plateRect, Offset.zero & size, v)!;
    return Stack(
      children: [
        Positioned.fill(child: Opacity(opacity: (v * 1.6 - 0.6).clamp(0.0, 1.0), child: child)),
        Positioned.fromRect(
          rect: paperRect,
          child: IgnorePointer(child: Opacity(opacity: (1 - (v - 0.85) / 0.15).clamp(0.0, 1.0), child: ColoredBox(key: const ValueKey('book-open-paper'), color: paper))),
        ),
        Positioned.fromRect(
          rect: plateRect,
          child: IgnorePointer(
            child: Opacity(
              opacity: (1 - v * 1.2).clamp(0.0, 1.0),
              child: Transform(
                key: const ValueKey('book-open-plate'),
                alignment: Alignment.centerLeft,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 1 / 900)
                  ..rotateY(-78 * math.pi / 180 * v),
                child: cover == null ? const ColoredBox(color: Color(0xFF26262B)) : Image(image: cover!, fit: BoxFit.cover),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
