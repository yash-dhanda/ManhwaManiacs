import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/sources/models/source_series.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';

typedef ReaderSeriesKey = ({String sourceId, String seriesKey});

/// The series behind the chapter being read: its title, status and chapters in reading order, for
/// the running head, the Contents list, the folio bar's neighbours and the end states.
class ReaderSeries {
  const ReaderSeries({required this.title, required this.status, required this.chapters, required this.summary});

  final String title;
  final String? status;

  /// Oldest to newest, unnumbered ones last (the reading order).
  final List<SourceChapterSummary> chapters;
  final SourceSeriesSummary summary;

  bool get completed => status?.trim().toLowerCase() == 'completed';

  int indexOf(String chapterKey) => chapters.indexWhere((c) => c.id == chapterKey);

  SourceChapterSummary? chapterOf(String chapterKey) {
    final i = indexOf(chapterKey);
    return i < 0 ? null : chapters[i];
  }

  SourceChapterSummary? previousOf(String chapterKey) {
    final i = indexOf(chapterKey);
    return i > 0 ? chapters[i - 1] : null;
  }

  SourceChapterSummary? nextOf(String chapterKey) {
    final i = indexOf(chapterKey);
    return i >= 0 && i < chapters.length - 1 ? chapters[i + 1] : null;
  }

  /// The chapter whose displayed title is [title] (the seam band only receives titles).
  SourceChapterSummary? chapterTitled(String title) {
    for (final c in chapters) {
      if (c.title == title) return c;
    }
    return null;
  }
}

List<SourceChapterSummary> readingOrder(List<SourceChapterSummary> chapters) {
  final numbered = chapters.where((c) => c.number != null).toList()..sort((a, b) => a.number!.compareTo(b.number!));
  return [...numbered, ...chapters.where((c) => c.number == null)];
}

/// `142` for 142.0, `142.5` as it is, `·` when the chapter has no number.
String chapterNumberText(double? number) {
  if (number == null) return '·';
  return number % 1 == 0 ? number.toInt().toString() : number.toString();
}

/// `CH 142` (the folio), or `CH ·` without a number.
String chapterFolio(double? number) => 'CH ${chapterNumberText(number)}';

final readerSeriesProvider = Provider.autoDispose.family<ReaderSeries?, ReaderSeriesKey>((ref, k) {
  final detail = ref.watch(sourceSeriesDetailProvider((sourceId: k.sourceId, seriesId: k.seriesKey))).valueOrNull;
  if (detail == null) return null;
  return ReaderSeries(
    title: detail.series.title,
    status: detail.series.status,
    chapters: readingOrder(detail.chapters),
    summary: detail.series,
  );
}, name: 'readerSeries',);
