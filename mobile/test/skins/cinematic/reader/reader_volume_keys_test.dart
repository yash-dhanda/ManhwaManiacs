import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/platform/native_bridge.dart';

import '../../../screenshots/support/shot_network.dart';
import 'reader_test_support.dart';

class _Bridge implements NativeBridge {
  // ignore: close_sinks
  final events = StreamController<VolumeKeyDirection>.broadcast();
  final calls = <bool>[];

  @override
  Future<void> setVolumeKeyNavEnabled(bool enabled) async => calls.add(enabled);
  @override
  Stream<VolumeKeyDirection> get volumeKeyEvents => events.stream;
  @override
  Future<DeviceMemoryInfo?> getDeviceMemoryInfo() async => null;
  @override
  Future<void> setHighRefreshRateEnabled(bool enabled) async {}
}

Future<void> _lifecycle(WidgetTester tester, List<AppLifecycleState> steps) async {
  for (final s in steps) {
    tester.binding.handleAppLifecycleStateChanged(s);
    await tester.pump();
  }
  await settleReader(tester, ms: 200);
}

void main() {
  setUpAll(setUpShotCoverCache);
  const k08 = {'settings_volume_key_navigation': true};

  testWidgets('K08 on, Android: enabled while resumed, off on pause, on again, volume down turns a page, off on dispose', (tester) async {
    final bridge = _Bridge();
    await pumpReader(tester, prefsValues: k08, extra: [nativeBridgeProvider.overrideWithValue(bridge)]);
    await settleReader(tester, ms: 500);
    expect(bridge.calls, [true]);
    expect(find.text('1 / 6'), findsOneWidget);

    bridge.events.add(VolumeKeyDirection.down);
    await settleReader(tester, ms: 900);
    expect(find.text('2 / 6'), findsOneWidget, reason: 'volume down is jumpToPage(n + 1)');
    bridge.events.add(VolumeKeyDirection.up);
    await settleReader(tester, ms: 900);
    expect(find.text('1 / 6'), findsOneWidget);

    await _lifecycle(tester, [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]);
    expect(bridge.calls.last, isFalse, reason: 'paused releases the volume keys');
    await _lifecycle(tester, [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]);
    expect(bridge.calls.last, isTrue, reason: 'resumed takes them back');

    await disposeReader(tester);
    expect(bridge.calls.last, isFalse, reason: 'leaving restores the volume');
    expect(bridge.calls.where((c) => c).length, 2);
  });

  testWidgets('K08 off: the reader never asks for the volume keys and a stray event does nothing', (tester) async {
    final bridge = _Bridge();
    await pumpReader(tester, extra: [nativeBridgeProvider.overrideWithValue(bridge)]);
    await settleReader(tester, ms: 500);
    bridge.events.add(VolumeKeyDirection.down);
    await settleReader(tester, ms: 900);
    expect(find.text('1 / 6'), findsOneWidget);
    await _lifecycle(tester, [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]);
    await _lifecycle(tester, [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]);
    expect(bridge.calls.where((c) => c), isEmpty);
    await disposeReader(tester);
  });

  testWidgets('iOS: nothing is enabled and nothing turns even with K08 on', (tester) async {
    final bridge = _Bridge();
    await pumpReader(tester, platform: TargetPlatform.iOS, prefsValues: k08, extra: [nativeBridgeProvider.overrideWithValue(bridge)]);
    await settleReader(tester, ms: 500);
    bridge.events.add(VolumeKeyDirection.down);
    await settleReader(tester, ms: 900);
    expect(bridge.calls.where((c) => c), isEmpty);
    expect(find.text('1 / 6'), findsOneWidget);
    await disposeReader(tester);
  });
}
