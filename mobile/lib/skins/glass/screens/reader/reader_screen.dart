import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_frames.dart';
import 'package:manhwamaniacs/features/reader/providers/series_reading_order_provider.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_anchor.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_feed_factory.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/glass_manga_reader.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/reader_states.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/reader_system_ui.dart';
import 'package:manhwamaniacs/skins/reader_entries.dart';

/// The Glass reader frames (glass 8.14): the two entry screens resolve the chapter and hand the body here.
ReaderFrames glassReaderFrames({bool readAll = false, String? q}) => ReaderFrames(
      // A constant key per series: a chapter switch under the constant page key reaches the same State (the engine survives).
      content: (context, body) => GlassMangaReader(key: ValueKey('glass-manga:${body.identity?.sourceId}:${body.identity?.seriesKey}'), body: body, readAll: readAll, q: q),
      loading: (context) => const GlassReaderLoading(),
      failure: (context, failure) => GlassReaderFailure(failure: failure),
    );

/// ScreenId `reader` (`/reader/:sourceId/:seriesKey/:chapterKey?page&at&all&q`) and its two mobile aliases: the library manifest
/// reader (`/library/read/...`, mobile S15) and the source reader (`/sources/:s/series/:id/chapters/:c/read`, mobile S19). Both
/// data paths render [GlassMangaReader].
class GlassReaderScreen extends StatelessWidget {
  const GlassReaderScreen({
    super.key,
    required this.sourceId,
    required this.seriesKey,
    required this.chapterKey,
    this.source = false,
    this.page = 1,
    this.at,
    this.all = false,
    this.q,
  });

  /// Builds the screen from a route state.
  factory GlassReaderScreen.of(GoRouterState s) {
    final p = s.pathParameters;
    final q = s.uri.queryParameters;
    return GlassReaderScreen(
      sourceId: p['sourceId'] ?? '',
      seriesKey: p['seriesKey'] ?? '',
      chapterKey: p['chapterKey'] ?? '',
      source: s.uri.path.startsWith('/sources/'),
      page: int.tryParse(q['page'] ?? '') ?? 1,
      at: double.tryParse(q['at'] ?? ''),
      all: q['all'] == '1' || q['all'] == 'true',
      q: q['q'],
    );
  }

  final String sourceId, seriesKey, chapterKey;
  final bool source;
  final int page;
  final double? at;
  final bool all;
  final String? q;

  @override
  Widget build(BuildContext context) {
    final ReaderAnchor? anchor = at == null || at!.isNaN ? null : (page: page, fraction: at!.clamp(0.0, 1.0));
    return GlassReaderSystemUi(
      child: ProviderScope(
        overrides: [readerFramesProvider.overrideWithValue(glassReaderFrames(readAll: all, q: q))],
        child: source
            ? sourceReaderEntry(sourceId: sourceId, seriesId: seriesKey, chapterId: chapterKey, initialPage: page, readAll: all)
            : manifestReaderEntry(sourceId: sourceId, seriesKey: seriesKey, chapterKey: chapterKey, initialPage: page, initialAnchor: anchor, readAll: all),
      ),
    );
  }
}

/// ScreenId `readAll` (`/read-all/:sourceId/:seriesKey?from&page&at`): the whole series as one strip, chapter 1 (or `from`) first,
/// slim seams with no card and no pause.
class GlassReadAllScreen extends ConsumerWidget {
  const GlassReadAllScreen({super.key, required this.sourceId, required this.seriesKey, this.from, this.page = 1, this.at});

  factory GlassReadAllScreen.of(GoRouterState s) => GlassReadAllScreen(
        sourceId: s.pathParameters['sourceId'] ?? '',
        seriesKey: s.pathParameters['seriesKey'] ?? '',
        from: s.uri.queryParameters['from'],
        page: int.tryParse(s.uri.queryParameters['page'] ?? '') ?? 1,
        at: double.tryParse(s.uri.queryParameters['at'] ?? ''),
      );

  final String sourceId, seriesKey;
  final String? from;
  final int page;
  final double? at;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (sourceId: sourceId, seriesId: seriesKey);
    final order = ref.watch(seriesReadingOrderProvider(key));
    void back() => GoRouter.maybeOf(context)?.go(Routes.feature(sourceId, seriesKey));
    final failure = ReaderFailure(error: null, noPages: true, retry: () => ref.invalidate(seriesReadingOrderProvider(key)), back: back);
    return GlassReaderSystemUi(
      child: order.when(
        loading: () => const GlassReaderLoading(),
        error: (_, __) => GlassReaderFailure(failure: ReaderFailure(error: null, noPages: false, retry: failure.retry, back: back)),
        data: (keys) {
          if (keys.isEmpty) return GlassReaderFailure(failure: failure);
          final start = from != null && keys.contains(from) ? from! : keys.first;
          return ProviderScope(
            overrides: [
              readerFramesProvider.overrideWithValue(glassReaderFrames(readAll: true)),
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
      ),
    );
  }
}
