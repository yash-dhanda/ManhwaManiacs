// ignore_for_file: directives_ordering, require_trailing_commas, prefer_const_constructors, avoid_redundant_argument_values, unnecessary_lambdas, unnecessary_await_in_return
import 'qa_audit.dart';

/// An exception to a QA rule, allowed by a section of `cinematic/DESIGN.md`. A violation is dropped
/// when its [rule] matches and its `finder` or `measured` text contains [match]; [screen] (a
/// `ScreenId.id`) narrows it. Every entry names the contract section that allows it.
class QaAccepted {
  const QaAccepted(this.rule, this.match, this.section, this.reason, {this.screen});
  final String rule;
  final String match;
  final String? screen;
  final String section;
  final String reason;

  bool covers(String screenId, QaViolation v) =>
      v.rule == rule && (screen == null || screen == screenId) && ('${v.finder} ${v.measured}').contains(match);
}

const List<QaAccepted> kQaAccepted = [
  QaAccepted(QaRule.textFloor, '10.0 px', 'cinematic/DESIGN.md 3.3 type table', '`type.nav` (tab bar) and `type.micro` (badges, kickers in fixed cells) are 10 px at phone scale by contract; 3.3 caps fixed-cell labels "never below 10 px".'),
  QaAccepted(QaRule.textFloor, '9.4 px', 'cinematic/DESIGN.md 3.3 literal sizes (superscript counts) and 7.5', 'The Numbers footnote numerals are raised folio marks at 0.72 x the caption size; the contract lists superscript counts as literal sizes outside the role floor.', screen: 'numbers'),
];

/// C6: paragraphs the contract keeps to one line and clips at large text (a match on the text).
class QaTruncation {
  const QaTruncation(this.match, this.section, this.reason);
  final String match;
  final String section;
  final String reason;
}

const List<QaTruncation> kQaTruncations = [
  QaTruncation('Search every source', 'cinematic/DESIGN.md 7.4', 'The index search placeholder is one typed line (typed at 50 ms per character); it never wraps.'),
  QaTruncation('Search what a character said', 'cinematic/DESIGN.md 7.4', 'The Dialogue search placeholder is one typed line.'),
  QaTruncation('NO. 10', 'cinematic/DESIGN.md 3.3 (slug lines)', 'Kicker slug lines are one line: `NO. 10 - THE NUMBERS` clips at 2.0 instead of wrapping.'),
  QaTruncation('chapters ·', 'cinematic/DESIGN.md 9.2 (chart readout)', 'The chart readout line is one line of folio type.'),
];
