// ignore_for_file: require_trailing_commas
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/alert.dart';
import 'package:manhwamaniacs/skins/glass/primitives/confirm_alert.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/shell/accessory_controller.dart';

import '../../skins/cinematic/feature/feature_test_support.dart' show Recorder;
import '../../skins/cinematic/library/library_test_support.dart' show ShelfLibrary;
import '../../skins/glass/home/home_rig.dart' show FakeHomeRepo, homeOverrides;
import '../../skins/glass/novel/novel_rig.dart' show pumpGlassNovel;
import '../../skins/glass/qa/glass_qa_screens.dart';
import '../../skins/glass/reader/glass_reader_rig.dart' show GlassReaderOrigin, pumpGlassReader;
import '../support/shot_harness.dart';
import '../support/skin_shots.dart';

/// The Glass alignment sweep: every Glass route, every Settings section and the major states (tabs, onboarding steps, sheets,
/// alerts, toasts, the accessory, empty / error / loading) at 375, 390, 430 and tablet 1024 wide, text scale 1.0, 1.3 and 2.0, with
/// the device's safe areas. A layout error (overflow) fails the test; PNGs are written only when `MM_PROOF_DIR` is set, and with
/// `MM_AUDIT_REPORT=1` each paragraph closer than 12 px to a side edge is printed. `MM_ALIGN_SIZES=375,430` / `MM_ALIGN_SCALES=2.0`
/// narrow the matrix:
///
///   MM_PROOF_DIR=/tmp/galign flutter test test/screenshots/glass/alignment_shots_test.dart
const _allSizes = {
  '375': (Size(375, 667), EdgeInsets.only(top: 20)),
  '390': (Size(390, 844), EdgeInsets.only(top: 47, bottom: 34)),
  '430': (Size(430, 932), EdgeInsets.only(top: 59, bottom: 34)),
  '1024': (Size(1024, 1366), EdgeInsets.only(top: 24, bottom: 20)),
};
const _allScales = [1.0, 1.3, 2.0];
const _readers = {ScreenId.reader, ScreenId.readAll, ScreenId.novel};

Map<String, (Size, EdgeInsets)> get _sizes {
  final only = (Platform.environment['MM_ALIGN_SIZES'] ?? '').split(',').where((s) => s.isNotEmpty).toSet();
  return {for (final e in _allSizes.entries) if (only.isEmpty || only.contains(e.key)) e.key: e.value};
}

List<double> get _scales {
  final only = (Platform.environment['MM_ALIGN_SCALES'] ?? '').split(',').where((s) => s.isNotEmpty).map(double.parse).toSet();
  return [for (final s in _allScales) if (only.isEmpty || only.contains(s)) s];
}

/// Paragraphs on screen whose box comes within 12 px of the left or right edge (a hint for the visual pass, never a failure).
void _edges(WidgetTester t, String name, double width) {
  for (final e in find.byType(RichText).evaluate()) {
    final p = e.renderObject as RenderParagraph?;
    if (p == null || !p.attached || !p.hasSize) continue;
    final text = p.text.toPlainText().trim();
    if (text.isEmpty) continue;
    final box = MatrixUtils.transformRect(p.getTransformTo(null), Offset.zero & p.size);
    if (box.right <= 0 || box.left >= width || box.bottom <= 0) continue;
    if (box.left < 12 || box.right > width - 12) {
      debugPrint('EDGE $name "${text.length > 40 ? text.substring(0, 40) : text}" ${box.left.toStringAsFixed(1)}..${box.right.toStringAsFixed(1)} y${box.top.round()}');
    }
  }
}

Future<void> _shot(WidgetTester t, String name, double width) async {
  final dir = proofDir;
  if (dir != null) await writeShot(t, find.byKey(kSkinShotKey), '$dir/$name.png', pixelRatio: 1.5);
  if (Platform.environment['MM_AUDIT_REPORT'] == '1') _edges(t, name, width);
}

/// The ready Home feed with its "Because you read" seed renamed to a long real-world-length title (the owner's 3-line case).
FakeHomeRepo _richHome() {
  final raw = File('test/fixtures/home/ready.json').readAsStringSync().replaceAll('Sword of the Ninth Spring', 'Surviving as a Genius on Borrowed Time');
  return FakeHomeRepo(() async => Ok(HomeFeed.fromJson(jsonDecode(raw) as Map<String, dynamic>)));
}

