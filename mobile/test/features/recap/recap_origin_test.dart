import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/recap/models/recap_origin.dart';

void main() {
  test('reads the origin from extra, else a Dip back to Tonight', () {
    const o = RecapOrigin(RecapEntry.wipe, returnTo: '/x');
    expect(readRecapOrigin(o), same(o));
    final d = readRecapOrigin(null);
    expect(d.entry, RecapEntry.dip);
    expect(d.returnTo, '/');
    expect(readRecapOrigin('nope').entry, RecapEntry.dip);
  });
}
