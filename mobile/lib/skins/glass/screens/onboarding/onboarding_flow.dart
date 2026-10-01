import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/features/onboarding/models/taste.dart';
import 'package:manhwamaniacs/features/onboarding/providers/onboarding_providers.dart';
import 'package:manhwamaniacs/features/onboarding/repositories/onboarding_repository.dart';
import 'package:manhwamaniacs/features/onboarding/store/onboarding_draft.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

/// A seed the reader chose in step 6: followed (has a [followedId]), kept in `taste.seeds` (no source has it), or failed.
@immutable
class SeedPick {
  const SeedPick({required this.anilistId, required this.title, this.coverUrl, this.followedId, this.sourceId, this.seriesKey, this.failed = false});
  final int anilistId;
  final String title;
  final String? coverUrl;
  final int? followedId;
  final String? sourceId;
  final String? seriesKey;
  final bool failed;

  bool get followed => followedId != null;

  SeedPick copyWith({bool? failed, int? followedId}) => SeedPick(anilistId: anilistId, title: title, coverUrl: coverUrl, followedId: followedId ?? this.followedId, sourceId: sourceId, seriesKey: seriesKey, failed: failed ?? this.failed);
}

@immutable
class GlassOnboardingState {
  const GlassOnboardingState({this.step = 1, this.taste = const Taste(), this.touched = const {}, this.picks = const [], this.everPicked = const {}, this.skin = 'glass', this.dirty = false});
  final int step;
  final Taste taste;
  final Set<TasteField> touched;
  final List<SeedPick> picks;
  final Set<int> everPicked;

  /// The Look step's choice: `glass` or `cinematic`.
  final String skin;

  /// A save failed and waits for the connection.
  final bool dirty;

  int weightOf(String genre) => switch (taste.genres[genre]) {
        GenreMark.like => 1,
        GenreMark.love => 2,
        GenreMark.skip => -1,
        _ => 0,
      };

  Map<String, int> get weights => {for (final e in taste.genres.entries) if (e.value != null) e.key: weightOf(e.key)};
  int get follows => picks.where((p) => p.followed).length;
  int get kept => picks.where((p) => !p.followed && !p.failed).length;

  GlassOnboardingState copyWith({int? step, Taste? taste, Set<TasteField>? touched, List<SeedPick>? picks, Set<int>? everPicked, String? skin, bool? dirty}) => GlassOnboardingState(
        step: step ?? this.step,
        taste: taste ?? this.taste,
        touched: touched ?? this.touched,
        picks: picks ?? this.picks,
        everPicked: everPicked ?? this.everPicked,
        skin: skin ?? this.skin,
        dirty: dirty ?? this.dirty,
      );
}

/// The onboarding state (glass 8.7) on the `mobile/20` data layer: answers restore from the draft, save touched-only after each
/// step change (debounced 800 ms, draft first), and `done` retries three times 2 s apart before it is stored as pending.
class GlassOnboardingFlow extends AutoDisposeNotifier<GlassOnboardingState> {
  Timer? _debounce;
  int _stepToSave = 1;
  bool _restored = false;

  @override
  GlassOnboardingState build() {
    ref.onDispose(() => _debounce?.cancel());
    final d = ref.read(onboardingStoreProvider).readDraft();
    return GlassOnboardingState(taste: d.taste, touched: d.touched);
  }

  int? get _profileId => ref.read(activeProfileProvider)?.id;

  CatalogKey catalogKey() => catalogKeyFor(
        ref,
        formats: [for (final f in state.taste.formats) f.wire],
        genres: [for (final e in state.taste.genres.entries) if (e.value == GenreMark.like || e.value == GenreMark.love) e.key],
        styles: [for (final s in state.taste.styles) s.wire],
      );

  void enter(int step) => state = state.copyWith(step: step);

  /// Fills what the draft lacks from the server (`getTaste`, when it can be read).
  Future<void> restore() async {
    if (_restored) return;
    _restored = true;
    final id = _profileId;
    if (!kTasteReadable || id == null) return;
    final r = await ref.read(onboardingRepositoryProvider).getTaste(id);
    if (r is! Ok<Taste?> || r.value == null) return;
    final server = r.value!;
    final s = state;
    state = s.copyWith(
      taste: Taste(
        formats: s.touched.contains(TasteField.formats) ? s.taste.formats : server.formats,
        genres: s.touched.contains(TasteField.genres) ? {...server.genres, ...s.taste.genres} : server.genres,
        styles: s.touched.contains(TasteField.styles) ? s.taste.styles : server.styles,
        seeds: s.touched.contains(TasteField.seeds) ? s.taste.seeds : server.seeds,
      ),
    );
  }

  void _set(Taste t, TasteField f) => state = state.copyWith(taste: t, touched: {...state.touched, f});

  void setSkin(String skin) => state = state.copyWith(skin: skin);

  void toggleFormat(FormatId f) {
    final l = [...state.taste.formats];
    l.contains(f) ? l.remove(f) : l.add(f);
    _set(state.taste.copyWith(formats: l), TasteField.formats);
  }

  /// Weight 1 like, 2 love, -1 skip, 0 removed.
  void setGenreWeight(String name, int weight) {
    final mark = switch (weight) {
      1 => GenreMark.like,
      2 => GenreMark.love,
      -1 => GenreMark.skip,
      _ => null,
    };
    _set(state.taste.copyWith(genres: {...state.taste.genres, name: mark}), TasteField.genres);
  }

  void toggleStyle(StyleId s) {
    final l = [...state.taste.styles];
    l.contains(s) ? l.remove(s) : l.add(s);
    _set(state.taste.copyWith(styles: l), TasteField.styles);
  }

