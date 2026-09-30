import 'package:intl/intl.dart';

final NumberFormat _n = NumberFormat.decimalPattern('en_GB');

/// `1,240` (en_GB grouping).
String fmt(int n) => _n.format(n);

/// `31 H`: whole hours; under one hour, minutes with ` M`.
String hoursValue(int seconds) => seconds >= 3600
    ? '${fmt(seconds ~/ 3600)} H'
    : '${(seconds / 60).round()} M';

/// `412 h` for the "all time" captions.
String hoursLower(int seconds) => seconds >= 3600
    ? '${fmt(seconds ~/ 3600)} h'
    : '${(seconds / 60).round()} m';

const _ones = [
  'zero',
  'one',
  'two',
  'three',
  'four',
  'five',
  'six',
  'seven',
  'eight',
  'nine',
  'ten',
  'eleven',
  'twelve',
  'thirteen',
  'fourteen',
  'fifteen',
  'sixteen',
  'seventeen',
  'eighteen',
  'nineteen',
];
const _tens = [
  '',
  '',
  'twenty',
  'thirty',
  'forty',
  'fifty',
  'sixty',
  'seventy',
  'eighty',
  'ninety',
];

/// One to ninety-nine spelled out; larger numbers as digits.
String spell(int n) {
  if (n < 0 || n > 99) return fmt(n);
  if (n < 20) return _ones[n];
  final t = _tens[n ~/ 10];
  return n % 10 == 0 ? t : '$t-${_ones[n % 10]}';
}

String capitalise(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// `Monday`..`Sunday` for a `DateTime.weekday` (1..7).
String weekdayName(int weekday) => _weekdays[weekday - 1];

/// "Monday, Tuesday and Thursday".
String joinNames(List<String> names) => names.length <= 1
    ? names.join()
    : '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';

/// The reading-status vocabulary of 7.19, in display order.
const List<(String, String)> kStatusRows = [
  ('reading', 'READING'),
  ('plan_to_read', 'PLAN TO READ'),
  ('on_hold', 'ON HOLD'),
  ('completed', 'DONE'),
  ('dropped', 'DROPPED'),
  ('unread', 'NOT STARTED'),
];
