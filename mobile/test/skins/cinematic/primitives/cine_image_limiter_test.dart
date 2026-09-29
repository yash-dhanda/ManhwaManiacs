import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/network/request_limiter.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _url = 'https://example.test/sources/s/series/a/cover';

void main() {
  final oldProbe = CineImage.cacheProbe, oldBuilder = CineImage.providerBuilder;
  var built = <String>[];
  late DateTime clock;

  setUp(() {
    built = [];
    clock = DateTime(2026);
    CineImage.providerBuilder = (url, headers) {
      built.add(url);
      return MemoryImage(Uint8List.fromList(const [0]));
    };
  });
  tearDown(() {
    CineImage.cacheProbe = oldProbe;
    CineImage.providerBuilder = oldBuilder;
  });

  Future<RequestLimiter> takenLimiter() async {
    final l = RequestLimiter(capacity: 1, now: () => clock);
    await l.acquire(RequestPriority.p1); // the only slot in the window is gone
    return l;
  }

  Future<void> host(WidgetTester t, RequestLimiter limiter, {Widget? child}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await t.pumpWidget(ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs), sourcesLimiterProvider.overrideWithValue(limiter)],
      child: MaterialApp(
        theme: ThemeData(extensions: const [cinematicTokens]),
        home: Scaffold(body: SizedBox(width: 120, height: 180, child: child ?? const CineImage(url: _url, title: 'Salt and Iron'))),
      ),
    ),);
  }

  testWidgets('a remote cover waits for a P2 grant', (t) async {
    CineImage.cacheProbe = (_) async => false;
    final limiter = await takenLimiter();
    await host(t, limiter);
    await t.pump(const Duration(milliseconds: 200));
    expect(built, isEmpty);
    clock = clock.add(const Duration(seconds: 61));
    await t.pump(const Duration(seconds: 61));
    await t.pump();
    expect(built, hasLength(1));
    expect(built.single, contains('?w=')); // snapped width requested
  });

  testWidgets('a cache hit never asks the limiter', (t) async {
    CineImage.cacheProbe = (_) async => true;
    final limiter = await takenLimiter();
    await host(t, limiter);
    await t.pump(const Duration(milliseconds: 50));
    expect(built, hasLength(1));
  });

  testWidgets('disposal before the grant cancels the wait', (t) async {
    CineImage.cacheProbe = (_) async => false;
    final limiter = await takenLimiter();
    await host(t, limiter);
    await t.pump(const Duration(milliseconds: 100));
    await host(t, limiter, child: const SizedBox());
    clock = clock.add(const Duration(seconds: 61));
    await t.pump(const Duration(seconds: 61));
    expect(built, isEmpty);
    // The slot is free for someone else: the cancelled waiter took none.
    expect(limiter.free(), 1);
  });

  testWidgets('asset covers skip the limiter and the cache', (t) async {
    var probed = false;
    CineImage.cacheProbe = (_) async {
      probed = true;
      return false;
    };
    final limiter = await takenLimiter();
    await host(t, limiter, child: const CineImage(url: 'assets/gallery/covers/01-salt-and-iron.webp'));
    await t.pump(const Duration(milliseconds: 50));
    expect(probed, isFalse);
    expect(built, isEmpty);
  });
}
