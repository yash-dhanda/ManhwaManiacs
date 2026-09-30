
import 'package:fake_async/fake_async.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/engine/page_analysis.dart';
import 'package:manhwamaniacs/features/reader/engine/page_tint.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_ambient.dart';
import 'package:manhwamaniacs/features/reader/engine/words.dart';

class _Img extends ImageProvider<_Img> {
  const _Img(this.n);
  final int n;
  @override
  Future<_Img> obtainKey(ImageConfiguration c) async => this;
  @override
  ImageStreamCompleter loadImage(_Img key, ImageDecoderCallback decode) => throw UnimplementedError();
}

void main() {
  test('tint from a sample; greys keep, sixth switches to cover; manifest tint first', () {
    fakeAsync((async) {
      final seeds = <String?>['#FF0000', null, null, null, null, null, null];
      var i = 0;
      final a = ReaderAmbient(analyse: ({tintPage, panelPage, required direction}) async => AnalysisResult(seed: seeds[i++]))
        ..resolver = ((c, p) => _Img(p))
        ..sampleInterval = const Duration(milliseconds: 600)
        ..pageCount = 20;
      a.seed('c1', tints: {1: '#00ff00'});
      a.onPage('c1', 1);
      expect(a.pageTint.value, const PageTintSource.page('#00FF00'));
      for (var p = 2; p <= 8; p++) {
        a.onPage('c1', p);
        async.elapse(const Duration(milliseconds: 650));
      }
      expect(a.pageTint.value, PageTintSource.cover);
      a.dispose();
    });
  });

  test('a 10 s continuous scroll makes at most 17 analysis calls; panels ride with the tint call', () {
    fakeAsync((async) {
      final calls = <(bool, bool)>[];
      final a = ReaderAmbient(analyse: ({tintPage, panelPage, required direction}) async {
        calls.add((tintPage != null, panelPage != null));
        return const AnalysisResult(seed: '#112233', panels: [Rect.fromLTWH(0, 0, 1, 0.5)]);
      },)
        ..resolver = ((c, p) => _Img(p))
        ..panelsWanted = true
        ..pageCount = 400;
      var page = 1;
      for (var ms = 0; ms < 10000; ms += 100) {
        a.onPage('c1', page++);
        async.elapse(const Duration(milliseconds: 100));
      }
      expect(a.analysisCalls, lessThanOrEqualTo(17));
      expect(calls.every((c) => c.$1 && c.$2), isTrue);
      final r = a.takeReport('c1');
      expect(r.tints, isNotEmpty);
      expect(r.panels, isNotEmpty);
      expect(a.takeReport('c1').isEmpty, isTrue);
      a.dispose();
    });
  });

  test('seeded panels, none, and wordsInPanel', () {
    final a = ReaderAmbient()..pageCount = 5;
    a.seed('c1', panels: {1: [const Rect.fromLTWH(0, 0, 1, 0.5), const Rect.fromLTWH(0, 0.5, 1, 0.5)], 2: <Rect>[]});
    a.onPage('c1', 1);
    expect(a.panels.value[1], isA<PanelsFound>());
    expect(a.panels.value[2], isA<PanelsNone>());
    a.setOcr({1: [const OcrWordBox(Rect.fromLTWH(0.1, 0.1, 0.2, 0.1), 'one two three'), const OcrWordBox(Rect.fromLTWH(0.1, 0.7, 0.2, 0.1), 'a b')]});
    expect(a.wordsInPanel(1, 0), 3);
    expect(a.wordsInPanel(1, 1), 2);
    expect(a.wordsInPanel(3, 0), isNull);
    a.dispose();
  });

  test('words on screen counted every 250 ms', () {
    fakeAsync((async) {
      final a = ReaderAmbient()..setOcr({1: [const OcrWordBox(Rect.fromLTWH(0.4, 0.4, 0.2, 0.1), 'x y z w')]});
      a.trackWords(enabled: true, toViewport: (p, f) => Offset(f.dx * 390, f.dy * 844), viewport: () => const Rect.fromLTWH(0, 0, 390, 844));
      async.elapse(const Duration(milliseconds: 300));
      expect(a.wordsOnScreen.value, 4);
      a.dispose();
    });
  });
}
