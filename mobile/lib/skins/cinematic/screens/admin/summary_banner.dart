import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/admin/utils/status_summary.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/typed_headline.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/admin/status_card.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The summary: a banner strip on `paper.0`, a 2 px left rule tinted by the worst state, the
/// headline typed at 50 ms per grapheme (whole at once under reduced motion) and the problems.
class SummaryBanner extends StatelessWidget {
  const SummaryBanner({super.key, required this.summary});
  final StatusSummary summary;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Semantics(
      container: true,
      label: '${summary.headline} ${summary.problems.join(' ')}',
      child: Container(
        key: const Key('status-summary'),
        margin: EdgeInsets.only(top: c.space6),
        decoration: BoxDecoration(
          color: c.colorPaper0,
          border: Border(left: BorderSide(color: stateColor(c, summary.worst), width: 2), bottom: c.ruleHair),
        ),
        padding: EdgeInsets.all(c.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TypedHeadline(summary.headline, key: ValueKey(summary.headline), style: CineText.style(context, c.typeSubhead), cap: c.typeSubhead.cap, level: 2),
            for (final p in summary.problems)
              Padding(
                padding: EdgeInsets.only(top: c.space2),
                child: CineRoleText(p, c.typeBody, color: c.colorInk80),
              ),
          ],
        ),
      ),
    );
  }
}
