import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/glass/copy/settings_index.dart';

/// The phone and the web share one settings index (glass 8.25). Until `design/glass-settings-index.json` generates both, this
/// compares the id sets whenever the web twin's file is present.
void main() {
  final web = File('../frontend/src/skins/glass/copy/settings-index.ts');
  test('the settings index ids match the web twin', () {
    final ids = RegExp(r'''id:\s*['"]([a-z0-9-]+)['"]''').allMatches(web.readAsStringSync()).map((m) => m.group(1)!).toSet();
    expect(ids, {for (final e in kSettingsIndex) e.id});
  }, skip: web.existsSync() ? false : 'frontend/src/skins/glass/copy/settings-index.ts does not exist yet',);
}
