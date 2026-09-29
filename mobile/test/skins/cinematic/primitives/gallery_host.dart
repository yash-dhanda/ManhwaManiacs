import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/gallery/primitives_gallery.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/test_overrides.dart';

/// Pumps the primitives gallery (or one [section]) at [size] under [scale] and [platform].
Future<void> pumpGallery(
  WidgetTester t, {
  Size size = const Size(390, 844),
  double scale = 1.0,
  bool reduced = false,
  String? section,
  TargetPlatform platform = TargetPlatform.iOS,
  List<Override> overrides = const [],
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs), authenticatedAuthOverride(), activeProfileOverride(), ...overrides],
      child: MaterialApp(
        theme: ThemeData(platform: platform),
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: reduced),
          child: app!,
        ),
        home: CinePrimitivesGalleryPage(section: section),
      ),
    ),
  );
  for (var i = 0; i < 6; i++) {
    await t.pump(const Duration(milliseconds: 120));
  }
}
