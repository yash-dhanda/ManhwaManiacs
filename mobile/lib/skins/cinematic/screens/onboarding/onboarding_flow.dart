import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/home/providers/home_feed_provider.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/features/onboarding/models/taste.dart';
import 'package:manhwamaniacs/features/onboarding/providers/onboarding_providers.dart';
import 'package:manhwamaniacs/features/onboarding/repositories/onboarding_repository.dart';
import 'package:manhwamaniacs/features/onboarding/store/onboarding_draft.dart';
import 'package:manhwamaniacs/features/onboarding/utils/genre_paragraph.dart';
import 'package:manhwamaniacs/features/onboarding/utils/print_run.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

/// The answers and picks of the run in progress (one per `/welcome` visit).
@immutable
class OnboardingState {
  const OnboardingState({
    this.step = 2,
    this.taste = const Taste(),
    this.touched = const {},
    this.picks = const [],
    this.everPicked = const {},
    this.pendingPickIds = const [],
  });

  /// The step on screen (2 to 5 while Glass is off).
  final int step;
  final Taste taste;
  final Set<TasteField> touched;

  /// The seed picks in pick order.
  final List<WorldItem> picks;

  /// AniList ids picked at any time this visit (a re-pick never asks for similar again).
  final Set<int> everPicked;

  /// Picks restored from the draft, matched to wall items once the catalog arrives.
  final List<int> pendingPickIds;

  OnboardingState copyWith({int? step, Taste? taste, Set<TasteField>? touched, List<WorldItem>? picks, Set<int>? everPicked, List<int>? pendingPickIds}) => OnboardingState(
        step: step ?? this.step,
        taste: taste ?? this.taste,
        touched: touched ?? this.touched,
        picks: picks ?? this.picks,
        everPicked: everPicked ?? this.everPicked,
        pendingPickIds: pendingPickIds ?? this.pendingPickIds,
      );

  GenreMark? genreMark(String name) => taste.genres[name];
  bool hasFormat(FormatId f) => taste.formats.contains(f);
  bool hasStyle(StyleId s) => taste.styles.contains(s);
  bool isPicked(WorldItem i) => picks.any((p) => p.anilistId == i.anilistId);
}

/// What Print did, for the Cut to home hand-off.
class PrintOutcome {
  const PrintOutcome({required this.followed, required this.failed, required this.homeOk, required this.savedDone});
  final List<WorldItem> followed, failed;
  final bool homeOk, savedDone;

  int get attempted => followed.length + failed.length;
  bool get allFailed => attempted > 0 && followed.isEmpty;
}

/// The Cinematic onboarding's state (skin-side: the widgets read it, the data layer is
/// `features/onboarding`).
class OnboardingFlow extends AutoDisposeNotifier<OnboardingState> {
  final Map<int, GlobalKey> _posterKeys = {};
  bool _restored = false;

  @override
  OnboardingState build() {
    final d = ref.read(onboardingStoreProvider).readDraft();
    return OnboardingState(taste: d.taste, touched: d.touched, pendingPickIds: d.picks, everPicked: {...d.picks});
  }

  int? get _profileId => ref.read(activeProfileProvider)?.id;

  /// A stable key per wall poster, for the flight's source rects.
  GlobalKey posterKey(int anilistId) => _posterKeys.putIfAbsent(anilistId, GlobalKey.new);

  /// The catalog for [step] with the answers so far.
  CatalogKey keyFor(int step) {
    final s = state;
    return catalogKeyFor(
      ref,
      formats: step >= 3 ? [for (final f in s.taste.formats) f.wire] : const [],
      genres: step >= 5 ? likedGenres(s.taste.genres) : const [],
      styles: step >= 5 ? [for (final x in s.taste.styles) x.wire] : const [],
    );
  }

  void enter(int step) => state = state.copyWith(step: step);

  /// Fills the answers from the server (when it can be read); the device draft wins for the fields
  /// it touched. Runs once per visit.
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

  void toggleFormat(FormatId f) {
    final l = [...state.taste.formats];
    l.contains(f) ? l.remove(f) : l.add(f);
    _set(state.taste.copyWith(formats: l), TasteField.formats);
  }

  void setGenre(String name, GenreMark? m) => _set(state.taste.copyWith(genres: {...state.taste.genres, name: m}), TasteField.genres);

  void toggleStyle(StyleId s) {
    final l = [...state.taste.styles];
    l.contains(s) ? l.remove(s) : l.add(s);
    _set(state.taste.copyWith(styles: l), TasteField.styles);
  }

