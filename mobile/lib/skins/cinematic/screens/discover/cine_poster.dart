import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/network/api_image.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// A cover image with the session's credentials, radius 0.
class CineCover extends ConsumerWidget {
  const CineCover({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.displayWidth,
  });

  final String? url;
  final BoxFit fit;
  final double? displayWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.cine;
    if (url == null || url!.isEmpty) return ColoredBox(color: t.colorPaper1);
    final w =
        coverRequestWidth(displayWidth, MediaQuery.devicePixelRatioOf(context));
    return CachedNetworkImage(
      imageUrl: coverUrlAtWidth(url!, w),
      httpHeaders: apiImageHttpHeaders(
        ref.watch(authTokenStoreProvider).token,
        profileId: ref.watch(activeProfileProvider)?.id,
      ),
      fit: fit,
      fadeInDuration: CineDur.beat,
      placeholder: (_, __) => ColoredBox(color: t.colorPaper1),
      errorWidget: (_, __, ___) => ColoredBox(color: t.colorPaper1),
    );
  }
}

/// A 1 px impression while pressed: 80 ms `easeSet` down, 160 ms `easeSettle`
/// up; none under reduced motion.
class PressImpression extends StatefulWidget {
  const PressImpression({super.key, required this.child});

  final Widget child;

  @override
  State<PressImpression> createState() => _PressImpressionState();
}

class _PressImpressionState extends State<PressImpression> {
  bool _down = false;

  void _set(bool v) {
    if (mounted && _down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: (_) => _set(true),
        onPointerUp: (_) => _set(false),
        onPointerCancel: (_) => _set(false),
        child: AnimatedContainer(
          duration: cineReduced(context)
              ? Duration.zero
              : (_down
                  ? const Duration(milliseconds: 80)
                  : const Duration(milliseconds: 160)),
          curve: _down ? CineCurves.easeSet : CineCurves.settle,
          transform: Matrix4.translationValues(0, _down ? 1 : 0, 0),
          child: widget.child,
        ),
      );
}
