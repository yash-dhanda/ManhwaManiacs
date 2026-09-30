import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/glass/glass/shape.dart';
import 'package:manhwamaniacs/skins/glass/parts/recommend/lift_provider.dart';
import 'package:manhwamaniacs/skins/glass/primitives/magnet_targets.dart';
import 'package:manhwamaniacs/skins/glass/primitives/poster.dart' show GlassLiftPhase;
import 'package:manhwamaniacs/skins/glass/primitives/profile_orb.dart';
import 'package:manhwamaniacs/skins/glass/primitives/spring_value.dart';
import 'package:manhwamaniacs/skins/glass/screens/profiles/avatar_map.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart' show glassOfflineProvider;
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart' show gt;

/// The friend orbs of the recommend gesture (glass 9.3.4), mounted by the screen that owns posters (Home now; `mobile/43` moves the
/// mount into the shell). While a poster is lifted and this profile shares activity and someone can receive it, their 56 px orbs
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

  @override
  void initState() {
    super.initState();
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

/// The orb row itself (public for the captures and the tests).
class RecommendOrbLayer extends ConsumerWidget {
  const RecommendOrbLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lift = ref.watch(liftProvider);
    final members = ref.watch(_orbRecipientsProvider);
    final held = ref.watch(magnetHeldProvider);
    final pulse = ref.watch(orbPulseProvider);
    final show = lift != null && lift.phase == GlassLiftPhase.lifted && members.isNotEmpty;
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
