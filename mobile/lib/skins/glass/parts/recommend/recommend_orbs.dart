import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/circle/utils/letters_deferred.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/glass/parts/recommend/lift_provider.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart' show gt;
import 'package:manhwamaniacs/skins/glass/primitives/magnet_targets.dart';
import 'package:manhwamaniacs/skins/glass/primitives/profile_orb.dart';
import 'package:manhwamaniacs/skins/glass/primitives/spring_value.dart';
import 'package:manhwamaniacs/skins/glass/screens/profiles/avatar_map.dart';
import 'package:manhwamaniacs/skins/glass/shell/purge.dart' show registerPurgeHolder;
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart' show glassOfflineProvider;
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';

/// The one magnet registry of the recommend orbs: every screen's posters read their `targets` from it (glass 9.3.4).
final glassRecommendMagnetsProvider = Provider<GlassMagnetRegistry>((ref) => GlassMagnetRegistry(), name: 'glassRecommendMagnets');

/// Registers the Circle's part of the 18+ purge (glass 8.0.8 step 5): the Circle caches go outright, the reaction outbox drops
/// its mature entries and every pending letter for a mature series is cancelled.
void purgeCircleMature(Ref ref) {
  for (final p in <ProviderOrFamily>[circleMembersProvider, circleMemberProvider, recipientsProvider, seriesMembersProvider, circleFeedProvider, memberFeedProvider, circleSeriesProvider, chapterReactionsProvider, lettersProvider, sentLettersProvider]) {
    ref.invalidate(p);
  }
  unawaited(ref.read(reactionOutboxProvider)?.dropMature());
  ref.read(pendingLettersProvider.notifier).dropMature();
}

/// The friend orbs of the recommend gesture (glass 9.3.4), mounted once by the Glass shell above the navigator (it was Home's
/// until `mobile/43`). While a poster is lifted and this profile shares activity and someone can receive it, their 56 px orbs
/// materialise along the top, 72 px apart, as one glass layer in a root [OverlayEntry]; each orb is a magnet target of [registry].
class GlassRecommendOrbs extends ConsumerStatefulWidget {
  const GlassRecommendOrbs({super.key, required this.registry, required this.child});

  /// The registry the screen's posters read their `targets` from.
  final GlassMagnetRegistry registry;
  final Widget child;

  @override
  ConsumerState<GlassRecommendOrbs> createState() => _GlassRecommendOrbsState();
}

class _GlassRecommendOrbsState extends ConsumerState<GlassRecommendOrbs> {
  OverlayEntry? _entry;
  late final VoidCallback _offPurge;

  @override
  void initState() {
    super.initState();
    _offPurge = registerPurgeHolder('circle', purgeCircleMature);
    // Keeps the pending letters alive for the session (their pause flush and the purge).
    ref.read(pendingLettersProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final overlay = Overlay.maybeOf(context, rootOverlay: true);
      if (overlay == null) return;
      _entry = OverlayEntry(builder: (_) => GlassMagnetScope(registry: widget.registry, child: const RecommendOrbLayer()));
      overlay.insert(_entry!);
    });
  }

  @override
  void dispose() {
    _offPurge();
    _entry?.remove();
    _entry?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// The recipients of the lifted series who can receive it, or none when sharing is off, the device is offline or nothing is lifted.
final _orbRecipientsProvider = Provider.autoDispose<List<CircleMember>>((ref) {
  final lift = ref.watch(liftProvider);
  if (lift == null) return const [];
  final profile = ref.watch(activeProfileProvider);
  if (profile == null || ref.watch(glassOfflineProvider)) return const [];
  final sharing = ref.watch(sharingProvider(profile.id)).valueOrNull;
  if (sharing == null || !sharing.activity) return const [];
  return ref.watch(recipientsProvider((sourceId: lift.sourceId, seriesKey: lift.seriesKey))).valueOrNull ?? const [];
});

/// Whether the recommend orbs are up (a lifted poster and someone to send it to). The shell hides the dock meanwhile, which
/// keeps a phone frame within 8 glass shapes with four orbs (glass 15.7).
final recommendOrbsUpProvider = Provider.autoDispose<bool>((ref) {
  final lift = ref.watch(liftProvider);
  return lift != null && lift.phase == LiftPhase.lifted && ref.watch(_orbRecipientsProvider).isNotEmpty;
}, name: 'glassRecommendOrbsUp',);

/// The orb row itself (public for the captures and the tests).
class RecommendOrbLayer extends ConsumerWidget {
  const RecommendOrbLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lift = ref.watch(liftProvider);
    final members = ref.watch(_orbRecipientsProvider);
    final held = ref.watch(magnetHeldProvider);
    final pulse = ref.watch(orbPulseProvider);
    final show = lift != null && lift.phase == LiftPhase.lifted && members.isNotEmpty;
    if (!show) return const SizedBox.shrink();
    final top = MediaQuery.viewPaddingOf(context).top + 72;
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Center(
        child: Semantics(
          container: true,
          label: 'Recommend to a friend',
          child: SkinGlassGroup(
            debugLabel: 'GlassRecommendOrbs',
            gap: 16,
            shapes: [
              for (final m in members)
                SkinGlassShape(
                  size: const Size(56, 56),
                  shape: const GlassShape.circle(),
                  child: _Orb(member: m, swollen: held == m.profileId, pulse: pulse == m.profileId),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.member, required this.swollen, required this.pulse});
  final CircleMember member;
  final bool swollen, pulse;

  @override
  Widget build(BuildContext context) => SpringValue(
        value: pulse ? 1.15 : (swollen ? 1.2 : 1),
        spring: pulse ? gt.springCelebrate : gt.springPress,
        builder: (context, v, _) => Transform.scale(
          scale: v,
          child: GlassProfileOrb(preset: glassPresetFor(member.avatarKey), size: 56, friend: true, name: member.name, targetId: member.profileId),
        ),
      );
}
