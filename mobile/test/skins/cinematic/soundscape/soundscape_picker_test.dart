import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/network/network_connectivity.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_profile_settings.dart';
import 'package:manhwamaniacs/features/reader/services/soundscape_files.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/soundscape/house_sound.dart';
import 'package:manhwamaniacs/skins/cinematic/soundscape/soundscape_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../feature/feature_test_support.dart' show featureTheme;

class _Files extends SoundscapeFiles {
  _Files(this.cached) : super(Dio());
  final bool cached;
  @override
  Future<bool> isCached(String id) async => cached;
  @override
  Future<File> soundscapeFile(String id) => throw StateError('not fetched in this test');
}

class _Net extends Fake implements NetworkConnectivity {
  _Net(this.online);
  final bool online;
  @override
  Future<bool> isOnline() async => online;
}

Future<void> _pump(WidgetTester tester, {required bool cached, required bool online, TargetPlatform platform = TargetPlatform.android}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 3000);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        soundscapeFilesProvider.overrideWithValue(_Files(cached)),
        networkConnectivityProvider.overrideWithValue(_Net(online)),
      ],
      child: MaterialApp(theme: featureTheme(platform), home: const Scaffold(body: SingleChildScrollView(child: SoundscapePicker()))),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('offline and uncached: every loop row reads "Available when you\'re online." and Hear is off', (tester) async {
    await _pump(tester, cached: false, online: false);
    expect(find.text("Available when you're online.", findRichText: true), findsNWidgets(8));
    for (final id in soundscapeIds) {
      final b = tester.widget<CineButton>(find.byKey(Key('hear-$id')));
      expect(b.onPressed, isNull, reason: id);
    }
  });

  testWidgets('cached or online: Hear is live on all eight loops', (tester) async {
    await _pump(tester, cached: true, online: false);
    expect(find.text("Available when you're online.", findRichText: true), findsNothing);
    for (final id in soundscapeIds) {
      expect(tester.widget<CineButton>(find.byKey(Key('hear-$id'))).onPressed, isNotNull, reason: id);
    }
  });

  testWidgets('OFF, MATCH THE MOOD and the loops are one radio group; a choice is saved for the profile', (tester) async {
    await _pump(tester, cached: true, online: true);
    expect(find.text('OFF', findRichText: true), findsOneWidget);
    expect(find.text('MATCH THE MOOD', findRichText: true), findsOneWidget);
    await tester.tap(find.text('Rain on glass', findRichText: true));
    await tester.pump(const Duration(milliseconds: 200));
    final c = ProviderScope.containerOf(tester.element(find.byType(SoundscapePicker)));
    expect(c.read(readerSettingsProvider).soundscape, 'rain-on-glass');
  });
}
