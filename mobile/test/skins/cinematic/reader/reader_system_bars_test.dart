import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../screenshots/support/shot_network.dart';
import 'reader_test_support.dart';

/// The system-bar choreography of cinematic 8.0.5, through the widget with a mocked
/// `SystemChannels.platform` (not just the decision function).
void main() {
  setUpAll(setUpShotCoverCache);
  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets('system bars on $platform: entry, chrome shown, chrome hidden, exit', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      final calls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        switch (call.method) {
          case 'SystemChrome.setEnabledSystemUIMode':
            calls.add('mode:${call.arguments}');
          case 'SystemChrome.setEnabledSystemUIOverlays':
            calls.add('overlays:${(call.arguments as List).join(',')}');
          case 'SystemChrome.setSystemUIOverlayStyle':
            final a = call.arguments as Map;
            if (a['statusBarColor'] == 0) calls.add('style:transparent:${a['systemNavigationBarColor']}');
        }
        return null;
      });

      try {
        final rig = await pumpReader(tester, platform: platform);
        await tester.pump(const Duration(milliseconds: 100));
        final android = platform == TargetPlatform.android;
        final entry = android ? 'mode:SystemUiMode.immersiveSticky' : 'overlays:';
        expect(calls.last, entry, reason: 'entry: $calls');

        await tester.pump(const Duration(milliseconds: 1000));
        calls.clear();
        // The chrome starts shown over the entry bars; a centre tap hides it: still the entry mode.
        await tapSingle(tester);
        expect(chromeVisible(tester), isFalse);
        expect(calls.where((c) => c != entry), isEmpty, reason: 'chrome hidden: $calls');

        calls.clear();
        await tapSingle(tester);
        expect(chromeVisible(tester), isTrue);
        expect(calls, ['overlays:SystemUiOverlay.top'], reason: 'chrome shown');

        calls.clear();
        await tapSingle(tester);
        expect(calls, [entry], reason: 'chrome hidden again');

        calls.clear();
        rig.router.pop();
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 600));
        expect(calls.where((c) => !c.startsWith('style')).last, 'mode:SystemUiMode.edgeToEdge', reason: 'exit: $calls');
        expect(calls, contains('style:transparent:0'), reason: 'transparent light bars: $calls');
        await disposeReader(tester);
      } finally {
        debugDefaultTargetPlatformOverride = null;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
      }
    });
  }
}
