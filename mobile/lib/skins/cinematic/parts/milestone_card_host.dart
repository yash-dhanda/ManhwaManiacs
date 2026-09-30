import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart';
import 'package:manhwamaniacs/features/library/models/shareable.dart';
import 'package:manhwamaniacs/features/library/providers/numbers_providers.dart';
import 'package:manhwamaniacs/features/library/utils/milestones.dart';
import 'package:manhwamaniacs/features/library/utils/streak_state.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/cine_text.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/cue.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/dip_page.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/milestone_card.dart';
import 'package:manhwamaniacs/skins/cinematic/share/press_run.dart';
import 'package:manhwamaniacs/skins/cinematic/share/share_card_model.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The profiles that already saw a milestone card this app session (once per
/// profile per session; the server's `milestones_seen` covers other devices).
final milestoneSessionProvider = StateProvider<Set<String>>((_) => {}, name: 'milestoneSession');

/// Pushes the milestone title card as an overlay route on the root navigator
/// (no path, `opaque: false`) on the first visit to Tonight or The Numbers after
/// the chapter that reached it. Never inside a reader. Wrap a screen with it and
/// hand it the streak the screen loaded.
///
/// TODO(mobile/08): Tonight mounts this with the `/home` streak
/// (`HomeStreak.toReadingStreak()`).
class MilestoneCardHost extends ConsumerStatefulWidget {
  const MilestoneCardHost({super.key, required this.streak, required this.child, this.shareable});

  final ReadingStreak? streak;
  final Shareable? shareable;
  final Widget child;

  @override
  ConsumerState<MilestoneCardHost> createState() => _MilestoneCardHostState();
}

class _MilestoneCardHostState extends ConsumerState<MilestoneCardHost> {
  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void didUpdateWidget(MilestoneCardHost old) {
    super.didUpdateWidget(old);
    if (old.streak != widget.streak) _check();
  }

  void _check() {
    final s = widget.streak;
    if (s == null) return;
    final days = pendingMilestone(s);
    if (days == null) return;
    final scope = ref.read(streakSeenKeyProvider); // unique per user and profile
    if (ref.read(milestoneSessionProvider).contains(scope)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final session = ref.read(milestoneSessionProvider);
      if (session.contains(scope)) return;
      ref.read(milestoneSessionProvider.notifier).state = {...session, scope};
      _open(s, days);
    });
  }

  void _open(ReadingStreak s, int days) {
    final nav = Navigator.of(context, rootNavigator: true);
    final repo = ref.read(numbersRepositoryProvider);
    // Mark every reached milestone up to the one shown; fire and forget.
    for (final m in milestonesToMark(s, days)) {
      repo.markMilestoneSeen(m);
    }
    cinematicCue(ref, HapticEvent.streakMilestone, SoundEvent.streakMilestone);
    final profile = ref.read(activeProfileProvider);
    nav.push<void>(
      DipOverlayRoute<void>(
        label: 'Streak milestone',
        reduced: cineReduced(context),
        builder: (context) => MilestoneCard(
          days: days,
          streak: s,
          onClose: nav.maybePop,
          onShare: () => showPressRun(context, ShareInput.milestone(days, streakTier(days), profile?.name ?? '', year: DateTime.now().year, art: widget.shareable)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