BuildContext _nav(GlassQaRig rig) => rig.shell.router.routerDelegate.navigatorKey.currentContext!;

/// One major state: a route with its overrides, an optional action once it settles, and a tall window for long pages.
class _State {
  const _State(this.name, this.screen, {this.act, this.tall = false, this.lib});
  final String name;
  final GlassQaScreen screen;
  final Future<void> Function(WidgetTester t, GlassQaRig rig)? act;
  final bool tall;
  final ShelfLibrary Function()? lib;
}

Future<void> _settle(WidgetTester t, [int ms = 1200]) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

final List<_State> _states = [
  _State('home-rich', GlassQaScreen(ScreenId.tonight, Routes.tonight(), extra: homeOverrides(_richHome())), tall: true),
  _State('home-rich-scrolled', GlassQaScreen(ScreenId.tonight, Routes.tonight(), extra: homeOverrides(_richHome())), act: (t, rig) async {
    await t.drag(find.byType(Scrollable).first, const Offset(0, -700));
    await _settle(t);
  }),
  _State('home-novels', GlassQaScreen(ScreenId.tonight, Routes.tonight(), novels: true, extra: homeOverrides(_richHome()))),
  _State('accessory-continue', GlassQaScreen(ScreenId.library, Routes.library()), act: (t, rig) async {
    rig.shell.container.read(glassAccessoryProvider.notifier).setContinue(GlassContinueAccessory(title: 'Continue The Lantern Courier', subtitle: 'Ch 143', coverUrl: '', onOpen: (_) {}));
    await _settle(t);
  }),
  _State('library-empty', GlassQaScreen(ScreenId.library, Routes.library()), lib: () => ShelfLibrary(all: [])),
  _State('library-error', GlassQaScreen(ScreenId.library, Routes.library()), lib: () => ShelfLibrary(all: [], failList: true)),
  _State('library-loading', GlassQaScreen(ScreenId.library, Routes.library()), lib: () => ShelfLibrary(all: [], listGate: Completer<void>())),
  for (final tab in ['queue', 'storage']) _State('downloads-$tab', GlassQaScreen(ScreenId.downloads, Routes.downloads({'tab': tab})), tall: tab == 'storage'),
  for (final tab in ['unread', 'followed']) _State('updates-$tab', GlassQaScreen(ScreenId.updates, Routes.updates({'tab': tab}))),
  for (final tab in ['letters', 'shelves']) _State('circle-$tab', GlassQaScreen(ScreenId.circle, Routes.circle({'tab': tab}))),
  for (var step = 2; step <= 7; step++)
    _State('onboarding-$step', GlassQaScreen(ScreenId.onboarding, Routes.onboarding({'step': step}), more: () => qaProfileList(step: '7'))),
  _State('sources-error', GlassQaScreen(ScreenId.sources, Routes.sources(), extra: [sourcesListProvider.overrideWith((ref) async => throw StateError('offline'))])),
  _State('sources-loading', GlassQaScreen(ScreenId.sources, Routes.sources(), extra: [sourcesListProvider.overrideWith((ref) => Completer<List<SourceSummary>>().future)])),
  // A sheet presents after the route's first frame and then materializes: give it time to settle.
  for (final sheet in ['filters', 'density', 'add-series', 'collection-new'])
    _State('sheet-$sheet', GlassQaScreen(ScreenId.library, Routes.library({'sheet': sheet})), act: (t, rig) => _settle(t, 3000)),
  for (final sheet in ['whats-new', 'shortcuts', 'app-update'])
    _State('sheet-$sheet', GlassQaScreen(ScreenId.tonight, Routes.tonight({'sheet': sheet})), act: (t, rig) => _settle(t, 3000)),
  _State('alert', GlassQaScreen(ScreenId.library, Routes.library()), act: (t, rig) async {
    unawaited(showGlassAlert<bool>(_nav(rig),
        title: 'Remove "Surviving as a Genius on Borrowed Time" from your library?',
        body: 'Your reading progress, bookmarks and downloaded chapters on this device go with it.',
        actions: const [GlassAlertAction('Cancel', role: GlassAlertRole.cancel), GlassAlertAction('Remove from library', role: GlassAlertRole.destructive, value: true)]));
    await _settle(t);
  }),
  _State('alert-confirm', GlassQaScreen(ScreenId.library, Routes.library()), act: (t, rig) async {
    unawaited(confirmAlert(_nav(rig), title: 'Sign out of every device?', body: 'You will need your password on each one.', confirmLabel: 'Sign out everywhere', destructive: true));
    await _settle(t);
  }),
  _State('toast', GlassQaScreen(ScreenId.library, Routes.library()), act: (t, rig) async {
    rig.shell.container.read(glassToastProvider.notifier).show(GlassToastSpec('Removed 12 chapters of Surviving as a Genius on Borrowed Time', undo: () {}));
    await _settle(t, 800);
  }),
  _State('toast-error', GlassQaScreen(ScreenId.tonight, Routes.tonight()), act: (t, rig) async {
    rig.shell.container.read(glassToastProvider.notifier).show(GlassToastSpec("Couldn't reach the server. Check your connection and try again.", kind: GlassToastKind.error, actionLabel: 'Retry', onAction: () {}));
    await _settle(t, 800);
  }),
];

