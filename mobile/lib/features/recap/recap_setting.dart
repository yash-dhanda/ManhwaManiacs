import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/storage/profile_scoped_key.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';

/// `mm.recap` (glass/DESIGN.md 15.6, binding for both skins): when to offer a recap before
/// continuing a series. Stored per profile as one JSON value.
enum RecapMode { off, ask, always }

/// Cinematic's three words for [RecapMode] (`NEVER`, `AFTER N DAYS AWAY`, `ALWAYS`).
enum CinematicRecapMode { never, afterDays, always }

class RecapSetting {
  const RecapSetting({
    this.mode = RecapMode.ask,
    this.seriesDays = 7,
    this.chapterDays = 3,
    this.skipSeries = const [],
  });

  final RecapMode mode;
  final int seriesDays, chapterDays;

  /// `"{sourceId}:{seriesKey}"` entries.
  final List<String> skipSeries;

  factory RecapSetting.fromJson(Object? json) {
    if (json is! Map) return const RecapSetting();
    final mode = RecapMode.values.where((m) => m.name == json['mode']).firstOrNull ?? RecapMode.ask;
    int days(Object? v, int d) => v is int && v >= 1 && v <= 365 ? v : d;
    final skip = json['skipSeries'];
    return RecapSetting(
      mode: mode,
      seriesDays: days(json['seriesDays'], 7),
      chapterDays: days(json['chapterDays'], 3),
      skipSeries: skip is List ? [for (final e in skip) if (e is String) e] : const [],
    );
  }

  Map<String, dynamic> toJson() => {'mode': mode.name, 'seriesDays': seriesDays, 'chapterDays': chapterDays, 'skipSeries': skipSeries};

  CinematicRecapMode get cinematicMode => switch (mode) {
        RecapMode.off => CinematicRecapMode.never,
        RecapMode.always => CinematicRecapMode.always,
        RecapMode.ask => CinematicRecapMode.afterDays,
      };

  RecapSetting copyWith({RecapMode? mode, int? seriesDays, List<String>? skipSeries}) => RecapSetting(
        mode: mode ?? this.mode,
        seriesDays: seriesDays ?? this.seriesDays,
        chapterDays: chapterDays,
        skipSeries: skipSeries ?? this.skipSeries,
      );
}

const kRecapPrefix = 'mm.recap.';
const kRecapAutoContinuePrefix = 'mm.recap.autoContinue.';

final recapSettingProvider = NotifierProvider<RecapSettingNotifier, RecapSetting>(RecapSettingNotifier.new, name: 'recapSetting');

class RecapSettingNotifier extends Notifier<RecapSetting> {
  String _key({required bool watch}) => profileScopedKey(ref, prefix: kRecapPrefix, deviceKey: '${kRecapPrefix}device', watch: watch);

  @override
  RecapSetting build() {
    final raw = ref.watch(sharedPrefsProvider).getString(_key(watch: true));
    if (raw == null) return const RecapSetting();
    try {
      return RecapSetting.fromJson(jsonDecode(raw));
    } catch (_) {
      return const RecapSetting();
    }
  }

  /// [days] (3-60) only counts for [CinematicRecapMode.afterDays]; writes keep `chapterDays` and
  /// `skipSeries`.
  Future<void> setCinematicMode(CinematicRecapMode m, {int? days}) => _write(
        state.copyWith(
          mode: switch (m) {
            CinematicRecapMode.never => RecapMode.off,
            CinematicRecapMode.always => RecapMode.always,
            CinematicRecapMode.afterDays => RecapMode.ask,
          },
          seriesDays: m == CinematicRecapMode.afterDays && days != null ? days.clamp(3, 60) : null,
        ),
      );

  /// Glass Settings: the three-segment control (Off, Ask, Always).
  Future<void> setMode(RecapMode m) => _write(state.copyWith(mode: m));

  Future<void> skip(String seriesId) =>
      state.skipSeries.contains(seriesId) ? Future<void>.value() : _write(state.copyWith(skipSeries: [...state.skipSeries, seriesId]));

  Future<void> allow(String seriesId) => _write(state.copyWith(skipSeries: [for (final s in state.skipSeries) if (s != seriesId) s]));

  Future<void> _write(RecapSetting next) async {
    state = next;
    await ref.read(sharedPrefsProvider).setString(_key(watch: false), jsonEncode(next.toJson()));
  }
}

/// Cinematic-only: continue on its own after a recap ends (default on).
final recapAutoContinueProvider = NotifierProvider<RecapAutoContinueNotifier, bool>(RecapAutoContinueNotifier.new, name: 'recapAutoContinue');

class RecapAutoContinueNotifier extends Notifier<bool> {
  String _key({required bool watch}) =>
      profileScopedKey(ref, prefix: kRecapAutoContinuePrefix, deviceKey: '${kRecapAutoContinuePrefix}device', watch: watch);

  @override
  bool build() => ref.watch(sharedPrefsProvider).getBool(_key(watch: true)) ?? true;

  Future<void> set(bool on) async {
    state = on;
    await ref.read(sharedPrefsProvider).setBool(_key(watch: false), on);
  }
}
