import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/network/cover_auto_retry.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _url = 'https://example.test/sources/s/series/a/cover';

/// Fails its first [failures] loads, then loads [image]. Like the real providers it evicts itself
/// from the image cache when a load fails, so a new `Image` resolving it loads again.
class _FlakyImage extends ImageProvider<_FlakyImage> {
  _FlakyImage(this.image, this.failures);
  final ui.Image image;
  int failures;
  int loads = 0;

  @override
  Future<_FlakyImage> obtainKey(ImageConfiguration configuration) => SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(_FlakyImage key, ImageDecoderCallback decode) {
    loads++;
    final fail = failures > 0;
    if (fail) failures--;
    return OneFrameImageStreamCompleter(
      Future<ImageInfo>(() {
        if (!fail) return ImageInfo(image: image.clone());
        scheduleMicrotask(() => PaintingBinding.instance.imageCache.evict(key));
        throw Exception('socket dropped');
      }),
    );
  }
}

void main() {
  final oldProbe = CineImage.cacheProbe, oldBuilder = CineImage.providerBuilder;
  tearDown(() {
    CineImage.cacheProbe = oldProbe;
    CineImage.providerBuilder = oldBuilder;
  });

  Future<_FlakyImage> host(WidgetTester t, {required int failures, Widget? child}) async {
    final image = (await t.runAsync(() => createTestImage(width: 4, height: 6)))!;
    final provider = _FlakyImage(image, failures);
    CineImage.cacheProbe = (_) async => true;
    CineImage.providerBuilder = (url, headers) => provider;
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await t.pumpWidget(ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        theme: ThemeData(extensions: const [cinematicTokens]),
        home: Scaffold(body: SizedBox(width: 120, height: 180, child: child ?? const CineImage(url: _url, title: 'Salt and Iron'))),
      ),
    ),);
    return provider;
  }

  final broken = find.byWidgetPredicate((w) => w is Semantics && w.properties.label == "Cover didn't load");

  Future<void> settle(WidgetTester t, [Duration d = const Duration(milliseconds: 100)]) async {
    await t.pump(d);
    await t.pump(d);
  }

  testWidgets('a cover that fails once loads on its own after the delay', (t) async {
    final provider = await host(t, failures: 1);
    await settle(t);
    expect(broken, findsOneWidget);
    expect(provider.loads, 1);

    await t.pump(kCoverAutoRetryDelay);
    await settle(t);
    expect(provider.loads, 2);
    expect(broken, findsNothing);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('a cover that fails twice keeps its placeholder and does not try a third time', (t) async {
    final provider = await host(t, failures: 2);
    await settle(t);
    await t.pump(kCoverAutoRetryDelay);
    await settle(t);
    expect(provider.loads, 2);
    expect(broken, findsOneWidget);

    await t.pump(kCoverAutoRetryDelay * 3);
    await settle(t);
    expect(provider.loads, 2);
    expect(broken, findsOneWidget);
  });

  testWidgets('leaving while the retry waits cancels it', (t) async {
    final provider = await host(t, failures: 1);
    await settle(t);
    expect(broken, findsOneWidget);

    await t.pumpWidget(const SizedBox());
    // The test ends with no pending timer or the framework fails it; the load must not come back either.
    await t.pump(kCoverAutoRetryDelay * 2);
    expect(provider.loads, 1);
  });

  testWidgets('a cover that loads at once is not touched', (t) async {
    final provider = await host(t, failures: 0);
    await settle(t);
    expect(broken, findsNothing);
    expect(provider.loads, 1);
  });
}
