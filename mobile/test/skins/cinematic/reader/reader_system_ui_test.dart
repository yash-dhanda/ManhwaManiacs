import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_system_ui.dart';

void main() {
  test('every platform x phase', () {
    for (final p in TargetPlatform.values) {
      final android = p == TargetPlatform.android;
      final entry = readerSystemUi(p, ReaderUiPhase.enter);
      expect(entry.mode, android ? SystemUiMode.immersiveSticky : SystemUiMode.manual);
      expect(entry.overlays, android ? isNull : isEmpty);
      final shown = readerSystemUi(p, ReaderUiPhase.chromeShown);
      expect(shown.mode, SystemUiMode.manual);
      expect(shown.overlays, [SystemUiOverlay.top]);
      expect(readerSystemUi(p, ReaderUiPhase.chromeHidden), entry);
      final exit = readerSystemUi(p, ReaderUiPhase.exit);
      expect(exit.mode, SystemUiMode.edgeToEdge);
      expect(exit.style?.statusBarColor, const Color(0x00000000));
      expect(exit.style?.systemNavigationBarColor, const Color(0x00000000));
      expect(exit.style?.systemNavigationBarContrastEnforced, isFalse);
    }
  });
}
