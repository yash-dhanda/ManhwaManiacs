/// The novel reader's hardware-keyboard rules that are not widgets (cinematic 8.15.8).
/// `mobile/15` (Listen) and `mobile/23` (auto-scroll) extend [novelEscapeStep] and
/// [kNovelChromeRevealingKeys].
library;

import 'package:flutter/services.dart' show LogicalKeyboardKey;

/// What `Esc` closes, in order: the go-to-percent field, a sheet, the Listen reading room, a panel,
/// then the reader itself (back to the book).
enum NovelEscape { cancelProgressField, closeSheet, collapsePlayer, closePanel, exitReader }

/// The next step of the escape order for the state the reader is in.
NovelEscape novelEscapeStep({required bool progressFieldOpen, required bool sheetOpen, required bool panelOpen, bool playerOpen = false}) {
  if (progressFieldOpen) return NovelEscape.cancelProgressField;
  if (sheetOpen) return NovelEscape.closeSheet;
  if (playerOpen) return NovelEscape.collapsePlayer;
  if (panelOpen) return NovelEscape.closePanel;
  return NovelEscape.exitReader;
}

/// The Listen keys (cinematic 8.15.8): `p` play / pause, `[` `]` the previous / next sentence,
/// `Shift+[` `Shift+]` back / forward 15 s, `<` `>` the Listen speed down / up 0.05x.
enum NovelListenKey { toggle, previousSentence, nextSentence, back15, forward15, slower, faster }

/// The Listen action [key] means with [shift], or null.
NovelListenKey? novelListenKey(LogicalKeyboardKey key, {bool shift = false}) {
  if (key == LogicalKeyboardKey.keyP && !shift) return NovelListenKey.toggle;
  if (key == LogicalKeyboardKey.bracketLeft) return shift ? NovelListenKey.back15 : NovelListenKey.previousSentence;
  if (key == LogicalKeyboardKey.bracketRight) return shift ? NovelListenKey.forward15 : NovelListenKey.nextSentence;
  if (key == LogicalKeyboardKey.comma && shift) return NovelListenKey.slower;
  if (key == LogicalKeyboardKey.period && shift) return NovelListenKey.faster;
  return null;
}

/// Keys that reveal the chrome when it is hidden: every other reader key leaves it alone.
const Set<String> kNovelChromeRevealingKeys = {'g', ',', 't', 'o', 'm'};

bool novelKeyRevealsChrome(String label) => kNovelChromeRevealingKeys.contains(label);

/// The size a `=`, `+`, `-` or `0` key press lands on: one step up or down within 14-40, or the
/// face default on `0` ([reset]).
double novelKeySize(double current, {int step = 0, bool reset = false, required double faceDefault}) {
  if (reset) return faceDefault.clamp(14, 40).toDouble();
  return (current + step).clamp(14, 40).roundToDouble();
}

/// Whether a key with no modifier is live: the "Single-key shortcuts" setting turns every
/// unmodified binding off.
bool novelSingleKeyLive({required bool singleKeyEnabled, required bool modified}) => modified || singleKeyEnabled;
