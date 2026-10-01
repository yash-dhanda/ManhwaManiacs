import 'dart:math' as math;
import 'dart:ui' show Rect, TextBox, TextDirection;

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/novels/models/novel_cast.dart';
import 'package:manhwamaniacs/skins/glass/listen/band_geometry.dart';
import 'package:manhwamaniacs/skins/glass/listen/cast_line.dart';
import 'package:manhwamaniacs/skins/glass/listen/job_rows.dart';
import 'package:manhwamaniacs/skins/glass/listen/listen_accessory.dart';
import 'package:manhwamaniacs/skins/glass/listen/orbit_math.dart';
import 'package:manhwamaniacs/skins/glass/listen/paged_follow.dart';
import 'package:manhwamaniacs/skins/glass/listen/skip_toast.dart';

NovelAudioJob job(String status, {double progress = 0, String? code}) => NovelAudioJob(jobId: 'j', chapterKey: 'c', status: status, progress: progress, errorCode: code);

void main() {
  group('castLine', () {
    test('automatic narrator', () => expect(castLine(narratorVoiceName: null, voicedCounts: const []), 'Narrated by the default voice'));
    test('names the voice with the most characters; ties go to the earlier voice', () {
      expect(castLine(narratorVoiceName: 'Aurora', voicedCounts: const [(voiceName: 'Ada', characters: 2), (voiceName: 'Kade', characters: 5), (voiceName: 'Mira', characters: 5)]), 'Narrated by Aurora · Kade voices 5 characters');
      expect(castLine(narratorVoiceName: 'Aurora', voicedCounts: const [(voiceName: 'Ada', characters: 1)]), 'Narrated by Aurora · Ada voices 1 character');
      expect(castLine(narratorVoiceName: 'Aurora', voicedCounts: const [(voiceName: 'Ada', characters: 0)]), 'Narrated by Aurora');
    });
  });

  test('accessory priority: narrating, downloading, continue (Home, hero gone)', () {
    GlassAccessoryKind f({bool n = false, bool d = false, bool c = false, bool home = true, bool hero = false}) => accessoryFor(narration: n, downloads: d, continueItem: c, onHome: home, heroVisible: hero);
    expect(f(n: true, d: true, c: true), GlassAccessoryKind.narrating);
    expect(f(d: true, c: true), GlassAccessoryKind.downloading);
    expect(f(c: true), GlassAccessoryKind.continueItem);
    expect(f(c: true, hero: true), GlassAccessoryKind.none);
    expect(f(c: true, home: false), GlassAccessoryKind.none);
  });

  group('orbit maths', () {
    test('depth', () {
      expect(orbitRotateY(0), 0);
      expect(orbitRotateY(1), closeTo(18 * math.pi / 180, 1e-9));
      expect(orbitRotateY(-5), closeTo(-36 * math.pi / 180, 1e-9));
      expect(orbitScale(0), 1);
      expect(orbitScale(1), closeTo(0.86, 1e-9));
      expect(orbitScale(3), closeTo(0.86, 1e-9));
      expect(orbitOpacity(1), closeTo(0.6, 1e-9));
      expect(orbitOpacity(0.5), closeTo(0.8, 1e-9));
      expect(kOrbitStride, 176);
    });
    test('pitch track and dots', () {
      expect(pitchPosition(80), 0);
      expect(pitchPosition(300), 1);
      expect(pitchPosition(190), closeTo(0.5, 1e-9));
      expect(pitchPosition(10), 0);
      expect({for (var r = 1; r <= 31; r++) expressivenessDots(r, 31)}, {1, 2, 3, 4, 5});
      expect(expressivenessDots(31, 31), 5);
      expect(expressivenessDots(1, 31), 1);
      expect(expressivenessRanks([0.3, 0.1, 0.2]), [3, 1, 2]);
    });
  });

  group('band geometry', () {
    TextBox box(double l, double t, double r, double b) => TextBox.fromLTRBD(l, t, r, b, TextDirection.ltr);
    test('merges boxes per line and pads 4 x 2', () {
      final r = bandRects([box(0, 0, 50, 20), box(50, 0, 90, 20), box(0, 22, 40, 42)]);
      expect(r, [const Rect.fromLTRB(-4, -2, 94, 22), const Rect.fromLTRB(-4, 20, 44, 44)]);
      expect(bandRects(const []), isEmpty);
    });
    test('morph pairs by index; extra rects grow from the last previous one; missing ones collapse', () {
      const a = [Rect.fromLTWH(0, 0, 100, 20)];
      const b = [Rect.fromLTWH(0, 0, 100, 20), Rect.fromLTWH(0, 22, 60, 20)];
      final mid = morphBands(a, b, 0.5);
      expect(mid.length, 2);
      expect(mid[1].top, closeTo(11, 1e-9));
      expect(morphBands(a, b, 1), b);
      expect(morphBands(b, a, 0.5).length, 2);
      expect(morphBands(b, a, 1), a);
      expect(morphBands(const [], b, 0.3), b);
    });
  });

  test('paged follow turns when the active line is below the page and decouples on a manual turn', () {
    expect(shouldTurn(activeFirstLineTop: 700, pageBottom: 600), isTrue);
    expect(shouldTurn(activeFirstLineTop: 500, pageBottom: 600), isFalse);
    final f = PagedFollow();
    expect(f.turnFor(activeFirstLineTop: 700, pageBottom: 600), isTrue);
    f.manualTurn();
    expect(f.turnFor(activeFirstLineTop: 700, pageBottom: 600), isFalse);
    f.backToTheVoice();
    expect(f.turnFor(activeFirstLineTop: 700, pageBottom: 600), isTrue);
  });

  group('job rows', () {
    test('every status', () {
      expect(jobRowFor(job('queued'), owner: true).title, 'Waiting for the narration PC');
      expect(jobRowFor(job('queued'), owner: true).canCancel, isTrue);
      expect(jobRowFor(job('queued'), owner: false).canCancel, isFalse);
      expect(jobRowFor(job('planning'), owner: true).spinner, isTrue);
      final r = jobRowFor(job('rendering', progress: 0.42), owner: true);
      expect(r.title, 'Rendering · 42 %');
      expect(r.progress, 0.42);
      expect(jobRowFor(job('done'), owner: true).tone, JobTone.success);
      expect(jobRowFor(job('cancelled'), owner: true).removable, isTrue);
    });
    test('failures', () {
      expect(jobRowFor(job('failed', code: 'lease_expired'), owner: true).title, 'The narration PC stopped responding');
      expect(jobRowFor(job('failed', code: 'audio_convert_failed'), owner: true).title, "Rendering failed: the audio couldn't be converted");
      expect(jobRowFor(job('failed', code: 'boom'), owner: true).title, 'Rendering failed (boom)');
      expect(jobRowFor(job('failed', code: 'boom'), owner: true).canRerender, isTrue);
      expect(jobRowFor(job('failed', code: 'boom'), owner: false).canRerender, isFalse);
    });
  });

  group('skip toast', () {
    test('four reasons', () {
      expect(queuedToast(queued: 5, skipped: {'a': 'already_rendered', 'b': 'already_rendered', 'c': 'chapter_not_cached'}), 'Queued 5 chapters for narration. Skipped: 2 already narrated, 1 not on the server yet.');
      expect(queuedToast(queued: 1, skipped: {'a': 'chapter_unreadable', 'b': 'already_queued'}), "Queued 1 chapter for narration. Skipped: 1 couldn't be read, 1 already waiting.");
      expect(queuedToast(queued: 3, skipped: const {}), 'Queued 3 chapters for narration.');
      expect(queuedToast(queued: 0, skipped: {'a': 'already_rendered'}), 'Nothing to narrate.');
      expect(savingToast(5), 'Saving the audio of 5 chapters to this device.');
    });
  });
}
