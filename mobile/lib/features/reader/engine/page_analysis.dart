import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:manhwamaniacs/features/reader/engine/page_tint.dart';
import 'package:manhwamaniacs/features/reader/engine/panels.dart';

/// Raw pixels of one analysis request; travels to the isolate as plain data.
class AnalysisRequest {
  const AnalysisRequest(this.tintRgba, this.panelRgba, this.panelWidth, this.panelHeight, this.direction);
  final Uint8List? tintRgba;
  final Uint8List? panelRgba;
  final int panelWidth;
  final int panelHeight;
  final PanelDirection direction;
}

/// What one analysis call found. [panels] are page fractions.
class AnalysisResult {
  const AnalysisResult({this.seed, this.tintFailed = false, this.panels, this.panelsFailed = false});
  final String? seed;
  final bool tintFailed;
  final List<PanelRect>? panels;
  final bool panelsFailed;
}

/// The isolate entry point: one pass for the tint (page n) and the panels (page n + 1).
AnalysisResult runAnalysis(AnalysisRequest r) {
  String? seed;
  var tintFailed = false;
  List<PanelRect>? panels;
  var panelsFailed = false;
  if (r.tintRgba != null) {
    try {
      seed = pickPageSeed(r.tintRgba!);
    } catch (_) {
      tintFailed = true;
    }
  }
  if (r.panelRgba != null) {
    try {
      final rects = detectPanels(luminanceOf(r.panelRgba!), r.panelWidth, r.panelHeight, r.direction);
      panels = toPageFractions(rects, r.panelWidth, r.panelHeight);
    } catch (_) {
      panelsFailed = true;
    }
  }
  return AnalysisResult(seed: seed, tintFailed: tintFailed, panels: panels, panelsFailed: panelsFailed);
}

Future<(Uint8List, int, int)?> _decode(ImageProvider provider) async {
  final stream = provider.resolve(ImageConfiguration.empty);
  final done = Completer<ui.Image>();
  final listener = ImageStreamListener(
    (info, _) {
      if (done.isCompleted) return;
      done.complete(info.image.clone());
    },
    onError: (e, s) {
      if (!done.isCompleted) done.completeError(e);
    },
  );
  stream.addListener(listener);
  ui.Image? image;
  try {
    image = await done.future;
    final data = await image.toByteData();
    if (data == null) return null;
    return (data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes), image.width, image.height);
  } catch (_) {
    return null;
  } finally {
    stream.removeListener(listener);
    image?.dispose();
    // Analysis decodes never count against the engine's decode budget.
    try {
      PaintingBinding.instance.imageCache.evict(await provider.obtainKey(ImageConfiguration.empty));
    } catch (_) {}
  }
}

/// The two ResizeImage providers analysis decodes, exposed so a test can check their eviction.
ImageProvider tintProviderOf(ImageProvider page) =>
    ResizeImage(page, width: 16, height: 16);
ImageProvider panelProviderOf(ImageProvider page) => ResizeImage(page, width: 360);

/// Decodes the tint sample of one page (16 x 16) and the panel sample of the next (360 px wide),
/// then runs [runAnalysis] in one `compute()` call. Both decodes are evicted from the image cache.
Future<AnalysisResult> analysePage({
  ImageProvider? tintPage,
  ImageProvider? panelPage,
  required PanelDirection direction,
  Future<AnalysisResult> Function(AnalysisRequest) runner = _compute,
}) async {
  final tint = tintPage == null ? null : await _decode(tintProviderOf(tintPage));
  final panel = panelPage == null ? null : await _decode(panelProviderOf(panelPage));
  final r = await runner(AnalysisRequest(tint?.$1, panel?.$1, panel?.$2 ?? 0, panel?.$3 ?? 0, direction));
  return AnalysisResult(
    seed: r.seed,
    tintFailed: r.tintFailed || (tintPage != null && tint == null),
    panels: r.panels,
    panelsFailed: r.panelsFailed || (panelPage != null && panel == null),
  );
}

Future<AnalysisResult> _compute(AnalysisRequest r) => compute(runAnalysis, r);

/// At most one sample per [interval] (600 ms): 10 s of continuous scrolling makes 17 calls.
class SampleThrottle {
  SampleThrottle(this.interval);
  final Duration interval;
  Duration? _last;

  bool tryAcquire(Duration now) {
    if (_last != null && now - _last! < interval) return false;
    _last = now;
    return true;
  }
}
