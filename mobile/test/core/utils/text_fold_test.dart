import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/utils/text_fold.dart';

void main() {
  test('foldDiacritics', () {
    expect(foldDiacritics('café'), 'cafe');
    expect(foldDiacritics('señor'), 'senor');
    expect(foldDiacritics('Łódź'), 'Lodz');
    expect(foldDiacritics('Ångström'), 'Angstrom');
    expect(foldDiacritics('plain 漢字'), 'plain 漢字');
  });
}
