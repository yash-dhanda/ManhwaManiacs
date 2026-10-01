import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';

/// glass 4.6: the chapter-end pull arms at 48 displayed px and locks the Next card at 72.
const double kChapterArmPx = 48;
const double kChapterLockPx = 72;

/// The pull's events (glass 5.2): `chapter.arm`, `chapter.next` (the lock) and `threshold.back` (back below the lock).
enum ChapterPullEvent { arm, lock, unlock }

/// The arm/lock state of the pull past the chapter's end (D12), fed the displayed overscroll.
class ChapterEndPull {
  bool armed = false, locked = false;

  /// The events crossing to [displayed] px fires.
  List<ChapterPullEvent> update(double displayed) {
    final out = <ChapterPullEvent>[];
    if (!armed && displayed >= kChapterArmPx) {
      armed = true;
      out.add(ChapterPullEvent.arm);
    }
    if (!locked && displayed >= kChapterLockPx) {
      locked = true;
      out.add(ChapterPullEvent.lock);
    } else if (locked && displayed < kChapterLockPx) {
      locked = false;
      out.add(ChapterPullEvent.unlock);
    }
    if (displayed < kChapterArmPx) armed = false;
    return out;
  }

  void reset() => armed = locked = false;
}

/// The inverse of [rubberband] for one sign: the raw distance that displays [shown].
double rubberbandInverse(double shown, double d, double c) {
  final s = shown.clamp(0.0, d * 0.999);
  return (d / c) * (1 / (1 - s / d) - 1);
}

/// The scroll physics of the novel column (D12): past the end the raw drag maps through `rubberband(x, viewport, 0.35)`
/// (`physicsRubberBandChapterC`), so the displayed overscroll is `pixels - maxScrollExtent`. Under reduced motion the end is a hard stop.
class GlassChapterEndPhysics extends BouncingScrollPhysics {
  const GlassChapterEndPhysics({super.parent, this.reduced = false});
  final bool reduced;

  @override
  GlassChapterEndPhysics applyTo(ScrollPhysics? ancestor) => GlassChapterEndPhysics(parent: buildParent(ancestor), reduced: reduced);

  static double get c => glassTokens.physicsRubberBandChapterC;

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    final max = position.maxScrollExtent;
    final next = position.pixels - offset;
    if (offset < 0 && next > max) {
      final d = position.viewportDimension;
      final shown = (position.pixels - max).clamp(0.0, double.infinity);
      final raw = rubberbandInverse(shown, d, c) + (next - (position.pixels > max ? position.pixels : max));
      final displayed = rubberband(raw, d, c);
      final pixelsTo = max + displayed;
      return position.pixels - pixelsTo;
    }
    return super.applyPhysicsToUserOffset(position, offset);
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    if (reduced && value > position.maxScrollExtent && value > position.pixels) return value - position.pixels.clamp(position.maxScrollExtent, double.infinity);
    if (reduced && value < position.minScrollExtent && value < position.pixels) return value - position.pixels.clamp(double.negativeInfinity, position.minScrollExtent);
    return super.applyBoundaryConditions(position, value);
  }
}
