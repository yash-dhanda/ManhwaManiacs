import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_frames.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_anchor.dart';
import 'package:manhwamaniacs/skins/reader_entries.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/manga_reader.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_states.dart';

/// The Cinematic frames of the reader: the manga reader chrome, the loading plates and the failure
/// notices (cinematic 8.14).
final ReaderFrames cineReaderFrames = ReaderFrames(
  content: (context, body) => CineMangaReader(key: ValueKey('${body.identity?.sourceId}:${body.identity?.seriesKey}'), body: body),
  loading: (context) => const ReaderLoading(),
  failure: (context, failure) => ReaderFailureView(failure: failure),
);

/// Whether a Cinematic reader owns the toast stack: the shell's host steps aside so the reader's
/// own (above the folio bar) is the only one.
final cineReaderOwnsToastsProvider = StateProvider<bool>((ref) => false, name: 'cineReaderOwnsToasts');

/// The two ways into a chapter, as thin entry widgets over the same engine and the same frame
/// (cinematic 8.14.2): `manifest` is the library reader (`/reader/...` and `/library/read/...`),
/// `source` the source reader (`/sources/:id/series/:key/chapters/:key/read`) with its own
/// progress. Both render `CineMangaReader` through [readerFramesProvider].
class CineReaderRoute extends StatelessWidget {
  const CineReaderRoute.manifest({
    super.key,
    required String sourceId,
    required String seriesKey,
    required String chapterKey,
    int initialPage = 1,
    ReaderAnchor? initialAnchor,
    bool readAll = false,
  })  : _manifest = true,
        _sourceId = sourceId,
        _seriesKey = seriesKey,
        _chapterKey = chapterKey,
        _page = initialPage,
        _anchor = initialAnchor,
        _readAll = readAll;

  const CineReaderRoute.source({
    super.key,
    required String sourceId,
    required String seriesKey,
    required String chapterKey,
    int initialPage = 1,
    bool readAll = false,
  })  : _manifest = false,
        _sourceId = sourceId,
        _seriesKey = seriesKey,
        _chapterKey = chapterKey,
        _page = initialPage,
        _anchor = null,
        _readAll = readAll;

  final bool _manifest, _readAll;
  final String _sourceId, _seriesKey, _chapterKey;
  final int _page;
  final ReaderAnchor? _anchor;

  @override
  Widget build(BuildContext context) => ProviderScope(
        overrides: [readerFramesProvider.overrideWithValue(cineReaderFrames)],
        child: _manifest
            ? manifestReaderEntry(
                sourceId: _sourceId,
                seriesKey: _seriesKey,
                chapterKey: _chapterKey,
                initialPage: _page,
                initialAnchor: _anchor,
                readAll: _readAll,
              )
            : sourceReaderEntry(
                sourceId: _sourceId,
                seriesId: _seriesKey,
                chapterId: _chapterKey,
                initialPage: _page,
                readAll: _readAll,
              ),
      );
}
