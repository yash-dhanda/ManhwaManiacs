import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart' show addTearDown;
import 'package:manhwamaniacs/features/recap/models/recap_models.dart';
import 'package:manhwamaniacs/features/recap/models/recap_origin.dart';
import 'package:manhwamaniacs/features/recap/providers/recap_providers.dart';
import 'package:manhwamaniacs/features/recap/repositories/recap_repository.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/recap/recap_screen.dart';

/// A recap repository the test scripts: an [open] answer, or a controller it pushes events into.
class FakeRecapRepository extends RecapRepository {
  FakeRecapRepository({this.none, RecapAvailability? availability})
      : availabilityAnswer = availability ?? const RecapAvailability(available: true, fromNumber: 131, toNumber: 142, estSeconds: 90),
        super(Dio());

  /// A JSON no-stream answer; null streams [events].
  final RecapNone? none;
  final RecapAvailability availabilityAnswer;
  final events = StreamController<RecapEvent>();
  int opens = 0;

  @override
  Future<RecapAvailability> availability(RecapKey k, {CancelToken? cancel}) async => availabilityAnswer;

  @override
  Future<RecapOpen> open(RecapKey k, {CancelToken? cancel}) async {
    opens++;
    return none ?? RecapOpen.stream(events.stream);
  }

  /// Pushes a whole scripted recap.
  void script({String text = 'Kim Dokja woke in the train. He read on.\n\nThe world ended and the story began. Kim Dokja survived.', bool done = true}) {
    events.add(const RecapMeta(
      range: RecapRange(fromNumber: 131, toNumber: 142),
      cast: [RecapCast('Kim Dokja', 'the reader')],
    ),);
    for (final chunk in text.split(' ')) {
      events.add(RecapDelta('$chunk '));
    }
    if (done) events.add(RecapDone(generatedAt: DateTime.now().toUtc()));
  }
}

const kSeries = SourceSeriesSummary(id: 'k', sourceId: 's', title: 'Omniscient Reader', chapterCount: 143, genres: [], coverUrl: '');

SourceSeriesDetailData detailData() => const SourceSeriesDetailData(
      series: kSeries,
      chapters: [
        SourceChapterSummary(id: 'c142', sourceId: 's', seriesId: 'k', title: 'Chapter 142', number: 142, pageCount: 20),
        SourceChapterSummary(id: 'c143', sourceId: 's', seriesId: 'k', title: 'Chapter 143', number: 143, pageCount: 20),
      ],
    );

List<Override> recapOverrides(FakeRecapRepository repo) => [
      recapRepositoryProvider.overrideWithValue(repo),
      sourceSeriesDetailProvider.overrideWith((ref, p) async => detailData()),
    ];

Widget recapScreen({RecapEntry entry = RecapEntry.wipe, bool screenReader = false}) => Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(accessibleNavigation: screenReader),
        child: RecapScreen(sourceId: 's', seriesKey: 'k', to: 'c143', origin: RecapOrigin(entry, returnTo: '/')),
      ),
    );

final _png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');

/// Covers load from memory, never the network or a platform cache.
void stubCovers() {
  final probe = CineImage.cacheProbe, builder = CineImage.providerBuilder;
  CineImage.cacheProbe = (_) async => false;
  CineImage.providerBuilder = (url, headers) => MemoryImage(Uint8List.fromList(_png));
  addTearDown(() {
    CineImage.cacheProbe = probe;
    CineImage.providerBuilder = builder;
  });
}
