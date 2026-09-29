const _fold = <int, String>{
  0xC0: 'A',
  0xC1: 'A',
  0xC2: 'A',
  0xC3: 'A',
  0xC4: 'A',
  0xC5: 'A',
  0xC6: 'AE',
  0xC7: 'C',
  0xC8: 'E',
  0xC9: 'E',
  0xCA: 'E',
  0xCB: 'E',
  0xCC: 'I',
  0xCD: 'I',
  0xCE: 'I',
  0xCF: 'I',
  0xD0: 'D',
  0xD1: 'N',
  0xD2: 'O',
  0xD3: 'O',
  0xD4: 'O',
  0xD5: 'O',
  0xD6: 'O',
  0xD8: 'O',
  0xD9: 'U',
  0xDA: 'U',
  0xDB: 'U',
  0xDC: 'U',
  0xDD: 'Y',
  0xDE: 'TH',
  0xDF: 'ss',
  0xE0: 'a',
  0xE1: 'a',
  0xE2: 'a',
  0xE3: 'a',
  0xE4: 'a',
  0xE5: 'a',
  0xE6: 'ae',
  0xE7: 'c',
  0xE8: 'e',
  0xE9: 'e',
  0xEA: 'e',
  0xEB: 'e',
  0xEC: 'i',
  0xED: 'i',
  0xEE: 'i',
  0xEF: 'i',
  0xF0: 'd',
  0xF1: 'n',
  0xF2: 'o',
  0xF3: 'o',
  0xF4: 'o',
  0xF5: 'o',
  0xF6: 'o',
  0xF8: 'o',
  0xF9: 'u',
  0xFA: 'u',
  0xFB: 'u',
  0xFC: 'u',
  0xFD: 'y',
  0xFE: 'th',
  0xFF: 'y',
};

// Latin Extended-A, U+0100..U+017F, as pairs of (upper, lower) base letters.
const _extA =
    'AaAaAaCcCcCcCcDdDdEeEeEeEeEeGgGgGgGgHhHhIiIiIiIiIiIiJjKkkLlLlLlLlLlNnNnNnnNnOoOoOoOoRrRrRrSsSsSsSsTtTtTtUuUuUuUuUuUuWwYyYZzZzZzs';

/// Maps the Latin-1 Supplement and Latin Extended-A letters to ASCII.
String foldDiacritics(String s) {
  final b = StringBuffer();
  for (final r in s.runes) {
    if (r >= 0xC0 && r <= 0xFF) {
      b.write(_fold[r] ?? String.fromCharCode(r));
    } else if (r >= 0x100 && r <= 0x17F) {
      b.write(_extA[r - 0x100]);
    } else {
      b.writeCharCode(r);
    }
  }
  return b.toString();
}
