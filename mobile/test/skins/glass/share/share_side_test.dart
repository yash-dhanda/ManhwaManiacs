import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/platform/media_store.dart';
import 'package:manhwamaniacs/features/library/models/annual.dart';
import 'package:manhwamaniacs/skins/glass/parts/share/share_side.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/wrapped/share_card.dart';
import 'package:share_plus/share_plus.dart';

import '../../../screenshots/support/shot_network.dart';
import '../../../support/numbers_fixtures.dart';
import '../shell/shell_rig.dart';
import '../stats/stats_rig.dart';

class _Delegate implements GlassShareDelegate {
  _Delegate(this.result);
  final ShareResult result;
  final calls = <ShareParams>[];
  @override
  Future<ShareResult> share(ShareParams params) async {
    calls.add(params);
    return result;
  }
}

class _Media extends MediaStoreChannel {
  _Media(this.can);
  final bool can;
  final saved = <String>[];
  @override
  Future<bool> canSaveImage() async => can;
  @override
  Future<bool> saveImage(Uint8List bytes, String name) async {
    saved.add(name);
    return true;
  }
}

final _px = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');

Future<void> _real(WidgetTester t, bool Function() done) async {
  for (var i = 0; i < 400 && !done(); i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    await t.pump(const Duration(milliseconds: 16));
  }
}

Future<ShellRig> _openShareSide(WidgetTester t, _Delegate d, _Media m, {required bool android}) async {
  final rig = await pumpStats(
    t,
    FakeNumbers(annuals: {2026: Annual.fromJson(annualJson(partial: false))}),
    start: '/library/statistics/annual/2026',
    extra: [
      glassShareDelegateProvider.overrideWithValue(d),
      mediaStoreProvider.overrideWithValue(m),
      glassShareIsAndroidProvider.overrideWithValue(android),
      glassShareImageProvider.overrideWithValue((url) => MemoryImage(_px)),
    ],
  );
  await t.tapAt(const Offset(300, 420)); // card 2, Time
  for (var i = 0; i < 5; i++) {
    await t.pump(const Duration(milliseconds: 300));
  }
  await t.tap(find.text('Export'));
  await _real(t, () => false);
  return rig;
}

/// The toasts raised (the shell's host draws them; Wrapped is a root takeover above it).
List<String> _toasts(ShellRig r) => [for (final e in r.container.read(glassToastProvider)) e.spec.message];

/// Real async runs here (the image work), so the platform plugins the shell touches get quiet mocks.
void _quietPlugins() {
  final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final name in ['dev.fluttercommunity.plus/connectivity_status', 'dev.fluttercommunity.plus/connectivity']) {
    m.setMockMethodCallHandler(MethodChannel(name), (call) async => call.method == 'check' ? <String>['wifi'] : null);
    addTearDown(() => m.setMockMethodCallHandler(MethodChannel(name), null));
  }
}

void main() {
  setUp(setUpShotCoverCache);
  setUp(_quietPlugins);

  testWidgets('Android without MediaStore: no Save image; Share passes an origin; a dismissal is silent', (t) async {
    final d = _Delegate(const ShareResult('', ShareResultStatus.dismissed));
    final m = _Media(false);
    final rig = await _openShareSide(t, d, m, android: true);
    expect(find.text('Story'), findsOneWidget);
    expect(find.text('Save image'), findsNothing, reason: 'canSaveImage is false (API 24-28)');
    await t.tap(find.text('Share').last);
    await _real(t, () => d.calls.isNotEmpty);
    expect(d.calls, hasLength(1));
    final origin = d.calls.single.sharePositionOrigin;
    expect(origin, isNotNull);
    expect(origin!.isEmpty, isFalse);
    expect(d.calls.single.files!.single.mimeType, 'image/png');
    await t.pump(const Duration(milliseconds: 300));
    expect(_toasts(rig), isNot(contains('Shared')), reason: 'dismissed is silent');
    expect(find.text('Story'), findsOneWidget, reason: 'the side stays open');
    await t.pump(const Duration(minutes: 11));
  });

  testWidgets('Android 10+: Save image writes to Pictures/ManhwaManiacs', (t) async {
    final d = _Delegate(const ShareResult('', ShareResultStatus.success));
    final m = _Media(true);
    final rig = await _openShareSide(t, d, m, android: true);
    await t.tap(find.text('Save image'));
    await _real(t, () => m.saved.isNotEmpty);
    await t.pump(const Duration(milliseconds: 300));
    expect(m.saved, hasLength(1));
    expect(_toasts(rig), contains('Saved to Pictures/ManhwaManiacs'));
    await t.pump(const Duration(minutes: 11));
  });

  testWidgets('iOS: Save to Photos through the sheet toasts "Saved to Photos"', (t) async {
    final d = _Delegate(const ShareResult('com.apple.UIKit.activity.SaveToCameraRoll', ShareResultStatus.success));
    final rig = await _openShareSide(t, d, _Media(false), android: false);
    expect(find.text('Save image'), findsOneWidget, reason: 'iOS always offers it (the sheet)');
    await t.tap(find.text('Save image'));
    await _real(t, () => d.calls.isNotEmpty);
    await t.pump(const Duration(milliseconds: 300));
    expect(_toasts(rig), contains('Saved to Photos'));
    await t.pump(const Duration(minutes: 11));
  });
}