  /// Toggles a pick; true the first time this visit it was picked (similar posters may insert).
  bool togglePick(WorldItem item) {
    final s = state;
    final on = s.isPicked(item);
    final picks = on ? [for (final p in s.picks) if (p.anilistId != item.anilistId) p] : [...s.picks, item];
    final first = !on && !s.everPicked.contains(item.anilistId);
    state = s.copyWith(
      picks: picks,
      everPicked: first ? {...s.everPicked, item.anilistId} : null,
      taste: s.taste.copyWith(seeds: [for (final p in picks) TasteSeed.anilist(p.anilistId)]),
      touched: {...s.touched, TasteField.seeds},
    );
    return first;
  }

  /// Turns the restored pick ids into picks once the wall's items are known.
  void adoptPicks(List<WorldItem> wall) {
    final s = state;
    if (s.pendingPickIds.isEmpty) return;
    final byId = {for (final w in wall) w.anilistId: w};
    state = s.copyWith(picks: [for (final id in s.pendingPickIds) if (byId[id] != null) byId[id]!], pendingPickIds: const []);
  }

  OnboardingDraft _draft() => OnboardingDraft(taste: state.taste, touched: state.touched, picks: [for (final p in state.picks) p.anilistId]);

  /// `Next`: the draft first, then the save in the background. A failed save is not lost: the
  /// draft carries every touched field, so the next `Next` and Print send it again.
  void commit(int nextStep) {
    final id = _profileId;
    final d = _draft();
    unawaited(ref.read(onboardingStoreProvider).writeDraft(d));
    if (id == null) return;
    unawaited(ref.read(onboardingRepositoryProvider).saveTaste(id, tasteBody(d, OnboardingStep.at(nextStep))));
  }

  /// Before a restart into the other skin: the draft and the taste with [step] (the other skin's
  /// numbering), both awaited, so the new skin's resume reads the step it continues at.
  // ponytail: one try; offline the server keeps the old step and the other skin resumes there.
  Future<void> handOff(int step) async {
    final id = _profileId;
    final d = _draft();
    await ref.read(onboardingStoreProvider).writeDraft(d);
    if (id != null) await ref.read(onboardingRepositoryProvider).saveTaste(id, tasteBody(d, OnboardingStep.at(step)));
  }

  /// Skip and Print's save: `step: done` with the touched fields, three tries 2 s apart; a
  /// failure goes to the pending key. True when the server has it.
  Future<bool> saveDone({Duration spacing = const Duration(seconds: 2)}) async {
    // The screen leaves before the save settles; the state must outlive it.
    final link = ref.keepAlive();
    try {
      return await _saveDone(spacing);
    } finally {
      link.close();
    }
  }

  Future<bool> _saveDone(Duration spacing) async {
    final id = _profileId;
    final store = ref.read(onboardingStoreProvider);
    final d = _draft();
    if (id == null) return false;
    final body = tasteBody(d, OnboardingStep.done);
    // Pending from the first moment: Tonight opens before the save settles, and the onboarding
    // redirect must already count the profile as done.
    await store.writePending(d);
    for (var attempt = 0; attempt < 3; attempt++) {
      if (attempt > 0) await Future<void>.delayed(spacing);
      final r = await ref.read(onboardingRepositoryProvider).saveTaste(id, body);
      if (r.isOk) {
        await store.clearDraft();
        // The kept-alive list still says the old step: the picker would send the profile back
        // into onboarding and credit it NEW. It says done before the pending marker goes.
        await ref.read(profilesProvider.notifier).refresh();
        await store.clearPending();
        return true;
      }
    }
    return false;
  }

  /// Print my first issue: follow the picks (4 at a time), save `done`, refetch `/home`.
  Future<PrintOutcome> printIssue({Duration spacing = const Duration(seconds: 2)}) async {
    final link = ref.keepAlive();
    try {
      return await _printIssue(spacing);
    } finally {
      link.close();
    }
  }

  Future<PrintOutcome> _printIssue(Duration spacing) async {
    final lib = ref.read(libraryRepositoryProvider);
    final picks = state.picks;
    final saving = saveDone(spacing: spacing);
    final run = await runFollows(picks, ({required sourceId, required seriesKey}) async => (await lib.follow(sourceId: sourceId, seriesKey: seriesKey)).isOk);
    final saved = await saving;
    var homeOk = true;
    try {
      await ref.read(homeFeedProvider.future);
      await ref.read(homeFeedProvider.notifier).refresh();
      final v = ref.read(homeFeedProvider);
      homeOk = !v.hasError && v.valueOrNull != null && v.valueOrNull!.state != HomeFeedState.unavailable;
    } catch (_) {
      homeOk = false;
    }
    return PrintOutcome(followed: run.followed, failed: run.failed, homeOk: homeOk, savedDone: saved);
  }
}

final onboardingFlowProvider = NotifierProvider.autoDispose<OnboardingFlow, OnboardingState>(OnboardingFlow.new, name: 'onboardingFlow');
