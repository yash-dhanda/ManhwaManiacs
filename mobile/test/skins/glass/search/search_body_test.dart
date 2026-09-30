import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/models/global_search_result.dart';
import 'package:manhwamaniacs/features/library/providers/library_list_provider.dart';
import 'package:manhwamaniacs/features/sources/models/source_search_group.dart';
import 'package:manhwamaniacs/skins/glass/screens/search/search_page.dart';
import 'package:manhwamaniacs/skins/glass/screens/search/tier_capsule.dart';

import '../shell/shell_rig.dart';

GlobalSearchItem item(String t) => GlobalSearchItem(kind: 'source', source: 'a', seriesId: t, title: t);

class _Search extends SearchListNotifier {
  _Search(this.result);
  final GroupedSearchResult result;
  @override
  Future<GroupedSearchResult> build() async => result;
}

GroupedSearchResult result({int? nextTier, int deferred = 0, int groups = 2, bool failed = false}) => GroupedSearchResult(
      groups: [
        for (var i = 0; i < groups; i++) SourceSearchGroup(source: 's$i', sourceName: 'Source $i', status: SourceGroupStatus.ok, items: [item('Tower $i')]),
        if (failed) const SourceSearchGroup(source: 'bad', sourceName: 'Bad Source', status: SourceGroupStatus.error),
        const SourceSearchGroup(source: 'quiet', sourceName: 'Quiet Source', status: SourceGroupStatus.empty),
      ],
      sourcesQueried: groups + 2,
      nextTier: nextTier,
      sourcesDeferred: deferred,
    );

List<Override> ov(GroupedSearchResult r) => [searchListProvider.overrideWith(() => _Search(r))];

void main() {
  test('tier capsule sentence', () {
    expect(TierCapsule.textFor(18, 8), '18 results · searching 8 more sources');
    expect(TierCapsule.textFor(18, 0), '18 results');
  });

  testWidgets('idle: Recent none, Trending chips, Browse sources, scopes', (t) async {
    await pumpGlassShell(t, start: '/search', extra: ov(result()));
    expect(find.byType(GlassSearchBody), findsOneWidget);
    expect(find.text('Trending'), findsOneWidget);
    expect(find.text('fantasy'), findsOneWidget);
    expect(find.text('Browse sources'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Sources'), findsOneWidget);
    // no Ask card while `picks` is pending, no Dialogue without OCR
    expect(find.text('Describe what you want to read'), findsNothing);
    expect(find.text('Dialogue'), findsNothing);
  });

  testWidgets('results: sections, capsule, quiet-sources disclosure', (t) async {
    await pumpGlassShell(t, start: '/search?q=tower', extra: ov(result(nextTier: 2, deferred: 3, failed: true)));
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('Source 0'), findsOneWidget);
    expect(find.text('Tower 0'), findsOneWidget);
    expect(find.text('2 results · searching 3 more sources'), findsOneWidget);
    expect(find.text("This source didn't answer"), findsOneWidget);
    expect(find.text('Show 1 sources with no matches'), findsOneWidget);
    await t.drag(find.byType(ListView).first, const Offset(0, -300));
    await t.pump();
    await t.tap(find.text('Show 1 sources with no matches'));
    await t.pump();
    expect(find.text('Quiet Source', skipOffstage: false), findsOneWidget);
    await t.pump(const Duration(seconds: 2));
  });

  testWidgets('more than six groups on a phone draws the jump bar with its buttons', (t) async {
    final h = t.ensureSemantics();
    await pumpGlassShell(t, start: '/search?q=tower', extra: ov(result(groups: 8)));
    await t.pump(const Duration(milliseconds: 600));
    expect(find.bySemanticsLabel('Jump to Source 3 results'), findsOneWidget);
    h.dispose();
  });

  testWidgets('no results shows the lens', (t) async {
    await pumpGlassShell(t, start: '/search?q=zzzz', extra: ov(const GroupedSearchResult()));
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('No results for “zzzz”'), findsOneWidget);
  });

  testWidgets('unknown or unavailable scopes fall back to All', (t) async {
    await pumpGlassShell(t, start: '/search?q=tower&scope=text', extra: ov(result()));
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('Source 0'), findsOneWidget);
  });
}
