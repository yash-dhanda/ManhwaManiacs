import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_badge.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rating_descriptors.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/rating_card_slot.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The rating card (cinematic 7.24, 8.33.5): a 20 px certificate, `18+` in `typeKicker` and the
/// descriptors in `typeCaption` `ink.60`, inside a `paper.0` box so text never sits on art.
/// Fades in over 480 ms `settle`, holds 3000 ms, fades out over 240 ms `lift`; informational only,
/// announced once. Reduced motion: 150 ms fades. [frozen] paints a fixed opacity (gallery).
class CineRatingCard extends StatefulWidget {
  const CineRatingCard({super.key, required this.genres, this.frozen, this.onDone, this.announce = true});
  final List<String> genres;
  final double? frozen;
  final VoidCallback? onDone;
  final bool announce;

  @override
  State<CineRatingCard> createState() => _CineRatingCardState();
}

class _CineRatingCardState extends State<CineRatingCard> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || widget.frozen != null) return;
    _started = true;
    final reduced = CineMotion.reduced(context);
    if (widget.announce) {
      // ignore: deprecated_member_use
      unawaited(SemanticsService.announce(ratingAnnouncement(widget.genres), Directionality.of(context)));
    }
    unawaited(_run(reduced));
  }

  Future<void> _run(bool reduced) async {
    final inD = reduced ? CineDur.reduced : CineDur.spread;
    final outD = reduced ? CineDur.reduced : CineDur.line;
    _c.duration = inD;
    await _c.forward(from: 0);
    await Future<void>.delayed(CineDur.holdRating);
    if (!mounted) return;
    _c.duration = outD;
    await _c.reverse(from: 1);
    if (mounted) widget.onDone?.call();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final reduced = CineMotion.reduced(context);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final v = widget.frozen ?? (_c.status == AnimationStatus.reverse
            ? 1 - CineCurves.lift.transform(1 - _c.value)
            : (reduced ? _c.value : CineCurves.settle.transform(_c.value)));
        return Opacity(opacity: v.clamp(0.0, 1.0), child: child);
      },
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(color: c.colorPaper0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              CineBadge.certificate(large: true),
              SizedBox(width: c.space2),
              CineRoleText('18+', c.typeKicker),
              SizedBox(width: c.space2),
              Flexible(child: CineRoleText(ratingDescriptorLine(widget.genres), c.typeCaption, color: c.colorInk60)),
            ],),
          ),
        ),
      ),
    );
  }
}

/// Shows the rating card in the shell's rating-card slot; it removes itself when it has faded.
void showMatureRatingCard(WidgetRef ref, {required List<String> genres}) {
  showRatingCard(ref, CineRatingCard(genres: genres, onDone: () => hideRatingCard(ref)));
}
