import 'dart:io';
import 'dart:ui' show Rect;

import 'package:manhwamaniacs/core/network/api_image.dart';

class ReaderPage {
  const ReaderPage({
    required this.id,
    required this.number,
    required this.imageUrl,
    this.width,
    this.height,
    this.localFile,
    this.tint,
    this.panels,
  });

  final String id;
  final int number;
  final String imageUrl;
  final int? width;
  final int? height;

  /// On-device chapter store resolution (1c-M3): when non-null,
  /// [ReaderPageImage] renders from this file instead of [imageUrl] — no
  /// network involved at all. Populated by
  /// `features/downloads/services/offline_reader.dart`, either as an overlay
  /// on an online-fetched chapter (bandwidth saved for already-downloaded
  /// pages) or as the sole source when the chapter was rebuilt entirely from
  /// the store because the network fetch failed.
  final File? localFile;

  /// The manifest's stored page tint (`#RRGGBB`), when a client reported one (mobile/23).
  final String? tint;

  /// The manifest's stored panels in page fractions; null = not analysed yet, empty = none.
  final List<Rect>? panels;

  double? get aspectRatio {
    final w = width;
    final h = height;
    if (w == null || h == null || h == 0) return null;
    return w / h;
  }

  /// Value equality, so a chapter re-resolved from the same bytes compares
  /// equal to the one it replaces — see [ReaderChapter]'s note for why the
  /// reader depends on that.
  ///
  /// [localFile] is compared by path: `dart:io`'s `File` does not override
  /// `==`, so two handles on the same file are never equal and comparing them
  /// directly would report every re-resolution as a change.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReaderPage &&
          other.id == id &&
          other.number == number &&
          other.imageUrl == imageUrl &&
          other.width == width &&
          other.height == height &&
          other.localFile?.path == localFile?.path &&
          other.tint == tint &&
          (other.panels == null) == (panels == null) &&
          (panels == null || other.panels!.length == panels!.length);

  @override
  int get hashCode =>
      Object.hash(id, number, imageUrl, width, height, localFile?.path, tint, panels?.length);

  ReaderPage withLocalFile(File file) => ReaderPage(
        id: id,
        number: number,
        imageUrl: imageUrl,
        width: width,
        height: height,
        localFile: file,
        tint: tint,
        panels: panels,
      );

  factory ReaderPage.fromJson(Map<String, dynamic> json, String apiBaseUrl) {
    final rawUrl = json['image_url'] as String? ?? '';
    return ReaderPage(
      id: json['id'].toString(),
      number: json['number'] as int,
      imageUrl: rawUrl.isEmpty ? '' : resolveApiResourceUrl(apiBaseUrl, rawUrl),
      width: json['width'] as int?,
      height: json['height'] as int?,
    );
  }
}
