import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/reader/utils/page_layout.dart';
import 'package:manhwamaniacs/features/settings/models/reader_defaults.dart';

void main() {
  group('page_layout', () {
    test('resolveInitialScrollTop prefers saved scroll', () {
      expect(
        resolveInitialScrollTop(
          savedScroll: 120,
          initialPage: 5,
          pageCount: 10,
          estimatedOffsetToPage: 80,
        ),
        120,
      );
    });

    test('resolveInitialScrollTop drops a saved scroll that is off the requested page', () {
      expect(
        resolveInitialScrollTop(
          savedScroll: 120,
          initialPage: 20,
          pageCount: 30,
          estimatedOffsetToPage: 4000,
          savedScrollWindow: (start: 3200, end: 4200),
        ),
        4000,
      );
      expect(
        resolveInitialScrollTop(
          savedScroll: 4100,
          initialPage: 20,
          pageCount: 30,
          estimatedOffsetToPage: 4000,
          savedScrollWindow: (start: 3200, end: 4200),
        ),
        4100,
      );
    });

    test('readerFitModeToBoxFit maps persisted fit modes', () {
      expect(readerFitModeToBoxFit(ReaderFitMode.width), BoxFit.fitWidth);
      expect(readerFitModeToBoxFit(ReaderFitMode.height), BoxFit.fitHeight);
      expect(readerFitModeToBoxFit(ReaderFitMode.screen), BoxFit.contain);
    });

    test('isAtReadingEnd respects horizontal direction', () {
      expect(
        isAtReadingEnd(
          scrollOffset: 900,
          viewport: 100,
          maxScroll: 1000,
          direction: ReadingDirection.leftToRight,
        ),
        isTrue,
      );
      expect(
        isAtReadingEnd(
          scrollOffset: 0,
          viewport: 100,
          maxScroll: 1000,
          direction: ReadingDirection.rightToLeft,
        ),
        isTrue,
      );
    });
  });
}
