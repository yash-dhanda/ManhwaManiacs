import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/glass/registry.dart';

import '../../../features/library/shelf_fixtures.dart';
import '../../../screenshots/support/shot_harness.dart';
import '../downloads/downloads_test.dart' show downloadOverrides, savedSeries;
import 'library_rig.dart';

/// The glass budget (glass 2.4.1): the phone case (nav row group, dock + orb, a sheet) reads at most 4 layers and 8 shapes; the tablet
/// case at most 6 layers and 6 shapes. Posters, rows, tiles and cards are content twins and never registered.
void main() {
  setUpAll(loadAppFonts);
  FakeLib lib() => FakeLib(series: [shelfSeries(1), shelfSeries(2), shelfSeries(3)]);

  for (final c in [('/library?sheet=filters', const Size(390, 844), 4, 8), ('/downloads?sheet=save-files', const Size(390, 844), 4, 8), ('/library', const Size(834, 1194), 6, 6)]) {
    testWidgets('${c.$1} at ${c.$2.width.toInt()} stays inside ${c.$3} layers and ${c.$4} shapes', (t) async {
      final rig = await pumpLibrary(t, lib(), start: c.$1, size: c.$2, extra: downloadOverrides([savedSeries('series-1', 'Salt and Iron', 3)]));
      await t.pump(const Duration(milliseconds: 600));
      final r = rig.container.read(glassRegistryProvider);
      // ignore: avoid_print
      print('registry ${c.$1} ${c.$2}: ${r.layers} layers, ${r.shapes} shapes: ${[for (final e in r.entries) '${e.label}/${e.kind.name}/${e.shapes}${e.exempt ? '/exempt' : ''}${e.scrim ? '/scrim' : ''}']}');
      expect(r.layers, lessThanOrEqualTo(c.$3));
      expect(r.shapes, lessThanOrEqualTo(c.$4));
    });
  }
}
