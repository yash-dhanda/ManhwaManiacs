import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/home/providers/home_feed_provider.dart';
import 'package:manhwamaniacs/features/library/providers/daily_goal_provider.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/updates/providers/unread_count_provider.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/parts/streak/plus_one.dart';
import 'package:manhwamaniacs/skins/glass/parts/streak/streak_ui.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/streak_flame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/typed_headline.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/greeting.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// The streak chip of the greeting's subline (glass 8.8): a content chip (`fill2`, 32 tall inside a hit area) with a 16 px `flame` Fill in
/// `streak` and the label, linking to Statistics. At risk the glyph shrinks to 0.8 and is the outlined flame with no core colour.
/// `mobile/42` replaces [glyph] with `StreakFlame` at 16 px and mounts its Plus one over this chip.
class GreetingStreakChip extends ConsumerWidget {
  const GreetingStreakChip({super.key, required this.days, this.atRisk = false, this.readToday = false, this.glyph});
  final int days;
  final bool atRisk;

  /// Whether today already has reading (full colour flame); else the dimmer not-yet-today flame.
  final bool readToday;

  /// The flame (mobile/42 passes `StreakFlame`); null draws the default glyph.
  final Widget? glyph;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hit = GlassFrame.hitMin(context);
    final ui = ref.watch(streakUiProvider);
    final flame = glyph ??
        StreakFlame(
          size: 16,
          days: days,
          flare: ui.flare,
          semanticLabel: false,
          state: flameStateOf(days: days, readToday: readToday, atRisk: atRisk),
        );
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: hit),
      child: GlassPressable(
        material: GlassMaterial.content,
        sink: 0.96,
        minHit: false,
        onTap: () => ref.read(skinRouterProvider).push<void>(Routes.numbers()),
        semanticsLabel: '$days-day streak',
        // Hugs its content (left, under the greeting), and grows with large text instead of clipping it.
        builder: (context, info) => Center(
          widthFactor: 1,
          child: Container(
            constraints: const BoxConstraints(minHeight: 32),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: gt.colorFill2, borderRadius: BorderRadius.circular(16)),
            child: GlassPlusOne(child: Row(mainAxisSize: MainAxisSize.min, children: [flame, const SizedBox(width: 6), GlassLabel('$days-day streak', role: gt.typeFootnote, wght: 600, color: gt.colorLabel1)])),
          ),
        ),
      ),
    );
  }
}

/// The screen's large title (glass 8.8): "Good evening, {name}" typed at 50 ms per grapheme once per app session, and the subline with the
/// new-chapters count and the streak chip.
class GreetingHeader extends ConsumerWidget {
  const GreetingHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(activeProfileProvider.select((p) => p?.name)) ?? '';
    final now = ref.watch(clockProvider)();
    final streak = ref.watch(homeFeedProvider.select((v) => v.valueOrNull?.feed?.streak)) ?? const HomeStreak();
    final unread = ref.watch(unreadNotificationCountProvider);
    final lastActive = streak.lastActiveDate;
    final readToday = ref.watch(dailyGoalProvider.select((g) => g.todaySeconds > 0)) ||
        (lastActive != null && lastActive.year == now.year && lastActive.month == now.month && lastActive.day == now.day);
    final sub = greetingSubline(unread: unread, streak: streak, now: now);
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TypedHeadline(greetingFor(now, name), role: gt.typeLargeTitle, placement: 'home.greeting', headingLevel: 1),
          if (!sub.isEmpty) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Semantics(
              container: true,
              label: sub.text,
              child: ExcludeSemantics(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    if (sub.riskLine != null)
                      GlassLabel(sub.riskLine!, role: gt.typeFootnote, color: gt.colorLabel1, maxLines: 2)
                    else if (sub.newChapters != null) ...[
                      GlassLabel(sub.newChapters!, role: gt.typeFootnote, color: gt.colorLabel2),
                      if (sub.streakDays > 0) GlassLabel('·', role: gt.typeFootnote, color: gt.colorLabel2),
                    ],
                    if (sub.streakDays > 0 && sub.riskLine == null) GreetingStreakChip(days: sub.streakDays, readToday: readToday),
                    if (sub.riskLine != null) GreetingStreakChip(days: sub.streakDays, atRisk: true),
                  ],
                ),
              ),
            ),
            ),
          ],
        ],
      ),
    );
  }
}
