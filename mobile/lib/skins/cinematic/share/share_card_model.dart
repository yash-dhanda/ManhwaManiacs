import 'package:manhwamaniacs/features/library/models/annual.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart';
import 'package:manhwamaniacs/features/library/models/shareable.dart';
import 'package:manhwamaniacs/features/library/utils/streak.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/numbers/clock_copy.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/numbers/numbers_format.dart';

/// The press run's model (cinematic 9.2.5): pure. **Only `shareable` fields
/// name a series, a cover or a genre**, and only the profile name is printed.
enum ShareFormat { story, post }

enum ShareId { time, chapters, no1, genres, streak, clock }

extension ShareIdLabel on ShareId {
  String get fileKey => name;
  String get label => switch (this) {
        ShareId.time => 'TIME',
        ShareId.chapters => 'CHAPTERS',
        ShareId.no1 => 'NO. 1',
        ShareId.genres => 'GENRES',
        ShareId.streak => 'STREAK',
        ShareId.clock => 'CLOCK',
      };
}

/// What art a template draws on: a cover and its ambient duotone.
class ShareArt {
  const ShareArt({required this.coverUrl, this.ambient});
  final String coverUrl;
  final SeriesAmbient? ambient;
}

enum ShareSource { annual, range, milestone }

class ShareInput {
  const ShareInput._({
    required this.source,
    required this.profileName,
    required this.kicker,
    required this.periodPhrase,
    this.secondsRead = 0,
    this.chaptersRead = 0,
    this.shareable,
    this.streakDays = 0,
    this.streakIsCurrent = true,
    this.tier = StreakTier.one,
    this.byHour = const [],
  });

  final ShareSource source;
  final String profileName;
  final String kicker;

  /// "in 2026", "in the last 30 days", "in the last year".
  final String periodPhrase;
  final int secondsRead;
  final int chaptersRead;
  final Shareable? shareable;
  final int streakDays;

  /// False when [streakDays] is the longest streak (nothing current).
  final bool streakIsCurrent;
  final StreakTier tier;
  final List<int> byHour;

  factory ShareInput.annual(Annual a, String profileName) => ShareInput._(
        source: ShareSource.annual,
        profileName: profileName,
        kicker: 'THE ANNUAL ${a.year}',
        periodPhrase: 'in ${a.year}',
        secondsRead: a.secondsRead,
        chaptersRead: a.chaptersRead,
        shareable: a.shareable,
        streakDays: a.longestStreak.days,
        tier: streakTier(a.longestStreak.days),
        byHour: a.byHour,
      );

  factory ShareInput.range(LibraryStatistics s, int days, String profileName) {
    final current = s.streak.currentDays;
    final n = current > 0 ? current : s.streak.longestDays;
    return ShareInput._(
      source: ShareSource.range,
      profileName: profileName,
      kicker: 'THE NUMBERS · ${days >= 365 ? 'YEAR' : '$days DAYS'}',
      periodPhrase: days >= 365 ? 'in the last year' : 'in the last $days days',
      secondsRead: s.window.secondsRead,
      chaptersRead: s.window.chaptersRead,
      shareable: s.shareable,
      streakDays: n,
      streakIsCurrent: current > 0,
      tier: streakTier(n),
      byHour: [
        for (var h = 0; h < 24; h++) s.byHour.where((x) => x.hour == h).fold<int>(0, (a, x) => a + x.secondsRead),
      ],
    );
  }

  /// The streak milestone card's Share: the Streak template only, prefilled.
  factory ShareInput.milestone(int days, StreakTier tier, String profileName, {int year = 0, Shareable? art}) => ShareInput._(
        source: ShareSource.milestone,
        profileName: profileName,
        kicker: 'THE ANNUAL ${year == 0 ? DateTime.now().year : year}',
        periodPhrase: '',
        shareable: art,
        streakDays: days,
        tier: tier,
      );
}

class ShareTemplate {
  const ShareTemplate({required this.id, required this.figure, required this.caption, required this.kicker, required this.profileName, this.art, this.tier});

