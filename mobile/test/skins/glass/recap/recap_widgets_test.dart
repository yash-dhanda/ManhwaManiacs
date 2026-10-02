import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/network/network_connectivity.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/novels/models/novel_cast.dart';
import 'package:manhwamaniacs/features/recap/background_recaps.dart';
import 'package:manhwamaniacs/features/recap/recap_cache.dart';
import 'package:manhwamaniacs/features/recap/recap_deck.dart';
import 'package:manhwamaniacs/features/recap/recap_setting.dart';
import 'package:manhwamaniacs/features/sources/models/source_chapter_progress.dart';
import 'package:manhwamaniacs/features/sources/providers/source_progress_provider.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/parts/recap/continue_series.dart';
import 'package:manhwamaniacs/skins/glass/parts/recap/how_it_works_sheet.dart';
import 'package:manhwamaniacs/skins/glass/parts/recap/offer_sheet.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/switch.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/speaker_bands.dart' show speakerHue;
import 'package:manhwamaniacs/skins/glass/screens/recap/recap_deck.dart';
import 'package:manhwamaniacs/skins/glass/screens/recap/recap_footer.dart';
import 'package:manhwamaniacs/skins/glass/screens/recap/recap_sheet.dart';

import '../../../screenshots/support/shot_harness.dart';
import '../primitives/support.dart' show pumpFor;
import '../shell/shell_rig.dart';
import 'recap_rig.dart';

Future<ShellRig> pumpRecap(WidgetTester t, RecapAdapter a, {String at = '/recap/s/k?to=c2', List<Override> extra = const []}) async {
  final rig = await pumpGlassShell(t, start: at, settle: false, extra: [recapOverride(a), networkConnectivityProvider.overrideWithValue(_Online()), clockProvider.overrideWithValue(() => DateTime.utc(2026, 10)), ...extra]);
  for (var i = 0; i < 10; i++) {
    await t.pump(const Duration(milliseconds: 200));
  }
  return rig;
}

class _Online implements NetworkConnectivity {
  @override
  Future<bool> isOnWifi() async => true;
  @override
  Future<bool> isOnline() async => true;
}

