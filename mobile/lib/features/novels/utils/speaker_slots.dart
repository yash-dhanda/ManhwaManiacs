import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:manhwamaniacs/features/novels/models/novel_cast.dart';

/// One tinted run of a paragraph: UTF-16 offsets into the paragraph, the colour slot 1-10 and
/// whether it is a dotted (slot 11+) reuse.
class SpeakerRun {
  const SpeakerRun({required this.start, required this.end, required this.slot, required this.dotted, required this.name});
  final int start, end, slot;
  final bool dotted;
  final String name;
}

/// The server's `chapter_fingerprint`: SHA-256 over each paragraph's UTF-8 bytes followed by a NUL.
String chapterFingerprint(List<String> paragraphs) {
  final bytes = BytesBuilder(copy: false);
  for (final p in paragraphs) {
    bytes
      ..add(utf8.encode(p))
      ..addByte(0);
  }
  return sha256.convert(bytes.takeBytes()).toString();
}

/// Whether [attribution]'s offsets were computed against exactly [paragraphs].
bool attributionMatches(NovelAttribution attribution, List<String> paragraphs) =>
    attribution.attributed && attribution.textFingerprint != null && attribution.textFingerprint == chapterFingerprint(paragraphs);

/// Slot (1-10) and dotted flag by speaker, in cast order (busiest first); a speaker the cast does
/// not list is appended in order of appearance. The 11th speaker reuses slot 1, dotted.
Map<String, ({int slot, bool dotted})> speakerSlots(NovelAttribution attribution) {
  final order = <String>[];
  for (final m in attribution.cast) {
    if (!order.contains(m.name)) order.add(m.name);
  }
  for (final s in attribution.spans) {
    final n = s.speaker;
    if (n != null && n.isNotEmpty && !order.contains(n)) order.add(n);
  }
  return {for (var i = 0; i < order.length; i++) order[i]: (slot: i % 10 + 1, dotted: i >= 10)};
}

/// Runs to tint, by paragraph index. Empty when the chapter is not attributed or the fingerprint
/// does not match the text on screen (stale text is never tinted). A paragraph one of whose spans
/// fails its `head` proof renders untinted, as the web does. Narration is never tinted.
Map<int, List<SpeakerRun>> speakerRuns(NovelAttribution attribution, List<String> paragraphs) {
  if (!attributionMatches(attribution, paragraphs)) return const {};
  final slots = speakerSlots(attribution);
  final byParagraph = <int, List<NovelSpeakerSpan>>{};
  for (final s in attribution.spans) {
    if (s.paragraph < 0 || s.paragraph >= paragraphs.length) continue;
    byParagraph.putIfAbsent(s.paragraph, () => []).add(s);
  }
  final out = <int, List<SpeakerRun>>{};
  byParagraph.forEach((p, spans) {
    final text = paragraphs[p];
    final runes = text.runes.toList();
    final astral = runes.length != text.length;
    // Code point offsets to UTF-16 ones.
    final utf16 = astral ? _utf16Offsets(text) : null;
    int at(int cp) => utf16 == null ? cp : utf16[cp.clamp(0, runes.length)];
    spans.sort((a, b) => a.start.compareTo(b.start));
    final runs = <SpeakerRun>[];
    var cursor = 0;
    var ok = true;
    for (final s in spans) {
      final st = at(s.start), en = at(s.end);
      if (st < cursor || en <= st || en > text.length || (s.head.isNotEmpty && !text.substring(st, en).startsWith(s.head))) {
        ok = false;
        break;
      }
      cursor = en;
      final name = s.speaker;
      final slot = name == null ? null : slots[name];
      if (slot != null) runs.add(SpeakerRun(start: st, end: en, slot: slot.slot, dotted: slot.dotted, name: name!));
    }
    if (ok && runs.isNotEmpty) out[p] = runs;
  });
  return out;
}

List<int> _utf16Offsets(String text) {
  final offsets = <int>[0];
  var i = 0;
  for (final r in text.runes) {
    i += r > 0xFFFF ? 2 : 1;
    offsets.add(i);
  }
  return offsets;
}
