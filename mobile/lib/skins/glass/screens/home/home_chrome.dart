import 'dart:async';

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/novels/providers/novels_gate_provider.dart';
import 'package:manhwamaniacs/features/updates/mark_all_read.dart';
import 'package:manhwamaniacs/features/updates/providers/unread_count_provider.dart';
import 'package:manhwamaniacs/features/updates/providers/updates_provider.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/shell/glass_scaffold.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// The bell's glyph: it swings as a pendulum about its top pivot when the unread count rises (glass 2.7): an angular
/// `SpringSimulation(springOf(springTick), 0, 0, 6)` (k 584.0, c 33.83) drives the rotation. Reduced motion: no swing.
class HomeBell extends ConsumerStatefulWidget {
  const HomeBell({super.key, this.pressed = false});
  final bool pressed;

  @override
  ConsumerState<HomeBell> createState() => _HomeBellState();
}

class _HomeBellState extends ConsumerState<HomeBell> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController.unbounded(vsync: this);

  @override
  void initState() {
    super.initState();
    ref.listenManual<int>(unreadNotificationCountProvider, (prev, next) {
      if (prev != null && next > prev) _swing();
    });
  }

  void _swing() {
    if (ref.read(glassMotionPrefsProvider).reduced) return;
    _c.value = 0;
    unawaited(_c.animateWith(SpringSimulation(springOf(GlassSprings.tick), 0, 0, 6)));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// For captures: the bell mid-swing.
  @visibleForTesting
  void swingNow() => _swing();

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, child) => Transform.rotate(angle: _c.value, alignment: Alignment.topCenter, child: child),
        child: Icon(GlassGlyph.bellSimple.regular, size: 22, color: gt.colorOnGlass),
      );
}

/// The bell and its count badge, then the overflow menu (Refresh, Ask for something to read, Updates, Mark all read).
List<GlassBarAction> homeBarActions(WidgetRef ref) => [
      GlassBarAction(
        id: 'updates',
        label: 'Updates',
        glyph: GlassGlyph.bellSimple,
        badge: ref.watch(unreadNotificationCountProvider),
        onPress: () => unawaited(ref.read(skinRouterProvider).push<void>(Routes.updates())),
        iconBuilder: (context) => const HomeBell(),
      ),
    ];

List<GlassMenuEntry> homeOverflow(WidgetRef ref, {required VoidCallback refresh}) => [
      GlassMenuEntry(label: 'Refresh', onSelected: refresh),
      GlassMenuEntry(label: 'Ask for something to read', onSelected: () => unawaited(ref.read(skinRouterProvider).push<void>(Routes.picks()))),
      GlassMenuEntry(label: 'Updates', onSelected: () => unawaited(ref.read(skinRouterProvider).push<void>(Routes.updates()))),
      homeMarkAllReadEntry(ref),
    ];

/// "Mark all read" for Home's overflow and the dock: the shared `markAllReadMode` scope (every mode unless novels are on) and a
/// label that names the mode it clears.
GlassMenuEntry homeMarkAllReadEntry(WidgetRef ref) {
  final mode = markAllReadMode(novelsEnabled: ref.read(novelsEnabledProvider), mode: ref.read(contentModeControllerProvider));
  return GlassMenuEntry(
    label: markAllReadLabel(mode),
    onSelected: () => unawaited(() async {
      final err = await ref.read(updatesProvider.notifier).markAllRead(mode: mode);
      showGlassToast(ref, err == null ? const GlassToastSpec('Marked all as read', kind: GlassToastKind.success) : const GlassToastSpec("Couldn't mark those as read", kind: GlassToastKind.error));
    }()),
  );
}
