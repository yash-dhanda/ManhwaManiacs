import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/primitives/stack/route_snapshot.dart';
import 'package:manhwamaniacs/skins/glass/primitives/stack/snapshot_store.dart';

Future<GlassRouteSnapshot> _snap(String key, {bool mature = false, GlassTab tab = GlassTab.home, int depth = 1}) async =>
    GlassRouteSnapshot(routeKey: key, title: key, depth: depth, tab: tab, mature: mature, rimTint: const Color(0xFF8F7EFF), image: await paintedImage(const Size(8, 8), const Color(0xFF223344)));

void main() {
  testWidgets('images are disposed on memory pressure, on drop, on dropMature and on dispose; the records stay after pressure', (tester) async {
    await tester.runAsync(() async {
      final c = ProviderContainer();
      final store = c.read(glassSnapshotStoreProvider.notifier);
      final a = await _snap('a');
      final b = await _snap('b', mature: true, depth: 2);
      final d = await _snap('d', depth: 3);
      final e = await _snap('e', tab: GlassTab.library);
      for (final s in [a, b, d, e]) {
        store.put(s);
      }
      expect(store.levels(GlassTab.home).map((s) => s.routeKey), ['a', 'b', 'd']);
      expect(store.has('a'), isTrue);

      store.dropMature();
      expect(b.image!.debugDisposed, isTrue);
      expect(c.read(glassSnapshotStoreProvider).containsKey('b'), isFalse);

      store.drop('d');
      expect(d.image!.debugDisposed, isTrue);

      TestWidgetsFlutterBinding.instance.handleMemoryPressure();
      expect(a.image!.debugDisposed, isTrue);
      expect(e.image!.debugDisposed, isTrue);
      final state = c.read(glassSnapshotStoreProvider);
      expect(state.keys.toSet(), {'a', 'e'}, reason: 'the records stay');
      expect(state['a']!.image, isNull);
      expect(store.has('a'), isFalse);

      final f = await _snap('f');
      store.put(f);
      c.dispose();
      expect(f.image!.debugDisposed, isTrue);
    });
  });

  testWidgets('captureRouteSnapshot renders the boundary once at half resolution and returns null when nothing is painted', (tester) async {
    final key = GlobalKey();
    expect(await captureRouteSnapshot(key), isNull);
    await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr, child: Center(child: SnapshotBoundary(boundaryKey: key, child: const SizedBox(width: 200, height: 100, child: ColoredBox(color: Color(0xFFFF0000)))))));
    late ui.Image? img;
    await tester.runAsync(() async => img = await captureRouteSnapshot(key));
    expect(img, isNotNull);
    expect(img!.width, 100);
    expect(img!.height, 50);
    img!.dispose();
  });
}
