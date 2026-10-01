import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/models/source_health.dart';
import 'package:manhwamaniacs/features/sources/models/source_pin.dart';
import 'package:manhwamaniacs/features/sources/providers/discover_providers.dart';
import 'package:manhwamaniacs/features/sources/providers/source_pins_provider.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/skins/glass/screens/sources/sources_screen.dart';

import '../shell/shell_rig.dart';

class _Pins extends SourcePinsNotifier {
  _Pins(this.log, this.pins);
  final List<String> log;
  final List<SourcePin> pins;
  @override
  Future<SourcePinsState> build() async => SourcePinsState(pins: pins, synced: true);
  @override
  Future<void> toggle(String sourceId, {String? name, String? iconUrl, bool mature = false}) async => log.add('toggle:$sourceId');
  @override
  Future<void> reorder(List<String> orderedIds) async => log.add('reorder:${orderedIds.join(",")}');
}

class _NoMature extends MatureContentController {
  @override
  Future<bool> build() async => false;
}

SourceSummary src(String id, {SourceHealthStatus st = SourceHealthStatus.ok}) => SourceSummary(id: id, name: 'Source $id', description: 'desc $id', browsable: true, supportsImport: false, health: SourceHealth(status: st));

List<Override> overrides(List<String> log, {List<SourceSummary>? sources, List<SourcePin> pins = const []}) => [
      sourcesListProvider.overrideWith((ref) async => sources ?? [src('a'), src('b'), src('c', st: SourceHealthStatus.failing)]),
      sourcePinsProvider.overrideWith(() => _Pins(log, pins)),
      sourceHealthSummaryProvider.overrideWith((ref) async => const SourceHealthSummary(total: 3, ok: 2, failing: 1)),
      matureContentProvider.overrideWith(_NoMature.new),
    ];

void main() {
  testWidgets('default: health line, chips with Having trouble, rows', (t) async {
    final log = <String>[];
    await pumpGlassShell(t, start: '/sources', extra: overrides(log));
    expect(find.byType(GlassSourcesScreen), findsOneWidget);
    expect(find.text('2 of 3 sources working'), findsOneWidget);
    expect(find.text('Having trouble (1)'), findsOneWidget);
    expect(find.text('Source a'), findsOneWidget);
    expect(find.text('All sources'), findsOneWidget);
  });

  testWidgets('no failing source hides the Having trouble chip', (t) async {
    await pumpGlassShell(t, start: '/sources', extra: overrides([], sources: [src('a'), src('b')]));
    expect(find.textContaining('Having trouble'), findsNothing);
  });

  testWidgets('pinned section lists pinned sources with a Pinned chip count', (t) async {
    await pumpGlassShell(t, start: '/sources', extra: overrides([], pins: const [SourcePin(sourceId: 'b', sortOrder: 0, name: 'Source b')]));
    expect(find.text('Pinned'), findsOneWidget);
    expect(find.text('Pinned (1)'), findsOneWidget);
  });

  testWidgets('a pinned source that is no longer installed offers Unpin', (t) async {
    await pumpGlassShell(t, start: '/sources', extra: overrides([], pins: const [SourcePin(sourceId: 'gone', sortOrder: 0, name: 'Old one', available: false)]));
    expect(find.text('No longer installed'), findsOneWidget);
    expect(find.text('Unpin'), findsOneWidget);
  });

  testWidgets('load error shows the retry lens', (t) async {
    await pumpGlassShell(t, start: '/sources', extra: [...overrides([]), sourcesListProvider.overrideWith((ref) async => throw Exception('x'))]);
    expect(find.text("Couldn't load sources"), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('no sources installed lens', (t) async {
    await pumpGlassShell(t, start: '/sources', extra: overrides([], sources: const []));
    expect(find.text('No sources installed'), findsOneWidget);
  });

  testWidgets('tap targets meet the iOS and labelled guidelines', (t) async {
    final h = t.ensureSemantics();
    await pumpGlassShell(t, start: '/sources', extra: overrides([]));
    await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
    h.dispose();
  });

  testWidgets('tablet frame draws the pinned shelf', (t) async {
    await pumpGlassShell(t, size: const Size(834, 1194), start: '/sources', extra: overrides([], pins: const [SourcePin(sourceId: 'b', sortOrder: 0, name: 'Source b')]));
    expect(find.text('No updates yet'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });
}
