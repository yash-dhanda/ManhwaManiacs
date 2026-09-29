// ignore_for_file: require_trailing_commas, avoid_redundant_argument_values, library_private_types_in_public_api, directives_ordering
import 'dart:convert';
import 'dart:io';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/library/models/continue_reading_item.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';


/// A fixture from `test/fixtures/home/`: invented series, invented sources.
HomeFeed loadHome(String name) =>
    HomeFeed.fromJson(jsonDecode(File('test/fixtures/home/$name.json').readAsStringSync()) as Map<String, dynamic>);


FollowedSeries followedRow(
  String key, {
  int id = 1,
  String source = 'shelf',
  String status = 'reading',
  bool favourite = false,
  int position = 5,
  int total = 20,
  int newCount = 0,
  bool started = true,
  int sortOrder = 0,
  DateTime? updatedAt,
  String rating = 'safe',
}) =>
    FollowedSeries.fromJson({
      'id': id,
      'source_id': source,
      'series_key': key,
      'title': 'Title $key',
      'cover_url': '/sources/$source/series/$key/cover',
      'is_favorite': favourite,
      'reading_status': status,
      'sort_order': sortOrder,
      'rating': rating,
      'chapter_count': total,
      'updated_at': updatedAt?.toUtc().toIso8601String(),
      'known_chapters': [for (var i = 1; i <= total; i++) {'key': 'c$i', 'number': i}],
      'read_state': {'started': started, 'chapter_key': 'c$position', 'chapter_number': position, 'position': position, 'total': total, 'new_count': newCount},
    });

ContinueReadingItem contRow(String key, {String source = 'shelf', int chapter = 5, int page = 10, int pages = 40, required DateTime at}) => ContinueReadingItem(
      sourceId: source,
      seriesKey: key,
      chapterKey: 'c$chapter',
      chapterNumber: chapter.toDouble(),
      lastPage: page,
      pageCount: pages,
      lastReadAt: at,
      title: 'Title $key',
      coverUrl: '/sources/$source/series/$key/cover',
    );
