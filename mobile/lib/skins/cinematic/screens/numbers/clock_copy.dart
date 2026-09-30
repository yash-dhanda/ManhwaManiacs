/// The four bands of the 24-hour clock and their copy (cinematic 9.2.1 and the
/// Annual's page 6), shared by The Numbers and The Annual.
enum ClockBand { night, morning, afternoon, evening }

/// night 22:00-04:59, morning 05:00-11:59, afternoon 12:00-16:59, evening 17:00-21:59.
ClockBand bandOfHour(int hour) {
  if (hour >= 22 || hour < 5) return ClockBand.night;
  if (hour < 12) return ClockBand.morning;
  if (hour < 17) return ClockBand.afternoon;
  return ClockBand.evening;
}

class ClockReading {
  const ClockReading(this.band, this.share);

  /// The band with the largest share of seconds; null when nothing is recorded.
  final ClockBand? band;

  /// Its share of the total, 0..1.
  final double share;

  /// Below 40 % (or nothing recorded) the reader is "at all hours".
  bool get allHours => band == null || share < 0.4;
}

/// [byHour] is 24 values of seconds. Ties go to the earlier band in enum order.
ClockReading readClock(List<int> byHour) {
  final sums = {for (final b in ClockBand.values) b: 0};
  var total = 0;
  for (var h = 0; h < byHour.length && h < 24; h++) {
    sums[bandOfHour(h)] = sums[bandOfHour(h)]! + byHour[h];
    total += byHour[h];
  }
  if (total <= 0) return const ClockReading(null, 0);
  ClockBand best = ClockBand.night;
  for (final b in ClockBand.values) {
    if (sums[b]! > sums[best]!) best = b;
  }
  return ClockReading(best, sums[best]! / total);
}

/// The Numbers' sentence under the clock.
String numbersClockSentence(ClockReading r) {
  if (r.allHours) return 'A reader at all hours.';
  return switch (r.band!) {
    ClockBand.night => 'A night reader: most of it after 22:00.',
    ClockBand.morning => 'An early reader: most of it before noon.',
    ClockBand.afternoon =>
      'An afternoon reader: most of it between 12:00 and 17:00.',
    ClockBand.evening =>
      'An evening reader: most of it between 17:00 and 22:00.',
  };
}

/// The Annual's page-6 line, with the share of the largest band.
String annualClockLine(ClockReading r) {
  if (r.allHours) return 'A reader at all hours.';
  final p = '${(r.share * 100).round()} %';
  return switch (r.band!) {
    ClockBand.night => 'A night owl: $p after 22:00.',
    ClockBand.morning => 'An early bird: $p before noon.',
    ClockBand.afternoon => 'An afternoon reader: $p between 12:00 and 17:00.',
    ClockBand.evening => 'An evening reader: $p between 17:00 and 22:00.',
  };
}

/// The share card's caption for the Clock template.
String clockCardCaption(ClockBand b) => switch (b) {
      ClockBand.night => 'of my reading after 22:00.',
      ClockBand.morning => 'of my reading before noon.',
      ClockBand.afternoon => 'of my reading between 12:00 and 17:00.',
      ClockBand.evening => 'of my reading between 17:00 and 22:00.',
    };

/// Spoken label of one clock bar: "22:00, 3 hours 10 minutes".
String hourSemantics(int hour, int seconds) {
  final m = (seconds / 60).round();
  final h = m ~/ 60;
  final r = m % 60;
  final parts = <String>[
    if (h > 0) '$h ${h == 1 ? 'hour' : 'hours'}',
    if (r > 0 || h == 0) '$r ${r == 1 ? 'minute' : 'minutes'}',
  ];
  return '${hour.toString().padLeft(2, '0')}:00, ${parts.join(' ')}';
}
