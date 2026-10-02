import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/downloads/utils/storage_meter.dart';

const gb = 1024 * 1024 * 1024;

void main() {
  test('capped: the scale is the cap, three segments, marker at 1.0, exact semantics', () {
    final m = glassStorageMeter(profileBytes: (1.2 * gb).round(), appDownloadBytes: (1.2 * gb).round() + (3.4 * gb).round(), capBytes: 10 * gb, deviceFree: 40 * gb)!;
    expect(m.capMarker, 1.0);
    expect(m.profileFraction + m.otherFraction + m.freeFraction, closeTo(1, 1e-9));
    expect(m.label, '4.6 GB of 10 GB');
    expect(m.semanticsValue, '4.6 GB of 10 GB used: this profile 1.2 GB, other app data 3.4 GB, 5.4 GB free');
  });

  test('capped: free is floored at 0 when the cap is over-full', () {
    final m = glassStorageMeter(profileBytes: 8 * gb, appDownloadBytes: 12 * gb, capBytes: 10 * gb, deviceFree: null)!;
    expect(m.freeFraction, 0);
    expect(m.profileFraction + m.otherFraction, closeTo(1, 1e-9));
  });

  test('unlimited: scale is profile + other + device free, no marker, phone or tablet noun', () {
    final m = glassStorageMeter(profileBytes: (1.2 * gb).round(), appDownloadBytes: (1.2 * gb).round(), capBytes: null, deviceFree: 21 * gb)!;
    expect(m.capMarker, isNull);
    expect(m.label, '1.2 GB used · 21 GB free on this phone');
    expect(glassStorageMeter(profileBytes: 0, appDownloadBytes: 0, capBytes: null, deviceFree: 21 * gb, deviceNoun: 'tablet')!.label, '0 B used · 21 GB free on this tablet');
  });

  test('megabytes under a gigabyte; null with no cap and no device figure', () {
    expect(glassStorageMeter(profileBytes: 800 * 1024 * 1024, appDownloadBytes: 800 * 1024 * 1024, capBytes: 2 * gb, deviceFree: null)!.label, '800 MB of 2 GB');
    expect(glassStorageMeter(profileBytes: 1, appDownloadBytes: 1, capBytes: null, deviceFree: null), isNull);
  });
}
