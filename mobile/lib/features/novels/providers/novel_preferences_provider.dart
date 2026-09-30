import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/storage/json_record.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/novels/models/novel_palette.dart';
import 'package:manhwamaniacs/features/novels/models/novel_typography.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_profile_settings.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';

/// Type settings for one book (the K25 record `mm.novel-prefs.u{user}p{profile}`, keyed
/// `source:series`).
///
/// The legacy fields keep their own (15-26, 1.4-2.1) clamps when read through the getters, but
/// the stored record is carried verbatim in [raw]: a legacy write never strips the Cinematic
/// fields (`face`, `paragraphSpacing`, `letterSpacing`, a size beyond 26) and a Cinematic write
/// never invents the legacy ones.
class NovelPreferences {
  const NovelPreferences({
    this.fontSize = kDefaultNovelFontSize,
    this.lineHeight = kDefaultNovelLineHeight,
    this.measure = kDefaultNovelMeasure,
    this.fontFamily = NovelFontFamily.serif,
    this.raw = const <String, dynamic>{},
  });

  final double fontSize;
  final double lineHeight;

  /// Column width in characters — see `models/novel_typography.dart`.
  final double measure;
  final NovelFontFamily fontFamily;

  /// The stored record, unknown fields included.
  final Map<String, dynamic> raw;

  bool get hasSize => raw['fontSize'] is num;
  bool get hasLineHeight => raw['lineHeight'] is num;
  bool get hasMeasure => raw['measure'] is num;

  /// The stored face, else the read-time fallback from the legacy `fontFamily` (`serif` ->
  /// Newsreader, `sans` -> Archivo); null when the book stores neither.
  NovelFace? get face =>
      NovelFace.fromWire(raw['face'] as String?) ??
      (raw['fontFamily'] is String ? (NovelFontFamily.fromWire(raw['fontFamily'] as String?) == NovelFontFamily.sans ? NovelFace.archivo : NovelFace.newsreader) : null);

  /// The stored Cinematic values, each clamped to its own range; null when absent.
  double? get storedSize => hasSize ? clampCineFontSize((raw['fontSize'] as num).toDouble()) : null;
  double? get storedLeading => hasLineHeight ? clampCineLeading((raw['lineHeight'] as num).toDouble()) : null;
  double? get storedMeasure => hasMeasure ? clampCineMeasure((raw['measure'] as num).toDouble()) : null;
  double get paragraphSpacing => raw['paragraphSpacing'] is num ? clampParagraphSpacing((raw['paragraphSpacing'] as num).toDouble()) : 0;
  double get letterSpacing => raw['letterSpacing'] is num ? clampLetterSpacing((raw['letterSpacing'] as num).toDouble()) : 0;

  NovelPreferences copyWith({
    double? fontSize,
    double? lineHeight,
    double? measure,
    NovelFontFamily? fontFamily,
  }) =>
      NovelPreferences(
        fontSize: clampNovelFontSize(fontSize ?? this.fontSize),
        lineHeight: clampNovelLineHeight(lineHeight ?? this.lineHeight),
        measure: clampNovelMeasure(measure ?? this.measure),
        fontFamily: fontFamily ?? this.fontFamily,
        raw: {
          ...raw,
          if (fontSize != null) 'fontSize': clampNovelFontSize(fontSize),
          if (lineHeight != null) 'lineHeight': clampNovelLineHeight(lineHeight),
          if (measure != null) 'measure': clampNovelMeasure(measure),
          if (fontFamily != null) 'fontFamily': fontFamily.wire,
        },
      );

  /// Sets Cinematic keys (already clamped by the caller) in the stored record; a null value
  /// removes the key, so the book falls back to the profile default again.
  NovelPreferences withRaw(Map<String, Object?> patch) {
    final next = {...raw};
    patch.forEach((k, v) => v == null ? next.remove(k) : next[k] = v);
    return NovelPreferences(
      fontSize: fontSize,
      lineHeight: lineHeight,
      measure: measure,
      fontFamily: fontFamily,
      raw: next,
    );
  }

  /// The record as stored: only keys somebody set. A book that never chose a size keeps no
  /// `fontSize`, so the Cinematic reader can still open it at the system-scaled default.
  Map<String, dynamic> toJson() => Map<String, dynamic>.of(raw);

