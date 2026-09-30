import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/streak_flame.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// "Seven days in a row." and its siblings (sentence case).
String milestoneHeadline(int days) => switch (days) {
      7 => 'Seven days in a row.',
      30 => 'Thirty days in a row.',
      100 => 'One hundred days in a row.',
      365 => 'A whole year, every day.',
      _ => '$days days in a row.',
    };

/// "Your longest yet." when the streak is the longest, else "Your longest is 41.".
String milestoneDeck(ReadingStreak s) => s.currentDays >= s.longestDays ? 'Your longest yet.' : 'Your longest is ${s.longestDays}.';

/// The milestone title card (cinematic 9.2.2): a takeover on `#000000`, the
/// tier flame at 96 px with its bloom, `STREAK`, the typed numeral at 1.5x, the
/// headline, the deck, `Share` (primary) and `Close` (quiet). A tap outside the
/// column, a swipe down (past 120 px or 800 px/s), Android back and `Esc` close it.
class MilestoneCard extends StatefulWidget {
  const MilestoneCard({super.key, required this.days, required this.streak, required this.now, required this.onShare, required this.onClose});

  final int days;
  final ReadingStreak streak;

  /// Today, local (the flame's read-today state).
  final DateTime now;
  final VoidCallback onShare;
  final VoidCallback onClose;

  @override
  State<MilestoneCard> createState() => _MilestoneCardState();
}

class _MilestoneCardState extends State<MilestoneCard> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController.unbounded(vsync: this);
  double _drag = 0;

  @override
  void initState() {
    super.initState();
    _c.addListener(() => setState(() => _drag = _c.value));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _end(double velocity) {
    if (_drag > 120 || velocity > 800) {
      widget.onClose();
      return;
    }
    _c.value = _drag;
    _c.animateWith(SpringSimulation(CineSprings.release.description, _drag, 0, velocity / 3));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    final wide = MediaQuery.sizeOf(context).width >= 600;
    final headline = milestoneHeadline(widget.days);
    final today = DateTime(widget.now.year, widget.now.month, widget.now.day);
    final numeral = CineText.style(context, t.typeNumeral).copyWith(color: CineColors.ink100, fontFeatures: const [FontFeature.liningFigures(), FontFeature.tabularFigures()]);
    return Focus(
      autofocus: true,
      onKeyEvent: (_, e) {
        if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
          widget.onClose();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        label: 'Streak milestone: $headline',
        child: ColoredBox(
          color: CineColors.paper0,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onClose,
            onVerticalDragStart: (_) => _c.stop(),
            onVerticalDragUpdate: (d) {
              _drag = (_drag + d.delta.dy).clamp(0.0, 2000.0);
              setState(() {});
            },
            onVerticalDragEnd: (d) => _end(d.primaryVelocity ?? 0),
            child: SafeArea(
              child: Center(
                child: Transform.translate(
                  offset: Offset(0, _drag),
                  child: GestureDetector(
                    onTap: () {},
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: wide ? 520 : 360),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                          StreakFlame(
                            streak: HomeStreak(currentDays: widget.days, longestDays: widget.streak.longestDays < widget.days ? widget.days : widget.streak.longestDays, lastActiveDate: today),
                            size: 96,
                            now: today,
                            ignite: false,
                          ),
                          SetHeading('STREAK', id: 'milestone-kicker', style: CineText.style(context, t.typeKicker).copyWith(color: CineColors.ink60), cap: t.typeKicker.cap, level: null, trigger: SetTrigger.signal),
                          const SizedBox(height: 8),
                          Semantics(
                            label: '${widget.days} days',
                            excludeSemantics: true,
                            child: TypedHeadline(
                              '${widget.days}',
                              style: numeral.copyWith(fontSize: numeral.fontSize! * 1.5),
                              cap: t.typeNumeral.cap,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SetHeading(headline, id: 'milestone-${widget.days}', style: CineText.style(context, t.typeHeadline).copyWith(color: CineColors.ink100), cap: t.typeHeadline.cap, level: 1, trigger: SetTrigger.signal),
                          const SizedBox(height: 12),
                          CineRoleText(milestoneDeck(widget.streak), t.typeDeck, color: CineColors.ink60),
                          const SizedBox(height: 24),
                          Row(children: [
                            CineButton(label: 'Share', onPressed: widget.onShare),
                            const SizedBox(width: 8),
                            CineButton(label: 'Close', variant: CineButtonVariant.quiet, onPressed: widget.onClose),
                          ],),
                        ],),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
