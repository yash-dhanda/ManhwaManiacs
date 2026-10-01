// ignore_for_file: require_trailing_commas, avoid_redundant_argument_values, prefer_const_declarations, directives_ordering, prefer_function_declarations_over_variables
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/haptics.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';

/// mobile/45 I7 (5.2, 14.9): the event table and the depth ramp. Rate limits, the Haptics switch, Android's system setting, "Feel it" and
/// the sound defaults are proven by `glass_haptics_test.dart`, `skin_haptics_test.dart`, `skin_audio_test.dart` and
/// `settings/settings_sections_test.dart`, named in `qa.md`.
void main() {
  test('detent.magnet is rigid at 0.4 and autoscroll.start is the cruise AHAP (5.2)', () {
    expect(glassHaptics[HapticEvent.detentMagnet]!.single.pattern, 'rigid:0.4');
    expect(glassHaptics[HapticEvent.autoscrollStart]!.single.pattern, 'ahap:cruise');
    expect(GlassHaptics.intensityOf(HapticEvent.detentMagnet), 0.4);
  });

  test('nav.push at depths 1 to 4 plays rise1 to rise4 at 0.38, 0.46, 0.54 and 0.62', () {
    expect(glassHaptics[HapticEvent.navPush]!.single.pattern, 'ahap:rise{depth}');
    final got = [for (var d = 1; d <= 4; d++) GlassHaptics.intensityOf(HapticEvent.navPush, depth: d)];
    expect(got[0], closeTo(0.38, 1e-9));
    expect(got[1], closeTo(0.46, 1e-9));
    expect(got[2], closeTo(0.54, 1e-9));
    expect(got[3], closeTo(0.62, 1e-9));
  });
}
