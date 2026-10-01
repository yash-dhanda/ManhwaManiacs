import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/models/reading_history_item.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_profile_settings.dart';
import 'package:manhwamaniacs/skins/glass/copy/settings_index.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/ai_recaps_section.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/circle_privacy_section.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/reader_defaults_section.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_index_filter.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_sections.dart';

List<String> _ids(String q, {TargetPlatform p = TargetPlatform.android, bool admin = false, bool gate = false, bool glass = false}) =>
    [for (final e in filterSettingsIndex(q, platform: p, admin: admin, matureGateOpen: gate, glassAvailable: glass)) e.id];

void main() {
  group('settings index', () {
    test('holds every row of glass 8.25.1 to 8.25.16', () {
      final ids = {for (final e in kSettingsIndex) e.id};
      expect(ids.length, kSettingsIndex.length, reason: 'unique ids');
      expect(ids.length, greaterThanOrEqualTo(80));
      for (final id in ['skin', 'solid-glass', 'legible-text', 'reader-reset', 'novel-face', 'listen-speed', 'ambient-cruise', 'mature-content', 'haptics-feel', 'soundscape-lower', 'members', 'backup-restore', 'server-url', 'diag-glass', 'shortcuts', 'sign-out', 'licences', 'share-streak', 'recap-skip', 'ai-status']) {
        expect(ids, contains(id));
      }
    });

    test('every-word, case- and diacritic-insensitive matching on label and keywords', () {
      expect(_ids('SOLID glass'), contains('solid-glass'));
      expect(_ids('opaque'), contains('solid-glass'));
      expect(_ids('atkinson dyslexia'), ['legible-text']);
      expect(_ids('zzzzqq'), isEmpty);
      expect(_ids('  '), isNotEmpty);
    });

    test('exclusions: platform, admin, gate, flag', () {
      expect(_ids('volume keys'), contains('reader-volume-keys'));
      expect(_ids('volume keys', p: TargetPlatform.iOS), isEmpty);
      expect(_ids('screen reader mode'), isEmpty, reason: 'web only');
      expect(_ids('haptics', p: TargetPlatform.macOS), isNot(contains('haptics')));
      expect(_ids('nightly backup'), isEmpty);
      expect(_ids('nightly backup', admin: true), contains('backup-nightly'));
      expect(_ids('include 18'), isEmpty);
      expect(_ids('include 18', gate: true), contains('include-mature-activity'));
      expect(_ids('preview glass skin'), contains('diag-preview-glass'));
      expect(_ids('preview glass skin', glass: true), isNot(contains('diag-preview-glass')));
      expect(_ids('app icon'), isEmpty);
      expect(_ids('app icon', glass: true), contains('app-icon-follows-skin'));
    });

    test('search hits open their section and row', () {
      final e = kSettingsIndex.firstWhere((e) => e.id == 'solid-glass');
      expect(settingsLocationFor(e), '/settings/appearance?row=solid-glass');
      expect(settingsLocationFor(kSettingsIndex.firstWhere((e) => e.id == 'licences')), '/settings/about?sheet=licenses');
      expect(settingsSectionTitle('feedback'), 'Sound and haptics');
    });
  });

  test('white on every tile colour is at least 3:1', () {
    for (final s in [...kSettingsSections, kAboutSection]) {
      expect(contrastRatio(const Color(0xFFFFFFFF), s.tile), greaterThanOrEqualTo(3.0), reason: s.label);
    }
  });

  test('the root lists sections in glass 8.24 order and hides by role, platform and keyboard', () {
    final all = visibleSettingsSections(platform: TargetPlatform.android, admin: true, keyboardSeen: true, wide: true);
    expect([for (final s in all) s.section.slug], ['appearance', 'reading-manga', 'content', 'circle', 'ai', 'feedback', 'notifications', 'security', 'storage', 'backup', 'server', 'diagnostics', 'keyboard']);
    final phone = visibleSettingsSections(platform: TargetPlatform.iOS, admin: false, keyboardSeen: true, wide: false);
    expect([for (final s in phone) s.section.slug], isNot(contains('notifications')));
    expect([for (final s in phone) s.section.slug], isNot(contains('keyboard')));
    // mobile/40 built the last sections.
    expect(sectionsBuiltLater, isEmpty);
  });

  test('the sharing preview line', () {
    const done = ReadingHistoryItem(id: 1, sourceId: 's', seriesKey: 'k', chapterKey: 'c', chapterNumber: 12, lastPage: 3, pageCount: 3, isCompleted: true, seriesTitle: 'Solo');
    expect(circlePreviewLine(sharing: true, name: 'Ana', latest: done), 'Others see: Ana finished chapter 12 of Solo.');
    expect(circlePreviewLine(sharing: true, name: 'Ana'), 'Others see: Ana started a series.');
    expect(circlePreviewLine(sharing: false, name: 'Ana', latest: done), 'Others see nothing from this profile.');
  });

  test('the AI status line', () {
    expect(aiStatusLine(available: true, reason: 'ok', remaining: 7), 'AI picks are on · 7 asks left today');
    expect(aiStatusLine(available: false, reason: 'budget_exhausted', remaining: 0), contains('used'));
    expect(aiStatusLine(available: true, reason: 'ok', remaining: 7, offline: true), contains('offline'));
  });

  test('manga direction maps onto the series defaults', () {
    const d = SeriesDefaults();
    expect(mangaDirectionOf(d), MangaDirection.vertical);
    final rtl = applyMangaDirection(d, MangaDirection.rtl);
    expect((rtl.layout, rtl.direction), ('single', 'rtl'));
    expect(mangaDirectionOf(rtl), MangaDirection.rtl);
    expect(applyMangaDirection(rtl, MangaDirection.vertical).layout, 'strip');
  });

  test('listen speed snaps to 0.05 and magnets to 1.0 within 0.08', () {
    expect(snapListenSpeed(1.06), 1.0);
    expect(snapListenSpeed(1.12), 1.1);
    expect(snapListenSpeed(0.1), 0.5);
    expect(snapListenSpeed(9), 3.0);
  });
}
