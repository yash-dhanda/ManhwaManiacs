/// The narration's loudness for the Glass speaking orb (glass 8.16.2, A4). `just_audio` exposes no audio level, so the chapter's
/// `ogg` rendition is decoded once by `flutter_soloud` (`readSamplesFromMem`, 30 averaged samples a second) and the orb reads that
/// envelope at the playhead; when the decode is unavailable the envelope is built from the segment timings instead.
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:manhwamaniacs/features/novels/models/novel_audio.dart';
import 'package:manhwamaniacs/features/novels/models/novel_audio_format.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_chapter_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';

/// Envelope samples per second of audio.
const int kNarrationLevelRate = 30;

class NarrationLevel {
  const NarrationLevel(this.envelope);

  /// 0..1 per 1/30 s.
  final List<double> envelope;

  /// The number of samples `readSamplesFromMem` is asked for: `ceil(total_ms / 1000 x 30)`.
  static int sampleCount(int totalMs) => totalMs <= 0 ? 0 : (totalMs / 1000 * kNarrationLevelRate).ceil();

  /// Normalises decoded [samples] (signed, averaged) to 0..1 against their own peak.
  factory NarrationLevel.fromSamples(Float32List samples) {
    var peak = 0.0;
    for (final s in samples) {
      peak = math.max(peak, s.abs());
    }
    if (peak <= 0) return NarrationLevel(List<double>.filled(samples.length, 0));
    return NarrationLevel([for (final s in samples) (s.abs() / peak).clamp(0.0, 1.0)]);
  }

  /// Speech is 1.0 inside a speech segment and 0 in the gaps.
  factory NarrationLevel.fromSegments(List<NovelAudioSegment> segments, int totalMs) {
    final n = sampleCount(totalMs);
    final env = List<double>.filled(n, 0);
    for (final s in segments) {
      if (!s.isSpeech) continue;
      final from = (s.startMs * kNarrationLevelRate / 1000).floor().clamp(0, n);
      final to = (s.endMs * kNarrationLevelRate / 1000).ceil().clamp(0, n);
      for (var i = from; i < to; i++) {
        env[i] = 1;
      }
    }
    return NarrationLevel(env);
  }

  /// The envelope at [position]; 0 outside it.
  double levelAt(Duration position) {
    final i = (position.inMicroseconds * kNarrationLevelRate / Duration.microsecondsPerSecond).floor();
    return i < 0 || i >= envelope.length ? 0 : envelope[i];
  }
}

typedef LevelFetch = Future<Uint8List?> Function(NovelChapterKey key);
typedef LevelDecode = Future<Float32List> Function(Uint8List bytes, int samples);

/// The `ogg` bytes of a chapter, through the authenticated client (the playing m4a stays the playback source on iOS).
final narrationLevelFetchProvider = Provider<LevelFetch>((ref) {
  final dio = ref.watch(dioProvider);
  return (key) async {
    try {
      final r = await dio.get<List<int>>(
        '/novels/audio/file',
        queryParameters: novelAudioFileQuery(
          sourceId: key.sourceId,
          seriesKey: key.seriesKey,
          chapterKey: key.chapterKey,
          format: NovelAudioFormat.ogg,
        ),
        options: Options(responseType: ResponseType.bytes),
      );
      final data = r.data;
      return data == null ? null : Uint8List.fromList(data);
    } catch (_) {
      return null;
    }
  };
},
    name: 'narrationLevelFetch',);

final narrationLevelDecodeProvider = Provider<LevelDecode>(
  (ref) => (bytes, n) => SoLoud.instance.readSamplesFromMem(bytes, n, average: true),
  name: 'narrationLevelDecode',
);

/// A saved copy's file when it is Ogg; the decode then needs no network.
typedef LevelSource = ({NovelChapterKey key, int totalMs, List<NovelAudioSegment> segments, File? savedOgg});

/// Builds the envelope for one chapter: decoded when possible, the segment fallback otherwise. The decode runs in the background after
/// playback starts; until it returns the caller shows a static orb.
Future<NarrationLevel> buildNarrationLevel(Ref ref, LevelSource src) async {
  try {
    final bytes = src.savedOgg != null ? await src.savedOgg!.readAsBytes() : await ref.read(narrationLevelFetchProvider)(src.key);
    if (bytes != null && bytes.isNotEmpty) {
      final samples = await ref.read(narrationLevelDecodeProvider)(bytes, NarrationLevel.sampleCount(src.totalMs));
      if (samples.isNotEmpty) return NarrationLevel.fromSamples(samples);
    }
  } catch (e) {
    debugPrint('narration level decode failed: $e');
  }
  return NarrationLevel.fromSegments(src.segments, src.totalMs);
}
