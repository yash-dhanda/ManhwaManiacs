import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/recap/background_recaps.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/routes/nav_extra.dart';
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

  @override
  void initState() {
    super.initState();
    _sub = ref.read(backgroundRecapsProvider).readyStream.listen(_ready);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
