// ignore_for_file: require_trailing_commas, avoid_redundant_argument_values, prefer_const_declarations, directives_ordering, prefer_function_declarations_over_variables
// ignore_for_file: prefer_const_constructors
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/platform/mm_platform.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart' show SkinGlass;

import '../skins/cinematic/qa/qa_screens.dart' as cine;
import '../skins/cinematic/feature/feature_test_support.dart' show Recorder;
import '../skins/cinematic/library/library_test_support.dart' show ShelfLibrary, shelfSeries;
import '../skins/glass/novel/novel_rig.dart' show pumpGlassNovel;
import '../skins/glass/qa/glass_qa_screens.dart';
import '../skins/glass/reader/demo_pages.dart';
import '../skins/glass/reader/glass_reader_rig.dart' show GlassReaderOrigin, pumpGlassReader, settleReader;
import '../skins/glass/home/home_rig.dart' show homeOverrides, homeRepoOf;
import 'glass_shell_shots_support.dart' show openShell;
import 'support/compose_png.dart';
import 'support/shot_covers.dart';
import 'support/shot_harness.dart';
import 'support/shot_network.dart';
import 'support/skin_shots.dart';

/// mobile/45 E, D and L: the Glass proof captures. One `--plain-name` per sub-group, each with its own `MM_PROOF_DIR`:
/// `mobile-45 screens`, `a11y`, `textscale`, `states`, `pairs`, `calibration`, `float`. Without `MM_PROOF_DIR` everything is
/// rasterised and discarded. Fixtures: invented titles (glass 12.7) and covers painted in-repo; never real names or art.
const _phone = SkinShotSize('phone', Size(390, 844), 3.0, EdgeInsets.only(top: 47, bottom: 34));
const _phoneMax = SkinShotSize('phone-max', Size(440, 956), 3.0, EdgeInsets.only(top: 62, bottom: 34));
const _phone1 = SkinShotSize('phone', Size(390, 844), 1.0, EdgeInsets.only(top: 47, bottom: 34));
const _tablet1 = SkinShotSize('tablet', Size(834, 1194), 1.0, EdgeInsets.only(top: 24, bottom: 20));

final _mainSizes = [_phone, _phoneMax, kSkinShotSizes[1], kSkinShotTabletWide, kSkinShotDesktop];

/// The base each sheet route opens over, for its "sheet over its base" presentation.
const _sheetBase = {
  ScreenId.feature: ScreenId.library,
  ScreenId.featureByFollow: ScreenId.library,
  ScreenId.recap: ScreenId.feature,
  ScreenId.circleMember: ScreenId.circle,
  ScreenId.profileNew: ScreenId.profiles,
  ScreenId.profileEdit: ScreenId.profiles,
};

const _special = {ScreenId.reader, ScreenId.readAll, ScreenId.novel};

class _SolidPlatform extends MmPlatform {
  _SolidPlatform() : super(channel: const MethodChannel('mm/platform-shots'));
  @override
  Future<bool> reduceTransparency() async => true;
}

void _mocks(WidgetTester t) {
  final m = t.binding.defaultBinaryMessenger;
  m.setMockMethodCallHandler(const MethodChannel('gaimon'), (_) async => null);
  m.setMockMethodCallHandler(const MethodChannel('dev.fluttercommunity.plus/connectivity_status'), (_) async => null);
  m.setMockMethodCallHandler(const MethodChannel('dev.fluttercommunity.plus/connectivity'), (_) async => <String>['wifi']);
  for (final c in const ['dev.fluttercommunity.plus/sensors/method', 'dev.fluttercommunity.plus/sensors/accelerometer', 'dev.fluttercommunity.plus/sensors/user_accel', 'dev.fluttercommunity.plus/sensors/gyroscope']) {
    m.setMockMethodCallHandler(MethodChannel(c), (_) async => null);
  }
  m.setMockMessageHandler('dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle', (_) async => const StandardMessageCodec().encodeMessage(<Object?>[null]));
  addTearDown(() {
    m.setMockMethodCallHandler(const MethodChannel('gaimon'), null);
    m.setMockMessageHandler('dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle', null);
  });
}

Future<void> _covers(WidgetTester t) async {
  final out = <String, Uint8List>{};
  await t.runAsync(() async {
    for (var i = 1; i <= 12; i++) {
      out['/covers/$i.png'] = await ShotCoverArt(title: kGlassQaTitles[(i - 1) % kGlassQaTitles.length], seed: i).toPng(width: 240, height: 360);
    }
  });
  addShotCovers(out);
}

