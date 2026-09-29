// ignore_for_file: require_trailing_commas, directives_ordering
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/cinematic_skin.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_rating_card.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/rating_card_slot.dart';

Future<void> _pump(WidgetTester t, Widget child, {bool reduced = false}) => t.pumpWidget(ProviderScope(
      child: MaterialApp(
        theme: CinematicSkin.baseTheme,
        builder: (c, w) => MediaQuery(data: MediaQuery.of(c).copyWith(disableAnimations: reduced), child: w!),
        home: Scaffold(body: Stack(children: [child, const CineRatingCardSlot()])),
      ),
    ),);

double _opacity(WidgetTester t) => t.widget<Opacity>(find.descendant(of: find.byType(CineRatingCard), matching: find.byType(Opacity)).first).opacity;

void main() {
  testWidgets('fades in over 480 ms, holds 3000 ms, fades out over 240 ms, then reports done', (t) async {
    var done = false;
    final said = <String>[];
    t.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, (m) async {
      final data = (m as Map?)?['data'] as Map?;
      if (data?['message'] is String) said.add(data!['message'] as String);
      return null;
    });
    addTearDown(() => t.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, null));
    await _pump(t, CineRatingCard(genres: const ['Violence', 'Smut'], onDone: () => done = true));
    // Sample every 20 ms and measure the three legs.
    final samples = <double>[];
    for (var ms = 0; ms < 4400 && !done; ms += 20) {
      await t.pump(const Duration(milliseconds: 20));
      if (!done) samples.add(_opacity(t));
    }
    expect(done, isTrue);
    final lastFull = samples.lastIndexWhere((o) => o > 0.99) * 20;
    final end = samples.length * 20;
    expect(samples.first, lessThan(0.7), reason: 'starts faded in from nothing');
    expect(samples.skip(25).take(100).every((o) => o > 0.999), isTrue, reason: 'fully in after the 480 ms fade');
    expect(lastFull, inInclusiveRange(3400, 3640), reason: '480 ms in + 3000 ms hold');
    expect(end - lastFull, inInclusiveRange(120, 340), reason: 'a 240 ms fade out');
    expect(said, ['Rated 18 plus: Violence, Sexual content']);
  });

  testWidgets('shows the certificate, 18+ and the descriptors on a paper box', (t) async {
    await _pump(t, const CineRatingCard(genres: ['Horror', 'Gore'], frozen: 1, announce: false));
    await t.pump();
    expect(find.text('18+'), findsOneWidget);
    expect(find.text('Gore · Horror'), findsOneWidget);
    expect(find.text('18'), findsOneWidget, reason: 'the certificate badge');
  });

  testWidgets('reduced motion: 150 ms fades', (t) async {
    var done = false;
    await _pump(t, CineRatingCard(genres: const ['x'], announce: false, onDone: () => done = true), reduced: true);
    var peak = 0.0;
    for (var ms = 0; ms < 4000 && !done; ms += 20) {
      await t.pump(const Duration(milliseconds: 20));
      if (!done) peak = _opacity(t) > peak ? _opacity(t) : peak;
    }
    expect(peak, closeTo(1, 0.01));
    expect(done, isTrue, reason: 'linear 150 ms fades, then gone');
  });
}
