// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/novel_paragraph.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/novel_reader_screen.dart';

import 'novel_test_support.dart';

void main() {
  testWidgets('opens on the page: opener, paragraphs, no chrome', (tester) async {
    await pumpNovel(tester);
    await settleNovel(tester);
    expect(find.byType(CineNovelReader), findsOneWidget);
    expect(find.text('Down the Rabbit-Hole'), findsOneWidget);
    expect(find.byType(NovelParagraph), findsWidgets);
    expect(tester.takeException(), isNull);
    await disposeNovel(tester);
  });
}
