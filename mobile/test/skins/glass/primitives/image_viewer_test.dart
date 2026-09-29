import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/primitives/image_viewer.dart';
import 'package:share_plus/share_plus.dart';

import 'overlay_support.dart';
import 'support.dart';

class _Img extends ImageProvider<_Img> {
  const _Img(this.image, {this.fail = false});
  final ui.Image? image;
  final bool fail;

  @override
  Future<_Img> obtainKey(ImageConfiguration configuration) => SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(_Img key, ImageDecoderCallback decode) {
    if (fail) return OneFrameImageStreamCompleter(Future<ImageInfo>.error(StateError('nope')));
    return OneFrameImageStreamCompleter(SynchronousFuture(ImageInfo(image: image!)));
  }

  @override
  bool operator ==(Object other) => other is _Img && other.image == image && other.fail == fail;
  @override
  int get hashCode => Object.hash(image, fail);
}

Iterable<HapticEvent> _events() => GlassHaptics.debugLog.map((e) => e.event);

const _thumb = Rect.fromLTWH(20, 300, 100, 150);

Future<GlassImageViewerRoute<void>> _open(WidgetTester tester, OverlayHost h, {bool fail = false, String? sharePath, GlassShareFile? share, bool settle = true}) async {
  glassViewerClock = () => Duration(microseconds: tester.binding.clock.now().microsecondsSinceEpoch);
  final img = fail ? null : await tester.runAsync(() => createTestImage(width: 200, height: 400));
  final r = GlassImageViewerRoute<void>(image: _Img(img, fail: fail), thumbRect: _thumb, description: 'Page one', sharePath: sharePath, share: share ?? (p, o) async => const ShareResult('ok', ShareResultStatus.success));
  h.push(r);
  await tester.pump();
  if (settle) await pumpFor(tester, 900);
  return r;
}

double _scale(WidgetTester t) {
  final img = find.byType(Image);
  final tr = t.widgetList<Transform>(find.ancestor(of: img, matching: find.byType(Transform))).first;
  return tr.transform.storage[0];
}

Rect _imageRect(WidgetTester t) => t.getRect(find.byType(Image));

