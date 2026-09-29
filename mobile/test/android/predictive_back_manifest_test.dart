import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('main manifest opts in to predictive back', () {
    final xml =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final app = RegExp(r'<application[^>]*>').firstMatch(xml)!.group(0)!;
    expect(app, contains('android:enableOnBackInvokedCallback="true"'));
  });
}
