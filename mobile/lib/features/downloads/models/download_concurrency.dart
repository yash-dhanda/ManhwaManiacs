/// How many chapters the download queue fetches at the same time — a
/// **per-install** device property alongside [StorageCap] and
/// [RetentionInterval], not a per-profile one: every profile on this phone
/// talks to the same server over the same connection, so the number that
/// matters is "how hard does this device push", not "who is signed in".
///
/// Deliberately a short ladder rather than a free number. The shared request
/// gate ([kQueueRequestConcurrency]) is the real ceiling on what is open
/// against the server at once; the ladder only decides how many chapters
/// compete for it. The page-image rate limit was raised from 60 to 1500 a
/// minute and the box has 4 vCPU, so ten chapters keep the gate full instead
/// of leaving it idle between a chapter's manifest and its pages.
enum DownloadConcurrency {
  one(1),
  two(2),
  three(3),
  five(5),
  ten(10);

  const DownloadConcurrency(this.chapters);

  /// How many chapters may be mid-download at once.
  final int chapters;

  String get label => switch (this) {
        DownloadConcurrency.one => '1 chapter',
        DownloadConcurrency.two => '2 chapters',
        DownloadConcurrency.three => '3 chapters',
        DownloadConcurrency.five => '5 chapters',
        DownloadConcurrency.ten => '10 chapters (fastest, default)',
      };

  /// [ten]: the owner asked for ten chapters at full speed. Anyone who wants a
  /// gentler queue can step down in Settings.
  static DownloadConcurrency fromWire(String? value) =>
      DownloadConcurrency.values.firstWhere(
        (option) => option.name == value,
        orElse: () => DownloadConcurrency.ten,
      );
}
