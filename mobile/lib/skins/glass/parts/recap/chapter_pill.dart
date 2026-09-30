import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/recap/models/recap_models.dart'
    show RecapKey;
import 'package:manhwamaniacs/features/recap/providers/recap_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/ai/machine_badge.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/routes/nav_extra.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// Projection past this many px upward dismisses the pill.
const double kPillSwipePx = 24;
const Duration kPillShown = Duration(seconds: 6);

/// The reader's "Previously · 20 s" pill (glass 9.1.3): a `glassThin` capsule at the top centre for 6 s. A tap opens the compact recap
/// (`scope=chapter`); a swipe up dismisses it. Shown by the readers' top-centre pill slot after `chapterPillDecision` said yes.
class RecapChapterPill extends ConsumerStatefulWidget {
  const RecapChapterPill(
      {super.key,
      required this.sourceId,
      required this.seriesKey,
      required this.chapterKey,
      this.onGone,});
  final String sourceId, seriesKey, chapterKey;
  final VoidCallback? onGone;

  @override
  ConsumerState<RecapChapterPill> createState() => _RecapChapterPillState();
}

class _RecapChapterPillState extends ConsumerState<RecapChapterPill> {
  Timer? _t;
  bool _gone = false;
  double _dy = 0;

  @override
  void initState() {
    super.initState();
    _t = Timer(kPillShown, _leave);
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  void _leave() {
    if (_gone || !mounted) return;
    setState(() => _gone = true);
    widget.onGone?.call();
  }

  void _open() {
    _leave();
    unawaited(ref.read(skinRouterProvider).push<void>(
        Routes.recap(widget.sourceId, widget.seriesKey,
            {'to': widget.chapterKey, 'scope': 'chapter'},),
        extra: const GlassNavExtra(),),);
  }

  @override
  Widget build(BuildContext context) {
    if (_gone) return const SizedBox.shrink();
    final est = ref
            .watch(recapAvailabilityProvider(
                RecapKey(widget.sourceId, widget.seriesKey, widget.chapterKey),),)
            .valueOrNull
            ?.estSeconds ??
        20;
    final hit = GlassFrame.hitMin(context);
    return Transform.translate(
      offset: Offset(0, _dy),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _open,
        onVerticalDragUpdate: (d) =>
            setState(() => _dy = (_dy + d.delta.dy).clamp(-60.0, 0.0)),
        onVerticalDragEnd: (_) =>
            _dy <= -kPillSwipePx ? _leave() : setState(() => _dy = 0),
        child: Semantics(
          button: true,
          label: 'Previously, $est seconds, suggested by AI',
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: hit),
            child: DecoratedBox(
              decoration: BoxDecoration(
                  color: gt.colorSurface1.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: gt.colorMachineRim, width: 0.5),),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const MachineBadge(),
                  const SizedBox(width: 6),
                  GlassText('Previously · $est s',
                      role: gt.typeCaption1, wght: 600, onGlass: true,),
                ],),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
