import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/platform/mm_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('mm/platform');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late MmPlatform platform;
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    platform = MmPlatform(channel: channel);
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return switch (call.method) {
        'a11y.reduceTransparency' => true,
        'a11y.contrastLevel' => 0.75,
        'audio.isMusicActive' => true,
        'haptics.systemEnabled' => false,
        _ => null,
      };
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('method names and typed results', () async {
    expect(await platform.reduceTransparency(), isTrue);
    expect(await platform.contrastLevel(), 0.75);
    expect(await platform.isMusicActive(), isTrue);
    expect(await platform.hapticsSystemEnabled(), isFalse);
    expect(calls.map((c) => c.method), [
      'a11y.reduceTransparency',
      'a11y.contrastLevel',
      'audio.isMusicActive',
      'haptics.systemEnabled',
    ]);
  });

  test('setExclusionRects sends [left, top, width, height] lists', () async {
    await platform.setExclusionRects([
      [0, 100, 24, 300],
      [366, 100, 24, 300],
    ]);
    await platform.setExclusionRects(const []);
    expect(calls[0].method, 'gestures.setExclusionRects');
    expect(calls[0].arguments, {
      'rects': [
        [0, 100, 24, 300],
        [366, 100, 24, 300],
      ],
    });
    expect(calls[1].arguments, {'rects': <List<double>>[]});
  });

  test('a missing handler answers the safe defaults', () async {
    messenger.setMockMethodCallHandler(channel, null);
    expect(await platform.reduceTransparency(), isFalse);
    expect(await platform.contrastLevel(), 0.0);
    expect(await platform.hapticsSystemEnabled(), isTrue);
  });

  test('native change callbacks reach the streams', () async {
    final rt = <bool>[];
    final cl = <double>[];
    final a = platform.reduceTransparencyChanges.listen(rt.add);
    final b = platform.contrastLevelChanges.listen(cl.add);
    Future<void> native(String m, Object v) => messenger.handlePlatformMessage(
          'mm/platform',
          const StandardMethodCodec().encodeMethodCall(MethodCall(m, {'value': v})),
          (_) {},
        );
    await native('a11y.reduceTransparencyChanged', true);
    await native('a11y.contrastLevelChanged', 1.0);
    await Future<void>.delayed(Duration.zero);
    expect(rt, [true]);
    expect(cl, [1.0]);
    await a.cancel();
    await b.cancel();
  });
}
