import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/shell/back_order.dart';

void main() {
  test('the highest priority active rule wins', () {
    expect(highestRule([GlassBackRule.selectMode, GlassBackRule.stackOverview]), GlassBackRule.stackOverview);
    expect(highestRule(const []), isNull);
  });

  test('a rule swallows back before anything pops', () {
    final r = resolveBack(rule: GlassBackRule.selectMode, depth: 3, tabIndex: 1);
    expect(r.result, GlassBackResult.handledByRule);
  });

  test('pop when deep, Home from other branch roots, leave from Home root', () {
    expect(resolveBack(rule: null, depth: 2, tabIndex: 2).result, GlassBackResult.popped);
    expect(resolveBack(rule: null, depth: 0, tabIndex: 2).result, GlassBackResult.goHome);
    expect(resolveBack(rule: null, depth: 0, tabIndex: 0).result, GlassBackResult.leaveApp);
  });
}