  /// Clamped on the way IN (legacy ranges) but the record itself is kept in [raw].
  factory NovelPreferences.fromJson(Map<String, dynamic> json) => NovelPreferences(
        fontSize: clampNovelFontSize(
          (json['fontSize'] as num?)?.toDouble() ?? kDefaultNovelFontSize,
        ),
        lineHeight: clampNovelLineHeight(
          (json['lineHeight'] as num?)?.toDouble() ?? kDefaultNovelLineHeight,
        ),
        measure: clampNovelMeasure(
          (json['measure'] as num?)?.toDouble() ?? kDefaultNovelMeasure,
        ),
        fontFamily: NovelFontFamily.fromWire(json['fontFamily'] as String?),
        raw: Map<String, dynamic>.from(json),
      );
}

/// Typography, per SERIES — the same split the manga reader draws between its
/// per-series mode/fit/zoom and its app-wide defaults.
///
/// A dense translated web novel wants a bigger face and looser leading than a
/// crisply edited original; a reader who tuned one should not have to re-tune
/// it every time they move between the two. So size / leading / measure / face
/// are keyed by series.
///
/// The reading PALETTE deliberately does not live here — it is a property of
/// the room and the hour, not of the book, so it is per-profile
/// ([novelPaletteControllerProvider]).
///
/// Scoped per `(user, profile)` like every other on-device preference: two
/// personas on one phone read different things, and inheriting a sibling's
/// setup is both wrong and a small disclosure that the sibling reads that
/// series at all.
final novelPreferencesControllerProvider = NotifierProvider.family<
    NovelPreferencesController, NovelPreferences, String>(
  NovelPreferencesController.new,
  name: 'novelPreferences',
);

/// Stable per-series key: the opaque `(sourceId, seriesKey)` pair, joined the
/// same way the manga reader's scroll-storage key is.
String novelSeriesPrefsKey(String sourceId, String seriesKey) =>
    '$sourceId:$seriesKey';

class NovelPreferencesController
    extends FamilyNotifier<NovelPreferences, String> {
  static const String _keyPrefix = 'mm.novel-prefs.';
  static const String _deviceKey = 'mm.novel-prefs.device';

  @override
  NovelPreferences build(String seriesKey) {
    final prefs = ref.watch(sharedPrefsProvider);
    final raw = prefs.getString(_storageKey(watch: true));
    return _readStore(raw)[seriesKey] ?? const NovelPreferences();
  }

  Future<void> update(NovelPreferences next) async {
    state = next;
    final prefs = ref.read(sharedPrefsProvider);
    final key = _storageKey(watch: false);
    final store = _readStore(prefs.getString(key));
    store[arg] = next;
    await prefs.setString(
      key,
      jsonEncode({for (final e in store.entries) e.key: e.value.toJson()}),
    );
  }

  Future<void> setFontSize(double value) =>
      update(state.copyWith(fontSize: value));

  Future<void> setLineHeight(double value) =>
      update(state.copyWith(lineHeight: value));

  Future<void> setMeasure(double value) =>
      update(state.copyWith(measure: value));

  Future<void> setFontFamily(NovelFontFamily value) =>
      update(state.copyWith(fontFamily: value));

  // Cinematic controls (mobile/14): each writes only its own key.
  Future<void> setFace(NovelFace face) => update(state.withRaw({'face': face.wire}));
  Future<void> setSize(double v) => update(state.withRaw({'fontSize': clampCineFontSize(v)}));
  Future<void> setLeading(double v) => update(state.withRaw({'lineHeight': clampCineLeading(v)}));
  Future<void> setCineMeasure(double v) => update(state.withRaw({'measure': clampCineMeasure(v)}));
  Future<void> setParagraphSpacing(double v) => update(state.withRaw({'paragraphSpacing': clampParagraphSpacing(v)}));
  Future<void> setLetterSpacing(double v) => update(state.withRaw({'letterSpacing': clampLetterSpacing(v)}));

  /// Forgets every per-book type value: the book reads the profile and face defaults again.
  Future<void> resetType() => update(state.withRaw({
        'face': null,
        'fontFamily': null,
        'fontSize': null,
        'lineHeight': null,
        'measure': null,
        'paragraphSpacing': null,
        'letterSpacing': null,
      }),);

  /// One map for every series this persona has tuned. A corrupt blob resolves
  /// to an empty store rather than throwing: type settings are a convenience,
  /// and losing them must never be the reason a chapter refuses to open.
  Map<String, NovelPreferences> _readStore(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return {
        for (final entry in decoded.entries)
          if (entry.value is Map)
            entry.key as String: NovelPreferences.fromJson(
              Map<String, dynamic>.from(entry.value as Map),
            ),
      };
    } catch (_) {
      return {};
    }
  }

  String _storageKey({required bool watch}) =>
      _scopedKey(ref, prefix: _keyPrefix, deviceKey: _deviceKey, watch: watch);
}

