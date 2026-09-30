// ignore_for_file: directives_ordering, require_trailing_commas, prefer_const_constructors, avoid_redundant_argument_values, unnecessary_lambdas, unnecessary_await_in_return, avoid_print
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/library/providers/numbers_providers.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../features/circle/fakes.dart';
import '../auth/auth_test_support.dart' show FakeProfiles, profile;
import '../feature/feature_test_support.dart' hide FakeUpdates;
import '../hub/hub_test_support.dart';
import '../support/cine_harness.dart' show FakeNumbersRepo;

/// Ready-state data for the screens whose default (offline) state has no masthead. Every title
/// is invented (fixtures under `test/fixtures/series/`, `shelfSeries`, the circle fakes).

Future<List<Override>> qaFeatureOverrides({bool novel = false}) async {
  final f = loadSeriesFixture(novel ? 'novel-short' : 'manga-ongoing');
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return [
    ...featureOverrides(FeatureRig(followed: followedRow()), prefs, novel: novel),
    sourceSeriesDetailProvider.overrideWith((ref, p) async => SourceSeriesDetailData(series: f.series, chapters: f.chapters)),
  ];
}

Future<List<Override>> qaCollectionOverrides() async => [
      libraryRepositoryProvider.overrideWithValue(HubLibrary(
        all: [for (var i = 1; i <= 6; i++) shelfSeries(i, status: i <= 3 ? 'reading' : 'completed', newCount: i == 1 ? 5 : 0)],
        collections: [shelfOf(1, 'Slow burns', description: 'For rainy weeks.')],
        members: {1: [('shelf', 'series-1'), ('shelf', 'series-2'), ('shelf', 'series-3')]},
      )),
      ...updatesOverrides(FakeUpdates()),
    ];

Future<List<Override>> qaAnnualOverrides() async => [numbersRepositoryProvider.overrideWithValue(FakeNumbersRepo())];

Future<List<Override>> qaCircleMemberOverrides() async => [
      circleRepositoryProvider.overrideWithValue(FakeCircleRepository(
        memberPage: MemberPage(
          profile: riya,
          shares: const CircleShares(activity: true, reactions: true, shelves: true),
          reading: const [MemberSeries(sourceId: 's', seriesKey: 'or', title: 'The Lantern Courier', chapterNumber: 212)],
          finished: const [MemberSeries(sourceId: 's', seriesKey: 'sl', title: 'Moonlit Bakery')],
          reactions: const [],
          shelves: const [],
        ),
        membersList: [member(riya, canReceive: true)],
      )),
    ];

Future<List<Override>> qaProfilesOverrides() async => [
      profilesRepositoryProvider.overrideWithValue(FakeProfiles([profile(1, 'Yash'), profile(2, 'Guest', step: null)])),
    ];
