import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart';
import 'package:manhwamaniacs/features/library/providers/numbers_providers.dart';
import 'package:manhwamaniacs/features/library/utils/you_cards.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/slab.dart';
import 'package:manhwamaniacs/skins/glass/primitives/charts/chart_math.dart' show ChartDatum;
import 'package:manhwamaniacs/skins/glass/primitives/charts/sparkline_painter.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/primitives/status_capsule.dart';
import 'package:manhwamaniacs/skins/glass/primitives/streak_flame.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/admin_common.dart' show glassSpan;
import 'package:manhwamaniacs/skins/glass/type.dart';

/// "12-day streak" or "Read today to start a streak".
String streakLine(int days) => days <= 0 ? 'Read today to start a streak' : '$days-day streak';

/// "This week: 3 h 12 min · 14 chapters".
String weekLine(WeekSummary w) => 'This week: ${formatDuration(w.seconds)} · ${w.chapters} ${w.chapters == 1 ? 'chapter' : 'chapters'}';

/// A card's error and offline forms (glass 8.24): never a full-screen error.
class YouCardProblem extends StatelessWidget {
  const YouCardProblem({super.key, required this.offline, required this.onRetry});
  final bool offline;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 120), // grows with the text scale instead of overflowing
      child: GlassSlab(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          GlassText(offline ? 'Needs a connection' : "Couldn't load this", role: gt.typeCallout, color: gt.colorLabel2),
          if (!offline) GlassButton(label: 'Retry', variant: GlassButtonVariant.plain, size: GlassButtonSize.small, onPressed: onRetry),
        ],),
      ),);
}

/// The Reading card (glass 8.24): streak, this week's time and chapters, a 7-point sparkline; the whole card opens Statistics.
class ReadingCard extends ConsumerWidget {
  const ReadingCard({super.key, this.offline = false});
  final bool offline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(numbersStatisticsProvider(7));
    if (stats.hasError && !stats.isLoading) return YouCardProblem(offline: offline, onRetry: () => ref.invalidate(numbersStatisticsProvider(7)));
    final load = stats.valueOrNull;
    if (load == null) return const GlassSkeletonGroup(label: 'Loading your reading', child: GlassSkeleton(height: 132, radius: 26));
    final s = load.data;
    final w = weekSummary(s.daily);
    final days = s.streak.currentDays;
    final now = ref.watch(clockProvider)();
    final today = s.daily.where((d) => d.date.year == now.year && d.date.month == now.month && d.date.day == now.day).firstOrNull;
    final readToday = (today?.pagesRead ?? 0) > 0;
    final saved = load.offline ? (_savedAgo(s.daily) ?? 'earlier') : null;
    return GlassSlab(
      padding: const EdgeInsets.all(16),
      semanticsLabel: 'Your reading: ${days <= 0 ? 'no streak' : '$days-day streak'}, this week ${formatDuration(w.seconds).replaceAll(' h', ' hours').replaceAll(' min', ' minutes')}, ${w.chapters} chapters',
      onTap: () => GoRouter.of(context).go(Routes.numbers()),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (saved != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: GlassStatusCapsule(kind: GlassStatusKind.savedCopy, savedAgo: saved)),
        Row(children: [
          SizedBox(width: 44, height: 44, child: Center(child: StreakFlame(size: 44, days: days, semanticLabel: false, state: flameStateOf(days: days, readToday: readToday, atRisk: s.streak.atRisk)))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              GlassText(streakLine(days), role: gt.typeHeadline),
              GlassText(weekLine(w), role: gt.typeFootnote, color: gt.colorLabel2),
            ],),
          ),
        ],),
        const SizedBox(height: 12),
        ExcludeSemantics(
          child: SizedBox(
            height: 24,
            width: double.infinity,
            child: CustomPaint(painter: SparklinePainter(data: [for (final v in w.sparkline) ChartDatum(value: v.toDouble())], progress: 1)),
          ),
        ),
      ],),
    );
  }

  static String? _savedAgo(List<DailyActivity> daily) => daily.isEmpty ? null : glassSpan(DateTime.now().difference(daily.last.date));
}
