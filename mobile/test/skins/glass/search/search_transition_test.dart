import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/utils/pagination.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/models/global_search_result.dart';
import 'package:manhwamaniacs/features/library/models/suggestion.dart';
import 'package:manhwamaniacs/features/library/providers/intelligence_providers.dart';
import 'package:manhwamaniacs/features/library/providers/library_list_provider.dart';
import 'package:manhwamaniacs/features/library/repositories/library_repository.dart';
import 'package:manhwamaniacs/features/library/utils/recent_searches.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/sources/models/source_search_group.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/shell/search_orb.dart';

import '../shell/shell_rig.dart';

/// Answers whatever the page asked for: one source group whose only result is "Result for <q>".
class _Search extends SearchListNotifier {
  @override
  Future<GroupedSearchResult> build() async {
    final q = ref.watch(searchQueryProvider).trim();
    if (q.isEmpty) return const GroupedSearchResult();
    return GroupedSearchResult(
      groups: [
        SourceSearchGroup(source: 'a', sourceName: 'Source A', status: SourceGroupStatus.ok, items: [GlobalSearchItem(kind: 'source', source: 'a', seriesId: 'k-$q', title: 'Result for $q')]),
        const SourceSearchGroup(source: null, sourceName: 'Library', status: SourceGroupStatus.empty),
      ],
      sourcesQueried: 1,
    );
  }
}

FollowedSeries _follow(int id, String title) => FollowedSeries(
      id: id,
      sourceId: 'a',
      seriesKey: 'shelf-$id',
      title: title,
      coverUrl: '',
      isFavorite: false,
      readingStatus: 'reading',
      notify: true,
      sortOrder: 0,
      contentRating: 'safe',
      rating: '',
      chapterCount: 0,
    );

/// The library half of search: `GET /library/search`.
class _Library implements LibraryRepository {
  @override
  Future<Result<PagedResult<FollowedSeries>>> search(String query, {int page = 1, int perPage = 20}) async =>
      Ok(PagedResult(items: [_follow(7, 'Shelf $query')], total: 1, page: 1, perPage: perPage, hasNext: false));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

List<Override> _ov({bool ask = false}) => [
      searchListProvider.overrideWith(_Search.new),
      libraryRepositoryProvider.overrideWithValue(_Library()),
      if (ask) suggestAvailabilityProvider.overrideWith((ref) async => const SuggestionAvailability(available: true, reason: 'ok', remainingToday: 5)),
    ];

Future<void> _ms(WidgetTester t, int ms) async {
  for (var i = 0; i < ms ~/ 16; i++) {
    await t.pump(const Duration(milliseconds: 16));
  }
}

Future<ShellRig> _shell(WidgetTester t, {bool ask = false, List<String> recent = const []}) async {
  final rig = await pumpGlassShell(t, extra: _ov(ask: ask));
  final prefs = rig.container.read(sharedPrefsProvider);
  for (final r in recent.reversed) {
    await writeRecentSearch(prefs, r, profileId: rig.container.read(activeProfileProvider)?.id);
  }
  return rig;
}

/// From the dock's search button, as on the phone.
Future<void> _open(WidgetTester t) async {
  await t.tap(find.byType(GlassSearchOrbBody));
  await _ms(t, 900);
}

bool _fieldFocused() {
  final f = FocusManager.instance.primaryFocus;
  return f?.context?.findAncestorWidgetOfExactType<EditableText>() != null;
}


Finder _field() => find.byType(EditableText);

/// Every case runs as an iPhone (the owner's device), with the override reset by the variant.
void _ios(String name, WidgetTesterCallback body) => testWidgets(name, body, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

void main() {
  group('the open and close transition', () {
    Rect fieldRect(WidgetTester t) => t.getRect(_field());

    _ios('the field grows out of the orb, settles within its spec and is focused at the end', (t) async {
      await _shell(t);
      final orb = t.getRect(find.byType(GlassSearchOrbBody));
      await t.tap(find.byType(GlassSearchOrbBody));
      await t.pump();
      await t.pump(const Duration(milliseconds: 16));
      // The capsule starts on the orb (not the whole screen): its centre is near the orb's.
      final start = t.getRect(find.byKey(kGlassSearchCapsuleKey));
      expect((start.center - orb.center).distance, lessThan(40));
      expect(start.width, lessThan(120));
      await t.pump(kGlassSearchOpen);
      await t.pump();
      final route = ModalRoute.of(t.element(find.byType(GlassSearchPage)))!;
      expect(route.animation!.status, AnimationStatus.completed);
      expect(_fieldFocused(), isTrue);
      expect(t.testTextInput.hasAnyClients, isTrue);
      final end = t.getRect(find.byKey(kGlassSearchCapsuleKey));
      expect(end.width, greaterThan(250));
      expect(fieldRect(t).height, greaterThan(0));
    });

    _ios('closing shrinks back into the orb and finishes within its spec', (t) async {
      final rig = await _shell(t);
      await _open(t);
      await t.tap(find.text('Cancel'));
      await t.pump();
      await t.pump(kGlassSearchClose);
      await t.pump();
      await t.pump(const Duration(milliseconds: 16));
      expect(rig.at, '/');
      expect(find.byType(GlassSearchPage), findsNothing);
    });

    _ios('under Reduce Motion it is a short cross-fade: no morph, field in place, focused at the end', (t) async {
      final rig = await _shell(t);
      rig.container.read(glassInAppPrefsProvider.notifier).setReduceMotion(true);
      await _ms(t, 300);
      await t.tap(find.byType(GlassSearchOrbBody));
      await t.pump();
      await t.pump(const Duration(milliseconds: 60));
      final mid = t.getRect(find.byKey(kGlassSearchCapsuleKey));
      final fade = t.widget<FadeTransition>(find.ancestor(of: find.byKey(kGlassSearchCapsuleKey), matching: find.byKey(kGlassSearchFadeKey)));
      expect(fade.opacity.value, inExclusiveRange(0.0, 1.0));
      await t.pump(const Duration(milliseconds: 120));
      await t.pump();
      final end = t.getRect(find.byKey(kGlassSearchCapsuleKey));
      expect(mid, end); // no rect morph, only opacity
      final route = ModalRoute.of(t.element(find.byType(GlassSearchPage)))!;
      expect(route.animation!.status, AnimationStatus.completed);
      expect(_fieldFocused(), isTrue);
      expect(t.testTextInput.hasAnyClients, isTrue);
    });
  });
}
