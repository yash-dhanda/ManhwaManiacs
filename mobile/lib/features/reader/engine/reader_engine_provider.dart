import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine.dart';

/// The [ReaderEngine] of the reader on screen. `ReaderEngineView` overrides it
/// for its own subtree, so a chrome widget anywhere below can watch it.
final readerEngineProvider = Provider<ReaderEngine>(
  (ref) => throw StateError(
    'readerEngineProvider is scoped: read it below ReaderEngineView.',
  ),
  dependencies: const [],
);
