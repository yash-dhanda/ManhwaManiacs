import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/stop_press_banner.dart';

void main() {
  test('plural and singular wording', () {
    expect(stopPressLine(5, 3), '5 new chapters across 3 series.');
    expect(stopPressLine(1, 1), '1 new chapter in 1 series.');
    expect(stopPressLine(4, 1), '4 new chapters in 1 series.');
    expect(stopPressLine(2, 2), '2 new chapters across 2 series.');
  });
}
