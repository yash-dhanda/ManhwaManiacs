// ignore_for_file: require_trailing_commas
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_view.dart';
import 'package:manhwamaniacs/features/reader/screens/reader_screen.dart';
import 'package:manhwamaniacs/features/sources/screens/source_reader_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/router.dart' show cineRootKey;
import 'package:manhwamaniacs/skins/cinematic/screens/discover/genre_grid.dart';
import 'package:manhwamaniacs/skins/contract.g.dart' show Routes;
import 'package:manhwamaniacs/skins/skins.dart';

import 'release_rig.dart';

/// The navigation half of the release checks, in the real app of each skin: every main tab and back (iOS edge swipe), both
/// reader entry points open, take the double-tap menu and close, and the 18+ gate holds on Discover's genre AI grid.

final _tabs = {
  SkinId.cinematic: [Routes.tonight(), Routes.library(), Routes.discover(), Routes.downloads(), Routes.indexHub()],
  SkinId.glass: [Routes.tonight(), Routes.library(), Routes.sources(), Routes.indexHub()],
};

Finder get _series => find.byWidgetPredicate((w) => const {'FeatureScreen', 'GlassFeatureScreen'}.contains(w.runtimeType.toString()));

NavigatorState _nav(WidgetTester t) => t.state<NavigatorState>(find.byType(Navigator).first);

Route<dynamic>? _top(NavigatorState nav) {
  Route<dynamic>? top;
  nav.popUntil((r) {
    top = r;
    return true;
  });
  return top;
}

/// Runs [go], then frames until the top route's transition is done; a frozen one never is.
Future<void> _step(WidgetTester t, String label, FutureOr<void> Function() go) async {
  await go();
  var frames = 0;
  while (frames < 150) {
    await t.pump(const Duration(milliseconds: 16));
    frames++;
    final top = _top(_nav(t));
    if (frames > 4 && (top is! TransitionRoute || top.animation!.isCompleted) && !_nav(t).userGestureInProgress) break;
  }
  expect(t.takeException(), isNull, reason: label);
  expect(frames, lessThan(150), reason: '$label: the transition never finished');
  await settle(t, ms: 600);
}

/// A finger from the left edge across most of the width, at a finger's pace.
Future<void> _edgeSwipeBack(WidgetTester t) async {
  final g = await t.startGesture(const Offset(4, 420));
  for (var i = 0; i < 30; i++) {
    await g.moveBy(const Offset(10, 0));
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
}

ReaderEngine _engine(WidgetTester t) => t.widget<ReaderEngineView>(find.byType(ReaderEngineView)).controller;

/// The engine's tap classifier reads the wall clock: real gaps keep two taps apart or together.
Future<void> _tap(WidgetTester t, {required bool double}) async {
  await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 350)));
  await t.tapAt(const Offset(195, 422));
  if (double) {
    await t.pump(const Duration(milliseconds: 60));
    await t.tapAt(const Offset(195, 422));
  }
  await settle(t, ms: 700);
}

void main() {
  for (final skin in const [SkinId.cinematic, SkinId.glass]) {
    releaseWidgets('${skin.name}: every main tab, a page pushed on it and an edge swipe back, twice', (t) async {
      final rig = await pumpRelease(t, skin: skin);
      for (var lap = 0; lap < 2; lap++) {
        for (final tab in _tabs[skin]!) {
          await _step(t, '$lap $tab', () => rig.router.go(tab));
          expect(rig.at, tab);
          await _step(t, '$lap $tab series', () => unawaited(rig.router.push<void>(Routes.feature('demo', 'k'))));
          expect(rig.at, Routes.feature('demo', 'k'));
          await _step(t, '$lap $tab back', () => _edgeSwipeBack(t));
          expect(rig.at, tab, reason: '$lap: the swipe went back to $tab');
          expect(_nav(t).userGestureInProgress, isFalse);
          await settle(t, ms: 600);
          expect(_series, findsNothing, reason: '$lap $tab: the popped series page was disposed');
        }
      }
      await disposeRelease(t);
    });

    releaseWidgets('${skin.name}: the library reader and the source reader open, a tap opens and closes the menu, and they close', (t) async {
      final rig = await pumpRelease(t, skin: skin, route: Routes.library());
      for (final (path, entry, swipe) in [
        (Routes.reader('demo', 'k', 'ch-1'), ReaderScreen, true),
        ('/sources/demo/series/k/chapters/ch-1/read', SourceReaderScreen, false),
      ]) {
        await _step(t, 'open $path', () => unawaited(rig.router.push<void>(path)));
        await settle(t, ms: 1500);
        expect(find.byType(entry), findsOneWidget, reason: path);
        _engine(t).hideChrome();
        await settle(t, ms: 700);
        expect(_engine(t).value.chromeVisible, isFalse);
        // 'Open menu with' Tap, the default: one tap opens, another closes, then it opens again.
        await _tap(t, double: false);
        expect(_engine(t).value.chromeVisible, isTrue, reason: '$path: a tap opens');
        await _tap(t, double: false);
        expect(_engine(t).value.chromeVisible, isFalse, reason: '$path: a tap closes');
        await _tap(t, double: false);
        expect(_engine(t).value.chromeVisible, isTrue, reason: '$path: a tap opens again');
        await _step(t, 'close $path', () => swipe ? _edgeSwipeBack(t) : rig.router.pop());
        await settle(t); // the popped reader's own exit
        expect(find.byType(entry), findsNothing, reason: '$path closed');
        expect(rig.at, Routes.library());
      }
      await disposeRelease(t);
    });
  }

  for (final open in const [false, true]) {
    releaseWidgets("Discover's genre AI grid ${open ? 'shows' : 'hides'} an 18+ title with the gate ${open ? 'open' : 'closed'}", (t) async {
      await pumpRelease(t, skin: SkinId.cinematic, route: Routes.discover(), gateOpen: open, genreItems: const [
        WorldItem(anilistId: 1, title: 'Salt and Iron'),
        WorldItem(anilistId: 2, title: 'Night Garden', isAdult: true),
      ]);
      unawaited(cineRootKey.currentState!.push(MaterialPageRoute<void>(builder: (_) => const GenreGridScreen(genre: 'Romance'))));
      await settle(t, ms: 2000);
      expect(find.textContaining('Salt and Iron', findRichText: true), findsWidgets);
      expect(find.textContaining('Night Garden', findRichText: true), open ? findsWidgets : findsNothing);
      expectSkinText(find.byType(GenreGridScreen));
      await disposeRelease(t);
    });
  }
}
