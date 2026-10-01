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

/// One of the three segments of the Glass storage capsule.
enum GlassMeterSegment { profile, other, free }

/// The Glass storage meter (glass 8.22): three segments on one scale, the label and the exact semantics value. Skin-neutral.
class GlassStorageMeter {
  const GlassStorageMeter({
    required this.profileFraction,
    required this.otherFraction,
    required this.freeFraction,
    required this.capMarker,
    required this.label,
    required this.semanticsValue,
    required this.capped,
  });

  /// Fractions of the scale; they sum to 1 (free is 0 when the cap is reached).
  final double profileFraction;
  final double otherFraction;
  final double freeFraction;

  /// `1.0` (the right end) when a cap is set, else null.
  final double? capMarker;

  /// `1.2 GB of 10 GB`, or `1.2 GB used · 21 GB free on this phone`.
  final String label;

  /// `1.2 GB of 10 GB used: this profile 1.2 GB, other app data 3.4 GB, 5.4 GB free` (capped) or the unlimited reading.
  final String semanticsValue;
  final bool capped;
}

/// [profileBytes] is this profile's visible downloads (after the mature filter); [appDownloadBytes] every profile's downloads.
/// Other profiles' bytes, hidden mature ones included, are one anonymous "other app data" segment. With a cap the scale is the cap;
/// unlimited, the scale is `profile + other + deviceFree`. Null when `deviceFree` is unknown and no cap is set.
GlassStorageMeter? glassStorageMeter({
  required int profileBytes,
  required int appDownloadBytes,
  required int? capBytes,
  required int? deviceFree,
  String deviceNoun = 'phone',
}) {
  final profile = profileBytes < 0 ? 0 : profileBytes;
  final other = (appDownloadBytes - profile) < 0 ? 0 : appDownloadBytes - profile;
  final cap = capBytes;
  if (cap != null && cap > 0) {
    final free = (cap - profile - other) < 0 ? 0 : cap - profile - other;
    final scale = (profile + other + free).toDouble();
    double f(int v) => scale <= 0 ? 0 : v / scale;
    final used = 'of ${_bytes(cap)}';
    return GlassStorageMeter(
      profileFraction: f(profile),
      otherFraction: f(other),
      freeFraction: f(free),
      capMarker: 1.0,
      // Against the cap, everything the cap counts: every profile's and mode's downloads, the
      // same total the queue pauses on. This profile's share stays in the bar and the semantics.
      label: '${_bytes(profile + other)} $used',
      semanticsValue: '${_bytes(profile + other)} $used used: this profile ${_bytes(profile)}, other app data ${_bytes(other)}, ${_bytes(free)} free',
      capped: true,
    );
  }
  if (deviceFree == null) return null;
  final free = deviceFree < 0 ? 0 : deviceFree;
  final scale = (profile + other + free).toDouble();
  if (scale <= 0) return null;
  return GlassStorageMeter(
    profileFraction: profile / scale,
    otherFraction: other / scale,
    freeFraction: free / scale,
    capMarker: null,
    label: '${_bytes(profile)} used · ${_bytes(free)} free on this $deviceNoun',
    semanticsValue: '${_bytes(profile)} used: this profile ${_bytes(profile)}, other app data ${_bytes(other)}, ${_bytes(free)} free on this $deviceNoun',
    capped: false,
  );
}