  /// The first pick of a seed (never picked before this session): the caller inserts its similar titles.
  bool isFirstPick(int anilistId) => !state.everPicked.contains(anilistId);

  /// A tap on a seed: follows its first source, keeps it in `taste.seeds` when no source has it, or undoes the pick.
  /// Returns the resulting pick (null after an undo).
  Future<SeedPick?> togglePick(WorldItem item) async {
    final existing = state.picks.where((p) => p.anilistId == item.anilistId).firstOrNull;
    if (existing != null && !existing.failed) {
      await _undo(existing);
      return null;
    }
    final source = item.openTarget;
    final base = SeedPick(anilistId: item.anilistId, title: item.title, coverUrl: item.coverUrl, sourceId: source?.sourceId, seriesKey: source?.seriesKey);
    final ever = {...state.everPicked, item.anilistId};
    if (source == null) {
      final pick = base;
      state = state.copyWith(
        picks: [...state.picks.where((p) => p.anilistId != item.anilistId), pick],
        everPicked: ever,
        taste: state.taste.copyWith(seeds: [...state.taste.seeds, TasteSeed.anilist(item.anilistId)]),
        touched: {...state.touched, TasteField.seeds},
      );
      return pick;
    }
    final r = await ref.read(libraryRepositoryProvider).follow(sourceId: source.sourceId, seriesKey: source.seriesKey);
    // Followed already (picked before a resume, whose draft keeps only the ids): the pick stands.
    // ponytail: no follow id comes back, so undoing it keeps the follow; a lookup by source and key would fix that.
    final err = r.isErr ? r.error : null;
    if (err is ApiError && err.code == 'already_followed') {
      state = state.copyWith(picks: [...state.picks.where((p) => p.anilistId != item.anilistId), base], everPicked: ever);
      return base;
    }
    if (r.isErr) {
      final failed = base.copyWith(failed: true);
      state = state.copyWith(picks: [...state.picks.where((p) => p.anilistId != item.anilistId), failed], everPicked: ever);
      return failed;
    }
    final pick = base.copyWith(followedId: r.value.id);
    state = state.copyWith(picks: [...state.picks.where((p) => p.anilistId != item.anilistId), pick], everPicked: ever);
    return pick;
  }

  /// Follows a search result (a title the reader typed for); no seed is kept.
  Future<bool> followSource({required String sourceId, required String seriesKey, required String title, String? coverUrl}) async {
    final r = await ref.read(libraryRepositoryProvider).follow(sourceId: sourceId, seriesKey: seriesKey);
    if (r.isErr) return false;
    final id = -(state.picks.length + 1) * 1000 - seriesKey.hashCode.abs() % 1000;
    state = state.copyWith(picks: [...state.picks, SeedPick(anilistId: id, title: title, coverUrl: coverUrl, followedId: r.value.id, sourceId: sourceId, seriesKey: seriesKey)]);
    return true;
  }

  Future<void> _undo(SeedPick p) async {
    if (p.followedId != null) await ref.read(libraryRepositoryProvider).unfollow(p.followedId!);
    final seeds = [for (final s in state.taste.seeds) if (s.anilistId != p.anilistId) s];
    state = state.copyWith(
      picks: [for (final x in state.picks) if (x.anilistId != p.anilistId) x],
      taste: state.taste.copyWith(seeds: seeds),
      touched: p.followed ? state.touched : {...state.touched, TasteField.seeds},
    );
  }

  // ---- saving --------------------------------------------------------------------------------------------------

  OnboardingDraft _draft() => OnboardingDraft(taste: state.taste, touched: state.touched, picks: [for (final p in state.picks) p.anilistId]);

  /// After a step change: debounced 800 ms, the draft first, then the taste for [step] (touched fields only).
  void commit(int step) {
    _stepToSave = step;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () => unawaited(flush()));
  }

  /// Writes the draft and sends the taste now; a failure keeps the draft and retries on the next step change.
  Future<bool> flush() async {
    _debounce?.cancel();
    final d = _draft();
    await ref.read(onboardingStoreProvider).writeDraft(d);
    final id = _profileId;
    if (id == null) return false;
    final r = await ref.read(onboardingRepositoryProvider).saveTaste(id, tasteBody(d, OnboardingStep.at(_stepToSave.clamp(1, 7))));
    state = state.copyWith(dirty: r.isErr);
    return r.isOk;
  }

  /// `step: done` with three attempts 2 s apart, then stored as pending; on success the draft clears and profiles refresh.
  Future<bool> saveDone({Duration spacing = const Duration(seconds: 2)}) async {
    final link = ref.keepAlive();
    try {
      _debounce?.cancel();
      final id = _profileId;
      final store = ref.read(onboardingStoreProvider);
      final d = _draft();
      if (id == null) return false;
      final body = tasteBody(d, OnboardingStep.done);
      // Pending from the first moment: the screen leaves for Home before the save settles, and the
      // onboarding redirect must already count the profile as done (else it bounces to /welcome).
      await store.writePending(d);
      for (var attempt = 0; attempt < 3; attempt++) {
        if (attempt > 0) await Future<void>.delayed(spacing);
        final r = await ref.read(onboardingRepositoryProvider).saveTaste(id, body);
        if (r.isOk) {
          await store.clearDraft();
          // The list says done before the pending marker goes.
          await ref.read(profilesProvider.notifier).refresh();
          await store.clearPending();
          return true;
        }
      }
      return false;
    } finally {
      link.close();
    }
  }
}

final glassOnboardingFlowProvider = NotifierProvider.autoDispose<GlassOnboardingFlow, GlassOnboardingState>(GlassOnboardingFlow.new, name: 'glassOnboardingFlow');