/// Rasterises [boundary] and writes `<MM_PROOF_DIR>/<name>.png` (or discards without it). Returns the path or null.
Future<String?> _snap(WidgetTester t, Finder boundary, String name, double ratio) async {
  final dir = proofDir;
  if (dir == null) {
    final b = t.renderObject<RenderRepaintBoundary>(boundary);
    await t.runAsync(() async => (await b.toImage(pixelRatio: ratio)).dispose());
    return null;
  }
  final path = '$dir/$name.png';
  await writeShot(t, boundary, path, pixelRatio: ratio);
  return path;
}

Future<void> _end(WidgetTester t, GlassQaRig? rig) async {
  if (rig != null) {
    await disposeGlassQa(t, rig);
  } else {
    await t.pumpWidget(const SizedBox.shrink());
    await t.pump(const Duration(seconds: 12));
  }
}

/// Mounts a Glass screen at [size] and returns the rig, or null for the three reader screens (their own rigs, demo pages).
Future<GlassQaRig?> _open(
  WidgetTester t,
  GlassQaScreen s,
  SkinShotSize size, {
  double textScale = 1,
  bool reduced = false,
  bool highContrast = false,
  bool bold = false,
  bool solid = false,
  Map<String, Object> prefs = const {},
  ShelfLibrary? lib,
  bool settle = true,
  bool accessible = false,
}) async {
  _mocks(t);
  await _covers(t);
  if (_special.contains(s.id)) {
    final demo = DemoPages.load();
    final artBytes = {...demo.bytes('c1', demo: 2), ...demo.bytes('c2'), ...demo.bytes('c3', demo: 2)};
    addShotCovers(artBytes);
    if (s.id == ScreenId.novel) {
      await pumpGlassNovel(t, size: size.logical, padding: size.padding, textScale: textScale, reduced: reduced, boldText: bold, boundaryKey: kSkinShotKey);
    } else {
      await pumpGlassReader(t,
          size: size.logical,
          padding: size.padding,
          origin: s.id == ScreenId.readAll ? GlassReaderOrigin.readAll : GlassReaderOrigin.manifest,
          chapters: {
            'c1': demo.chapter('c1', demo: 2, title: 'Chapter 142', next: 'c2'),
            'c2': demo.chapter('c2', title: 'Chapter 143', prev: 'c1', next: 'c3'),
            'c3': demo.chapter('c3', demo: 2, title: 'Chapter 144', prev: 'c2'),
          },
          extra: [readerRepositoryProvider.overrideWithValue(GlassQaReader(Recorder()))],
          mockPathProvider: false);
    }
    await pumpUntilCoversLoad(t, rounds: 8);
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
    await settleReader(t, ms: 900);
    return null;
  }
  final rig = await pumpGlassQa(
    t,
    s,
    size: size.logical,
    padding: size.padding,
    textScale: textScale,
    reduced: reduced,
    highContrast: highContrast,
    boldText: bold,
    accessible: accessible,
    prefs: prefs,
    coverArt: true,
    lib: lib,
    mockPlugins: false,
    settle: settle,
    boundaryKey: kSkinShotKey,
    extra: [if (solid) mmPlatformProvider.overrideWithValue(_SolidPlatform())],
  );
  if (settle) await pumpUntilCoversLoad(t, rounds: 6);
  return rig;
}

Finder get _shotBoundary => find.byKey(kSkinShotKey);