void main() {
  setUpAll(() async {
    await loadAppFonts();
    // A screen that listens for connectivity or the tilt sensor gets an answer while the PNG is written (real async).
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    m.setMockMethodCallHandler(const MethodChannel('dev.fluttercommunity.plus/connectivity_status'), (_) async => null);
    m.setMockMethodCallHandler(const MethodChannel('dev.fluttercommunity.plus/connectivity'), (_) async => <String>['wifi']);
    for (final c in ['dev.fluttercommunity.plus/sensors/method', 'dev.fluttercommunity.plus/sensors/accelerometer']) {
      m.setMockMethodCallHandler(MethodChannel(c), (_) async => null);
    }
  });

  group('screens', () {
    for (final s in kGlassQaScreens) {
      for (final size in _sizes.entries) {
        for (final scale in _scales) {
          final name = 'screens/${s.id.id}-${size.key}-x$scale';
          glassQaWidgets(name, (t) async {
            final (logical, padding) = size.value;
            GlassQaRig? rig;
            if (s.id == ScreenId.novel) {
              await pumpGlassNovel(t, size: logical, textScale: scale, padding: padding, boundaryKey: kSkinShotKey);
            } else if (_readers.contains(s.id)) {
              // The reader chrome clamps its own text scale (glass 3.3).
              await pumpGlassReader(t,
                  size: logical,
                  padding: padding,
                  origin: s.id == ScreenId.readAll ? GlassReaderOrigin.readAll : GlassReaderOrigin.manifest,
                  extra: [readerRepositoryProvider.overrideWithValue(GlassQaReader(Recorder()))]);
            } else {
              rig = await pumpGlassQa(t, s, size: logical, padding: padding, textScale: scale, boundaryKey: kSkinShotKey);
            }
            if (rig == null) await t.pump(const Duration(milliseconds: 1500));
            await _shot(t, name, logical.width);
            if (rig != null) {
              await disposeGlassQa(t, rig);
            } else {
              await t.pumpWidget(const SizedBox());
              await t.pump(const Duration(seconds: 11));
            }
          });
        }
      }
    }
  });

  group('states', () {
    for (final st in _states) {
      for (final size in _sizes.entries) {
        for (final scale in _scales) {
          final name = 'states/${st.name}-${size.key}-x$scale';
          glassQaWidgets(name, (t) async {
            final (logical, padding) = size.value;
            final rig = await pumpGlassQa(t, st.screen,
                size: st.tall ? Size(logical.width, 2400) : logical, padding: padding, textScale: scale, boundaryKey: kSkinShotKey, lib: st.lib?.call());
            await st.act?.call(t, rig);
            await _shot(t, name, logical.width);
            await disposeGlassQa(t, rig);
            await t.pump(const Duration(minutes: 11)); // the Home feed's keep-alive timer
          });
        }
      }
    }
  });

  // Each Settings section at full length: a tall window shows the whole section in one frame.
  group('settings', () {
    for (final section in SettingsSection.values) {
      for (final size in _sizes.entries) {
        for (final scale in _scales) {
          final name = 'settings/${section.slug}-${size.key}-x$scale';
          glassQaWidgets(name, (t) async {
            final (logical, padding) = size.value;
            final rig = await pumpGlassQa(t, GlassQaScreen(ScreenId.settings, Routes.settings(section)),
                size: Size(logical.width, 2400), padding: padding, textScale: scale, boundaryKey: kSkinShotKey);
            await _shot(t, name, logical.width);
            await disposeGlassQa(t, rig);
          });
        }
      }
    }
  });
}
