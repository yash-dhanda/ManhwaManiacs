import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:manhwamaniacs/features/reader/engine/lru.dart';
import 'package:manhwamaniacs/features/reader/engine/page_sample.dart';
import 'package:manhwamaniacs/features/reader/engine/resolve_sample.dart';

typedef SampleDecoder = Future<PageSample?> Function(ImageProvider provider);

/// 64 px wide (at most 64 x 256) decode of [provider], sampled in `compute()`; null on any failure.
Future<PageSample?> decodePageSample(ImageProvider provider) async {
  final resized = ResizeImage(provider, width: 64, height: 256, policy: ResizeImagePolicy.fit);
  final stream = resized.resolve(ImageConfiguration.empty);
  final done = Completer<ui.Image?>();
  late ImageStreamListener l;
  l = ImageStreamListener((info, _) {
    if (!done.isCompleted) done.complete(info.image.clone());
    stream.removeListener(l);
  }, onError: (_, __) {
    if (!done.isCompleted) done.complete(null);
    stream.removeListener(l);
  },);
  stream.addListener(l);
  final image = await done.future;
  if (image == null) return null;
  try {
    final bytes = await image.toByteData();
    if (bytes == null) return null;
    return await samplePageInIsolate(bytes.buffer.asUint8List(), image.width, image.height);
  } finally {
    image.dispose();
  }
}

/// The page-sample duty of glass 15.4: the page under the reading line, sampled at most every
/// 600 ms while scrolling and once on settle, cached per page key in an LRU of 500, held while
/// the strip moves faster than 3000 px/s.
class PageSampler {
  PageSampler({required this.onSample, SampleDecoder? decoder, this.interval = const Duration(milliseconds: 600)})
      : _decode = decoder ?? decodePageSample;

  final void Function(PageSample sample) onSample;
  final SampleDecoder _decode;
  final Duration interval;

  /// Optional cover palette: the tint after 6 greyscale pages in a row.
  List<Color>? coverPalette;

  /// Decodes started: what the 120-page test bounds.
  int requests = 0;

  final Lru<String, PageSample> _cache = Lru(500);
  PageSample? _previous;
  int _greyRun = 0;
  ({String key, ImageProvider provider, String? manifestTint})? _target;
  String? _lastKey;
  PageSample? _held;
  bool _holding = false;
  DateTime? _lastDecode;
  Timer? _trailing, _settle;
  bool _disposed = false;
  DateTime Function() clock = DateTime.now;

  /// The reading line is on the page [key] (a url or chapter:page) while the strip moves at [velocity].
  void onScroll(String key, ImageProvider provider, String? manifestTint, double velocity) {
    if (_disposed) return;
    _target = (key: key, provider: provider, manifestTint: manifestTint);
    setVelocity(velocity);
    if (key != _lastKey) {
      _lastKey = key;
      final cached = _cache[key];
      if (cached != null) {
        _publish(resolveSample(_previous, cached, _greyRun, coverPalette));
      } else if (manifestTint != null) {
        final c = _parseHex(manifestTint);
        if (c != null) _publish(PageSample.manifest(c));
      }
    }
    if (!_cache.containsKey(key)) _schedule();
    _settle?.cancel();
    _settle = Timer(const Duration(milliseconds: 150), _decodeTarget);
  }

  /// Holds publication above 3000 px/s and releases the latest sample below it.
  void setVelocity(double v) {
    final hold = v.abs() > 3000;
    if (!hold && _holding) {
      _holding = false;
      final h = _held;
      _held = null;
      if (h != null) onSample(h);
    }
    _holding = hold;
  }

  void _schedule() {
    final last = _lastDecode;
    final now = clock();
    if (last == null || now.difference(last) >= interval) {
      _decodeTarget();
    } else {
      _trailing ??= Timer(interval - now.difference(last), () {
        _trailing = null;
        _decodeTarget();
      });
    }
  }

  Future<void> _decodeTarget() async {
    final t = _target;
    if (t == null || _disposed || _cache.containsKey(t.key)) return;
    _lastDecode = clock();
    requests++;
    final s = await _decode(t.provider);
    if (s == null || _disposed) return;
    _greyRun = nextGreyRun(_greyRun, s);
    final resolved = resolveSample(_previous, s, _greyRun, coverPalette);
    _cache[t.key] = s;
    if (_target?.key == t.key) _publish(resolved);
  }

  void _publish(PageSample s) {
    _previous = s;
    if (_holding) {
      _held = s;
    } else {
      onSample(s);
    }
  }

  static Color? _parseHex(String h) {
    final m = RegExp(r'^#?([0-9a-fA-F]{6})$').firstMatch(h);
    return m == null ? null : Color(0xFF000000 | int.parse(m.group(1)!, radix: 16));
  }

  void dispose() {
    _disposed = true;
    _trailing?.cancel();
    _settle?.cancel();
  }
}