void mobile45Shots() {
  group('screens', () {
    for (final s in kGlassQaScreens) {
      glassQaWidgets('${s.id.id} at the five proof sizes', (t) async {
        for (final size in _mainSizes) {
          final rig = await _open(t, s, size);
          await _snap(t, _shotBoundary, 'glass-${s.id.id}-${size.label}', size.pixelRatio);
          await _end(t, rig);
          t.view.reset();
        }
      }, timeout: const Timeout(Duration(minutes: 4)));
    }
    for (final id in _sheetBase.keys) {
      glassQaWidgets('${id.id} as a sheet over its base', (t) async {
        for (final size in _mainSizes) {
          final base = kGlassQaScreens.firstWhere((e) => e.id == _sheetBase[id]);
          final target = kGlassQaScreens.firstWhere((e) => e.id == id);
          final rig = (await _open(t, base, size))!;
          unawaited(rig.shell.router.push<void>(target.location));
          for (var i = 0; i < 14; i++) {
            await t.pump(const Duration(milliseconds: 150));
          }
          await _snap(t, _shotBoundary, '${id.id}-sheet-${size.name}', size.pixelRatio);
          await _end(t, rig);
          t.view.reset();
        }
      }, timeout: const Timeout(Duration(minutes: 4)));
    }
  });

  group('a11y', () {
    for (final s in kGlassQaScreens) {
      glassQaWidgets('${s.id.id}: reduced, solid, contrast, bold, legible (OS path and in-app switch)', (t) async {
        final mismatches = <String>[];
        final dir = proofDir;
        Future<String?> one(String variant, {bool os = true}) async {
          final rig = await _open(t, s, _phone1,
              reduced: os && variant == 'reduced',
              solid: os && variant == 'solid',
              highContrast: os && variant == 'contrast',
              bold: variant == 'bold',
              prefs: {
                if (!os && variant == 'reduced') 'mm.a11y.p1.reduceMotion': true,
                if (!os && variant == 'solid') 'mm.a11y.p1.solidGlass': true,
                if (!os && variant == 'contrast') 'mm.a11y.p1.increaseContrast': true,
                if (variant == 'legible') 'mm.a11y.p1.hyperlegible': true,
              });
          final path = await _snap(t, _shotBoundary, os ? '${s.id.id}-$variant-phone' : 'inapp/${s.id.id}-$variant-phone', 0.75);
          await _end(t, rig);
          t.view.reset();
          return path;
        }

        for (final v in const ['reduced', 'solid', 'contrast', 'bold', 'legible']) {
          final os = await one(v);
          if (v == 'bold' || v == 'legible' || dir == null) continue;
          final app = await one(v, os: false);
          if (os == null || app == null) continue;
          final osBytes = await rawRgba(t, os);
          if (!listEquals(osBytes, await rawRgba(t, app))) {
            // A second OS-path capture tells a real difference from an animation caught at another moment.
            final again = await one(v);
            if (again != null && listEquals(osBytes, await rawRgba(t, again))) {
              mismatches.add('${s.id.id}-$v');
            } else {
              debugPrint('A11Y non-deterministic ${s.id.id}-$v');
            }
          }
        }
        expect(mismatches, isEmpty, reason: 'the in-app switch must give the OS-path capture pixel for pixel');
      }, timeout: const Timeout(Duration(minutes: 4)));
    }
  });

  group('textscale', () {
    for (final s in kGlassQaScreens) {
      glassQaWidgets('${s.id.id} at 1.0, 1.3 and 2.0', (t) async {
        for (final scale in const [1.0, 1.3, 2.0]) {
          final rig = await _open(t, s, _phone1, textScale: scale);
          await _snap(t, _shotBoundary, '${s.id.id}-$scale-phone', 1.0);
          await _end(t, rig);
          t.view.reset();
        }
      }, timeout: const Timeout(Duration(minutes: 4)));
    }
  });

  group('states', () {
    // The states the contract defines for screens that read the library: loading, ready, empty, error. The other screens' states are
    // asserted by `primitives/lists_states_*` and each screen's own tests.
    const ids = [ScreenId.library, ScreenId.history, ScreenId.bookmarks, ScreenId.collections, ScreenId.updates, ScreenId.downloads, ScreenId.picks, ScreenId.tonight];
    for (final id in ids) {
      glassQaWidgets('${id.id}: loading, empty, error at the phone and the tablet', (t) async {
        final s = kGlassQaScreens.firstWhere((e) => e.id == id);
        for (final size in [_phone1, _tablet1]) {
          for (final state in const ['loading', 'empty', 'error']) {
            final rig = await _open(t, s, size,
                settle: state != 'loading', lib: state == 'empty' ? ShelfLibrary(all: const []) : (state == 'error' ? ShelfLibrary(all: [shelfSeries(1)], failList: true) : null));
            await _snap(t, _shotBoundary, '${id.id}-$state-${size.name}', 1.0);
            await _end(t, rig);
            t.view.reset();
          }
        }
      }, timeout: const Timeout(Duration(minutes: 4)));
    }
  });

  group('pairs', () {
    for (final s in kGlassQaScreens.where((e) => !_special.contains(e.id))) {
      glassQaWidgets('${s.id.id}: Cinematic left, Glass right', (t) async {
        final tmp = Directory.systemTemp.createTempSync('mm-pairs-').path;
        final cs = cine.kQaScreens.firstWhere((e) => e.id == s.id);
        final key = GlobalKey(debugLabel: 'pair-cine');
        t.view
          ..physicalSize = _phone1.logical
          ..devicePixelRatio = 1;
        final crig = await cine.pumpQaScreen(t, cs, size: _phone1.logical, boundaryKey: key);
        final left = '$tmp/cine.png';
        await writeShot(t, find.byKey(key), left, pixelRatio: 1.0);
        await cine.disposeQa(t, crig);
        t.view.reset();
        final grig = await _open(t, s, _phone1);
        final right = '$tmp/glass.png';
        await writeShot(t, _shotBoundary, right, pixelRatio: 1.0);
        await _end(t, grig);
        final dir = proofDir;
        if (dir != null) await composeSideBySide(t, left, right, '$dir/${s.id.id}.png');
      }, timeout: const Timeout(Duration(minutes: 4)));
    }
  });

  group('calibration', () {
    glassQaWidgets('Settings > Diagnostics > Glass calibration at 390 x 844 @3, with 4x crops of the T2 button and the T4 menu', (t) async {
      final dir = proofDir;
      final rig = (await _open(t, GlassQaScreen(ScreenId.settings, '/dev/glass/calibration'), _phone))!;
      await t.pump(const Duration(seconds: 2));
      final path = await _snap(t, _shotBoundary, 'calibration-flutter-harness-phone', 3.0);
      if (dir != null && path != null) {
        final top = '$dir/calibration-flutter-harness.png';
        File(path).renameSync(top);
        Future<void> crop(String label, String name) async {
          final r = t.getRect(find.byWidgetPredicate((w) => w is SkinGlass && w.debugLabel == label).first);
          await cropScaled(t, top, Rect.fromLTWH((r.left - 16) * 3, (r.top - 16) * 3, (r.width + 32) * 3, (r.height + 32) * 3), 4, '$dir/calibration/$name.png');
        }

        await crop('calibration T2', 't2-button-4x');
        await crop('calibration T4', 't4-menu-4x');
      }
      await _end(t, rig);
    });
  });

  group('float', () {
    // The five UIs of the 12.5 "Float" set at 440 x 956 @3, for the side-by-side with the web's Playwright frames.
    Future<void> frame(WidgetTester t, String name, Finder boundary) => _snap(t, boundary, name, 3.0);

    glassQaWidgets('1 Home on the demo covers', (t) async {
      _mocks(t);
      final paths = <String>{};
      void walk(Object? v) {
        if (v is Map) {
          for (final e in v.entries) {
            if (e.key == 'cover_url' && e.value is String) paths.add(Uri.parse(e.value as String).path);
            walk(e.value);
          }
        } else if (v is List) {
          v.forEach(walk);
        }
      }

      for (final f in Directory('test/fixtures/home').listSync().whereType<File>().where((f) => f.path.endsWith('.json'))) {
        walk(jsonDecode(f.readAsStringSync()));
      }
      final out = <String, Uint8List>{};
      await t.runAsync(() async {
        var i = 0;
        for (final p in paths) {
          out[p] = await ShotCoverArt(title: kGlassQaTitles[i % kGlassQaTitles.length], seed: i++).toPng(width: 240, height: 360);
        }
      });
      addShotCovers(out);
      final s = await openShell(t, _phoneMax, extra: homeOverrides(homeRepoOf('ready'), unread: 0), settle: false);
      for (var i = 0; i < 8; i++) {
        await s.settle(600);
      }
      await pumpUntilCoversLoad(t, rounds: 20);
      await frame(t, 'float-1-home', _shotBoundary);
      await t.pumpWidget(const SizedBox.shrink());
      await t.pump(const Duration(minutes: 11));
    }, timeout: const Timeout(Duration(minutes: 3)));

    glassQaWidgets('2 the manga reader mid-chapter with the chrome shown', (t) async {
      final rig = await _open(t, kGlassQaScreens.firstWhere((e) => e.id == ScreenId.reader), _phoneMax);
      await frame(t, 'float-2-reader', _shotBoundary);
      await _end(t, rig);
    }, timeout: const Timeout(Duration(minutes: 3)));

    glassQaWidgets('4 the Wrapped cover card', (t) async {
      final rig = await _open(t, kGlassQaScreens.firstWhere((e) => e.id == ScreenId.annual), _phoneMax);
      await frame(t, 'float-4-wrapped', _shotBoundary);
      await _end(t, rig);
    }, timeout: const Timeout(Duration(minutes: 3)));

    glassQaWidgets('5 the Circle with the second profile\'s activity', (t) async {
      final rig = await _open(t, kGlassQaScreens.firstWhere((e) => e.id == ScreenId.circle), _phoneMax);
      await frame(t, 'float-5-circle', _shotBoundary);
      await _end(t, rig);
    }, timeout: const Timeout(Duration(minutes: 3)));
  });
}
