import 'package:manhwamaniacs/features/library/models/followed_series.dart';

/// One smart-shelf condition (backend `RuleCondition`): `field op value`.
class ShelfRule {
  const ShelfRule({required this.field, required this.op, required this.value});

  /// `reading_status | is_favorite | new_count | format | content_kind`.
  final String field;

  /// `eq | gte | in | ne`.
  final String op;

  /// A bool, an int, a string or (for `in`) a list of strings.
  final Object value;

  static const fields = {'reading_status', 'is_favorite', 'new_count', 'format', 'content_kind'};

  /// Null for anything that is not a known condition.
  static ShelfRule? tryParse(Object? json) {
    if (json is! Map) return null;
    final Object? field = json['field'], op = json['op'], value = json['value'];
    if (field is! String || op is! String || value == null) return null;
    if (value is List) return ShelfRule(field: field, op: op, value: [for (final v in value) '$v']);
    return ShelfRule(field: field, op: op, value: value);
  }

  Map<String, dynamic> toJson() => {'field': field, 'op': op, 'value': value};

  @override
  bool operator ==(Object other) =>
      other is ShelfRule && other.field == field && other.op == op && '${other.value}' == '$value';

  @override
  int get hashCode => Object.hash(field, op, '$value');
}

/// The rules of a smart shelf: every one must hold (AND).
class ShelfRules {
  const ShelfRules({this.all = const []});
  final List<ShelfRule> all;

  static ShelfRules? tryParse(Object? json) {
    if (json is! Map || json['all'] is! List) return null;
    return ShelfRules(all: [for (final r in json['all'] as List) if (ShelfRule.tryParse(r) case final x?) x]);
  }

  Map<String, dynamic> toJson() => {'all': [for (final r in all) r.toJson()]};

  @override
  bool operator ==(Object other) => other is ShelfRules && other.all.length == all.length && _same(other.all);

  bool _same(List<ShelfRule> o) {
    for (var i = 0; i < all.length; i++) {
      if (all[i] != o[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(all);
}

/// The "unfinished novels" pair of the New shelf form.
const unfinishedNovels = [
  ShelfRule(field: 'content_kind', op: 'eq', value: 'novel'),
  ShelfRule(field: 'reading_status', op: 'ne', value: 'completed'),
];

bool _holds(ShelfRule r, Object? actual) {
  final v = r.value;
  switch (r.op) {
    case 'eq':
      return '$actual' == '$v';
    case 'ne':
      return '$actual' != '$v';
    case 'gte':
      final a = actual is num ? actual : num.tryParse('$actual');
      final b = v is num ? v : num.tryParse('$v');
      return a != null && b != null && a >= b;
    case 'in':
      return v is List && v.contains('$actual');
    default:
      return true;
  }
}

/// The rows of [rows] that satisfy every rule of [rules], in the library's order (the one
/// evaluator both skins run, glass 8.18). `new_count` comes from the row's read state;
/// `format` and `content_kind` come from [formatOf] and [contentKindOf] (the backend sends
/// neither on a follow, so the screen supplies the source's kind). A rule on an unknown field,
/// or whose value the row cannot supply, is ignored.
List<FollowedSeries> evaluateShelf(
  ShelfRules rules,
  List<FollowedSeries> rows, {
  String? Function(FollowedSeries row)? formatOf,
  String? Function(FollowedSeries row)? contentKindOf,
}) {
  final active = [for (final r in rules.all) if (ShelfRule.fields.contains(r.field)) r];
  bool ok(FollowedSeries s) {
    for (final r in active) {
      final Object? actual = switch (r.field) {
        'reading_status' => s.readingStatus,
        'is_favorite' => s.isFavorite,
        'new_count' => s.readState?.newCount ?? 0,
        'format' => formatOf?.call(s),
        'content_kind' => contentKindOf?.call(s),
        _ => null,
      };
      if ((r.field == 'format' || r.field == 'content_kind') && actual == null) continue;
      if (!_holds(r, actual)) return false;
    }
    return true;
  }

  return [for (final s in rows) if (ok(s)) s];
}

const _statusWords = {
  'unread': 'NOT STARTED',
  'reading': 'READING',
  'completed': 'DONE',
  'on_hold': 'ON HOLD',
  'plan_to_read': 'PLAN TO READ',
  'dropped': 'DROPPED',
};

/// The credit text: `READING · 3+ NEW · FAVOURITES · MANHWA, MANGA · UNFINISHED NOVELS`.
String describeRules(ShelfRules rules) {
  final parts = <String>[];
  final novelKind = rules.all.any((r) => r.field == 'content_kind' && r.op == 'eq' && r.value == 'novel');
  final unfinished = rules.all.any((r) => r.field == 'reading_status' && r.op == 'ne' && r.value == 'completed');
  for (final r in rules.all) {
    switch ((r.field, r.op)) {
      case ('reading_status', 'eq'):
        parts.add(_statusWords['${r.value}'] ?? '${r.value}'.toUpperCase());
      case ('reading_status', 'ne') when novelKind && unfinished:
        break;
      case ('content_kind', 'eq') when novelKind && unfinished:
        parts.add('UNFINISHED NOVELS');
      case ('is_favorite', 'eq') when r.value == true:
        parts.add('FAVOURITES');
      case ('new_count', 'gte'):
        parts.add('${r.value}+ NEW');
      case ('format', 'in'):
        parts.add((r.value as List).map((e) => '$e'.toUpperCase()).join(', '));
      case ('format', 'eq'):
        parts.add('${r.value}'.toUpperCase());
      case ('content_kind', 'eq'):
        parts.add('${r.value}'.toUpperCase());
    }
  }
  return parts.join(' · ');
}
