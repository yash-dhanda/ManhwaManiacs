import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/panel_fit.dart';

void main() {
  test('the desktop strip clamps 480-900 at half the width', () {
    expect(desktopStripWidth(800), 480);
    expect(desktopStripWidth(1366), 683);
    expect(desktopStripWidth(2000), 900);
  });

  test('panels push the strip; both fit from 1,212 px wide', () {
    expect(stripWithPanels(1366, left: true), 683);
    expect(stripWithPanels(1366, left: true, right: true), 634);
    expect(bothPanelsFit(1212), isTrue);
    expect(bothPanelsFit(1211), isFalse);
    expect(bothPanelsFit(1100), isFalse);
    expect(bothPanelsFit(1366), isTrue);
  });

  test('the strip centre is the middle of the remaining width', () {
    expect(stripCentre(1366), 683);
    expect(stripCentre(1366, left: true), 324 + (1366 - 324) / 2);
    expect(stripCentre(1366, right: true), (1366 - 384) / 2);
  });
}
