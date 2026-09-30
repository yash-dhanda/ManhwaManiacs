import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/shell/depth_stack.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart';

void main() {
  test('depth counts levels above the tab root and weighs at most 4', () {
    final d = GlassDepthStack();
    for (var i = 0; i < 6; i++) {
      d.push(GlassTab.home, 'r$i');
    }
    expect(d.depthOf(GlassTab.home), 6);
    expect(d.weighed(GlassTab.home), 4);
    expect(d.depthOf(GlassTab.library), 0);
  });

  test('popsTo gives the pops needed for a picked level', () {
    final d = GlassDepthStack()
      ..push(GlassTab.you, 'a')
      ..push(GlassTab.you, 'b')
      ..push(GlassTab.you, 'c');
    expect(d.popsTo(GlassTab.you, 'c'), 0);
    expect(d.popsTo(GlassTab.you, 'a'), 2);
    expect(d.popsTo(GlassTab.you, null), 3);
    expect(d.popsTo(GlassTab.you, 'zzz'), isNull);
  });

  test('pop and clear', () {
    final d = GlassDepthStack()..push(GlassTab.home, 'a');
    d.pop(GlassTab.home, 'a');
    expect(d.depthOf(GlassTab.home), 0);
    d.push(GlassTab.home, 'b');
    d.clear();
    expect(d.depthOf(GlassTab.home), 0);
  });
}
