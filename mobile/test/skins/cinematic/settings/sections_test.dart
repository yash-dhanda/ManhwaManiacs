// ignore_for_file: directives_ordering, unawaited_futures, avoid_dynamic_calls, library_private_types_in_public_api, inference_failure_on_collection_literal
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/updates/models/update_settings.dart';
import 'package:manhwamaniacs/features/updates/repositories/updates_repository.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/features/settings/services/server_switch.dart';
import 'package:manhwamaniacs/features/setup/utils/server_check.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_stepper.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_switch.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/edition/next_issue_plate.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/edition/edition_picker.dart' show kEditionCaption;
import 'package:manhwamaniacs/skins/cinematic/screens/settings/sections/server_section.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/shared/mature_gate_switch.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/skin_audio.dart';
import 'package:manhwamaniacs/skins/skins.dart';

import '../downloads/downloads_rig.dart' show settle;
import 'settings_rig.dart';

/// Scrolls [f] to the middle of the screen (under neither the running head nor the thumb index).
Future<void> reveal(WidgetTester tester, Finder f) async {
  Scrollable.ensureVisible(tester.element(f.first), alignment: 0.5);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> tapText(WidgetTester tester, String text, {int index = 0}) async {
  final f = find.text(text).at(index);
  await reveal(tester, f);
  await tester.tap(f);
  await settle(tester, ms: 400);
}

Future<void> tapFinder(WidgetTester tester, Finder f) async {
  await reveal(tester, f);
  await tester.tap(f.first);
  await settle(tester, ms: 400);
}

Finder switchOf(String label) => find.byWidgetPredicate((w) => w is CineSwitch && w.label == label);

class _FakeSwitch implements ServerSwitch {
  final calls = <String>[];
  @override
  Future<ServerCheck> check(String input) async => input.contains('bad') ? const ServerCheck.notManhwaManiacs() : ServerCheck.ok(input.trim());
  @override
  String get current => 'https://manhwamaniacs.xyz';
  @override
  bool isSame(String normalisedUrl) => normaliseAddress(normalisedUrl) == normaliseAddress(current);
  @override
  Future<AppError?> confirm(String normalisedUrl) async {
    calls.add('confirm $normalisedUrl');
    return null;
  }

  @override
  Future<AppError?> reset() async {
    calls.add('reset');
    return null;
  }
}

void main() {
  group('Appearance', () {
    testWidgets('the Glass card is live: Switch to Glass and the restart caption, no NEXT ISSUE plate', (tester) async {
      await pumpSettings(tester, path: '/settings/appearance');
      expect(find.byType(NextIssuePlate), findsNothing);
      expect(find.text('NEXT ISSUE'), findsNothing);
      expect(find.text('Switch to Glass', skipOffstage: false), findsOneWidget);
      expect(find.text(kEditionCaption, skipOffstage: false), findsOneWidget);
      expect(find.text('THIS EDITION'), findsOneWidget);
      expect(find.text('Two versions of the same app.'), findsOneWidget);
    });

    testWidgets('Hyperlegible text and reduced motion write the per-profile record', (tester) async {
      final c = await pumpSettings(tester, path: '/settings/appearance');
      await tapFinder(tester, switchOf('Hyperlegible text'));
      await tapText(tester, 'ON');
      final m = jsonDecode(c.read(sharedPrefsProvider).getString('mm.boot.a11y.u1p1')!) as Map<String, dynamic>;
      expect(m['legible'], true);
      expect(m['motion'], 'reduced');
    });

    testWidgets('Reading mode appears only when novels are on', (tester) async {
      await pumpSettings(tester, path: '/settings/appearance');
      expect(find.text('Reading mode'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await pumpSettings(tester, rig: SettingsRig(novels: false), path: '/settings/appearance');
      expect(find.text('Reading mode'), findsNothing);
    });
  });

  group('Reading: manga', () {
    testWidgets('a default edits the record the reader reads and shows its scope', (tester) async {
      final c = await pumpSettings(tester, path: '/settings/reading-manga');
      await tapText(tester, 'SINGLE');
      final m = jsonDecode(c.read(sharedPrefsProvider).getString('mm.reader-settings.u1p1')!) as Map<String, dynamic>;
      expect((m['seriesDefaults'] as Map)['layout'], 'single');
      expect(find.textContaining('Saved for this profile'), findsWidgets);
      expect(find.text('Dims below your screen\'s lowest setting.'), findsOneWidget);
      expect(find.textContaining('Tap the centre five times to unlock.'), findsOneWidget);
    });

    testWidgets('the Android-only rows are absent on iOS, and phones get Side margin', (tester) async {
      await pumpSettings(tester, path: '/settings/reading-manga');
      expect(find.text('Volume keys turn pages'), findsOneWidget);
      expect(find.text('Refresh rate'), findsOneWidget);
      expect(find.text('Side margin'), findsOneWidget);
      expect(find.text('Strip width'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await pumpSettings(tester, path: '/settings/reading-manga', platform: TargetPlatform.iOS, size: const Size(834, 1194));
      expect(find.text('Volume keys turn pages'), findsNothing);
      expect(find.text('Refresh rate'), findsNothing);
      expect(find.text('Strip width'), findsOneWidget);
      expect(find.text('Side margin'), findsNothing);
    });

    testWidgets('Previously on is one setting shared with the novels section', (tester) async {
      final c = await pumpSettings(tester, path: '/settings/reading-manga');
      expect(find.text('AFTER 7 DAYS AWAY'), findsOneWidget);
      await tapText(tester, 'NEVER');
      expect(jsonDecode(c.read(sharedPrefsProvider).getString('mm.recap.u1p1')!)['mode'], 'off');
      expect(find.text('Days away'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await pumpSettings(tester, path: '/settings/reading-novels', reuse: c);
      expect(find.text('NEVER'), findsOneWidget);
      await tapText(tester, 'ALWAYS');
      expect(jsonDecode(c.read(sharedPrefsProvider).getString('mm.recap.u1p1')!)['mode'], 'always');
    });

    testWidgets('Reset reader settings asks first, with the arm delay', (tester) async {
      final c = await pumpSettings(tester, path: '/settings/reading-manga');
      await tapText(tester, 'SINGLE');
      await tapText(tester, 'Reset reader settings');
      await settle(tester, ms: 500);
      expect(find.text('Restore every reader setting to its default?'), findsOneWidget);
      await tester.tap(find.text('Restore defaults'), warnIfMissed: false);
      await settle(tester, ms: 200);
      expect(c.read(sharedPrefsProvider).containsKey('mm.reader-settings.u1p1'), isTrue, reason: 'armed: the confirm is dead for 1000 ms');
      await settle(tester, ms: 1200);
      await tester.tap(find.text('Restore defaults'));
      await settle(tester, ms: 600);
      expect(c.read(sharedPrefsProvider).containsKey('mm.reader-settings.u1p1'), isFalse);
      expect(c.read(cineToastsProvider).any((t) => t.text == 'Reader settings reset.'), isTrue);
    });
  });

  group('Reading: novels', () {
    testWidgets('five faces, the low-vision caption, seven stocks and the fallback line', (tester) async {
      final c = await pumpSettings(tester, path: '/settings/reading-novels');
      for (final f in ['newsreader', 'literata', 'sourceserif', 'archivo', 'atkinson']) {
        expect(find.byKey(Key('face-$f')), findsOneWidget, reason: f);
      }
      expect(find.text('Designed for low vision'), findsOneWidget);
      for (final s in ['issue', 'nitrate', 'ink', 'sepiaNight', 'dusk', 'moss', 'rosewood']) {
        expect(find.byKey(Key('stock-$s')), findsOneWidget, reason: s);
      }
      expect(find.text("Issue uses each book's own colour."), findsOneWidget);
      await tapFinder(tester, find.byKey(const Key('face-literata')));
      expect((jsonDecode(c.read(sharedPrefsProvider).getString('mm.novel-settings.u1p1')!)['bookDefaults'] as Map)['face'], 'literata');
    });
  });

  group('Listen and Ambient', () {
    testWidgets('Listen: defaults, shake to extend on, the sleep list and the voices', (tester) async {
      final c = await pumpSettings(tester, path: '/settings/listen');
      expect(switchOf('Shake to extend'), findsOneWidget);
      expect(tester.widget<CineSwitch>(switchOf('Shake to extend')).value, isTrue);
      expect(tester.widget<CineSwitch>(switchOf('Keep the player visible')).value, isFalse);
      await tapText(tester, 'Sleep timer default');
      await settle(tester, ms: 600);
      expect(find.text('End of next chapter'), findsOneWidget);
      await tester.tap(find.text('45 min'));
      await settle(tester, ms: 600);
      expect(jsonDecode(c.read(sharedPrefsProvider).getString('mm.listen-settings.u1p1')!)['sleepDefault'], '45');
      await tapText(tester, 'Voices');
      await settle(tester, ms: 600);
      expect(find.text('THE VOICES'), findsOneWidget);
      expect(find.text('Atlas'), findsOneWidget);
    });

    testWidgets('Ambient: the eight loops with their lines, one choice writes both records', (tester) async {
      final c = await pumpSettings(tester, path: '/settings/ambient');
      for (final line in ['A soft hum with distant reel ticks.', 'Steady rain on a window.', 'Distant traffic after dark.', 'Low voices and cups.', 'Wind across an empty street.'.replaceFirst('Wind', 'Wind'), 'A deep, even hum.', 'Birds and far-off voices.', 'Slow bells over a quiet courtyard.']) {
        expect(find.text(line), findsOneWidget, reason: line);
      }
      expect(find.text('MATCH THE MOOD'), findsOneWidget);
      expect(find.byKey(const Key('hear-rain-on-glass')), findsOneWidget, reason: 'each loop row has Hear');
      await tapText(tester, 'Rain on glass');
      final prefs = c.read(sharedPrefsProvider);
      expect(jsonDecode(prefs.getString('mm.reader-settings.u1p1')!)['soundscape'], 'rain-on-glass');
      expect(jsonDecode(prefs.getString('mm.novel-settings.u1p1')!)['soundscape'], 'rain-on-glass');
      expect(find.text('Hold each panel'), findsNothing);
      await tapFinder(tester, switchOf('Guided view auto-advance'));
      expect(find.text('PACE BY WORDS'), findsOneWidget);
      await tapText(tester, 'FIXED');
      expect(find.text('Hold each panel'), findsOneWidget);
      // The fixed hold is a 2-10 s stepper in half-second steps over the stored milliseconds.
      final hold = find.byWidgetPredicate((w) => w is CineStepper && w.label == 'Hold each panel');
      final stepper = tester.widget<CineStepper>(hold);
      expect((stepper.value, stepper.min, stepper.max, stepper.step), (7, 4, 20, 1));
      expect(stepper.format!(7), '3.5 s');
      expect(find.text('5'), findsOneWidget, reason: 'the folio keeps the formatted text');
      await tapFinder(tester, find.descendant(of: hold, matching: find.bySemanticsLabel('Increase')));
      expect(jsonDecode(prefs.getString('mm.reader-settings.u1p1')!)['guidedAutoAdvance']['fixedMs'], 4000);
    });
  });

  group('Content, Feedback', () {
    testWidgets('Content mounts the 18+ switch with its certificate flow', (tester) async {
      await pumpSettings(tester, path: '/settings/content');
      expect(find.byType(MatureGateSwitch), findsOneWidget);
      expect(find.text('Show mature content (18+)'), findsWidgets);
      expect(find.text('Manage pinned sources'), findsOneWidget);
    });

    testWidgets('Feel it needs haptics; Play a sample needs UI sounds and plays the set cue', (tester) async {
      final rig = SettingsRig();
      final c = await pumpSettings(tester, rig: rig, path: '/settings/feedback');
      expect(find.text('Turn UI sounds on to hear them.'), findsOneWidget);
      expect(tester.widget<CineButton>(find.widgetWithText(CineButton, 'Play a sample')).onPressed, isNull);
      expect(tester.widget<CineButton>(find.widgetWithText(CineButton, 'Feel it')).onPressed, isNotNull);
      await tapFinder(tester, find.widgetWithText(CineButton, 'Feel it'));
      expect(rig.haptics, contains('follow.add'));
      // haptics off disables it and says why
      await tapFinder(tester, switchOf('Haptic feedback'));
      expect(find.text('Turn haptics on to feel them.'), findsOneWidget);
      expect(tester.widget<CineButton>(find.widgetWithText(CineButton, 'Feel it')).onPressed, isNull);
      // UI sounds default off, per profile
      expect(c.read(sharedPrefsProvider).getString('mm.sounds.u1p1'), isNull);
      await tapFinder(tester, switchOf('UI sounds'));
      expect(jsonDecode(c.read(sharedPrefsProvider).getString('mm.sounds.u1p1')!)['on'], true);
      await tapFinder(tester, find.widgetWithText(CineButton, 'Play a sample'));
      expect(rig.engine.played.last, 'assets/sounds/cinematic/set.wav');
    });
  });

  group('Notifications', () {
    testWidgets('the per-profile master shows for everyone, the admin block only for admins', (tester) async {
      await pumpSettings(tester, rig: SettingsRig(admin: false), path: '/settings/notifications');
      expect(find.text('Notify me about new chapters'), findsOneWidget);
      expect(find.text('Check automatically'), findsNothing);
      expect(find.text('Source cache lifetime'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await pumpSettings(tester, path: '/settings/notifications');
      expect(find.text('Check automatically'), findsOneWidget);
      expect(find.textContaining('LAST CHECK'), findsOneWidget);
      expect(find.textContaining('EVERY 30 MIN'), findsOneWidget);
      expect(find.textContaining('Expected 15 min ago'), findsOneWidget);
      expect(find.text('The server enforces a 5-minute floor.'), findsOneWidget);
    });

    testWidgets('Save after a switch flip leaves an interval above 120 min alone', (tester) async {
      final repo = _RecordingUpdates();
      await pumpSettings(tester, rig: SettingsRig(checkInterval: 360), path: '/settings/notifications', more: [updatesRepositoryProvider.overrideWithValue(repo)]);
      await tapFinder(tester, find.text('Check on startup'));
      await tapFinder(tester, find.widgetWithText(CineButton, 'Save').first);
      expect(repo.saved, hasLength(1));
      expect(repo.saved.single, isNull);
    });

    testWidgets('the cache lifetime refuses values under 5 minutes', (tester) async {
      await pumpSettings(tester, path: '/settings/notifications');
      final field = find.descendant(of: find.byKey(const Key('unused')), matching: find.byType(EditableText));
      expect(field, findsNothing);
      final ttl = find.byType(EditableText).last;
      await reveal(tester, ttl);
      await tester.enterText(ttl, '3');
      await tester.pump();
      await tapFinder(tester, find.widgetWithText(CineButton, 'Save').last);
      expect(find.textContaining('At least 5 minutes.'), findsOneWidget);
    });
  });

  group('Server', () {
    testWidgets('a bad address shows the Setup line; the same server is a no-op toast; a different one asks first', (tester) async {
      final fake = _FakeSwitch();
      final c = await pumpSettings(tester, path: '/settings/server', more: [serverSwitchProvider.overrideWithValue(fake)]);
      final field = find.byType(EditableText);
      await tester.enterText(field, 'https://bad.example');
      await tapFinder(tester, find.widgetWithText(CineButton, 'Save'));
      expect(find.textContaining("That address isn't a ManhwaManiacs server."), findsOneWidget);
      await tester.enterText(field, 'https://manhwamaniacs.xyz/');
      await tapFinder(tester, find.widgetWithText(CineButton, 'Save'));
      expect(c.read(cineToastsProvider).any((t) => t.text == 'Already connected to this server.'), isTrue);
      expect(fake.calls, isEmpty);
      await tester.enterText(field, 'https://other.example');
      await tapFinder(tester, find.widgetWithText(CineButton, 'Save'));
      await settle(tester, ms: 300);
      expect(find.text('Switch servers?'), findsOneWidget);
      expect(find.text(kSwitchServersBody), findsOneWidget);
      await tester.tap(find.text('Switch servers'), warnIfMissed: false);
      await settle(tester, ms: 300);
      expect(fake.calls, isEmpty, reason: 'the destructive confirm is armed for 1000 ms');
      await settle(tester, ms: 1200);
      await tester.tap(find.text('Switch servers'));
      await settle(tester, ms: 600);
      expect(fake.calls, ['confirm https://other.example']);
      expect(c.read(cineToastsProvider).any((t) => t.text == 'Signed out: new server.'), isTrue);
    });

    testWidgets('the field asks for a URL keyboard and shows the saved address', (tester) async {
      await pumpSettings(tester, path: '/settings/server');
      final t = tester.widget<EditableText>(find.byType(EditableText));
      expect(t.keyboardType, TextInputType.url);
      expect(t.autocorrect, isFalse);
      expect(t.controller.text, 'https://manhwamaniacs.xyz');
    });
  });

  group('Diagnostics, About, Keyboard, Storage', () {
    testWidgets('Diagnostics: the rendering numerals, display, device, cache and the developer rows', (tester) async {
      await pumpSettings(tester, path: '/settings/diagnostics');
      for (final s in ['RENDERING', 'DISPLAY', 'DEVICE', 'IMAGE CACHE', 'FPS', 'JANK', 'WORST']) {
        expect(find.text(s), findsWidgets, reason: s);
      }
      expect(find.text('Collecting frames… scroll a screen to sample.'), findsOneWidget);
      expect(find.text('Show the layout grid'), findsOneWidget);
      expect(find.text('Show motion timings'), findsOneWidget);
      expect(find.text('Use the highest refresh rate everywhere'), findsOneWidget);
      expect(find.text('Edition (debug)'), findsNothing, reason: 'the pre-flip debug row is gone');
      expect(find.text('LEGACY'), findsNothing);
      // debug builds only
      expect(kDebugMode, isTrue);
      expect(find.text('Stop the press (dry run)'), findsOneWidget);
      expect(find.text('Stop the press (failure)'), findsOneWidget);
    });

    testWidgets('Diagnostics on iOS explains that display modes are Android-only', (tester) async {
      await pumpSettings(tester, path: '/settings/diagnostics', platform: TargetPlatform.iOS);
      expect(find.text('Display modes can only be switched on Android.'), findsOneWidget);
      expect(find.text('Use the highest refresh rate everywhere'), findsNothing);
    });

    testWidgets('About: versions, What is new, Licenses, and the platform card', (tester) async {
      await pumpSettings(tester, path: '/settings/about');
      expect(find.text('APP VERSION'), findsOneWidget);
      expect(find.text('SERVER'), findsOneWidget);
      expect(find.text('3.5.0 (57)'), findsNWidgets(2));
      expect(find.text("What's new"), findsOneWidget);
      expect(find.text('Licenses'), findsOneWidget);
      expect(find.byKey(const Key('app-update-card')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await pumpSettings(tester, path: '/settings/about', platform: TargetPlatform.iOS);
      expect(find.byKey(const Key('sidestore-card')), findsOneWidget);
      expect(find.byKey(const Key('app-update-card')), findsNothing);
    });

    testWidgets('Keyboard (tablets): the single-key switch and the registered keys as keycaps', (tester) async {
      await pumpSettings(tester, path: '/settings/keyboard', size: const Size(834, 1194));
      expect(switchOf('Single-key shortcuts'), findsOneWidget);
      expect(find.text('SETTINGS'), findsOneWidget);
      expect(find.text('Search settings'), findsWidgets);
      expect(find.text('/'), findsWidgets, reason: 'the search key as a keycap');
    });

    testWidgets('Storage mounts the mobile/17 panel', (tester) async {
      await pumpSettings(tester, path: '/settings/storage');
      expect(find.byKey(const Key('storage-panel')), findsOneWidget);
    });
  });

  test('the next-issue plate and skins are skin-neutral names', () {
    expect(SkinId.cinematic.displayFamily, 'BodoniModa');
    expect(SkinId.glass.displayFamily, 'GoogleSansFlexMM');
  });

  test('UI sound prefs default to off at 60 % for Cinematic', () {
    expect(SoundPrefs.cinematicDefault.on, isFalse);
    expect(SoundPrefs.cinematicDefault.level, 60);
  });
}

class _RecordingUpdates implements UpdatesRepository {
  final List<int?> saved = [];
  @override
  Future<Result<UpdateSettings>> updateSettings({bool? enabled, int? checkIntervalMinutes, bool? notifyEnabled, bool? checkOnStartup}) async {
    saved.add(checkIntervalMinutes);
    return Ok(UpdateSettings(enabled: true, checkIntervalMinutes: checkIntervalMinutes ?? 360, notifyEnabled: true, checkOnStartup: true));
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}
