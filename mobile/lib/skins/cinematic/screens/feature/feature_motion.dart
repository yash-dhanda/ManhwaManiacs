import 'package:manhwamaniacs/skins/cinematic/motion_names.g.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_match_cut_page.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/reader_entry.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// The moves the series page plays and their planned durations, as the
/// motion-timings overlay lists them (DESIGN §4). No row is `proof`.
class FeatureMotionRow {
  const FeatureMotionRow(this.move, this.where, this.plannedMs);
  final MotionName move;
  final String where;
  final int plannedMs;

  @override
  String toString() => '${move.label} · $where · $plannedMs ms';
}

/// TODO(mobile/03): fed to the shared `MotionRecorder` when it lands.
final List<FeatureMotionRow> featureMotionRows = [
  FeatureMotionRow(MotionName.matchCut, 'poster to series page, in', kMatchCutIn.inMilliseconds),
  FeatureMotionRow(MotionName.matchCut, 'series page to poster, out', kMatchCutOut.inMilliseconds),
  FeatureMotionRow(MotionName.dissolve, 'ambient wash', CineDur.dissolve.inMilliseconds),
  FeatureMotionRow(MotionName.letterSet, 'title, per letter', CineDur.letter.inMilliseconds),
  const FeatureMotionRow(MotionName.ruleDraw, 'Book title rule', 480),
  FeatureMotionRow(MotionName.columnWipe, 'Continue, phone (4 blades)', const WipeTimings(4).totalMs),
  FeatureMotionRow(MotionName.columnWipe, 'Continue, tablet (8 blades)', const WipeTimings(8).totalMs),
  FeatureMotionRow(MotionName.drift, 'cover, one cycle', CineDur.drift.inMilliseconds),
  const FeatureMotionRow(MotionName.lightbox, 'cover to Lightbox', 480),
];
