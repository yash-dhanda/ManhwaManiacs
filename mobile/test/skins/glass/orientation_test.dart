import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/orientation.dart';

void main() {
  final calls = <List<Object?>>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemChrome.setPreferredOrientations') calls.add(call.arguments as List<Object?>);
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Future<void> pump(WidgetTester tester, Size size, {bool mounted = true}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData.fromView(tester.view),
        child: mounted ? const GlassOrientationScope(child: SizedBox()) : const SizedBox(),
      ),
    );
  }

  testWidgets('a phone is locked to portrait and released on leaving Glass', (tester) async {
    await pump(tester, const Size(390, 844));
    expect(calls.last, ['DeviceOrientation.portraitUp']);
    await pump(tester, const Size(390, 844), mounted: false);
    expect(calls.last, isEmpty);
  });

  testWidgets('a rotated phone is still a phone (shorter side)', (tester) async {
    await pump(tester, const Size(844, 390));
    expect(calls.last, ['DeviceOrientation.portraitUp']);
  });

  testWidgets('a tablet rotates freely', (tester) async {
    await pump(tester, const Size(834, 1194));
    expect(calls.last, isEmpty);
  });

  testWidgets('the reader may widen and restore', (tester) async {
    await pump(tester, const Size(390, 844));
    await GlassOrientation.widenForReader();
    expect(calls.last, isEmpty);
  });
}
