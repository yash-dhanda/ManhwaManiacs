import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/novels/models/novel_audio.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/listen/follow_along.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/novel_paragraph.dart';

import '../../../support/narration_harness.dart';

class _Surface implements FollowSurface {
  _Surface({this.paged = false});
  final bool paged;
  double? top = 300;
  double height = 800;
  final List<({double delta, bool animate})> scrolls = [];
  final List<int> jumps = [];
  final List<int> pages = [];
  int page = 1;

  @override
  bool get isPaged => paged;
  @override
  double? paragraphTop(int index) => top;
  @override
  double get viewportHeight => height;
  @override
  void scrollBy(double delta, {required bool animate}) => scrolls.add((delta: delta, animate: animate));
  @override
  void jumpToParagraph(int index) => jumps.add(index);
  @override
  int? pageOfParagraph(int index) => index < 3 ? 1 : 2;
  @override
  int get currentPage => page;
  @override
  void showPage(int p) {
    pages.add(p);
    page = p;
  }
}

class _T implements Timer {
  _T(this.cb);
  final void Function() cb;
  bool cancelled = false;
  @override
  void cancel() => cancelled = true;
  @override
  bool get isActive => !cancelled;
  @override
  int get tick => 0;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('sweepRects', () {
    const boxes = [Rect.fromLTWH(0, 0, 100, 20), Rect.fromLTWH(0, 20, 60, 20)];
    test('sweeps line after line, left to right', () {
      expect(sweepRects(boxes, 0), isEmpty);
      expect(sweepRects(boxes, 0.5), [const Rect.fromLTWH(0, 0, 80, 20)]);
      final more = sweepRects(boxes, 0.75);
      expect(more, [const Rect.fromLTWH(0, 0, 100, 20), const Rect.fromLTWH(0, 20, 20, 20)]);
      expect(sweepRects(boxes, 1), boxes);
    });
  });

  group('listenDecorations', () {
    final audio = NovelAudio.fromJson(listenFixture('unit-audio'));
    const wash = Color(0x29F4D03F);
    const ink = Color(0xFFEEEEEE);
    final tint = [
      const NovelDecoration(start: 0, end: 15, fill: Color(0x1FFF0000), underline: Color(0xB3FF0000), speaker: 'Iris'),
      const NovelDecoration(start: 40, end: 50, fill: Color(0x1F00FF00), underline: Color(0xB300FF00), speaker: 'Dokja'),
    ];

    test('another paragraph is untouched', () {
      expect(listenDecorations(paragraph: 3, audio: audio, segment: 2, speaker: tint, wash: wash, ink: ink), tint);
      expect(listenDecorations(paragraph: 1, audio: audio, segment: -1, speaker: tint, wash: wash, ink: ink), tint);
    });

    test('the band and the word go over the sentence; overlapping tints lose their fill but keep the underline', () {
      final segment = audio.segments[2]; // paragraph 1
      final out = listenDecorations(
        paragraph: 1,
        audio: audio,
        segment: 2,
        speaker: tint,
        wash: wash,
        ink: ink,
        word: (paragraph: 1, start: segment.start, end: segment.start + 2),
        sweep: 0.4,
      );
      expect(out.length, 4);
      expect(out[0].fill, isNull);
      expect(out[0].underline, isNotNull);
      expect(out[1].fill, isNotNull, reason: 'a tint clear of the sentence keeps its background');
      final band = out[2];
      expect(band.fill, wash);
      expect((band.start, band.end), (segment.start, segment.end));
      expect(band.sweep, 0.4);
      expect(out[3].underline, ink);
      expect(out[3].fill, isNull);
    });
  });

  group('ListenFollower', () {
    late NarrationHarness h;
    late _Surface surface;
    late List<_T> timers;
    late ListenFollower follower;

    setUp(() async {
      h = await NarrationHarness.create();
      surface = _Surface();
      timers = [];
      await h.startAndSettle(listenTarget());
      follower = ListenFollower(
        surface: surface,
        narration: h.controller,
        reduced: () => false,
        timer: (d, cb) {
          expect(d, const Duration(milliseconds: 4000));
          return _T(cb)..also(timers.add);
        },
      );
    });
    tearDown(() {
      follower.dispose();
      h.dispose();
    });

    Future<void> at(int ms) async {
      h.player.tick(ms);
      await h.settle();
    }

    test('does nothing while the paragraph sits inside 20-70 percent', () async {
      surface.top = 400;
      await at(12000); // segment 1
      expect(surface.scrolls, isEmpty);
    });

    test('scrolls to the reading line when it leaves the band, and jumps when far', () async {
      surface.top = 760;
      await at(12000);
      expect(surface.scrolls.single.delta, closeTo(760 - 0.38 * 800, 1e-9));
      expect(surface.scrolls.single.animate, isTrue);
      surface.top = 4000;
      await at(22000);
      expect(surface.scrolls.last.animate, isFalse);
    });

    test('a paragraph that is not built jumps', () async {
      surface.top = null;
      await at(22000);
      expect(surface.jumps, isNotEmpty);
    });

    test('a manual scroll decouples, and 4000 ms idle re-follows', () async {
      surface.top = 760;
      follower.userMoved();
      expect(follower.decoupled.value, isTrue);
      await at(12000);
      expect(surface.scrolls, isEmpty);
      timers.last.cb();
      expect(follower.decoupled.value, isFalse);
      expect(surface.scrolls, hasLength(1));
    });

    test('Back to the voice re-follows at once', () async {
      follower.userMoved();
      follower.refollow();
      expect(follower.decoupled.value, isFalse);
    });

    test('paged mode turns to the active sentence page, and only when it differs', () async {
      final paged = _Surface(paged: true);
      final f = ListenFollower(surface: paged, narration: h.controller, reduced: () => false);
      await at(2000);
      await at(42000);
      expect(paged.pages, [2]);
      await at(43000);
      expect(paged.pages, [2]);
      f.dispose();
    });

    test('stale timings follow nothing', () async {
      await h.startAndSettle(listenTarget(stale: true));
      surface.top = 900;
      await at(12000);
      expect(surface.scrolls, isEmpty);
      follower.userMoved();
      expect(follower.decoupled.value, isFalse);
    });
  });
}

extension<T> on T {
  void also(void Function(T) f) => f(this);
}
