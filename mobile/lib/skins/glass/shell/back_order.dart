/// The Android back order of glass 8.0.5, top to bottom. Each rule is a `PopScope(canPop: false, onPopInvokedWithResult:)` owned by
/// the component in that state, so the system shows no predictive preview while one applies; a test pumps each state the shell owns.
///
/// 1. text selected: clear the selection
/// 2. anchored picker, menu or context menu open: close it (`mobile/27` popup routes)
/// 3. stack overview open: close it
/// 4. a share side flipped (`mobile/42`)
/// 5. bulk select mode: exit (`mobile/28`)
/// 6. dialogue overlay or hit lens
/// 7. guided view
/// 8. cinema mode (readers)
/// 9. Settings search overlay (`mobile/39`)
/// 10. otherwise pop (sheets and alerts first)
///
/// Tab roots: back on a non-Home branch root goes to Home; back on Home's root leaves the app.
enum GlassBackRule {
  textSelection,
  anchoredPopup,
  stackOverview,
  shareFlip,
  selectMode,
  dialogueOverlay,
  guidedView,
  cinema,
  settingsSearch,
  pop,
}

enum GlassBackResult { handledByRule, popped, goHome, leaveApp }

/// What a back press does on [tabIndex]'s stack: pop when the stack has depth, go to Home from another branch root, leave the app
/// from Home's root. [rule] is the highest-priority active rule, or null.
({GlassBackResult result, GlassBackRule? rule}) resolveBack({required GlassBackRule? rule, required int depth, required int tabIndex}) {
  if (rule != null && rule != GlassBackRule.pop) return (result: GlassBackResult.handledByRule, rule: rule);
  if (depth > 0) return (result: GlassBackResult.popped, rule: GlassBackRule.pop);
  if (tabIndex != 0) return (result: GlassBackResult.goHome, rule: null);
  return (result: GlassBackResult.leaveApp, rule: null);
}

/// The highest-priority rule among [active] (lowest index wins).
GlassBackRule? highestRule(Iterable<GlassBackRule> active) {
  GlassBackRule? best;
  for (final r in active) {
    if (best == null || r.index < best.index) best = r;
  }
  return best;
}
