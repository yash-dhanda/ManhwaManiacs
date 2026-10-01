/// The player's artwork (glass 8.16.2, E4): the book plate on a `fill2` twin card, radius 20, with parallax: the art moves up to
/// +/-6 px against the card from the phone's gravity (the shared 30 Hz low-passed source, relative to the pose at open), subscribed only
/// while the player is visible and "Light follows the device" is on. Static under reduced motion.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/platform/gravity.dart';
import 'package:manhwamaniacs/features/library/utils/cover_url.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/poster.dart' show GlassCoverImage;

/// The artwork's offset for a gravity reading [g] (in g): 12 px per g, at most 6 px each way.
Offset parallaxOffset(Offset g) => Offset((g.dx * 12).clamp(-6.0, 6.0), (g.dy * -12).clamp(-6.0, 6.0));

class GlassArtwork extends ConsumerStatefulWidget {
  const GlassArtwork({super.key, required this.sourceId, required this.seriesKey, required this.size});
  final String sourceId, seriesKey;
  final double size;

  @override
  ConsumerState<GlassArtwork> createState() => _GlassArtworkState();
}

class _GlassArtworkState extends ConsumerState<GlassArtwork> {
  StreamSubscription<Offset>? _sub;
  final ValueNotifier<Offset> _offset = ValueNotifier(Offset.zero);

  void _sync() {
    final reduced = ref.read(glassMotionPrefsProvider).reduced;
    final follows = ref.read(glassInAppPrefsProvider).lightFollowsDevice;
    final want = !reduced && follows && TickerMode.valuesOf(context).enabled;
    if (want && _sub == null) {
      _sub = ref.read(gravityProvider).stream.listen((g) => _offset.value = parallaxOffset(g), onError: (Object _) {});
    } else if (!want && _sub != null) {
      unawaited(_sub!.cancel());
      _sub = null;
      _offset.value = Offset.zero;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    _offset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(glassMotionPrefsProvider.select((m) => m.reduced), (_, __) => _sync());
    ref.listen(glassInAppPrefsProvider.select((p) => p.lightFollowsDevice), (_, __) => _sync());
    final base = ref.watch(apiBaseUrlProvider);
    final url = sourceSeriesCoverUrl(base, widget.sourceId, widget.seriesKey);
    final s = widget.size;
    return ExcludeSemantics(
      child: Container(
        width: s,
        height: s * 1.0,
        decoration: BoxDecoration(color: gt.colorFill2, borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: ValueListenableBuilder<Offset>(
          valueListenable: _offset,
          builder: (context, o, _) => Transform.translate(
            offset: o,
            child: Transform.scale(scale: 1 + 12 / math.max(s, 1) , child: GlassCoverImage(url: url, width: s)),
          ),
        ),
      ),
    );
  }
}
