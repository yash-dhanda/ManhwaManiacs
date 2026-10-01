import 'dart:convert';

import 'package:manhwamaniacs/features/recap/models/recap_models.dart' show RecapCast;
import 'package:manhwamaniacs/features/recap/sse.dart';

/// One card of the deck: `kind` is `left_off | happened | cast | threads | last_time`.
class DeckSection {
  const DeckSection({required this.kind, required this.title, this.text = '', this.words = const []});
  final String kind, title, text;

  /// [text] split on spaces, for the word fade.
  final List<String> words;

  DeckSection append(String more) {
    final t = text + more;
    return DeckSection(kind: kind, title: title, text: t, words: t.split(' ').where((w) => w.isNotEmpty).toList());
  }

  Map<String, dynamic> toJson() => {'kind': kind, 'title': title, 'text': text};
  factory DeckSection.fromJson(Map<String, dynamic> j) => DeckSection(kind: j['kind'] as String? ?? '', title: j['title'] as String? ?? '').append(j['text'] as String? ?? '');
}

/// The `done` event: what the recap covers and who wrote it.
class DeckDone {
  const DeckDone({this.from, this.to, this.coveredThrough, this.cast = const [], this.sourcedFrom = 'ocr', this.model = '', this.generatedAt, this.available = true, this.reason});
  final num? from, to, coveredThrough;
  final List<RecapCast> cast;
  final String sourcedFrom, model;
  final DateTime? generatedAt;
  final bool available;
  final String? reason;

  factory DeckDone.fromJson(Map<String, dynamic> j) {
    final r = j['range'];
    return DeckDone(
      from: r is List && r.isNotEmpty ? r[0] as num? : null,
      to: r is List && r.length > 1 ? r[1] as num? : null,
      coveredThrough: j['covered_through'] as num?,
      cast: [
        for (final c in (j['cast'] as List? ?? const []))
          if (c is Map && ((c['name'] as String?)?.isNotEmpty ?? false)) RecapCast(c['name'] as String, (c['note'] ?? c['role'] ?? '') as String),
      ],
      sourcedFrom: j['sourced_from'] as String? ?? 'ocr',
      model: j['model'] as String? ?? '',
      generatedAt: DateTime.tryParse((j['generated_at'] as String?) ?? ''),
      available: j['available'] as bool? ?? true,
      reason: j['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'range': [from, to],
        'covered_through': coveredThrough,
        'cast': [for (final c in cast) {'name': c.name, 'note': c.role}],
        'sourced_from': sourcedFrom,
        'model': model,
        'generated_at': generatedAt?.toIso8601String(),
        'available': available,
        'reason': reason,
      };

  /// "120–141", "141", or null with no range.
  String? get rangeLabel {
    String n(num v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();
    final a = from, b = to;
    if (b == null) return null;
    return a == null || a == b ? n(b) : '${n(a)}–${n(b)}';
  }
}

class DeckError {
  const DeckError(this.code, this.message);
  final String code, message;
}

class DeckState {
  const DeckState({this.phase, this.sections = const [], this.done, this.error});
  final String? phase;
  final List<DeckSection> sections;
  final DeckDone? done;
  final DeckError? error;

  bool get finished => done != null || error != null;

  Map<String, dynamic> toJson() => {'sections': [for (final s in sections) s.toJson()], 'done': done?.toJson()};
  factory DeckState.fromJson(Map<String, dynamic> j) => DeckState(
        sections: [for (final s in (j['sections'] as List? ?? const [])) if (s is Map<String, dynamic>) DeckSection.fromJson(s)],
        done: j['done'] is Map<String, dynamic> ? DeckDone.fromJson(j['done'] as Map<String, dynamic>) : null,
      );
}

/// Folds one deck SSE event into the state: `phase`, `section` (arrival order), `delta` (appended to its section), `done`, `error`.
DeckState deckReducer(DeckState s, SseEvent e) {
  Map<String, dynamic> j = const {};
  try {
    final d = jsonDecode(e.data);
    if (d is Map<String, dynamic>) j = d;
  } catch (_) {}
  switch (e.event) {
    case 'phase':
      return DeckState(phase: j['phase'] as String?, sections: s.sections, done: s.done, error: s.error);
    case 'section':
      final kind = j['kind'] as String? ?? '';
      if (s.sections.any((x) => x.kind == kind)) return s;
      return DeckState(phase: s.phase, sections: [...s.sections, DeckSection(kind: kind, title: j['title'] as String? ?? '')], done: s.done, error: s.error);
    case 'delta':
      final kind = j['kind'] as String? ?? '';
      final text = j['text'] as String? ?? '';
      final has = s.sections.any((x) => x.kind == kind);
      final next = [for (final x in s.sections) x.kind == kind ? x.append(text) : x];
      if (!has) next.add(DeckSection(kind: kind, title: '').append(text));
      return DeckState(phase: s.phase, sections: next, done: s.done, error: s.error);
    case 'done':
      return DeckState(phase: s.phase, sections: s.sections, done: DeckDone.fromJson(j), error: s.error);
    case 'error':
      return DeckState(phase: s.phase, sections: s.sections, done: s.done, error: DeckError(j['code'] as String? ?? 'ai_failed', j['message'] as String? ?? ''));
  }
  return s;
}

/// Bullets of a section: one per line when it has lines, else one per sentence; empty items dropped.
List<String> sectionBullets(String text) {
  final parts = text.contains('\n') ? text.split('\n') : text.split(RegExp(r'(?<=[.!?])\s+'));
  return [for (final p in parts) if (p.trim().isNotEmpty) p.trim()];
}

/// The chapter "Start from ... instead" goes to: the start of the last third of the covered range.
String lastThirdStart(List<String> chapterKeys) => chapterKeys[(chapterKeys.length * 2) ~/ 3];

/// "3 days" (under 14), "3 weeks" (under 63), "3 months" after; singular forms for 1.
String gapWords(int days) {
  String f(int n, String u) => '$n $u${n == 1 ? '' : 's'}';
  if (days < 14) return f(days, 'day');
  if (days < 63) return f((days / 7).round(), 'week');
  return f((days / 30).round(), 'month');
}
