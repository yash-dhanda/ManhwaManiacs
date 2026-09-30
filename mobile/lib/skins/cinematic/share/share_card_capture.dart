import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/authed_cover.dart';
import 'package:manhwamaniacs/skins/cinematic/share/share_card.dart';
import 'package:manhwamaniacs/skins/cinematic/share/share_card_model.dart';

/// Renders [t] as a PNG (1080 x 1920 or 1080 x 1350 at pixel ratio 1.0): an
/// off-screen `RepaintBoundary` on the root overlay, the art precached, then
/// `toImage` and `toByteData(png)`. Never draws a screenshot of the UI.
Future<Uint8List> renderShareCard(
    BuildContext context, ShareTemplate t, ShareFormat f,) async {
  final overlay = Overlay.of(context, rootOverlay: true);
  final key = GlobalKey();
  final sz = shareSize(f);
  ImageProvider? art;
  final url = t.art?.coverUrl;
  if (url != null) {
    art = ProviderScope.containerOf(context).read(authedCoverProvider)(url);
    final done = Completer<void>();
    unawaited(precacheImage(art, context,
            onError: (_, __) => done.isCompleted ? null : done.complete(),)
        .then((_) => done.isCompleted ? null : done.complete()),);
    await done.future;
  }
  final entry = OverlayEntry(
    builder: (context) => Positioned(
      left: -100000,
      top: 0,
      width: sz.width,
      height: sz.height,
      child: RepaintBoundary(
          key: key, child: ShareCard(template: t, format: f, art: art),),
    ),
  );
  overlay.insert(entry);
  try {
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  } finally {
    entry.remove();
  }
}
