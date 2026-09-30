import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart' show GlassIconWeight;
import 'package:manhwamaniacs/skins/glass/primitives/cards/slab.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// The "This week" card (glass 8.8): three figures side by side (minutes, chapters, the streak); the whole card links to Statistics.
class HomeThisWeekCard extends ConsumerWidget {
  const HomeThisWeekCard({super.key, required this.numbers});
  final HomeNumbersItem numbers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final minutes = (numbers.secondsWeek / 60).round();
    final chapters = numbers.chaptersWeek;
    final days = numbers.streak.currentDays;
    final margin = GlassFrame.screenMargin(context);
    Widget figure(Widget value, String label) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [value, GlassLabel(label, role: gt.typeFootnote, color: gt.colorLabel2)],
          ),
        );
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: margin),
      child: GlassSlab(
        padding: const EdgeInsets.all(16),
        semanticsLabel: 'This week: $minutes minutes, $chapters chapters, $days-day streak',
        onTap: () => ref.read(skinRouterProvider).push<void>(Routes.numbers()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            GlassLabel('This week', role: gt.typeTitle3),
            const SizedBox(height: 12),
            ExcludeSemantics(
              child: Row(
                children: [
                  figure(GlassLabel('$minutes', role: gt.typeTitle2, color: gt.colorLabel1), 'min'),
                  figure(GlassLabel('$chapters', role: gt.typeTitle2, color: gt.colorLabel1), 'chapters'),
                  figure(
                    Row(
                      children: [
                        GlyphIcon(GlassGlyph.flame, size: 16, color: gt.colorStreak, weight: GlassIconWeight.fill),
                        const SizedBox(width: 4),
                        GlassLabel('$days', role: gt.typeTitle2, color: gt.colorLabel1),
                      ],
                    ),
                    'day streak',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
