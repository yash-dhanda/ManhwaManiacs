import 'package:manhwamaniacs/features/downloads/utils/format_bytes.dart';

const int kStorageFloorBytes = 1610612736; // 1.5 GB

/// Three segments of the storage meter as fractions of its whole (they sum to 1), the cap tick,
/// the two notes and the folio line. Skin-neutral: Cinematic and Glass paint the same model.
class StorageMeterModel {
  const StorageMeterModel({
    required this.otherFraction,
    required this.appFraction,
    required this.freeFraction,
    required this.capTick,
    required this.nearFloor,
    required this.capReached,
    required this.folio,
    required this.appBytes,
    required this.capBytes,
  });

  /// Other apps: `total − free − app` (0 when the device total is unknown).
  final double otherFraction;
  final double appFraction;
  final double freeFraction;

  /// Where the cap sits on the bar, `(other + cap) / total`; null when unlimited.
  final double? capTick;
  final bool nearFloor;
  final bool capReached;

  /// `4.1 GB OF 10 GB · 21 GB FREE ON THIS PHONE`.
  final String folio;
  final int appBytes;
  final int? capBytes;
}

/// [deviceTotal] null keeps two segments (app and free, over `appBytes + free`). Null only when
/// [deviceFree] is null too. [deviceNoun] is `PHONE` or `TABLET`.
StorageMeterModel? storageMeter({
  required int appBytes,
  required int? capBytes,
  required int? deviceFree,
  required int? deviceTotal,
  String deviceNoun = 'PHONE',
}) {
  if (deviceFree == null) return null;
  final free = deviceFree < 0 ? 0 : deviceFree;
  final hasTotal = deviceTotal != null && deviceTotal > 0;
  final total = hasTotal ? deviceTotal : appBytes + free;
  if (total <= 0) return null;
  final other = hasTotal ? (total - free - appBytes).clamp(0, total) : 0;
  final whole = (other + appBytes + free).toDouble();
  double f(num v) => whole <= 0 ? 0 : v / whole;
  final cap = capBytes;
  final tick = cap == null ? null : ((other + cap) / whole).clamp(0.0, 1.0);
  final used = _bytes(appBytes);
  final folio = cap == null
      ? '$used · ${_bytes(free)} FREE ON THIS $deviceNoun'
      : '$used OF ${_bytes(cap)} · ${_bytes(free)} FREE ON THIS $deviceNoun';
  return StorageMeterModel(
    otherFraction: f(other),
    appFraction: f(appBytes),
    freeFraction: f(free),
    capTick: tick,
    nearFloor: free <= kStorageFloorBytes,
    capReached: cap != null && appBytes >= cap,
    folio: folio,
    appBytes: appBytes,
    capBytes: cap,
  );
}

/// One decimal, `MB` under 1 GB (the store's formatter), upper case like every folio.
String _bytes(int b) {
  const gb = 1024 * 1024 * 1024;
  if (b >= gb) return '${(b / gb).toStringAsFixed(b % gb == 0 ? 0 : 1)} GB';
  final mb = b / (1024 * 1024);
  if (b >= 1024 * 1024) return '${mb.toStringAsFixed(mb == mb.roundToDouble() ? 0 : 1)} MB';
  return formatDownloadBytes(b);
}