void main() {
  setUpAll(loadAppFonts);

  test('a Continue target reads its reader off the source, whichever row built it', () {
    const scope = ContentModeScope(mode: ContentMode.novel, index: {'n': ContentMode.novel, 'm': ContentMode.manga}, novelsEnabled: true);
    expect(const HomeContinueTarget(sourceId: 'n', seriesKey: 'k', chapterKey: 'c1').ofKind(scope).readerLocation, startsWith('/novel'));
    expect(const HomeContinueTarget(sourceId: 'm', seriesKey: 'k', chapterKey: 'c1').ofKind(scope).readerLocation, startsWith('/reader'));
  });

  testWidgets('a recap opens up to the continue chapter, not the last finished one', (t) async {
    final rig = await pumpGlassShell(t, settle: false);
    await t.pump(const Duration(milliseconds: 600));
    final ref = t.element(find.byWidgetPredicate((w) => w is ConsumerWidget || w is ConsumerStatefulWidget).first) as WidgetRef;
    unawaited(openRecapFor(ref, const HomeContinueTarget(sourceId: 's', seriesKey: 'k', chapterKey: 'c11', recap: RecapAvailability(available: true, toKey: 'c10'))));
    await t.pump(const Duration(milliseconds: 300));
    final cfg = rig.router.routerDelegate.currentConfiguration;
    final last = cfg.last;
    expect((last is ImperativeRouteMatch ? last.matches.uri : cfg.uri).queryParameters['to'], 'c11');
    await pumpFor(t, 1200);
  });

  test('the deck maths: depth 0.94 and 0.89, dim 40 and 60 percent, the swipe threshold', () {
    expect(deckScale(0), 1);
    expect(deckScale(1), closeTo(0.94, 1e-9));
    expect(deckScale(2), closeTo(0.89, 1e-9));
    expect(deckDim(1), closeTo(0.4, 1e-9));
    expect(deckDim(2), closeTo(0.6, 1e-9));
    expect(swipeUpAdvances(-81, 0), isTrue);
    expect(swipeUpAdvances(-20, -900), isTrue);
    expect(swipeUpAdvances(-20, -300), isFalse);
  });

  test('the footer quotes the model and what it covers, and a cached one its age', () {
    final done = DeckDone.fromJson({'range': [120, 141], 'covered_through': 141, 'model': 'm1'});
    final now = DateTime.utc(2026, 10, 3);
    expect(footerText(done, now: now), 'Written by m1 from chapters 120–141. Covers up to chapter 141. Nothing after where you stopped.');
    expect(footerText(done, savedAt: now.subtract(const Duration(days: 2)), now: now), endsWith('Written 2 d ago.'));
  });

  testWidgets('the deck streams in, four cards, the footer quotes the model; right, space and swipe up lift the front card', (t) async {
    final a = RecapAdapter(chunks: deckEvents());
    await pumpRecap(t, a);
    expect(a.calls.single.queryParameters, containsPair('shape', 'deck'));
    expect(a.calls.single.queryParameters, containsPair('scope', 'series'));
    expect(find.text('Where you left off'), findsOneWidget);
    expect(find.textContaining('Written by test-model from chapters 120–141. Covers up to chapter 141.'), findsOneWidget);
    final s = t.state<RecapDeckViewState>(find.byType(RecapDeckView));
    expect(s.index, 0);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await pumpFor(t, 1500);
    expect(s.index, 1);
    await t.sendKeyEvent(LogicalKeyboardKey.space);
    await pumpFor(t, 1500);
    expect(s.index, 2);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await pumpFor(t, 1500);
    expect(s.index, 1);
    await t.fling(find.byType(RecapDeckView), const Offset(0, -300), 1200);
    await pumpFor(t, 1500);
    expect(s.index, 2);
  });

  testWidgets('with a screen reader on the four cards are one list with four headings', (t) async {
    final a = RecapAdapter(chunks: deckEvents());
    final h = t.ensureSemantics();
    final rig = await pumpRecap(t, a);
    rig.container.read(glassAssistiveProvider.notifier).state = true;
    await pumpFor(t, 400);
    for (final title in ['Where you left off', 'What happened', "Who's who", 'Open threads']) {
      expect(find.text(title), findsOneWidget);
    }
    h.dispose();
  });

  testWidgets('no dialogue reads as No recap yet with Continue and How it works', (t) async {
    await pumpRecap(t, RecapAdapter(json: {'available': false, 'reason': 'no_dialogue'}));
    expect(find.text('No recap yet'), findsOneWidget);
    expect(find.text('Continue'), findsWidgets);
    expect(find.text('How it works'), findsOneWidget);
  });

  testWidgets('AI unavailable says the long line and offers Continue', (t) async {
    await pumpRecap(t, RecapAdapter(json: {'available': false, 'reason': 'not_configured'}));
    expect(find.textContaining("AI isn't set up on this server"), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('a cached recap opens at once without a request and says how old it is', (t) async {
    final a = RecapAdapter(chunks: const []);
    final rig = await pumpGlassShell(t, settle: false, extra: [recapOverride(a), clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 3)), networkConnectivityProvider.overrideWithValue(_Online())]);
    final done = DeckDone.fromJson({'range': [1, 3], 'covered_through': 3, 'model': 'm'});
    final deck = DeckState(sections: [const DeckSection(kind: 'left_off', title: 'Where you left off')], done: done);
    await rig.container.read(recapCacheProvider).save('s:k:c2:series', deck);
    rig.router.go('/recap/s/k?to=c2');
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }
    expect(a.calls, isEmpty);
    expect(find.textContaining('Nothing after where you stopped.'), findsOneWidget);
  });

  testWidgets('closing mid-stream hands it to keep-alive; when it lands the recap.ready haptic fires and a profile switch would cancel it', (t) async {
    final ctl = StreamController<List<int>>();
    final a = RecapAdapter(controller: ctl);
    final rig = await pumpRecap(t, a);
    for (final e in deckEvents(withDone: false)) {
      ctl.add(utf8.encode(e));
    }
    await pumpFor(t, 300);
    rig.router.go('/');
    await pumpFor(t, 800);
    final bg = rig.container.read(backgroundRecapsProvider);
    expect(bg.length, 1);
    final ready = <RecapReady>[];
    bg.readyStream.listen(ready.add);
    ctl.add(utf8.encode(deckEvents().last));
    await pumpFor(t, 300);
    expect(ready.single.title, isNotEmpty);
    expect(GlassHaptics.debugLog.map((e) => e.event.toString()).join(), contains('recapReady'));
    await ctl.close();
  });

  testWidgets('the recap offer opens on the current page instead of pushing another Home', (t) async {
    final rig = await pumpGlassShell(t, settle: false, extra: [clockProvider.overrideWithValue(() => DateTime(2026, 10, 1, 12))]);
    await t.pump(const Duration(milliseconds: 600));
    registerOfferSheet();
    final el = t.element(find.byWidgetPredicate((w) => w is ConsumerWidget || w is ConsumerStatefulWidget).first);
    unawaited(continueSeries(el, el as WidgetRef, HomeContinueTarget(sourceId: 's', seriesKey: 'k', chapterKey: 'c2', recap: const RecapAvailability(available: true, toKey: 'c1'), lastReadAt: DateTime(2026, 9, 10, 12)), Rect.zero));
    await t.pump(const Duration(milliseconds: 300));
    final cfg = rig.router.routerDelegate.currentConfiguration;
    expect(cfg.last, isNot(isA<ImperativeRouteMatch>()));
    expect(cfg.uri.queryParameters['sheet'], 'offer');
    await pumpFor(t, 1200);
  });

  testWidgets('the offer asks, Show recap opens the deck, the switch writes skipSeries', (t) async {
    final rig = await pumpGlassShell(t, settle: false, extra: [clockProvider.overrideWithValue(() => DateTime(2026, 10, 1, 12))]);
    await t.pump(const Duration(milliseconds: 600));
    final target = HomeContinueTarget(sourceId: 's', seriesKey: 'k', chapterKey: 'c2', recap: const RecapAvailability(available: true, toKey: 'c2'), lastReadAt: DateTime(2026, 9, 10, 12));
    rig.container.read(offerTargetProvider.notifier).state = target;
    var continued = 0;
    rig.container.read(offerContinueProvider.notifier).state = () => continued++;
    registerOfferSheet();
    rig.router.go('/?sheet=offer');
    await pumpFor(t, 1200);
    expect(find.text("It's been 3 weeks"), findsOneWidget);
    expect(find.text('Want a quick recap of what happened?'), findsOneWidget);
    await t.tap(find.byType(GlassSwitch));
    await pumpFor(t, 400);
    await t.tap(find.text('Just continue'));
    await pumpFor(t, 600);
    expect(rig.container.read(recapSettingProvider).skipSeries, contains('s:k'));
    expect(continued, 1);
  });

  testWidgets('How it works shows the phone copy and Open downloads', (t) async {
    final rig = await pumpGlassShell(t, settle: false);
    await t.pump(const Duration(milliseconds: 600));
    registerHowItWorksSheet();
    rig.router.go('/?sheet=how-it-works');
    await pumpFor(t, 1200);
    expect(find.text('Download the chapter'), findsOneWidget);
    expect(find.text('Extract text'), findsOneWidget);
    expect(find.text('Recaps and dialogue search use it'), findsOneWidget);
    expect(find.text('Open downloads'), findsOneWidget);
  });

  test('Continue names the chapter and the saved page when each is known', () {
    expect(continueLabel('142', 12), 'Continue · Ch 142, p. 12');
    expect(continueLabel('142', null), 'Continue · Ch 142');
    expect(continueLabel('', 12), 'Continue · p. 12');
    expect(continueLabel('', null), 'Continue');
  });

  test("Who's who takes the continue chapter's speaker hue by name, any case; others stay g700", () {
    const a = NovelAttribution(attributed: true, narrator: null, narratorVoiceId: null, cast: [
      NovelCastMember(name: 'Arthur', gender: 'male', voiceId: null),
      NovelCastMember(name: 'Tessia', gender: 'female', voiceId: null),
    ],);
    final hue = recapCastHue(a);
    expect(hue('arthur'), speakerHue(1));
    expect(hue('TESSIA'), speakerHue(2));
    expect(hue('Sylvie'), isNull);
    expect(recapCastHue(NovelAttribution.none)('Arthur'), isNull);
  });

  testWidgets('Continue on the deck restores the saved page of the continue chapter', (t) async {
    final a = RecapAdapter(chunks: deckEvents());
    final rig = await pumpRecap(t, a, at: '/', extra: [
      sourceSeriesProgressProvider.overrideWith((ref, s) => {
            'c2': SourceChapterProgress(page: 12, pageCount: 40, completed: false, updatedAt: DateTime.utc(2026, 9)),
          },),
    ],);
    unawaited(rig.router.push<void>('/recap/s/k?to=c2'));
    await pumpFor(t, 2000);
    expect(find.textContaining('p. 12'), findsOneWidget);
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await pumpFor(t, 1500);
    final last = rig.router.routerDelegate.currentConfiguration.last;
    expect(last.matchedLocation, '/reader/s/k/c2');
    expect((last as ImperativeRouteMatch).matches.uri.queryParameters, containsPair('page', '12'));
  });

  testWidgets('Write it again asks with fresh=1; a refusal keeps the recap and disables the button with the reason', (t) async {
    final a = _Then(chunks: deckEvents(), later: {'available': false, 'reason': 'budget_exhausted'});
    await pumpRecap(t, a);
    expect(a.calls.single.queryParameters.containsKey('fresh'), isFalse);
    await t.sendKeyEvent(LogicalKeyboardKey.keyR);
    await pumpFor(t, 1500);
    expect(a.calls, hasLength(2));
    expect(a.calls.last.queryParameters, containsPair('fresh', '1'));
    expect(find.text('Where you left off'), findsOneWidget);
    expect(find.textContaining('Written by test-model'), findsOneWidget);
    await t.sendKeyEvent(LogicalKeyboardKey.keyR);
    await pumpFor(t, 600);
    expect(a.calls, hasLength(2));
  });

  testWidgets('Write it again streams a new recap in place of the old one', (t) async {
    final a = RecapAdapter(chunks: deckEvents());
    await pumpRecap(t, a);
    await t.tap(find.bySemanticsLabel('Write it again'));
    await pumpFor(t, 2000);
    expect(a.calls, hasLength(2));
    expect(a.calls.last.queryParameters, containsPair('fresh', '1'));
    expect(find.textContaining('Written by test-model'), findsOneWidget);
  });
}

/// Streams the deck on the first call and answers [later] as JSON after it.
class _Then extends RecapAdapter {
  _Then({super.chunks, required this.later});
  final Map<String, Object?> later;

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? b, Future<void>? c) async {
    if (calls.isEmpty) return super.fetch(o, b, c);
    calls.add(o);
    return ResponseBody.fromString(jsonEncode(later), 200, headers: {'content-type': ['application/json']});
  }
}
