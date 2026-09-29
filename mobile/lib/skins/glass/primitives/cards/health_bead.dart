import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';

/// A source's health (`capabilities.md` 16.1 `health.status`).
enum GlassSourceHealth {
  ok('working'),
  failing('having trouble'),
  dead('not working'),
  unknown('not checked yet');

  const GlassSourceHealth(this.spoken);
  final String spoken;

  Color get color => switch (this) {
        GlassSourceHealth.ok => gt.colorSuccess,
        GlassSourceHealth.failing => gt.colorWarning,
        GlassSourceHealth.dead => gt.colorDanger,
        GlassSourceHealth.unknown => GlassColors.g600,
      };
}

/// The 10 px health bead of a source row (glass 7.7), a content twin: `success`, `warning`, `danger` or
/// `g600`; a 1 px `warning` ring when the source is demoted. The semantics text carries the status, and
/// ", skipped by search" when demoted.
class GlassHealthBead extends StatelessWidget {
  const GlassHealthBead({super.key, required this.status, this.demoted = false});
  final GlassSourceHealth status;
  final bool demoted;

  String get semanticsText => demoted ? '${status.spoken}, skipped by search' : status.spoken;

  @override
  Widget build(BuildContext context) => Semantics(
        label: semanticsText,
        image: true,
        child: ExcludeSemantics(
          child: Container(
            width: demoted ? 12 : 10,
            height: demoted ? 12 : 10,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, border: demoted ? Border.all(color: gt.colorWarning) : null),
            child: Container(width: 10, height: 10, decoration: BoxDecoration(color: status.color, shape: BoxShape.circle)),
          ),
        ),
      );
}
