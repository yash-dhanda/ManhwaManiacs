import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/share/press_run.dart';
import 'package:manhwamaniacs/skins/cinematic/share/share_card.dart';
import 'package:manhwamaniacs/skins/cinematic/share/share_card_model.dart';
import 'package:share_plus/share_plus.dart';

import '../../../screenshots/support/shot_harness.dart';
import '../../../support/numbers_fixtures.dart';
import '../support/cine_harness.dart';

int _u32(Uint8List b, int o) =>
    (b[o] << 24) | (b[o + 1] << 16) | (b[o + 2] << 8) | b[o + 3];

({int w, int h}) pngSize(Uint8List b) {
  expect(b.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
  return (w: _u32(b, 16), h: _u32(b, 20));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);

  Widget host(WidgetBuilder builder) =>
      Scaffold(body: Builder(builder: builder));

  testWidgets(
      'every template captures to a PNG of 1080 x 1920 (Story) and 1080 x 1350 (Post)',
      (tester) async {
    final env = CineTestEnv();
    late BuildContext ctx;
    await pumpCine(
      tester,
      env,
      router: cineRouter(
        initial: '/',
        home: host((c) {
          ctx = c;
          return const SizedBox();
        }),
      ),
    );
    final templates =
        shareTemplates(ShareInput.annual(annualFixture(), 'Yash'));
    expect(templates, hasLength(6));
    for (final t in templates) {
      for (final f in ShareFormat.values) {
        final bytes = await captureCard(tester, ctx, t, f);
        final s = pngSize(bytes);
        expect(s.w, 1080, reason: '${t.id} ${f.name}');
        expect(s.h, f == ShareFormat.story ? 1920 : 1350,
            reason: '${t.id} ${f.name}',);
      }
    }
  });

  testWidgets(
      'a card draws only shareable fields: the mature title never appears',
      (tester) async {
    final env = CineTestEnv();
    late BuildContext ctx;
    await pumpCine(
      tester,
      env,
      router: cineRouter(
        initial: '/',
        home: host((c) {
          ctx = c;
          return const SizedBox();
        }),
      ),
    );
    final j = annualJson();
    (j['top_series'] as List).insert(0, {
      'source_id': 'x',
      'series_key': 'm',
      'title': 'MATURE SECRET',
      'cover_url': '/c',
      'seconds_read': 99999,
      'chapters_read': 999,
    });
    final input = ShareInput.annual(annualFromJson(j), 'Yash');
    for (final t in shareTemplates(input)) {
      await captureCard(tester, ctx, t, ShareFormat.story);
      expect(kDebugMode, isTrue);
      expect(debugShareCardTexts.join('|'), isNot(contains('MATURE SECRET')),
          reason: '${t.id}',);
      expect(debugShareCardTexts, contains('Yash'));
      expect(debugShareCardTexts, contains('manhwamaniacs'));
    }
    final no1 = shareTemplates(input).firstWhere((t) => t.id == ShareId.no1);
    await captureCard(tester, ctx, no1, ShareFormat.post);
    expect(debugShareCardTexts.join('|'), contains('Solo Leveling'));
  });

  testWidgets('a failing cover leaves the dark band and the card still renders',
      (tester) async {
    final env = CineTestEnv();
    late BuildContext ctx;
    await pumpCine(
      tester,
      env,
      router: cineRouter(
        initial: '/',
        home: host((c) {
          ctx = c;
          return const SizedBox();
        }),
      ),
    );
    final t = shareTemplates(
            ShareInput.annual(annualFixture(withShareable: false), 'Yash'),)
        .first;
    final bytes =
        await captureCard(tester, ctx, t, ShareFormat.story);
    expect(pngSize(bytes).h, 1920);
  });

  group('press run sheet', () {
    void sheetTest(String name, Future<void> Function(WidgetTester) body) => testWidgets(name, (tester) async {
          try {
            await body(tester);
          } finally {
            debugDefaultTargetPlatformOverride = null;
          }
        });

    Future<CineTestEnv> open(WidgetTester tester,
        {bool canSave = true,
        TargetPlatform platform = TargetPlatform.android,
        ShareInput? input,
        FakeNumbersRepo? repo,}) async {
      final env = CineTestEnv(repo: repo)..media.can = canSave;
      debugDefaultTargetPlatformOverride = platform;
      await pumpCine(
        tester,
        env,
        platform: platform,
        extra: [
          cardRendererProvider
              .overrideWithValue((context, t, f) async => kTinyPng),
        ],
        router: cineRouter(
            initial: '/',
            home: host((c) => Center(
                child: TextButton(
                    onPressed: () => showPressRun(
                        c, input ?? ShareInput.annual(annualFixture(), 'Yash'),),
                    child: const Text('OPEN'),),),),),
      );
      await tester.tap(find.text('OPEN'));
      await tester.pump();
      await pumpMs(tester, 700);
      return env;
    }

    sheetTest(
        'the slug line lists the available templates; the format control and actions show',
        (tester) async {
      await open(tester);
      for (final l in [
        'TIME',
        'CHAPTERS',
        'NO. 1',
        'GENRES',
        'STREAK',
        'CLOCK',
        'STORY',
        'POST',
        'Share',
        'Save image',
      ]) {
        expect(find.text(l), findsOneWidget, reason: l);
      }
      expect(find.text('PRESS RUN'), findsOneWidget);
      expect(find.byType(Image), findsWidgets);
    });

    sheetTest('a fixture with an empty shareable.topSeries has no No. 1',
        (tester) async {
      final j = annualJson();
      (j['shareable'] as Map)['top_series'] = <Object?>[];
      await open(tester, input: ShareInput.annual(annualFromJson(j), 'Yash'));
      expect(find.text('NO. 1'), findsNothing);
      expect(find.text('TIME'), findsOneWidget);
    });

    sheetTest(
        'Share hands the PNG to share_plus with the spec file name and fires the press-run haptic',
        (tester) async {
      final env = await open(tester);
      await tester.tap(find.text('Share'));
      await pumpMs(tester, 300);
      expect(env.share.shared, hasLength(1));
      final params = env.share.shared.single;
      expect(params.fileNameOverrides, ['manhwamaniacs-time-story.png']);
      expect(params.files!.single.mimeType, 'image/png');
      expect(env.haptics.events.map((e) => e.name), contains('shareExport'));
      await tester.tap(find.text('NO. 1'));
      await pumpMs(tester, 300);
      await tester.tap(find.text('POST'));
      await pumpMs(tester, 300);
      await tester.tap(find.text('Share'));
      await pumpMs(tester, 300);
      expect(env.share.shared.last.fileNameOverrides, ['manhwamaniacs-no1-post.png']);
    });

    sheetTest('a dismissed share is silent', (tester) async {
      final env = await open(tester);
      env.share.status = ShareResultStatus.dismissed;
      await tester.tap(find.text('Share'));
      await pumpMs(tester, 300);
      expect(find.textContaining('Saved the card'), findsNothing);
      expect(find.textContaining("Couldn't"), findsNothing);
      expect(env.media.saved, isEmpty);
      expect(find.text('Share'), findsOneWidget); // the sheet stays open
    });

    sheetTest('an unavailable share (or an exception) saves the card instead',
        (tester) async {
      final env = await open(tester);
      env.share.status = ShareResultStatus.unavailable;
      await tester.tap(find.text('Share'));
      await pumpMs(tester, 300);
      expect(find.text('Saved the card instead.'), findsOneWidget);
      expect(env.media.saved, ['manhwamaniacs-time-story.png']);
      env.share.status = ShareResultStatus.success;
      env.share.throwOnShare = true;
      await tester.pump(const Duration(seconds: 5));
      await tester.tap(find.text('Share'));
      await pumpMs(tester, 300);
      expect(env.media.saved, hasLength(2));
    });

    sheetTest('Android 10+: Save image writes to Pictures and says so',
        (tester) async {
      final env = await open(tester);
      await tester.tap(find.text('Save image'));
      await pumpMs(tester, 300);
      expect(env.media.saved, ['manhwamaniacs-time-story.png']);
      expect(
          find.text('Card saved to Pictures › ManhwaManiacs.'), findsOneWidget,);
      expect(env.share.shared, isEmpty);
    });

    sheetTest('Save image is absent when canSaveImage is false (Android 7-9)',
        (tester) async {
      await open(tester, canSave: false);
      expect(find.text('Save image'), findsNothing);
      expect(find.text('Share'), findsOneWidget);
    });

    sheetTest(
        'iOS: Save image opens the share sheet and confirms only on SaveToCameraRoll',
        (tester) async {
      final env = await open(tester, platform: TargetPlatform.iOS);
      env.share.raw = 'com.apple.UIKit.activity.SaveToCameraRoll';
      await tester.tap(find.text('Save image'));
      await pumpMs(tester, 300);
      expect(env.share.shared, hasLength(1));
      expect(find.text('Card saved.'), findsOneWidget);
    });

    sheetTest('a render failure keeps the last good card and toasts',
        (tester) async {
      final env = CineTestEnv();
      var calls = 0;
      await pumpCine(
        tester,
        env,
        extra: [
          cardRendererProvider.overrideWithValue((context, t, f) async {
            calls++;
            if (calls > 1) throw StateError('boom');
            return kTinyPng;
          }),
        ],
        router: cineRouter(
            initial: '/',
            home: host((c) => Center(
                child: TextButton(
                    onPressed: () => showPressRun(
                        c, ShareInput.annual(annualFixture(), 'Yash'),),
                    child: const Text('OPEN'),),),),),
      );
      await tester.tap(find.text('OPEN'));
      await pumpMs(tester, 700);
      await tester.tap(find.text('CHAPTERS'));
      await pumpMs(tester, 400);
      expect(find.text("Couldn't make the card. Try again."), findsOneWidget);
      expect(find.byType(Image), findsWidgets);
    });

    sheetTest('hit targets on both platforms', (tester) async {
      for (final p in [TargetPlatform.iOS, TargetPlatform.android]) {
        await open(tester, platform: p);
        final min = p == TargetPlatform.iOS ? 44.0 : 48.0;
        for (final b in find.byType(CineButton).evaluate()) {
          final size = tester.getSize(find.byWidget(b.widget));
          expect(size.height, greaterThanOrEqualTo(min));
        }
        await tester.tap(find.text('Done'));
        await pumpMs(tester, 500);
      }
    });
  });
}
