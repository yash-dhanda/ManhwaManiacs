import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/network/api_image.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_extras.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

// TODO(mobile/04): CinePoster stand-in (caption mode Below, radius 0).

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

/// 2:3 poster, title on 2 lines below, optional folio caption.
class CinePoster extends StatelessWidget {
  const CinePoster({
    super.key,
    required this.title,
    required this.coverUrl,
    required this.onTap,
    this.caption,
    this.width,
    this.onLongPress,
    this.heroTag,
  });

  final String title;
  final String? coverUrl;
  final String? caption;
  final double? width;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    Widget art = AspectRatio(
      aspectRatio: 2 / 3,
      child: CineCover(url: coverUrl, displayWidth: width),
    );
    if (heroTag != null) art = Hero(tag: heroTag!, child: art);
    return Semantics(
      button: true,
      label: caption == null ? title : '$title, $caption',
      excludeSemantics: true,
      onLongPress: onLongPress,
      child: CineFocusRing(
        child: CineLongPress(
          onLongPress: onLongPress,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  art,
                  const SizedBox(height: CineSpace.s2),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: cineText(context, t.typeTitle),
                  ),
                  if (caption != null)
                    Text(
                      caption!,
                      style: cineText(
                        context,
                        t.typeFolio,
                        color: t.colorInk60,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Duotone over [child]: luminance mapped from black to [duo]. TODO(mobile/04):
/// swap for `duotone.dart` and the series' own `ambient.duo`.
class Duotone extends StatelessWidget {
  const Duotone({super.key, required this.duo, required this.child});

  final Color duo;
  final Widget child;

  static const _gray = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) => ColorFiltered(
        colorFilter: ColorFilter.mode(duo, BlendMode.modulate),
        child: ColorFiltered(colorFilter: _gray, child: child),
      );
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
