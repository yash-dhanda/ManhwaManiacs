import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/app/boot_step.dart';

void main() {
  test('a step that throws resolves to the fallback', () async {
    final v = await bootStep<String?>(
      'API URL read',
      Future<String?>.error(PlatformException(code: '-25308')),
      const Duration(seconds: 3),
      () => null,
    );
    expect(v, isNull);
  });

  test('a step that never answers times out to the fallback', () async {
    final v = await bootStep<int>(
      'slow',
      Future<int>.delayed(const Duration(seconds: 5), () => 1),
      const Duration(milliseconds: 20),
      () => 7,
    );
    expect(v, 7);
  });

  test('a normal step returns its value', () async {
    expect(await bootStep<int>('ok', Future.value(3), const Duration(seconds: 1), () => 7), 3);
  });
}
