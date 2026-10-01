import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/recap/background_recaps.dart';
import 'package:manhwamaniacs/features/recap/recap_cache.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/routes/nav_extra.dart';
import 'package:manhwamaniacs/skins/glass/shell/purge.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// Listens once to [BackgroundRecaps.readyStream] and shows "Recap for X is ready" with Open anywhere in the app (glass 9.1.3);
/// `recap.ready` fires as `success`.
class RecapReadyListener extends ConsumerStatefulWidget {
  const RecapReadyListener({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<RecapReadyListener> createState() => _RecapReadyListenerState();
}

class _RecapReadyListenerState extends ConsumerState<RecapReadyListener> {
  StreamSubscription<RecapReady>? _sub;
  final List<VoidCallback> _off = [];

  @override
  void initState() {
    super.initState();
    final bg = ref.read(backgroundRecapsProvider);
    _sub = bg.readyStream.listen(_ready);
    // A profile switch or sign-out cancels running recaps; the 18+ purge cancels mature ones and deletes cached payloads (glass 8.0.8, 8.0.9).
    _off
      ..add(registerPlaybackStop('recap', bg.cancelAll))
      ..add(registerMatureStop('recap', () => bg.cancelWhere((e) => e.mature)))
      ..add(registerPurgeHolder('recap', (r) => unawaited(r.read(recapCacheProvider).clear())));
  }

  void _ready(RecapReady r) {
    unawaited(ref.read(glassHapticsProvider).fire(HapticEvent.recapReady));
    showGlassToast(
      ref,
      GlassToastSpec(
        'Recap for ${r.title} is ready',
        kind: GlassToastKind.success,
        actionLabel: 'Open',
        onAction: () => unawaited(ref.read(skinRouterProvider).push<void>(
            Routes.recap(r.sourceId, r.seriesKey,
                {'to': r.to, if (r.scope != 'series') 'scope': r.scope},),
            extra: const GlassNavExtra(),),),
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    for (final o in _off) {
      o();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
