import 'dart:ui' show Color;

import 'package:manhwamaniacs/core/time/server_instant.dart';
import 'package:manhwamaniacs/features/library/utils/smart_shelf.dart';

class CollectionRef {
  const CollectionRef({required this.id, required this.name});

  final int id;
  final String name;

  factory CollectionRef.fromJson(Map<String, dynamic> json) => CollectionRef(
        id: json['id'] as int,
        name: json['name'] as String,
      );
}

class Collection {
  const Collection({
    required this.id,
    required this.name,
    this.description,
    this.coverUrl,
    required this.seriesCount,
    required this.sortOrder,
    this.rules,
    this.previewCovers = const [],
    this.previewAmbientDuo,
    this.createdAt,
  });

  final int id;
  final String name;
  final String? description;
  final String? coverUrl;
  final int seriesCount;
  final int sortOrder;

  /// Smart-shelf rules; null for a manual shelf.
  final ShelfRules? rules;

  /// At most four member cover URLs (empty for a smart shelf: the device computes its mosaic).
  final List<String> previewCovers;

  /// The first member's duotone colour where the server sent it.
  final Color? previewAmbientDuo;
  final DateTime? createdAt;

  bool get smart => rules != null;

  factory Collection.fromJson(Map<String, dynamic> json) {
    final covers = json['preview_covers'];
    final duo = json['preview_ambient_duo'];
    final hex = duo is String ? int.tryParse(duo.startsWith('#') ? duo.substring(1) : duo, radix: 16) : null;
    return Collection(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      coverUrl: json['cover_url'] as String?,
      seriesCount: (json['series_count'] as num?)?.toInt() ?? 0,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      rules: ShelfRules.tryParse(json['rules']),
      previewCovers: covers is List ? [for (final c in covers.take(4)) if (c is String) c] : const [],
      previewAmbientDuo: hex == null ? null : Color(0xFF000000 | hex),
      createdAt: serverInstant(json['created_at']),
    );
  }
}
