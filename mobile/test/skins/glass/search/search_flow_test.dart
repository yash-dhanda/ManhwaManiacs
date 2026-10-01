import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/utils/pagination.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/models/global_search_result.dart';
import 'package:manhwamaniacs/features/library/models/suggestion.dart';
import 'package:manhwamaniacs/features/library/providers/intelligence_providers.dart';
import 'package:manhwamaniacs/features/library/providers/library_list_provider.dart';
import 'package:manhwamaniacs/features/library/providers/pending_ask_provider.dart';
import 'package:manhwamaniacs/features/library/repositories/library_repository.dart';
import 'package:manhwamaniacs/features/library/utils/recent_searches.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/sources/models/source_search_group.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
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

String _fieldText(WidgetTester t) => t.widget<EditableText>(find.byType(EditableText)).controller.text;

Finder _field() => find.byType(EditableText);

/// Every case runs as an iPhone (the owner's device), with the override reset by the variant.
void _ios(String name, WidgetTesterCallback body) => testWidgets(name, body, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

void main() {
  group('Glass search on iOS, from the dock search button', () {
    _ios('opens with the field focused and the keyboard connection open', (t) async {
      final rig = await _shell(t);
      await _open(t);
      expect(rig.at, '/search');
      expect(_fieldFocused(), isTrue);
      expect(t.testTextInput.hasAnyClients, isTrue);
      expect(t.testTextInput.isVisible, isTrue);
    });

    _ios('tapping the focused field brings the keyboard back', (t) async {
      await _shell(t);
      await _open(t);
      await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
      expect(t.testTextInput.isVisible, isFalse);
      await t.tap(_field());
      await _ms(t, 400);
      expect(t.testTextInput.hasAnyClients, isTrue);
      expect(t.testTextInput.isVisible, isTrue);
    });

    _ios('typing and submitting shows results', (t) async {
      final rig = await _shell(t);
      await _open(t);
      await t.enterText(_field(), 'tower');
      await t.testTextInput.receiveAction(TextInputAction.search);
      await _ms(t, 700);
      expect(rig.container.read(searchQueryProvider), 'tower');
      expect(find.text('Result for tower'), findsOneWidget);
    });

    _ios('a Recent row runs its search; x removes it', (t) async {
      final rig = await _shell(t, recent: ['solo leveling', 'magic emperor']);
      await _open(t);
      expect(find.text('solo leveling'), findsOneWidget);
      await t.tap(find.byTooltip('Remove magic emperor').evaluate().isEmpty ? find.bySemanticsLabel('Remove magic emperor') : find.byTooltip('Remove magic emperor'));
      await _ms(t, 200);
      expect(find.text('magic emperor'), findsNothing);
      await t.tap(find.text('solo leveling'));
      await _ms(t, 700);
      expect(rig.container.read(searchQueryProvider), 'solo leveling');
      expect(_fieldText(t), 'solo leveling');
      expect(find.text('Result for solo leveling'), findsOneWidget);
    });

    _ios('a Trending chip runs its search', (t) async {
      final rig = await _shell(t);
      await _open(t);
      await t.tap(find.text('fantasy'));
      await _ms(t, 700);
      expect(rig.container.read(searchQueryProvider), 'fantasy');
      expect(_fieldText(t), 'fantasy');
      expect(find.text('Result for fantasy'), findsOneWidget);
    });

    _ios('scope tabs change the results: Library shows the shelf, Sources the sources', (t) async {
      await _shell(t);
      await _open(t);
      await t.tap(find.text('fantasy'));
      await _ms(t, 700);
      await t.tap(find.text('Library'));
      await _ms(t, 700);
      expect(find.text('Shelf fantasy'), findsOneWidget);
      expect(find.text('Result for fantasy'), findsNothing);
      await t.tap(find.text('Sources'));
      await _ms(t, 700);
      expect(find.text('Result for fantasy'), findsOneWidget);
      expect(find.text('Shelf fantasy'), findsNothing);
    });

    _ios('Browse sources goes to Sources', (t) async {
      final rig = await _shell(t);
      await _open(t);
      await t.tap(find.text('Browse sources'));
      await _ms(t, 900);
      expect(rig.at, '/sources');
      expect(t.takeException(), isNull);
    });

    _ios('Describe what you want to read hands the words to the Ask row on Picks', (t) async {
      final rig = await _shell(t, ask: true);
      await _open(t);
      await t.enterText(_field(), 'a');
      await _ms(t, 400);
      String? handed;
      rig.container.listen(pendingAskProvider, (_, n) => handed ??= n, fireImmediately: true);
      await t.tap(find.text('Describe what you want to read'));
      await _ms(t, 900);
      expect(handed, 'a');
      expect(rig.at, '/library/recommendations');
      expect(t.takeException(), isNull);
    });

    _ios('a result opens its series', (t) async {
      final rig = await _shell(t);
      await _open(t);
      await t.tap(find.text('fantasy'));
      await _ms(t, 700);
      await t.tap(find.text('Result for fantasy'));
      await _ms(t, 900);
      expect(rig.at, '/sources/a/series/k-fantasy');
    });

    _ios('a library hit opens the followed series', (t) async {
      final rig = await _shell(t);
      await _open(t);
      await t.tap(find.text('fantasy'));
      await _ms(t, 700);
      await t.tap(find.text('Library'));
      await _ms(t, 700);
      await t.tap(find.text('Shelf fantasy'));
      await _ms(t, 900);
      expect(rig.at, '/library/7');
    });

    _ios('Cancel closes search and the dock comes back', (t) async {
      final rig = await _shell(t);
      await _open(t);
      await t.tap(find.text('Cancel'));
      await _ms(t, 900);
      expect(rig.at, '/');
      expect(find.byType(GlassSearchPage), findsNothing);
      expect(t.testTextInput.hasAnyClients, isFalse);
      expect(find.byType(GlassSearchOrbBody).hitTestable(), findsOneWidget);
    });
  });
}