  final ShareId id;
  final String figure;
  final String caption;
  final String kicker;
  final String profileName;
  final ShareArt? art;

  /// Only for the Streak template: the flame drawn above the figure.
  final StreakTier? tier;
}

ShareArt? _art0(Shareable? s) => s == null || s.artSeries.isEmpty ? null : ShareArt(coverUrl: s.artSeries.first.coverUrl, ambient: s.artSeries.first.ambient);

String _hoursOrMinutes(int seconds) => seconds >= 3600 ? fmt(seconds ~/ 3600) : '${(seconds / 60).round()}';

/// The templates with data, in the order Time, Chapters, No. 1, Genres,
/// Streak, Clock.
List<ShareTemplate> shareTemplates(ShareInput input) {
  ShareTemplate t(ShareId id, String figure, String caption, {ShareArt? art, StreakTier? tier}) =>
      ShareTemplate(id: id, figure: figure, caption: caption, kicker: input.kicker, profileName: input.profileName, art: art ?? _art0(input.shareable), tier: tier);
  final out = <ShareTemplate>[];
  final sh = input.shareable;
  final phrase = input.periodPhrase;

  if (input.source != ShareSource.milestone) {
    if (input.secondsRead > 0) {
      final unit = input.secondsRead >= 3600 ? 'hours' : 'minutes';
      out.add(t(ShareId.time, _hoursOrMinutes(input.secondsRead), '$unit of reading $phrase.'));
    }
    if (input.chaptersRead > 0) {
      out.add(t(ShareId.chapters, fmt(input.chaptersRead), 'chapters $phrase.'));
    }
    if (sh != null && sh.topSeries.isNotEmpty) {
      final s = sh.topSeries.first;
      final time = s.secondsRead >= 3600 ? '${fmt(s.secondsRead ~/ 3600)} ${s.secondsRead ~/ 3600 == 1 ? 'hour' : 'hours'}' : '${(s.secondsRead / 60).round()} minutes';
      out.add(t(ShareId.no1, 'No. 1', '${s.title}: ${s.chaptersRead} ${s.chaptersRead == 1 ? 'chapter' : 'chapters'}, $time.', art: s.coverUrl == null ? null : ShareArt(coverUrl: s.coverUrl!, ambient: s.ambient)));
    }
    if (sh != null && sh.genreWeights.isNotEmpty) {
      final g = [...sh.genreWeights]..sort((a, b) => b.weight.compareTo(a.weight));
      final p = '${(g.first.weight * 100).round()} %';
      final caption = switch (g.length) {
        1 => '$p of my reading.',
        2 => '$p of my reading, then ${g[1].genre}.',
        _ => '$p of my reading, then ${g[1].genre} and ${g[2].genre}.',
      };
      out.add(t(ShareId.genres, g.first.genre, caption));
    }
  }
  if (input.streakDays > 0) {
    final caption = switch (input.source) {
      ShareSource.milestone => 'days in a row.',
      ShareSource.annual => 'days in a row, my longest ${input.periodPhrase}.',
      ShareSource.range => input.streakIsCurrent ? 'days in a row, and counting.' : 'days in a row, my longest.',
    };
    out.add(t(ShareId.streak, '${input.streakDays}', caption, tier: input.tier));
  }
  if (input.source != ShareSource.milestone) {
    final r = readClock(input.byHour);
    if (r.band != null && !r.allHours) {
      out.add(t(ShareId.clock, '${(r.share * 100).round()} %', clockCardCaption(r.band!)));
    }
  }
  return out;
}

/// `manhwamaniacs-{time|chapters|no1|genres|streak|clock}-{story|post}.png`.
String shareFileName(ShareId id, ShareFormat format) => 'manhwamaniacs-${id.fileKey}-${format.name}.png';

/// 1080 x 1920 (Story) or 1080 x 1350 (Post).
({double width, double height}) shareSize(ShareFormat f) => (width: 1080, height: f == ShareFormat.story ? 1920 : 1350);
