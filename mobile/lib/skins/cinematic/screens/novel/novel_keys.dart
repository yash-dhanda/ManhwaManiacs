/// The novel reader's hardware-keyboard rules that are not widgets (cinematic 8.15.8).
/// `mobile/15` (Listen) and `mobile/23` (auto-scroll) extend [novelEscapeStep] and
/// [kNovelChromeRevealingKeys].
library;

/// What `Esc` closes, in order: the go-to-percent field, a sheet, a panel, then the reader itself
/// (back to the book).
enum NovelEscape { cancelProgressField, closeSheet, closePanel, exitReader }

/// The next step of the escape order for the state the reader is in.
NovelEscape novelEscapeStep({required bool progressFieldOpen, required bool sheetOpen, required bool panelOpen}) {
  if (progressFieldOpen) return NovelEscape.cancelProgressField;
  if (sheetOpen) return NovelEscape.closeSheet;
  if (panelOpen) return NovelEscape.closePanel;
  return NovelEscape.exitReader;
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
