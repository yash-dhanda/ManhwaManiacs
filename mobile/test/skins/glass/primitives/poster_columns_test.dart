import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/primitives/poster_grid_math.dart';

void main() {
  test('columns at gridMin 152 and gap 20 (glass 7.8)', () {
    expect(posterColumns(860, 152, 20), 5);
    expect(posterColumns(1056, 152, 20), 6);
    expect(posterColumns(1360, 152, 20), 8);
  });

  test('content width for the three windows', () {
    expect(posterContentWidth(windowWidth: 1024, sidebarOffset: 100, margin: 32), 860);
    expect(posterContentWidth(windowWidth: 1440, sidebarOffset: 304, margin: 40), 1056);
    expect(posterContentWidth(windowWidth: 1920, sidebarOffset: 304, margin: 40), 1360);
  });
}
