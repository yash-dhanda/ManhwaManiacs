import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/features/reader/screens/reader_screen.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_anchor.dart';
import 'package:manhwamaniacs/features/sources/screens/source_reader_screen.dart';

/// The two reader entry screens, handed to skins that must not import `features/*/screens`
/// (`test/skins/import_boundary_test.dart`). Each owns one data path: the manifest reader (the
/// library, `POST /reader/progress`) and the source reader (source-local progress); both render
/// whatever frame `readerFramesProvider` names.
Widget manifestReaderEntry({
  required String sourceId,
  required String seriesKey,
  required String chapterKey,
  int initialPage = 1,
  ReaderAnchor? initialAnchor,
  bool readAll = false,
}) =>
    ReaderScreen(
      sourceId: sourceId,
      seriesKey: seriesKey,
      chapterKey: chapterKey,
      initialPage: initialPage,
      initialAnchor: initialAnchor,
      readAll: readAll,
    );

Widget sourceReaderEntry({
  required String sourceId,
  required String seriesId,
  required String chapterId,
  int initialPage = 1,
  bool readAll = false,
}) =>
    SourceReaderScreen(
      sourceId: sourceId,
      seriesId: seriesId,
      chapterId: chapterId,
      initialPage: initialPage,
      readAll: readAll,
    );
