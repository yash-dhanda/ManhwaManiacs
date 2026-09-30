import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// One completed chapter's reading pace.
class NovelPaceSample {
  const NovelPaceSample(this.chapterKey, this.wpm);
  final String chapterKey;
  final double wpm;

  Map<String, dynamic> toJson() => {'chapter_key': chapterKey, 'wpm': wpm};
}

const int kDefaultNovelPaceWpm = 250;
const int _maxSamples = 10;
const int _minSamplesForMedian = 3;

/// The pace of one finished chapter, or null when it does not count: 60-7200 s spent and a pace of
/// 80-900 wpm only.
double? chapterPaceWpm(int wordCount, int timeSpentSeconds) {
  if (timeSpentSeconds < 60 || timeSpentSeconds > 7200 || wordCount <= 0) return null;
  final wpm = wordCount / (timeSpentSeconds / 60);
  return wpm >= 80 && wpm <= 900 ? wpm : null;
}

/// The median of the last 10 samples, 250 wpm until 3 samples exist.
double novelPaceWpm(List<NovelPaceSample> samples) {
  final recent = samples.length > _maxSamples ? samples.sublist(samples.length - _maxSamples) : samples;
  if (recent.length < _minSamplesForMedian) return kDefaultNovelPaceWpm.toDouble();
  final v = [for (final s in recent) s.wpm]..sort();
  final mid = v.length ~/ 2;
  return v.length.isOdd ? v[mid] : (v[mid - 1] + v[mid]) / 2;
}

/// Adds (or replaces) a chapter's sample, keeping the newest 10.
List<NovelPaceSample> withSample(List<NovelPaceSample> samples, NovelPaceSample s) {
  final next = [for (final x in samples) if (x.chapterKey != s.chapterKey) x, s];
  return next.length > _maxSamples ? next.sublist(next.length - _maxSamples) : next;
}

/// The words per rendered line of a laid-out chapter.
double avgWordsPerLine(int wordCount, int lineCount) => lineCount <= 0 ? 1 : wordCount / lineCount;

/// `mm.novel-pace.u{user}p{profile}` in SharedPreferences: `{samples: [{chapter_key, wpm}]}`.
class NovelPaceStore {
  NovelPaceStore(this._prefs, this.key);
  final SharedPreferences _prefs;
  final String key;

  static String keyFor(int userId, int profileId) => 'mm.novel-pace.u${userId}p$profileId';

  List<NovelPaceSample> samples() {
    try {
      final raw = _prefs.getString(key);
      if (raw == null) return const [];
      final list = (jsonDecode(raw) as Map<String, dynamic>)['samples'] as List<dynamic>;
      return [
        for (final e in list)
          NovelPaceSample((e as Map<String, dynamic>)['chapter_key'] as String, (e['wpm'] as num).toDouble()),
      ];
    } catch (_) {
      return const [];
    }
  }

  double get paceWpm => novelPaceWpm(samples());

  /// Recomputes on a chapter completion; returns the new pace.
  Future<double> recordCompletion({
    required String chapterKey,
    required int wordCount,
    required int timeSpentSeconds,
  }) async {
    final wpm = chapterPaceWpm(wordCount, timeSpentSeconds);
    if (wpm == null) return paceWpm;
    final next = withSample(samples(), NovelPaceSample(chapterKey, wpm));
    await _prefs.setString(key, jsonEncode({'samples': [for (final s in next) s.toJson()]}));
    return novelPaceWpm(next);
  }
}
