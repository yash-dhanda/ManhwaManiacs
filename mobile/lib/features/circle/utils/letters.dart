import 'dart:math' as math;
import 'dart:ui' show Rect;

import 'package:flutter/services.dart' show TextEditingValue, TextInputFormatter, TextSelection;
import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';

/// The server's note limit (`NOTE_MAX`), counted as it counts: code points (Python `len`), not the graphemes Flutter's
/// `maxLength` counts. A flag or a family emoji is one grapheme but up to eight code points.
const int kLetterNoteMax = 140;
int noteLength(String note) => note.runes.length;

/// Cuts the note at [kLetterNoteMax] code points (whole graphemes only), so a note the field accepts is one the server accepts.
final TextInputFormatter noteLimit = TextInputFormatter.withFunction((old, next) {
  if (noteLength(next.text) <= kLetterNoteMax) return next;
  final out = StringBuffer();
  var n = 0;
  for (final g in next.text.characters) {
    n += g.runes.length;
    if (n > kLetterNoteMax) break;
    out.write(g);
  }
  final text = out.toString();
  return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
});

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
