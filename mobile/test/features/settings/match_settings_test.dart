import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/settings/utils/settings_search.dart';

void main() {
  const rows = [
    SettingsRowRef(id: 'a', section: 'appearance', label: 'Hyperlegible text', keywords: ['dyslexia']),
    SettingsRowRef(id: 'b', section: 'reading-manga', label: 'Auto next chapter'),
    SettingsRowRef(id: 'c', section: 'reading-novels', label: 'Text size', keywords: ['font']),
    SettingsRowRef(id: 'd', section: 'feedback', label: 'Café sounds'),
    SettingsRowRef(id: 'e', section: 'about', label: 'The text of licences', keywords: ['legal']),
  ];

  test('label prefix, then label substring, then keyword', () {
    expect(matchSettings('text', rows).map((r) => r.id), ['c', 'a', 'e']);
    expect(matchSettings('font', rows).map((r) => r.id), ['c']);
    expect(matchSettings('dyslex', rows).map((r) => r.id), ['a']);
  });

  test('case and diacritics fold', () {
    expect(matchSettings('CAFE', rows).map((r) => r.id), ['d']);
    expect(matchSettings('café', rows).map((r) => r.id), ['d']);
  });

  test('empty query matches nothing and results cap at 12', () {
    expect(matchSettings('  ', rows), isEmpty);
    final many = [for (var i = 0; i < 30; i++) SettingsRowRef(id: '$i', section: 's', label: 'Row $i')];
    expect(matchSettings('row', many), hasLength(12));
  });
}
