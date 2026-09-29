import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/ocr/models/ocr_search_result.dart';
import 'package:manhwamaniacs/features/ocr/models/page_text.dart';
import 'package:manhwamaniacs/features/ocr/providers/dialogue_jump_provider.dart';
import 'package:manhwamaniacs/features/ocr/utils/engine_label.dart';
import 'package:manhwamaniacs/features/ocr/utils/still_crop.dart';

void main() {
  group('stillCropWindow', () {
    const aspect = 0.7;
    test('centred box', () {
      final r =
          stillCropWindow(const OcrBox(x: 0.4, y: 0.4, w: 0.2, h: 0.1), aspect);
      expect(r.width, closeTo(0.2 / 0.6, 1e-9));
      expect(r.height, closeTo(r.width * 9 / 16 * aspect, 1e-9));
      expect(r.center.dx, closeTo(0.5, 1e-9));
      expect(r.center.dy, closeTo(0.45, 1e-9));
    });
    test('edges are clamped inside the page', () {
      for (final b in [
        const OcrBox(x: 0, y: 0, w: 0.2, h: 0.1),
        const OcrBox(x: 0.8, y: 0.9, w: 0.2, h: 0.1),
      ]) {
        final r = stillCropWindow(b, aspect);
        expect(r.left, greaterThanOrEqualTo(0));
        expect(r.top, greaterThanOrEqualTo(0));
        expect(r.right, lessThanOrEqualTo(1 + 1e-9));
        expect(r.bottom, lessThanOrEqualTo(1 + 1e-9));
      }
    });
    test('null box is the top 16:9', () {
      expect(stillCropWindow(null, aspect),
          const Rect.fromLTWH(0, 0, 1, 9 / 16 * aspect),);
    });
    test('very wide page caps the height then the width', () {
      final r =
          stillCropWindow(const OcrBox(x: 0.1, y: 0.1, w: 0.5, h: 0.5), 4);
      expect(r.height, 1);
      expect(r.width, closeTo(1 / (9 / 16 * 4), 1e-9));
    });
    test('a huge box fills the page width', () {
      expect(
          stillCropWindow(const OcrBox(x: 0, y: 0, w: 1, h: 1), 0.7).width, 1,);
    });
  });

  test('engineLabel', () {
    expect(engineLabel('Apple_Vision'), 'VISION');
    expect(engineLabel('vision'), 'VISION');
    expect(engineLabel('ml-kit'), 'ML KIT');
    expect(engineLabel('tesseract'), 'TESSERACT');
    expect(engineLabel(null), '—');
  });

  test('dialogueJump take is one-shot and identity-matched', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final n = c.read(dialogueJumpProvider.notifier);
    n.set(const DialogueJump(
        sourceId: 's', seriesKey: 'k', chapterKey: 'c', q: 'x', page: 3,),);
    expect(n.take('s', 'k', 'other'), isNull);
    expect(n.take('s', 'k', 'c')?.page, 3);
    expect(n.take('s', 'k', 'c'), isNull);
  });

  test('findMatchPage folds diacritics and needs every term', () {
    const pages = [
      PageText(page: 1, text: 'nothing here'),
      PageText(page: 2, text: 'El niño dijo: ŁÓDŹ está lejos'),
      PageText(page: 3, text: 'niño lejos'),
    ];
    expect(findMatchPage(pages, 'nino lodz'), 2);
    expect(findMatchPage(pages, 'NIÑO'), 2);
    expect(findMatchPage(pages, 'niño missing'), isNull);
    expect(findMatchPage(pages, '  '), isNull);
  });
}
