import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/error/fatal_error.dart';
import 'package:manhwamaniacs/core/error/not_available.dart';

ApiError _e(String code) => ApiError(statusCode: 404, code: code, message: 'm');

void main() {
  test('maps the three codes', () {
    expect(notAvailableKind(_e('series_not_found')), NotAvailableKind.series);
    expect(notAvailableKind(_e('source_not_found')), NotAvailableKind.source);
    expect(notAvailableKind(_e('source_not_browsable')), NotAvailableKind.notBrowsable);
  });

  test('anything else is null', () {
    expect(notAvailableKind(_e('nope')), isNull);
    expect(notAvailableKind(const TimeoutError()), isNull);
  });

  test('fatal report ref is 8 hex digits and stable', () {
    final a = FatalErrorReport(StateError('x'));
    expect(a.ref, matches(RegExp(r'^[0-9a-f]{8}$')));
    expect(a.ref, FatalErrorReport(StateError('x')).ref);
  });
}
