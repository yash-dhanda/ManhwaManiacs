import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/downloads/utils/storage_meter.dart';

const gb = 1024 * 1024 * 1024;

void main() {
  test('segments sum to 1 and other apps are total - free - app', () {
    final m = storageMeter(appBytes: 4 * gb, capBytes: 10 * gb, deviceFree: 20 * gb, deviceTotal: 100 * gb)!;
    expect(m.otherFraction, closeTo(0.76, 1e-9));
    expect(m.appFraction, closeTo(0.04, 1e-9));
    expect(m.freeFraction, closeTo(0.20, 1e-9));
    expect(m.otherFraction + m.appFraction + m.freeFraction, closeTo(1, 1e-9));
  });

  test('cap tick sits at (other + cap) / total; none when unlimited', () {
    final m = storageMeter(appBytes: 4 * gb, capBytes: 10 * gb, deviceFree: 20 * gb, deviceTotal: 100 * gb)!;
    expect(m.capTick, closeTo(0.86, 1e-9));
    expect(storageMeter(appBytes: 4 * gb, capBytes: null, deviceFree: 20 * gb, deviceTotal: 100 * gb)!.capTick, isNull);
  });

  test('folio line, with and without a cap, and the tablet noun', () {
    final a = storageMeter(appBytes: (4.1 * gb).round(), capBytes: 10 * gb, deviceFree: 21 * gb, deviceTotal: 128 * gb)!;
    expect(a.folio, '4.1 GB OF 10 GB · 21 GB FREE ON THIS PHONE');
    final b = storageMeter(appBytes: (4.1 * gb).round(), capBytes: null, deviceFree: 21 * gb, deviceTotal: 128 * gb, deviceNoun: 'TABLET')!;
    expect(b.folio, '4.1 GB · 21 GB FREE ON THIS TABLET');
    final c = storageMeter(appBytes: 800 * 1024 * 1024, capBytes: null, deviceFree: 21 * gb, deviceTotal: 128 * gb)!;
    expect(c.folio, startsWith('800 MB'));
  });

  test('near floor at 1.5 GB free, cap reached at the cap', () {
    expect(storageMeter(appBytes: 1, capBytes: null, deviceFree: kStorageFloorBytes, deviceTotal: 100 * gb)!.nearFloor, isTrue);
    expect(storageMeter(appBytes: 1, capBytes: null, deviceFree: kStorageFloorBytes + 1, deviceTotal: 100 * gb)!.nearFloor, isFalse);
    expect(storageMeter(appBytes: 10 * gb, capBytes: 10 * gb, deviceFree: 50 * gb, deviceTotal: 100 * gb)!.capReached, isTrue);
    expect(storageMeter(appBytes: 9 * gb, capBytes: 10 * gb, deviceFree: 50 * gb, deviceTotal: 100 * gb)!.capReached, isFalse);
  });

  test('no device total: two segments over app + free, no other', () {
    final m = storageMeter(appBytes: 1 * gb, capBytes: 10 * gb, deviceFree: 3 * gb, deviceTotal: null)!;
    expect(m.otherFraction, 0);
    expect(m.appFraction, closeTo(0.25, 1e-9));
    expect(m.freeFraction, closeTo(0.75, 1e-9));
  });

  test('null only when free space is unknown too', () {
    expect(storageMeter(appBytes: 1, capBytes: null, deviceFree: null, deviceTotal: 100 * gb), isNull);
    expect(storageMeter(appBytes: 1, capBytes: null, deviceFree: null, deviceTotal: null), isNull);
  });
}
