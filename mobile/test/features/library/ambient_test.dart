// ignore_for_file: require_trailing_commas, avoid_redundant_argument_values, library_private_types_in_public_api, directives_ordering
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/models/ambient.dart';
import 'package:manhwamaniacs/features/library/models/continue_reading_item.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';

const good = {'duo': '#B8B2A4', 'tint': '#0E0D0B', 'ink': '#F3F0E8'};

void main() {
  test('tryParse: valid, null, missing key, bad hex', () {
    final a = Ambient.tryParse(good)!;
    expect(a.duo, const Color(0xFFB8B2A4));
    expect(a.tint, const Color(0xFF0E0D0B));
    expect(a.ink, const Color(0xFFF3F0E8));
    expect(Ambient.tryParse(null), isNull);
    expect(Ambient.tryParse('#B8B2A4'), isNull);
    expect(Ambient.tryParse({'duo': '#B8B2A4', 'tint': '#0E0D0B'}), isNull);
    expect(Ambient.tryParse({...good, 'ink': '#GGGGGG'}), isNull);
    expect(Ambient.tryParse({...good, 'ink': '#FFF'}), isNull);
    expect(Ambient.tryParse(a.toJson()), a);
  });

  test('each model carries ambient when sent and null when not', () {
    final followed = {'id': 1, 'source_id': 's', 'series_key': 'k', 'title': 't'};
    expect(FollowedSeries.fromJson({...followed, 'ambient': good}).ambient, isNotNull);
    expect(FollowedSeries.fromJson(followed).ambient, isNull);
    expect(FollowedSeries.fromJson(FollowedSeries.fromJson({...followed, 'ambient': good}).toJson()).ambient, isNotNull);
    expect(FollowedSeries.fromJson({...followed, 'ambient': good}).copyWith(isFavorite: true).ambient, isNotNull);
    final cont = {'source_id': 's', 'series_key': 'k', 'chapter_key': 'c'};
    expect(ContinueReadingItem.fromJson({...cont, 'ambient': good}).ambient, isNotNull);
    expect(ContinueReadingItem.fromJson(cont).ambient, isNull);
    expect(WorldItem.fromJson({'title': 'w', 'ambient': good}).ambient, isNotNull);
    expect(WorldItem.fromJson({'title': 'w'}).ambient, isNull);
    final src = {'id': 'k', 'source_id': 's', 'title': 't', 'cover_url': ''};
    expect(SourceSeriesSummary.fromJson({...src, 'ambient': good}, 'http://x').ambient, isNotNull);
    expect(SourceSeriesSummary.fromJson(src, 'http://x').ambient, isNull);
  });
}
