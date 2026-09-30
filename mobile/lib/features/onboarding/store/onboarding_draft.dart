import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/storage/profile_scoped_key.dart';
import 'package:manhwamaniacs/features/onboarding/models/taste.dart';
import 'package:manhwamaniacs/features/onboarding/repositories/onboarding_repository.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The device draft of one profile's answers: what was chosen, which fields were touched, and the
/// picks (AniList ids in pick order).
class OnboardingDraft {
  const OnboardingDraft({this.taste = const Taste(), this.touched = const {}, this.picks = const []});
  final Taste taste;
  final Set<TasteField> touched;
  final List<int> picks;

  bool get isEmpty => touched.isEmpty && picks.isEmpty;

  Map<String, Object> toJson() => {
        'taste': {
          'formats': [for (final f in taste.formats) f.wire],
          'genres': {for (final e in taste.genres.entries) e.key: e.value?.wire ?? 0},
          'styles': [for (final s in taste.styles) s.wire],
          'seeds': [for (final s in taste.seeds) s.toJson()],
        },
        'touched': [for (final t in touched) t.name],
        'picks': picks,
      };

  /// A corrupt blob is an empty draft.
  factory OnboardingDraft.fromJson(Object? j) {
    try {
      final m = j as Map;
      final t = Map<String, dynamic>.from(m['taste'] as Map);
      final genres = <String, GenreMark?>{
        for (final e in ((t['genres'] as Map?) ?? const {}).entries)
          if (e.key is String && (e.value is int)) e.key as String: GenreMark.fromWire(e.value),
      };
      final base = Taste.fromJson({...t, 'genres': <String, Object>{}});
      return OnboardingDraft(
        taste: base.copyWith(genres: genres),
        touched: {for (final n in (m['touched'] as List)) ...TasteField.values.where((f) => f.name == n)},
        picks: [for (final p in (m['picks'] as List)) p as int],
      );
    } catch (_) {
      return const OnboardingDraft();
    }
  }
}

/// [step] plus only the touched fields: a resume on another device never overwrites the server's
/// answers with empty ones.
TasteUpdate tasteBody(OnboardingDraft d, OnboardingStep step) => TasteUpdate(step: step, partial: d.taste, touched: d.touched);

const _draftPrefix = 'mm.onboarding.draft.';
const _pendingPrefix = 'mm.onboarding.pending.';

/// Device state per `(user, profile)`.
class OnboardingStore {
  OnboardingStore(this._ref);
  final Ref _ref;

  SharedPreferences get _p => _ref.read(sharedPrefsProvider);
  String _key(String prefix) => profileScopedKey(_ref, prefix: prefix, deviceKey: '${prefix}device', watch: false);

  OnboardingDraft readDraft() {
    final raw = _p.getString(_key(_draftPrefix));
    if (raw == null) return const OnboardingDraft();
    try {
      return OnboardingDraft.fromJson(jsonDecode(raw));
    } catch (_) {
      return const OnboardingDraft();
    }
  }

  Future<void> writeDraft(OnboardingDraft d) => _p.setString(_key(_draftPrefix), jsonEncode(d.toJson()));
  Future<void> clearDraft() => _p.remove(_key(_draftPrefix));

  /// A `step: done` update that failed to save.
  TasteUpdate? readPending() {
    final raw = _p.getString(_key(_pendingPrefix));
    if (raw == null) return null;
    try {
      final d = OnboardingDraft.fromJson((jsonDecode(raw) as Map)['draft']);
      return tasteBody(d, OnboardingStep.done);
    } catch (_) {
      return null;
    }
  }

  Future<void> writePending(OnboardingDraft d) => _p.setString(_key(_pendingPrefix), jsonEncode({'draft': d.toJson()}));
  Future<void> clearPending() => _p.remove(_key(_pendingPrefix));

  /// Sends a waiting `step: done` save for [profileId] in the background; clears it on success.
  Future<void> flushPending(int profileId, OnboardingRepository repo) async {
    final pending = readPending();
    if (pending == null) return;
    if ((await repo.saveTaste(profileId, pending)).isOk) await clearPending();
  }
}

final onboardingStoreProvider = Provider<OnboardingStore>(OnboardingStore.new, name: 'onboardingStore');
