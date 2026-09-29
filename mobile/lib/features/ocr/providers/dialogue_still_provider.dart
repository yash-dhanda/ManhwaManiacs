import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/network/request_limiter.dart';
import 'package:manhwamaniacs/features/downloads/models/chapter_identity.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

/// The page image behind one dialogue still: a local file for a downloaded
/// chapter (no request), else bytes at 480 px wide, plus the page aspect.
class DialogueStill {
  const DialogueStill({this.file, this.bytes, this.aspect});

  final File? file;
  final Uint8List? bytes;

  /// Page width / height when the page list knows it.
  final double? aspect;
}

typedef DialogueStillKey = ({ChapterIdentity chapter, int page});

/// Page list at P1 (cached per chapter by Riverpod), image at P3, or the local
/// blob when the chapter is downloaded. Null when the page can't be found.
final dialogueStillProvider = FutureProvider.autoDispose
    .family<DialogueStill?, DialogueStillKey>((ref, key) async {
  final limiter = ref.read(requestLimiterProvider);
  final local =
      await ref.read(downloadsStoreProvider)?.localPagePaths(key.chapter) ??
          const <int, File>{};
  final file = local[key.page];
  if (file != null) return DialogueStill(file: file);

  final pages = await limiter.run(
    RequestPriority.p1,
    () => ref.read(sourcesRepositoryProvider).getChapterPages(
          key.chapter.sourceId,
          key.chapter.chapterKey,
        ),
  );
  if (pages.isErr) return null;
  final page = pages.value.where((p) => p.number == key.page).firstOrNull;
  if (page == null || page.imageUrl.isEmpty) return null;
  final aspect = page.aspectRatio;
  final bytes = await limiter.run(RequestPriority.p3, () async {
    final r = await ref.read(dioProvider).get<List<int>>(
          page.imageUrl,
          queryParameters: {'w': 480},
          options: Options(responseType: ResponseType.bytes),
        );
    return Uint8List.fromList(r.data ?? const []);
  });
  return bytes.isEmpty ? null : DialogueStill(bytes: bytes, aspect: aspect);
});