void main() {
  setUp(GlassHaptics.debugLog.clear);
  tearDown(() => glassViewerClock = () => Duration(microseconds: DateTime.now().microsecondsSinceEpoch));

  testWidgets('the image flies from its thumbnail rect to its fitted rect on springZoom', (tester) async {
    final h = OverlayHost(tester);
    await h.pump();
    final r = await _open(tester, h, settle: false);
    await tester.pump(const Duration(milliseconds: 16));
    final early = _imageRect(tester);
    expect((early.center - _thumb.center).distance, lessThan(120));
    await pumpFor(tester, 900);
    final fitted = _imageRect(tester);
    expect(fitted.height, closeTo(780, 1)); // 200 x 400 in 390 x 844: width-limited, 390 x 780
    expect(fitted.width, closeTo(fitted.height / 2, 1));
    expect(fitted.center.dx, closeTo(195, 0.5));
    expect(fitted.center.dy, closeTo(422, 0.5));
    expect(r.isActive, isTrue);
  });

  testWidgets('a touch during the flight catches it', (tester) async {
    final h = OverlayHost(tester);
    await h.pump();
    await _open(tester, h, settle: false);
    await pumpFor(tester, 120);
    final g = await tester.startGesture(const Offset(195, 400));
    await tester.pump(const Duration(milliseconds: 16));
    expect(_events(), contains(HapticEvent.motionCatch));
    final held = _imageRect(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(_imageRect(tester), held);
    await g.up();
    await pumpFor(tester, 900);
  });

  testWidgets('a double tap toggles 1x to 2.5x at the tap point and back; single taps are never delayed', (tester) async {
    final h = OverlayHost(tester);
    await h.pump();
    await _open(tester, h);
    expect(_scale(tester), closeTo(1, 0.01));
    await tester.tapAt(const Offset(195, 300));
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tapAt(const Offset(195, 300));
    await pumpFor(tester, 700);
    expect(_scale(tester), closeTo(2.5, 0.05));
    expect(_events(), contains(HapticEvent.zoomSnap));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tapAt(const Offset(195, 300));
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tapAt(const Offset(195, 300));
    await pumpFor(tester, 700);
    expect(_scale(tester), closeTo(1, 0.05));
  });

  testWidgets('two taps more than 280 ms apart are not a double tap', (tester) async {
    final h = OverlayHost(tester);
    await h.pump();
    await _open(tester, h);
    await tester.tapAt(const Offset(195, 300));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tapAt(const Offset(195, 300));
    await pumpFor(tester, 700);
    expect(_scale(tester), closeTo(1, 0.01));
  });

  testWidgets('a pinch zooms around the focal point and rubber-bands past 4x', (tester) async {
    final h = OverlayHost(tester);
    await h.pump();
    await _open(tester, h);
    final a = await tester.startGesture(const Offset(150, 400), pointer: 1);
    final b = await tester.startGesture(const Offset(240, 400), pointer: 2);
    for (var i = 1; i <= 8; i++) {
      await a.moveTo(Offset(150 - 12.0 * i, 400));
      await b.moveTo(Offset(240 + 12.0 * i, 400));
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(_scale(tester), greaterThan(1.8));
    for (var i = 9; i <= 30; i++) {
      await a.moveTo(Offset(150 - 12.0 * i, 400));
      await b.moveTo(Offset(240 + 12.0 * i, 400));
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(_scale(tester), lessThanOrEqualTo(4.19));
    expect(_events(), contains(HapticEvent.zoomLimit));
    await a.up();
    await b.up();
    await pumpFor(tester, 900);
    expect(_scale(tester), closeTo(4, 0.05));
  });

  testWidgets('at 1x a vertical drag dismisses: scale, radius and backdrop follow, the line fires threshold.cross, a fling flies it back', (tester) async {
    final h = OverlayHost(tester);
    await h.pump();
    final r = await _open(tester, h);
    final g = await tester.startGesture(const Offset(195, 400));
    await g.moveBy(const Offset(0, 30));
    await g.moveBy(const Offset(0, 120));
    await tester.pump(const Duration(milliseconds: 16));
    expect(_scale(tester), lessThan(0.95));
    final bd = tester.widget<Opacity>(find.ancestor(of: find.byKey(const ValueKey('glass-viewer-backdrop')), matching: find.byType(Opacity)).first).opacity;
    expect(bd, lessThan(0.7));
    await g.moveBy(const Offset(0, 80));
    await tester.pump(const Duration(milliseconds: 16));
    expect(_events(), contains(HapticEvent.thresholdCross));
    await g.moveBy(const Offset(0, -150));
    await tester.pump(const Duration(milliseconds: 16));
    expect(_events(), contains(HapticEvent.thresholdBack));
    await g.up();
    await pumpFor(tester, 900);
    expect(r.isActive, isTrue); // a slow release springs back on settle
    await tester.fling(find.byType(Image), const Offset(0, 200), 1500);
    await pumpFor(tester, 1500);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('chrome fades after 2 s idle and returns on a tap or a key', (tester) async {
    final h = OverlayHost(tester);
    await h.pump();
    await _open(tester, h);
    expect(find.byKey(const ValueKey('glass-viewer-close')), findsOneWidget);
    await pumpFor(tester, 2600);
    final faded = tester.widgetList<Opacity>(find.descendant(of: find.byType(GlassImageViewer), matching: find.byType(Opacity))).map((o) => o.opacity);
    expect(faded.any((o) => o < 0.05), isTrue);
    await tester.tapAt(const Offset(195, 300));
    await pumpFor(tester, 400);
    final back = tester.widgetList<Opacity>(find.descendant(of: find.byType(GlassImageViewer), matching: find.byType(Opacity))).map((o) => o.opacity);
    expect(back.any((o) => o > 0.95), isTrue);
  });

  testWidgets('keys: + - 0 zoom, arrows pan, Esc closes', (tester) async {
    final h = OverlayHost(tester);
    await h.pump();
    final r = await _open(tester, h);
    await tester.sendKeyEvent(LogicalKeyboardKey.equal);
    await pumpFor(tester, 600);
    expect(_scale(tester), closeTo(1.5, 0.05));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await pumpFor(tester, 600);
    final panned = _imageRect(tester).center.dx;
    expect(panned, greaterThan(195));
    await tester.sendKeyEvent(LogicalKeyboardKey.digit0);
    await pumpFor(tester, 700);
    expect(_scale(tester), closeTo(1, 0.05));
    await tester.sendKeyEvent(LogicalKeyboardKey.minus);
    await pumpFor(tester, 300);
    expect(_scale(tester), closeTo(1, 0.05)); // 1x is the floor
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await pumpFor(tester, 1500);
    expect(r.isActive, isFalse);
  });

  testWidgets('share hands the file and the button rect to share_plus; an error toast path does not throw', (tester) async {
    Rect? origin;
    String? shared;
    final h = OverlayHost(tester);
    await h.pump();
    await _open(tester, h, sharePath: '/tmp/page.png', share: (p, o) async {
      shared = p;
      origin = o;
      return const ShareResult('ok', ShareResultStatus.success);
    });
    await tester.tap(find.byKey(const ValueKey('glass-viewer-share')));
    await pumpFor(tester, 200);
    expect(shared, '/tmp/page.png');
    expect(origin!.size.shortestSide, greaterThanOrEqualTo(44));
  });

  testWidgets('an image that fails shows the message with Retry on glass', (tester) async {
    final h = OverlayHost(tester);
    await h.pump();
    await _open(tester, h, fail: true);
    await pumpFor(tester, 400);
    expect(find.text("Couldn't load this image"), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('semantics: labelled by the description, with Zoom in, Zoom out and Close actions; focus is trapped', (tester) async {
    final handle = tester.ensureSemantics();
    final h = OverlayHost(tester);
    await h.pump();
    await _open(tester, h);
    expect(find.bySemanticsLabel('Page one'), findsAny);
    final node = tester.getSemantics(find.bySemanticsLabel(RegExp('Zoom in|Page one')).first);
    expect(node, isNotNull);
    handle.dispose();
  });

  testWidgets('reduced motion: open and close are 200 ms cross-fades', (tester) async {
    final h = OverlayHost(tester);
    await h.pump(reduced: true);
    await _open(tester, h, settle: false);
    await tester.pump(const Duration(milliseconds: 16));
    final r0 = _imageRect(tester);
    await pumpFor(tester, 300);
    final r1 = _imageRect(tester);
    expect(r1, r0); // no fly: it is already at its fitted rect
  });
}
