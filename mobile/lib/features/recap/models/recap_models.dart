import 'package:manhwamaniacs/features/home/models/home_feed.dart' show RecapAvailability;
import 'package:manhwamaniacs/features/recap/sse.dart';

export 'package:manhwamaniacs/features/home/models/home_feed.dart' show RecapAvailability;

class RecapRange {
  const RecapRange({this.fromKey, this.toKey, this.fromNumber, this.toNumber});
  final String? fromKey, toKey;
  final num? fromNumber, toNumber;

  static RecapRange? tryParse(Object? j) {
    if (j is! Map) return null;
    return RecapRange(
      fromKey: j['from_key'] as String?,
      toKey: j['to_key'] as String?,
      fromNumber: j['from_number'] as num?,
      toNumber: j['to_number'] as num?,
    );
  }

  /// `131–142` or `142`; null with no numbers.
  String? get label {
    String n(num v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();
    final a = fromNumber, b = toNumber;
    if (b == null) return null;
    return a == null || a == b ? n(b) : '${n(a)}–${n(b)}';
  }

  bool get single => fromNumber == null || fromNumber == toNumber;
}

class RecapCast {
  const RecapCast(this.name, this.role);
  final String name, role;
}

sealed class RecapEvent {
  const RecapEvent();
}

class RecapMeta extends RecapEvent {
  const RecapMeta({this.range, this.cast = const [], this.sourcedFrom = 'ocr', this.generatedAt});
  final RecapRange? range;
  final List<RecapCast> cast;

  /// `ocr` or `text`.
  final String sourcedFrom;
  final DateTime? generatedAt;

  factory RecapMeta.fromJson(Map<String, dynamic> j) => RecapMeta(
        range: RecapRange.tryParse(j['range']),
        cast: [
          for (final c in (j['cast'] as List? ?? const []))
            if (c is Map && ((c['name'] as String?)?.isNotEmpty ?? false)) RecapCast(c['name'] as String, (c['note'] ?? c['role'] ?? '') as String),
        ],
        sourcedFrom: j['sourced_from'] as String? ?? 'ocr',
        generatedAt: DateTime.tryParse((j['generated_at'] as String?) ?? ''),
      );
}

class RecapDelta extends RecapEvent {
  const RecapDelta(this.text);
  final String text;
}

class RecapDone extends RecapEvent {
  const RecapDone({this.generatedAt});
  final DateTime? generatedAt;
}

class RecapError extends RecapEvent {
  const RecapError(this.code, this.message, {this.retryAfter});
  final String code, message;
  final int? retryAfter;
}

/// The answer to opening a recap: a stream, or a plain JSON reason.
sealed class RecapOpen {
  const RecapOpen();
  const factory RecapOpen.none(String reason, {int? retryAfter}) = RecapNone;
  const factory RecapOpen.stream(Stream<RecapEvent> events) = RecapStream;
}

class RecapNone extends RecapOpen {
  const RecapNone(this.reason, {this.retryAfter});
  final String reason;
  final int? retryAfter;
}

class RecapStream extends RecapOpen {
  const RecapStream(this.events);
  final Stream<RecapEvent> events;
}

/// A deck recap (`shape=deck`): the raw SSE events (`phase`, `section`, `delta`, `done`, `error`) for `deckReducer`.
class DeckStream extends RecapOpen {
  const DeckStream(this.events);
  final Stream<SseEvent> events;
}

/// `Chapters 131–142` label of an availability range.
String? recapRangeLabel(RecapAvailability? a) => RecapRange(fromNumber: a?.fromNumber, toNumber: a?.toNumber).label;

/// A recap's identity for providers.
class RecapKey {
  const RecapKey(this.source, this.series, this.to);
  final String source, series, to;

  @override
  bool operator ==(Object other) => other is RecapKey && other.source == source && other.series == series && other.to == to;
  @override
  int get hashCode => Object.hash(source, series, to);
}
