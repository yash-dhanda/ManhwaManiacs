import 'dart:math' as math;
import 'dart:ui' show Rect;

import 'package:manhwamaniacs/features/circle/models/circle_models.dart';

/// Letters in state `new`: the Index folio, the thumb-index badge and the LETTERS tab count.
int newCount(List<Letter> letters) => letters.where((l) => l.state == LetterState.newLetter).length;

/// `Sent to Riya.` / `Sent to Riya and Arjun.` / `Sent to Riya, Arjun and Mei.`
String sendToast(List<String> names) => switch (names.length) {
      0 => 'Sent.',
      1 => 'Sent to ${names[0]}.',
      _ => 'Sent to ${names.sublist(0, names.length - 1).join(', ')} and ${names.last}.',
    };

/// A letter turns `read` once this much of it has been visible for this long.
const double letterReadFraction = 0.5;
const Duration letterReadAfter = Duration(milliseconds: 2000);

/// The visible fraction of [item] inside [viewport] (0 when either is empty).
double visibleFraction(Rect item, Rect viewport) {
  if (item.isEmpty || viewport.isEmpty) return 0;
  final i = item.intersect(viewport);
  if (i.width <= 0 || i.height <= 0) return 0;
  return math.min(1, (i.width * i.height) / (item.width * item.height));
}
