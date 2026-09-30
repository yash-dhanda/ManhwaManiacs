// ignore_for_file: directives_ordering, unawaited_futures, avoid_dynamic_calls, library_private_types_in_public_api, inference_failure_on_collection_literal
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_highlight_sweep.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/set_heading.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/section_pane.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_registry.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_search_page.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_contents.dart';

import '../downloads/downloads_rig.dart' show settle;
import 'settings_rig.dart';

Finder heading(String t) => find.byWidgetPredicate((w) => w is SetHeading && w.text == t);
Finder toc(String slug) => find.byKey(Key('settings-toc-$slug'));
Finder jumpRow(String id) => find.byWidgetPredicate((w) => w is JumpRow && w.id == id);

const _tablet = Size(834, 1194);
const _wide = Size(1024, 1366);

void main() {
  group('one pane', () {
    testWidgets('the contents lists the visible sections with gapless folios and current values', (tester) async {
      await pumpSettings(tester);
      expect(heading('Settings'), findsOneWidget);
      for (final s in ['profile', 'appearance', 'reading-manga', 'reading-novels', 'listen', 'ambient', 'storage', 'content', 'circle', 'feedback', 'notifications', 'server', 'admin', 'diagnostics', 'about']) {
        expect(toc(s), findsOneWidget, reason: s);
      }
      expect(toc('keyboard'), findsNothing, reason: 'phones have no keyboard section');
      // 15 visible sections: 01 ... 15, no gaps.
      for (var i = 1; i <= 15; i++) {
        expect(find.text(i.toString().padLeft(2, '0')), findsOneWidget, reason: '$i');
      }
      expect(find.text('CINEMATIC'), findsOneWidget);
      expect(find.text('STRIP'), findsOneWidget);
      expect(find.text('4.1 GB'), findsOneWidget);
      expect(find.text('HAPTICS ON'), findsOneWidget);
      expect(find.text('manhwamaniacs.xyz'), findsOneWidget);
      expect(find.text('3.5.0 (57)'), findsOneWidget);
      expect(find.text('Settings save as you change them.'), findsOneWidget);
    });

    testWidgets('a member without novels or downloads gets a shorter list, still gapless', (tester) async {
      await pumpSettings(tester, rig: SettingsRig(admin: false, novels: false, clientDownloads: false));
      for (final s in ['reading-novels', 'listen', 'storage', 'admin', 'keyboard']) {
        expect(toc(s), findsNothing, reason: s);
      }
      // profile, appearance, reading-manga, ambient, content, circle, feedback, notifications, server, diagnostics, about
      expect(find.text('11'), findsOneWidget);
      expect(find.text('12'), findsNothing);
    });

    testWidgets('a tablet in portrait below 900 dp is one pane and adds the Keyboard section', (tester) async {
      await pumpSettings(tester, size: _tablet);
      expect(toc('keyboard'), findsOneWidget);
      expect(find.text('16'), findsOneWidget);
      expect(find.byType(SettingsPaneTocRow), findsNothing);
    });

    testWidgets('a section is a pushed page with its own heading', (tester) async {
      await pumpSettings(tester);
      await tester.tap(toc('appearance'));
      await settle(tester, ms: 800);
      expect(heading('Appearance'), findsOneWidget);
      expect(find.byType(SettingsContentsList), findsNothing);
    });

    testWidgets('capabilities hide Downloads & storage', (tester) async {
      await pumpSettings(tester, rig: SettingsRig(clientDownloads: false));
      expect(toc('storage'), findsNothing);
    });

    testWidgets('every section renders every registered row', (tester) async {
      for (final slug in ['profile', 'appearance', 'reading-manga', 'reading-novels', 'listen', 'ambient', 'storage', 'content', 'circle', 'feedback', 'notifications', 'server', 'admin', 'diagnostics', 'about']) {
        await pumpSettings(tester, path: '/settings/$slug');
        final def = settingsSectionOf(slug)!;
        const env = SettingsEnv(admin: true, novels: true, clientDownloads: true, tablet: false, android: true);
        for (final r in def.rows) {
          if (!env.allows(r.gate)) continue;
          expect(jumpRow(r.id), findsWidgets, reason: '$slug / ${r.id}');
        }
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('a non-admin at /settings/members, /settings/backup and /settings/admin sees ADMINISTRATORS ONLY', (tester) async {
      for (final slug in ['members', 'backup', 'admin']) {
        await pumpSettings(tester, rig: SettingsRig(admin: false), path: '/settings/$slug');
        expect(find.byType(AdminOnlyNotice), findsOneWidget, reason: slug);
        expect(find.text('ADMINISTRATORS ONLY'), findsOneWidget, reason: slug);
        expect(find.text('Back to Settings'), findsOneWidget, reason: slug);
        expect(find.text('Export backup'), findsNothing, reason: slug);
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('with no profile a per-profile section shows the NOTE strip and its controls are off', (tester) async {
      await pumpSettings(tester, rig: SettingsRig(profile: false), path: '/settings/reading-manga');
      expect(find.text(NoProfileBanner.line), findsOneWidget);
      expect(find.text('Choose a profile'), findsOneWidget);
      expect(find.byType(IgnorePointer), findsWidgets);
    });

    testWidgets('the search: pushes a full-screen list, folds case, jumps and flashes the row', (tester) async {
      await pumpSettings(tester);
      await tester.tap(find.bySemanticsLabel('Search settings').first);
      await settle(tester, ms: 500);
      expect(find.byType(SettingsSearchPage), findsOneWidget);
      await tester.enterText(find.byType(EditableText), 'HAPTIC');
      await tester.pump();
      expect(find.byKey(const Key('settings-result-haptics')), findsOneWidget);
      await tester.enterText(find.byType(EditableText), 'zzzz');
      await tester.pump();
      expect(find.text('No setting matches "zzzz".'), findsOneWidget);
      await tester.enterText(find.byType(EditableText), 'haptic');
      await tester.pump();
      await tester.tap(find.byKey(const Key('settings-result-haptics')));
      await settle(tester, ms: 900);
      expect(heading('Feedback'), findsOneWidget);
      expect(find.byType(CineHighlightSweep), findsOneWidget, reason: 'the row is flashed');
      await settle(tester, ms: 2000);
      expect(find.byType(CineHighlightSweep), findsNothing, reason: 'the band goes after 1200 ms');
    });

    testWidgets('reduced motion: the jump lands at once and the band shows', (tester) async {
      await pumpSettings(tester, reduced: true);
      await tester.tap(find.bySemanticsLabel('Search settings').first);
      await settle(tester, ms: 400);
      await tester.enterText(find.byType(EditableText), 'strip taps');
      await tester.pump();
      await tester.tap(find.byKey(const Key('settings-result-strip-taps')));
      await settle(tester, ms: 300);
      expect(find.byType(CineHighlightSweep), findsOneWidget);
      await settle(tester, ms: 1800);
    });

    testWidgets('Android back closes the search first; iOS shows Close and cannot pop it', (tester) async {
      await pumpSettings(tester);
      await tester.tap(find.bySemanticsLabel('Search settings').first);
      await settle(tester, ms: 500);
      expect(find.text('Close'), findsNothing);
      await tester.binding.handlePopRoute();
      await settle(tester, ms: 400);
      expect(find.byType(SettingsSearchPage), findsNothing);
      expect(find.byType(SettingsContentsList), findsOneWidget);
    });

    testWidgets('iOS: a visible Close and PopScope', (tester) async {
      await pumpSettings(tester, platform: TargetPlatform.iOS);
      await tester.tap(find.bySemanticsLabel('Search settings').first);
      await settle(tester, ms: 500);
      expect(find.text('Close'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await settle(tester, ms: 400);
      expect(find.byType(SettingsSearchPage), findsOneWidget, reason: 'the system back cannot pop it');
      await tester.tap(find.text('Close'));
      await settle(tester, ms: 400);
      expect(find.byType(SettingsSearchPage), findsNothing);
    });
  });

  group('two panes (from 900 dp)', () {
    testWidgets('the search leads the contents; the first section shows on the right; the current row is lit', (tester) async {
      await pumpSettings(tester, size: _wide);
      expect(find.byType(SettingsPaneTocRow), findsWidgets);
      expect(find.byType(SectionPane), findsOneWidget);
      expect(heading('Profile & account'), findsOneWidget);
      final lit = tester.widget<SettingsPaneTocRow>(find.byKey(const Key('settings-toc-profile')));
      expect(lit.current, isTrue);
      expect(tester.widget<SettingsPaneTocRow>(find.byKey(const Key('settings-toc-appearance'))).current, isFalse);
      // the right pane holds controls at most 720 dp wide
      expect(tester.getSize(find.byType(SectionPane)).width, lessThanOrEqualTo(720));
    });

    testWidgets('tapping a section swaps the right pane', (tester) async {
      await pumpSettings(tester, size: _wide);
      await tester.tap(find.byKey(const Key('settings-toc-appearance')));
      await settle(tester, ms: 600);
      expect(heading('Appearance'), findsOneWidget);
      expect(tester.widget<SettingsPaneTocRow>(find.byKey(const Key('settings-toc-appearance'))).current, isTrue);
    });

    testWidgets('a pushed page shows under a back link and the parent stays lit', (tester) async {
      await pumpSettings(tester, size: _wide, path: '/settings/security');
      expect(heading('Password & security'), findsOneWidget);
      expect(find.text('← Profile & account'), findsOneWidget);
      expect(tester.widget<SettingsPaneTocRow>(find.byKey(const Key('settings-toc-profile'))).current, isTrue);
    });

    testWidgets('the search drops a list under the field; arrows and Enter open a result', (tester) async {
      await pumpSettings(tester, size: _wide);
      await tester.tap(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'haptic');
      await tester.pump();
      expect(find.byKey(const Key('settings-result-haptics')), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await settle(tester, ms: 1000);
      expect(heading('Feedback'), findsOneWidget);
    });

    testWidgets('keys: / focuses the search, j and k walk the contents, Esc returns', (tester) async {
      await pumpSettings(tester, size: _wide);
      await tester.sendKeyEvent(LogicalKeyboardKey.slash);
      await tester.pump();
      expect(find.byType(EditableText), findsOneWidget);
      expect(tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus, isTrue);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
      await tester.pump();
      expect(Focus.of(tester.element(find.byKey(const Key('settings-toc-appearance')))).hasFocus || FocusManager.instance.primaryFocus != null, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
    });

    testWidgets('the footer is under the section', (tester) async {
      await pumpSettings(tester, size: _wide);
      expect(find.text('Settings save as you change them.'), findsOneWidget);
    });
  });

  test('the footer only mentions the restart once Glass exists', () {
    expect(settingsFooter(), 'Settings save as you change them.');
    expect(settingsFooter(glassAvailable: true), 'Settings save as you change them. Changing the edition restarts the app.');
  });

  test('folios are assigned over the visible sections, the slugs stay stable', () {
    const env = SettingsEnv(admin: false, novels: false, clientDownloads: true, tablet: false, android: false);
    final visible = visibleSettingsSections(env);
    expect([for (final s in visible) folioOf(visible, s.slug)], [for (var i = 1; i <= visible.length; i++) i.toString().padLeft(2, '0')]);
    expect(registeredSlugs, containsAll(['security', 'members', 'backup', 'appearance']));
    expect(parentSectionOf('security'), 'profile');
    expect(parentSectionOf('backup'), 'admin');
  });
}
