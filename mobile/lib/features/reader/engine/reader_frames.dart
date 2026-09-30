import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/reader/widgets/reader_content.dart';

/// Which of the two ways into a chapter built the reader.
enum ReaderOrigin { manifest, source }

/// What a skin's error frame needs to draw the states of a chapter that did not open.
class ReaderFailure {
  const ReaderFailure({required this.error, required this.noPages, required this.retry, required this.back});

  /// The error, or null when the chapter opened with no pages.
  final AppError? error;
  final bool noPages;
  final VoidCallback retry;

  /// Leaves for the series page.
  final VoidCallback back;
}

/// The reader frames a skin supplies. Every field null is the legacy reader: `ReaderContent`,
/// `ReaderSkeleton` and `ReaderErrorState`. The two entry screens (`ReaderScreen`,
/// `SourceReaderScreen`) read this, so a skin swaps the frame without owning a data path.
class ReaderFrames {
  const ReaderFrames({this.content, this.loading, this.failure});

  /// Receives the resolved reader body (feed, callbacks, identity) as the legacy widget.
  final Widget Function(BuildContext context, ReaderContent body)? content;
  final Widget Function(BuildContext context)? loading;
  final Widget Function(BuildContext context, ReaderFailure failure)? failure;
}

/// Overridden by the Cinematic reader route; the default keeps the legacy frame.
final readerFramesProvider = Provider<ReaderFrames>((ref) => const ReaderFrames(), name: 'readerFrames');
