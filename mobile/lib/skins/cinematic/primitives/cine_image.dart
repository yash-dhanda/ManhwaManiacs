import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/network/api_image.dart';
import 'package:manhwamaniacs/core/network/request_limiter.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The plate a cover sits on before, and instead of, its picture: `paper.1`, the inner hairline
/// and (when the title is known) a title card in Bodoni Moda Italic bottom-left.
class CinePlate extends StatelessWidget {
  const CinePlate({super.key, this.title, this.flicker = false, this.error = false, this.errorLabel = "Cover didn't load", this.index = 0});
  final String? title;
  final bool flicker, error;
  final String errorLabel;
  final int index;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    Widget plate = ColoredBox(color: c.colorPaper1, child: const SizedBox.expand());
    if (flicker) plate = CineFlicker(index: index, child: plate);
    return Stack(fit: StackFit.expand, children: [
      plate,
      if (title != null && title!.isNotEmpty)
        Positioned(
          left: 8,
          bottom: 8,
          right: error ? 32 : 8,
          child: ExcludeSemantics(child: CineLit(title!, CineFace.bodoni, 14, 16, italic: true, color: c.colorInk60, maxLines: 3, overflow: TextOverflow.ellipsis)),
        ),
      if (error)
        Positioned(
          right: 8,
          bottom: 8,
          child: Semantics(label: errorLabel, image: true, child: CineGlyphIcon(CineGlyph.imageBroken, size: 16, color: c.colorInk45)),
        ),
    ],);
  }
}

/// A cover picture (cinematic 7.7). Remote covers ask for the nearest snapped width at the
/// device pixel ratio, wait for a P2 grant from the sources limiter unless the bytes are already
/// in the local cache, and rack into focus on first decode.
class CineImage extends ConsumerStatefulWidget {
  const CineImage({
    super.key,
    required this.url,
    this.title,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.withCredentials = true,
    this.flickerIndex = 0,
    this.width,
  });

  /// Absolute API or CDN URL, `assets/...`, `file:` or `data:`; null shows the plate.
  final String? url;
  final String? title;
  final BoxFit fit;
  final Alignment alignment;

  /// False for somebody else's host: the bearer token and profile id are this server's.
  final bool withCredentials;
  final int flickerIndex;

  /// The slot width when the parent does not bound it.
  final double? width;

  /// Whether [url] is already in the local cache: a hit costs nothing and skips the limiter.
  @visibleForTesting
  static Future<bool> Function(String url) cacheProbe = (url) async {
    try {
      return await DefaultCacheManager().getFileFromCache(url) != null;
    } catch (_) {
      return false;
    }
  };

  @visibleForTesting
  static ImageProvider Function(String url, Map<String, String>? headers) providerBuilder =
      (url, headers) => CachedNetworkImageProvider(url, headers: headers);

  static bool isLocal(String url) => url.startsWith('assets/') || url.startsWith('file:') || url.startsWith('data:') || url.startsWith('/');

  @override
  ConsumerState<CineImage> createState() => _CineImageState();
}

class _CineImageState extends ConsumerState<CineImage> {
  ImageProvider? _provider;
  String? _resolvedFor;
  Completer<void>? _cancel;
  bool _granted = false;
  int _gen = 0;

  @override
  void dispose() {
    _gen++;
    _abort();
    super.dispose();
  }

  void _abort() {
    final c = _cancel;
    if (c != null && !c.isCompleted && !_granted) c.complete();
  }

  ImageProvider _local(String url) {
    if (url.startsWith('assets/')) return AssetImage(url);
    if (url.startsWith('data:')) return MemoryImage(UriData.parse(url).contentAsBytes());
    return FileImage(File(url.startsWith('file:') ? Uri.parse(url).toFilePath() : url));
  }

  void _resolve(String url, double logicalWidth, double dpr) {
    final key = '$url|${snappedCoverWidth(logicalWidth, dpr)}';
    if (_resolvedFor == key) return;
    _resolvedFor = key;
    _abort();
    _gen++;
    _granted = false;
    _provider = null;
    if (CineImage.isLocal(url)) {
      _provider = _local(url);
      return;
    }
    final gen = _gen;
    final finalUrl = coverUrlAtWidth(url, snappedCoverWidth(logicalWidth, dpr));
    final headers = widget.withCredentials
        ? apiImageHttpHeaders(ref.read(authTokenStoreProvider).token, profileId: ref.read(activeProfileProvider)?.id)
        : null;
    final cancel = _cancel = Completer<void>();
    unawaited(() async {
      if (await CineImage.cacheProbe(finalUrl)) {
        if (mounted && gen == _gen) setState(() => _provider = CineImage.providerBuilder(finalUrl, headers));
        return;
      }
      // The cache probe is async: a page that was left meanwhile must not touch `ref`.
      if (!mounted || gen != _gen) return;
      final limiter = ref.read(sourcesLimiterProvider);
      LimiterTicket ticket;
      try {
        ticket = await limiter.acquire(RequestPriority.p2, cancel: cancel.future);
      } on LimiterCancelled {
        return;
      }
      _granted = true;
      limiter.release(ticket);
      if (mounted && gen == _gen) setState(() => _provider = CineImage.providerBuilder(finalUrl, headers));
    }());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final url = widget.url;
    if (url == null || url.isEmpty) return CinePlate(title: widget.title, flicker: true, index: widget.flickerIndex);
    return LayoutBuilder(builder: (context, box) {
      final w = box.hasBoundedWidth ? box.maxWidth : (widget.width ?? 240);
      _resolve(url, w, MediaQuery.devicePixelRatioOf(context));
      final p = _provider;
      if (p == null) return CinePlate(title: widget.title, flicker: true, index: widget.flickerIndex);
      return Stack(fit: StackFit.expand, children: [
        ColoredBox(color: c.colorPaper1, child: const SizedBox.expand()),
        Image(
          image: p,
          fit: widget.fit,
          alignment: widget.alignment,
          gaplessPlayback: true,
          frameBuilder: (context, child, frame, sync) {
            if (frame == null && !sync) return CinePlate(title: widget.title, flicker: true, index: widget.flickerIndex);
            return CineRackImage(skip: sync, child: child);
          },
          errorBuilder: (_, __, ___) => CinePlate(title: widget.title, error: true),
        ),
      ],);
    },);
  }
}
