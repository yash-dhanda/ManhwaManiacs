// ignore_for_file: directives_ordering, require_trailing_commas, prefer_const_constructors, avoid_redundant_argument_values, unnecessary_lambdas, unnecessary_await_in_return, avoid_print
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
