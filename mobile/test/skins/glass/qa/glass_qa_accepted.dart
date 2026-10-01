// ignore_for_file: require_trailing_commas, avoid_redundant_argument_values, prefer_const_declarations, directives_ordering, prefer_function_declarations_over_variables
import 'glass_audit.dart';

/// An accepted exception: the rule, a screen id (or `*`), a substring of the finder, and the contract section that allows it.
class GlassAccepted {
  const GlassAccepted(this.rule, this.screen, this.finder, this.section, this.reason);
  final String rule;
  final String screen;
  final String finder;
  final String section;
  final String reason;
  bool covers(String screenId, GlassViolation v) => v.rule == rule && (screen == '*' || screen == screenId) && v.finder.contains(finder);
}

const List<GlassAccepted> kGlassQaAccepted = [];
