import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_frames.dart';
import 'package:manhwamaniacs/features/reader/providers/series_reading_order_provider.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_feed_factory.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/manga_reader.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_entry.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_states.dart';
import 'package:manhwamaniacs/skins/reader_entries.dart';

/// The read-all route (ScreenId `readAll`, `/read-all/:sourceId/:seriesKey?from&page&at`): one
/// continuous strip across the whole series (cinematic 8.14.4). The chapter list comes first; while
/// it loads the reader plates show, and when it fails the list-failure notice does. Then the first
/// chapter (`from`, else chapter 1) opens from its own manifest and windows of chapters fill in
/// behind it through [readAllFeedFactory].
class ReadAllScreen extends ConsumerWidget {
  const ReadAllScreen({super.key, required this.sourceId, required this.seriesKey, this.from, this.page = 1, this.at});

  final String sourceId, seriesKey;

  /// The chapter to start at (a chapter key), else the first of the series.
  final String? from;
  final int page;

  /// The fraction within [page] to open at.
  final double? at;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (sourceId: sourceId, seriesId: seriesKey);
    final order = ref.watch(seriesReadingOrderProvider(key));
    return order.when(
      loading: () => const ReaderLoading(),
      error: (_, __) => ReadAllListFailureView(
        onRetry: () => ref.invalidate(seriesReadingOrderProvider(key)),
        onBack: () => leaveReaderByDip(context, sourceId: sourceId, seriesKey: seriesKey),
      ),
      data: (keys) {
        if (keys.isEmpty) {
          return ReadAllListFailureView(
            onRetry: () => ref.invalidate(seriesReadingOrderProvider(key)),
            onBack: () => leaveReaderByDip(context, sourceId: sourceId, seriesKey: seriesKey),
          );
        }
        final start = from != null && keys.contains(from) ? from! : keys.first;
        return ProviderScope(
          overrides: [
            readerFramesProvider.overrideWithValue(
              ReaderFrames(
                content: (context, body) => CineMangaReader(key: ValueKey('read-all:$sourceId:$seriesKey'), body: body, readAll: true),
                loading: (context) => const ReaderLoading(),
                failure: (context, failure) => ReaderFailureView(failure: failure),
              ),
            ),
            readerFeedFactoryProvider.overrideWith((ref) => readAllFeedFactory(ref, sourceId: sourceId, seriesKey: seriesKey)),
          ],
          child: manifestReaderEntry(
            sourceId: sourceId,
            seriesKey: seriesKey,
            chapterKey: start,
            initialPage: page,
            initialAnchor: at == null || at!.isNaN ? null : (page: page, fraction: at!.clamp(0.0, 1.0)),
            readAll: true,
          ),
        );
      },
    );
  }
}