/// The reading palette, per PROFILE.
///
/// Unlike typography (which is about the book), the surface a page is painted
/// on is about the room, the hour and the reader's eyes. It should follow
/// someone from novel to novel, exactly as the manga reader's dimmer and
/// warmth do.
///
/// The stored value is a palette id, [NovelPalettes.followAppId], or nothing
/// at all — and "nothing at all" is a real state, not a missing value: it
/// means "never chose one", and only then does the app's own light/dark seed
/// Paper or Dusk. An explicit choice is never overridden by a theme change,
/// because a palette that flips when the app's theme flips is not an
/// independent palette.
final novelPaletteControllerProvider =
    NotifierProvider<NovelPaletteController, String?>(
  NovelPaletteController.new,
  name: 'novelPalette',
);

class NovelPaletteController extends Notifier<String?> {
  static const String _keyPrefix = 'mm.novel-palette.';
  static const String _deviceKey = 'mm.novel-palette.device';

  @override
  String? build() {
    final prefs = ref.watch(sharedPrefsProvider);
    final stored = prefs.getString(_storageKey(watch: true));
    return NovelPalettes.isChoice(stored) ? stored : null;
  }

  Future<void> setChoice(String choice) async {
    if (!NovelPalettes.isChoice(choice)) return;
    state = choice;
    await ref
        .read(sharedPrefsProvider)
        .setString(_storageKey(watch: false), choice);
  }

  String _storageKey({required bool watch}) =>
      _scopedKey(ref, prefix: _keyPrefix, deviceKey: _deviceKey, watch: watch);
}

/// `"{prefix}u{userId}p{profileId}"`, or [deviceKey] outside a session.
///
/// The same scope-id convention as the on-device chapter store and the theme
/// controller — one format for all per-persona device state, so there is one
/// shape to get wrong rather than three. `watch` is true from a `build` (so
/// profile and account switches recompute) and false from a write (which must
/// not add dependencies).
String _scopedKey(
  Ref ref, {
  required String prefix,
  required String deviceKey,
  required bool watch,
}) {
  int? selectUserId(AuthState auth) =>
      auth is AuthAuthenticated ? auth.user.id : null;
  final userId = watch
      ? ref.watch(authControllerProvider.select(selectUserId))
      : selectUserId(ref.read(authControllerProvider));
  final profileId = watch
      ? ref.watch(activeProfileProvider.select((p) => p?.id))
      : ref.read(activeProfileProvider)?.id;
  if (userId == null || profileId == null) return deviceKey;
  return '${prefix}u${userId}p$profileId';
}


/// Resolves what the Cinematic reader sets its body in: the book's stored values, then the
/// profile's `bookDefaults` (Settings), then the face defaults scaled by the system text scale
/// (cinematic 3.3, 3.4). Pure: [systemScale] is `MediaQuery.textScalerOf(context).scale(1)`.
NovelType resolveNovelType({
  required NovelPreferences book,
  required JsonRecord settings,
  required bool legible,
  required double systemScale,
  required bool tablet,
  required bool osBold,
}) {
  final defaults = settings.data['bookDefaults'] is Map ? settings.child('bookDefaults') : null;
  final face = book.face ??
      NovelFace.fromWire(defaults?.data['face'] as String?) ??
      (legible ? NovelFace.atkinson : NovelFace.newsreader);
  final d = faceDefaults(face, tablet: tablet);
  final double size = book.storedSize ??
      (defaults != null && defaults.data['fontSize'] is num
          ? clampCineFontSize(defaults.doubleOf('fontSize', d.size))
          : clampCineFontSize((d.size * systemScale).roundToDouble()));
  final leading = book.storedLeading ??
      (defaults != null && defaults.data['lineHeight'] is num ? clampCineLeading(defaults.doubleOf('lineHeight', d.leading)) : d.leading);
  final measure = book.storedMeasure ??
      (defaults != null && defaults.data['measure'] is num ? clampCineMeasure(defaults.doubleOf('measure', kCineDefaultMeasure)) : kCineDefaultMeasure);
  return NovelType(
    face: face,
    fontSize: size,
    lineHeight: leading,
    measure: measure,
    letterSpacing: book.letterSpacing,
    paragraphSpacing: book.paragraphSpacing,
    bold: settings.novelBold,
    osBold: osBold,
    justify: settings.novelJustify,
  );
}
