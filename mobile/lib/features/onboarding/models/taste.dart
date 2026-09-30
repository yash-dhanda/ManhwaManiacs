/// The onboarding answers and how they travel (`PUT /profiles/{id}/taste`). Skin-neutral.
enum FormatId {
  manhwa('manhwa'),
  manga('manga'),
  manhua('manhua'),
  novel('novel');

  const FormatId(this.wire);
  final String wire;

  static FormatId? fromWire(Object? v) {
    for (final f in values) {
      if (f.wire == v) return f;
    }
    return null;
  }
}

/// The server's union of both skins' art styles; Cinematic offers the first nine.
enum StyleId {
  painted('painted'),
  cel('cel'),
  screentone('screentone'),
  manhua3d('manhua-3d'),
  sketch('sketch'),
  retro('retro'),
  pastel('pastel'),
  noir('noir'),
  chibi('chibi'),
  watercolour('watercolour'),
  darkRealism('dark-realism');

  const StyleId(this.wire);
  final String wire;

  static StyleId? fromWire(Object? v) {
    for (final s in values) {
      if (s.wire == v) return s;
    }
    return null;
  }
}

enum GenreMark {
  like(1),
  love(2),
  skip(-1);

  const GenreMark(this.wire);
  final int wire;

  static GenreMark? fromWire(Object? v) {
    for (final m in values) {
      if (m.wire == v) return m;
    }
    return null;
  }
}

/// A saved step: 1 to 7, or done.
class OnboardingStep {
  const OnboardingStep._(this.n);
  factory OnboardingStep.at(int n) {
    assert(n >= 1 && n <= 7, 'step 1 to 7');
    return OnboardingStep._(n);
  }
  static const OnboardingStep done = OnboardingStep._(null);

  /// The step number, null for done.
  final int? n;
  bool get isDone => n == null;

  /// An `int`, `"done"`, a digit string, or null (anything else is null).
  static OnboardingStep? parse(Object? json) {
    if (json is String) {
      if (json == 'done') return done;
      json = int.tryParse(json);
    }
    if (json is int && json >= 1 && json <= 7) return OnboardingStep._(json);
    return null;
  }

  Object toJson() => n ?? 'done';

  @override
  bool operator ==(Object other) => other is OnboardingStep && other.n == n;
  @override
  int get hashCode => n.hashCode;
  @override
  String toString() => 'OnboardingStep(${n ?? 'done'})';
}

/// A pick: an AniList id, or a source series.
class TasteSeed {
  const TasteSeed.anilist(int this.anilistId)
      : sourceId = null,
        seriesKey = null;
  const TasteSeed.series(String this.sourceId, String this.seriesKey) : anilistId = null;
  final int? anilistId;
  final String? sourceId, seriesKey;

  Map<String, Object> toJson() => anilistId != null ? {'anilist_id': anilistId!} : {'source_id': sourceId!, 'series_key': seriesKey!};

  static TasteSeed? fromJson(Object? j) {
    if (j is! Map) return null;
    final a = j['anilist_id'];
    if (a is int) return TasteSeed.anilist(a);
    final s = j['source_id'], k = j['series_key'];
    return s is String && k is String ? TasteSeed.series(s, k) : null;
  }
}

enum TasteField { formats, genres, styles, seeds }

/// The answers. A genre mapped to null was cleared (it travels as weight 0).
class Taste {
  const Taste({this.formats = const [], this.genres = const {}, this.styles = const [], this.seeds = const []});
  final List<FormatId> formats;
  final Map<String, GenreMark?> genres;
  final List<StyleId> styles;
  final List<TasteSeed> seeds;

  Taste copyWith({List<FormatId>? formats, Map<String, GenreMark?>? genres, List<StyleId>? styles, List<TasteSeed>? seeds}) =>
      Taste(formats: formats ?? this.formats, genres: genres ?? this.genres, styles: styles ?? this.styles, seeds: seeds ?? this.seeds);

  /// `GET /profiles/{id}/taste`, leniently.
  factory Taste.fromJson(Map<String, dynamic> j) => Taste(
        formats: [for (final f in (j['formats'] as List? ?? const [])) if (FormatId.fromWire(f) != null) FormatId.fromWire(f)!],
        genres: {
          for (final e in ((j['genres'] as Map?) ?? const {}).entries)
            if (e.key is String && GenreMark.fromWire(e.value) != null) e.key as String: GenreMark.fromWire(e.value),
        },
        styles: [for (final s in (j['styles'] as List? ?? const [])) if (StyleId.fromWire(s) != null) StyleId.fromWire(s)!],
        seeds: [for (final s in (j['seeds'] as List? ?? const [])) if (TasteSeed.fromJson(s) != null) TasteSeed.fromJson(s)!],
      );
}

/// A step plus only the fields the reader touched.
class TasteUpdate {
  const TasteUpdate({required this.step, this.partial = const Taste(), this.touched = const {}});
  final OnboardingStep step;
  final Taste partial;
  final Set<TasteField> touched;

  Map<String, Object> toJson() => {
        'step': step.toJson(),
        if (touched.contains(TasteField.formats)) 'formats': [for (final f in partial.formats) f.wire],
        if (touched.contains(TasteField.genres)) 'genres': {for (final e in partial.genres.entries) e.key: e.value?.wire ?? 0},
        if (touched.contains(TasteField.styles)) 'styles': [for (final s in partial.styles) s.wire],
        if (touched.contains(TasteField.seeds)) 'seeds': [for (final s in partial.seeds) s.toJson()],
      };
}
