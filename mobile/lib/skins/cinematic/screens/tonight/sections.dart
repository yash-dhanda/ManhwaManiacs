import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/network/api_image.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/home/utils/rerank.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/navigation.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/numbers_teaser.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/sections/circle_sections.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/sections/continue_cuttings.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/sections/genres_line.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/sections/posters.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/sections/sources_tiles.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/tonight_layout.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// What every section needs from the screen.
class TonightEnv {
  const TonightEnv({required this.feed, required this.tags, required this.now, required this.refresh, this.entry = ReaderEntry.wipe});
  final HomeFeed feed;
  final HeroTags tags;
  final DateTime now;
  final VoidCallback refresh;

  /// Tonight's Quick look `Continue` and cuttings use the Column wipe (cinematic 8.14.2).
  final ReaderEntry entry;
}

/// One section to render: its place in the feed, and its gapless folio (`01`, `02`, ...).
class PlannedSection {
  const PlannedSection({required this.section, required this.index, required this.folio});
  final HomeSection section;
  final int index;
  final String folio;
}

/// The section types Tonight renders (`Sent to you`, `From the Circle` and `Most read in the circle`
/// are the Circle's).
const Set<HomeSectionType> kRenderedSections = {
  HomeSectionType.firstPicks,
  HomeSectionType.continueReading,
  HomeSectionType.newThisWeek,
  HomeSectionType.almostThere,
  HomeSectionType.whereWereWe,
  HomeSectionType.picked,
  HomeSectionType.because,
  HomeSectionType.sources,
  HomeSectionType.genres,
  HomeSectionType.numbers,
  HomeSectionType.popular,
  HomeSectionType.saved,
  HomeSectionType.sentToYou,
  HomeSectionType.circle,
  HomeSectionType.circleTop,
};

/// AI-written sections: they never show a `SAVED COPY` badge (they show `PICKED ... AGO`).
bool isAiSection(HomeSectionType t) => t == HomeSectionType.picked || t == HomeSectionType.because;

/// Whether a section has anything to show. A section that failed to load with nothing in it still
/// renders (its header and the rail error line), except the AI ones, which are omitted.
bool sectionVisible(HomeSection s) {
  if (!kRenderedSections.contains(s.type)) return false;
  if (s.hasItems) return true;
  return s.state == HomeSectionState.unavailable && !isAiSection(s.type) && s.type != HomeSectionType.genres && s.type != HomeSectionType.sources;
}

/// The genre a rail leans on: the first genre of its first item, when the item carries one.
String? sectionTopGenre(HomeSection s) {
  for (final it in s.items) {
    if (it is HomePickItem) {
      final g = it.world?.genres.firstOrNull ?? it.source?.genres.firstOrNull;
      if (g != null) return g;
    }
  }
  return null;
}

/// The rendered sections in the server's order, re-ranked in-session by the genres of series the
/// reader opened from a rail ([noted], cinematic 9.1.4: each matching rail moves up one place, never
/// above `Continue`), with folios assigned without a gap.
List<PlannedSection> planSections(HomeFeed feed, {List<String> noted = const []}) {
  final visible = <(int, HomeSection)>[
    for (var i = 0; i < feed.sections.length; i++)
      if (sectionVisible(feed.sections[i])) (i, feed.sections[i]),
  ];
  final cont = visible.indexWhere((e) => e.$2.type == HomeSectionType.continueReading);
  final ranked = noted.isEmpty ? visible : rerankRails<(int, HomeSection)>(visible, noted, (e) => sectionTopGenre(e.$2), floor: cont + 1);
  return [
    for (var k = 0; k < ranked.length; k++) PlannedSection(section: ranked[k].$2, index: ranked[k].$1, folio: (k + 1).toString().padLeft(2, '0')),
  ];
}

/// The absolute URL of a cover path or URL, or null.
String? coverAbs(WidgetRef ref, String? url) => url == null || url.isEmpty ? null : resolveApiResourceUrl(ref.read(apiBaseUrlProvider), url);

/// Where `See all` goes, or null when the section has no destination.
VoidCallback? seeAllFor(BuildContext context, HomeSectionType t) => switch (t) {
      HomeSectionType.firstPicks || HomeSectionType.continueReading => () => context.go(Routes.library()),
      HomeSectionType.newThisWeek => () => context.go(Routes.updates()),
      HomeSectionType.picked || HomeSectionType.because => () => context.go(Routes.picks()),
      HomeSectionType.sources => () => context.go(Routes.sources()),
      HomeSectionType.sentToYou => () => context.go(Routes.circle({'tab': 'letters'})),
      HomeSectionType.circle => () => context.go(Routes.circle()),
      HomeSectionType.numbers => () => context.go(Routes.numbers()),
      _ => null,
    };

/// The section registry: one builder per section type.
Widget buildSection(PlannedSection plan, TonightEnv env) => switch (plan.section.type) {
      HomeSectionType.continueReading => ContinueCuttingsSection(plan: plan, env: env),
      HomeSectionType.sources => SourceTilesSection(plan: plan, env: env),
      HomeSectionType.genres => GenresLineSection(plan: plan),
      HomeSectionType.numbers => NumbersTeaser(plan: plan, env: env),
      HomeSectionType.sentToYou => SentToYouSection(plan: plan),
      HomeSectionType.circle => FromTheCircleSection(plan: plan),
      HomeSectionType.circleTop => MostReadInCircleSection(plan: plan),
      _ => PostersSection(plan: plan, env: env),
    };
