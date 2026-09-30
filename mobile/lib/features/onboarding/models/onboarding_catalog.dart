import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/features/onboarding/models/taste.dart';

class FormatCovers {
  const FormatCovers({required this.format, this.covers = const []});
  final FormatId format;
  final List<String> covers;
}

class GenreWeight {
  const GenreWeight({required this.name, required this.weight});
  final String name;
  final double weight;
}

/// `GET /onboarding/catalog`. [unavailableReason] is set when the worldwide catalogue could not be
/// reached (the lists are then thin or empty).
class OnboardingCatalog {
  const OnboardingCatalog({this.formats = const [], this.genres = const [], this.seeds = const [], this.unavailableReason});
  final List<FormatCovers> formats;
  final List<GenreWeight> genres;
  final List<WorldItem> seeds;
  final String? unavailableReason;

  factory OnboardingCatalog.fromJson(Map<String, dynamic> j) => OnboardingCatalog(
        formats: [
          for (final e in (j['formats'] as List? ?? const []))
            if (e is Map && FormatId.fromWire(e['format']) != null)
              FormatCovers(format: FormatId.fromWire(e['format'])!, covers: [for (final c in (e['covers'] as List? ?? const [])) if (c is String && c.isNotEmpty) c]),
        ],
        genres: [
          for (final e in (j['genres'] as List? ?? const []))
            if (e is Map && e['name'] is String) GenreWeight(name: e['name'] as String, weight: (e['weight'] as num?)?.toDouble() ?? 0),
        ],
        seeds: [
          for (final e in (j['seeds'] as List? ?? const []))
            if (e is Map<String, dynamic>) WorldItem.fromJson(e),
        ],
        unavailableReason: j['unavailable_reason'] as String?,
      );
}
