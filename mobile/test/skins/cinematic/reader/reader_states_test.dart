import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_signals_provider.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_prefs_migration.dart';

import '../../../screenshots/support/shot_network.dart';
import 'reader_test_support.dart';

Future<void> _toEnd(WidgetTester tester) async {
  // Past the last page, onto the footer (credits, bands, end notices).
  for (var i = 0; i < 3; i++) {
    final position = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    position.jumpTo(position.maxScrollExtent);
    await settleReader(tester, ms: 500);
  }
}

void main() {
  setUpAll(setUpShotCoverCache);

  testWidgets('a page that fails shows PAGE n DIDNT LOAD with Retry', (tester) async {
    await pumpReader(tester, pages: 3);
    await pumpUntilCoversLoad(tester, rounds: 12);
    await settleReader(tester, ms: 300);
    expect(find.textContaining('PAGE 1 DIDN', findRichText: true), findsOneWidget);
    expect(find.text('Retry', findRichText: true), findsWidgets);
    await disposeReader(tester);
  });

  testWidgets('loading: the running head reads LOADING and three plates show', (tester) async {
    final gate = Completer<void>();
    await pumpReader(tester, holds: {'c2': gate.future});
    await settleReader(tester, ms: 600);
    expect(find.textContaining('LOADING', findRichText: true), findsOneWidget);
    expect(find.byType(AspectRatio), findsWidgets);
    gate.complete();
    await settleReader(tester, ms: 600);
    await disposeReader(tester);
  });

  testWidgets('next chapter loading: CH 3 IS ON ITS WAY, and the slow caption after 8 s', (tester) async {
    final gate = Completer<void>();
    await pumpReader(tester, holds: {'c3': gate.future});
    await settleReader(tester, ms: 600);
    await _toEnd(tester);
    await settleReader(tester, ms: 500);
    expect(find.textContaining('IS ON ITS WAY', findRichText: true), findsOneWidget);
    expect(find.text('This source can take a while.', findRichText: true), findsNothing);
    await settleReader(tester, ms: 8200);
    expect(find.text('This source can take a while.', findRichText: true), findsOneWidget);
    gate.complete();
    await settleReader(tester, ms: 600);
    await disposeReader(tester);
  });

  testWidgets('rate limited: SLOW DOWN with a live countdown', (tester) async {
    await pumpReader(tester, failing: {'c3': const ApiError(statusCode: 429, code: 'rate_limited', message: 'slow', retryAfter: Duration(seconds: 12))});
    await settleReader(tester, ms: 600);
    await _toEnd(tester);
    await settleReader(tester, ms: 500);
    expect(find.textContaining('SLOW DOWN', findRichText: true), findsOneWidget);
    expect(find.textContaining('Retrying in', findRichText: true), findsOneWidget);
    final before = tester.widget<Text>(find.textContaining('Retrying in')).data;
    await settleReader(tester, ms: 3000);
    final after = tester.widget<Text>(find.textContaining('Retrying in')).data;
    expect(after, isNot(before), reason: 'the countdown ticks');
    await disposeReader(tester);
  });

  test('a 429 with no Retry-After waits 10 s, anything else is not a rate limit', () {
    expect(rateLimitWait(const ApiError(statusCode: 429, code: 'x', message: 'x')), const Duration(seconds: 10));
    expect(rateLimitWait(const ApiError(statusCode: 429, code: 'x', message: 'x', retryAfter: Duration(seconds: 3))), const Duration(seconds: 3));
    expect(rateLimitWait(const ApiError(statusCode: 500, code: 'x', message: 'x')), isNull);
    expect(rateLimitWait(const NetworkError(message: 'x')), isNull);
  });

  testWidgets('next chapter failed: the notice with Try again and the on-its-own exit', (tester) async {
    await pumpReader(tester, failing: {'c3': const NetworkError(message: 'x')});
    await settleReader(tester, ms: 600);
    await _toEnd(tester);
    await settleReader(tester, ms: 500);
    expect(find.textContaining('Chapter 3 didn', findRichText: true), findsOneWidget);
    expect(find.text('Try again', findRichText: true), findsOneWidget);
    expect(find.text('Open it on its own →', findRichText: true), findsOneWidget);
    await disposeReader(tester);
  });

  testWidgets('caught up on an ongoing series', (tester) async {
    await pumpReader(tester, chapterKey: 'cx');
    await settleReader(tester, ms: 600);
    await _toEnd(tester);
    expect(find.text('CAUGHT UP', findRichText: true), findsOneWidget);
    expect(find.textContaining('everything so far', findRichText: true), findsOneWidget);
    expect(find.text('Notify me', findRichText: true), findsWidgets);
    expect(find.text('Mark as done', findRichText: true), findsNothing);
    await disposeReader(tester);
  });

  testWidgets('the end of a completed series: You finished, Mark as done, no Notify me', (tester) async {
    await pumpReader(tester, chapterKey: 'cx', status: 'Completed');
    await settleReader(tester, ms: 600);
    await _toEnd(tester);
    expect(find.text('THE END', findRichText: true), findsOneWidget);
    expect(find.textContaining('You finished', findRichText: true), findsOneWidget);
    expect(find.text('Mark as done', findRichText: true), findsOneWidget);
    expect(find.text('Notify me', findRichText: true), findsNothing);
    await disposeReader(tester);
  });

  testWidgets('full credits with the Coming up card when auto-next is off; compact when it is on', (tester) async {
    final hold = Completer<void>();
    await pumpReader(tester, chapterKey: 'c3', holds: {'cx': hold.future});
    await settleReader(tester, ms: 600);
    await _toEnd(tester);
    hold.complete();
    expect(find.textContaining('End of chapter 3', findRichText: true), findsOneWidget, reason: 'compact');
    expect(find.textContaining('SERIES', findRichText: true), findsNothing);
    await disposeReader(tester);

    final hold2 = Completer<void>();
    await pumpReader(tester, chapterKey: 'c3', holds: {'cx': hold2.future}, prefsValues: {kReaderPrefsSeedKey: jsonEncode({'autoNextChapter': false})});
    await settleReader(tester, ms: 600);
    await _toEnd(tester);
    hold2.complete();
    expect(find.textContaining('SERIES', findRichText: true), findsOneWidget, reason: 'full credits');
    expect(find.textContaining('COMING UP', findRichText: true), findsOneWidget);
    expect(find.textContaining('PULL TO CONTINUE', findRichText: true), findsOneWidget);
    await disposeReader(tester);
  });
}
