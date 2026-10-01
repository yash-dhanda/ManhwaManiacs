import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/storage/json_record.dart';
import 'package:manhwamaniacs/features/novels/models/glass_novel_prefs.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_preferences_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_profile_settings.dart';
import 'package:manhwamaniacs/features/settings/providers/a11y_prefs_provider.dart';

/// `mm.novel-defaults.u{user}p{profile}`: the profile's Glass book defaults `{size, lineHeight, measure, glassFace}`
/// (no earlier record existed; `mobile/39`'s Novels group edits it). Unknown fields survive every write.
class GlassNovelDefaultsNotifier extends ProfileRecordNotifier {
  @override
  String get prefix => 'mm.novel-defaults.';
}

final glassNovelDefaultsProvider = NotifierProvider<GlassNovelDefaultsNotifier, JsonRecord>(GlassNovelDefaultsNotifier.new, name: 'glassNovelDefaults');

/// One book.
typedef GlassBookRef = ({String sourceId, String seriesKey});

/// The Glass novel preferences of one book (A1): [values] resolves them for the current window and text
/// scale; the writers touch only Glass's fields and the shared ones, through the record notifiers that keep
/// every unknown field.
class GlassNovelPrefs {
  const GlassNovelPrefs._(this.book, this._book, this._settings, this._defaults, this._k26, this._legible, this._writer);
  final GlassBookRef book;
  final Map<String, dynamic> _book;
  final JsonRecord _settings, _defaults;
  final String? _k26;
  final bool _legible;
  final _GlassNovelWriter _writer;

  /// The values for a window in the desktop frame or not, at the system text [scale].
  GlassNovelValues values({required bool desktopFrame, double Function(double size)? scale}) => resolveGlassNovel(
        book: _book,
        settings: _settings,
        defaults: _defaults,
        k26: _k26,
        legible: _legible,
        desktopFrame: desktopFrame,
        scale: scale,
      );

  /// Writes per-book fields (a null removes the key, so the book falls back again).
  Future<void> setBook(Map<String, Object?> patch) => _writer.setBook(patch);

  /// Writes per-profile fields of `mm.novel-settings`.
  Future<void> setProfile(Map<String, Object?> patch) => _writer.setProfile(patch);

  /// Back to the defaults for this book: only the Glass-visible per-book fields go.
  Future<void> resetBook() => setBook({for (final k in GlassNovelKeys.bookTypography) k: null});
}

/// Watches nothing, so its ref is never stale when a writer runs after a record changed.
class _GlassNovelWriter {
  _GlassNovelWriter(this._ref, this._key);
  final Ref _ref;
  final String _key;

  Future<void> setBook(Map<String, Object?> patch) =>
      _ref.read(novelPreferencesControllerProvider(_key).notifier).update(_ref.read(novelPreferencesControllerProvider(_key)).withRaw(patch));

  Future<void> setProfile(Map<String, Object?> patch) => _ref.read(novelSettingsProvider.notifier).put(patch);
}

final _glassNovelWriterProvider = Provider.family<_GlassNovelWriter, GlassBookRef>(
  (ref, b) => _GlassNovelWriter(ref, novelSeriesPrefsKey(b.sourceId, b.seriesKey)),
);

/// Rebuilds whenever one of the four records (or Legible text) changes, so a watcher re-resolves.
final glassNovelPrefsProvider = Provider.family<GlassNovelPrefs, GlassBookRef>(
  (ref, book) => GlassNovelPrefs._(
    book,
    ref.watch(novelPreferencesControllerProvider(novelSeriesPrefsKey(book.sourceId, book.seriesKey))).raw,
    ref.watch(novelSettingsProvider),
    ref.watch(glassNovelDefaultsProvider),
    ref.watch(novelPaletteControllerProvider),
    ref.watch(legibleTextProvider),
    ref.watch(_glassNovelWriterProvider(book)),
  ),
  name: 'glassNovelPrefs',
);
