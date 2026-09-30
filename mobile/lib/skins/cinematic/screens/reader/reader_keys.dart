/// The reader's hardware-keyboard rules that are not widgets (cinematic 8.14.9).

/// What `Esc` closes, in order: a sheet, then a panel, then cinema mode, then the reader itself.
enum ReaderEscape { closeSheet, closePanel, leaveCinema, exitReader }

/// The next step of the escape order for the state the reader is in.
ReaderEscape escapeStep({required bool sheetOpen, required bool panelOpen, required bool cinema}) {
  if (sheetOpen) return ReaderEscape.closeSheet;
  if (panelOpen) return ReaderEscape.closePanel;
  if (cinema) return ReaderEscape.leaveCinema;
  return ReaderEscape.exitReader;
}

/// Keys that reveal the chrome when it is hidden: every other reader key leaves it alone.
const Set<String> kChromeRevealingKeys = {'g', ',', '[', ']', '?'};

/// Whether a key press with [label] shows the hidden chrome.
bool keyRevealsChrome(String label) => kChromeRevealingKeys.contains(label);

/// One page by reading direction: `→` / `d` is forward in LTR, backward in RTL; `←` / `a` the reverse.
bool arrowGoesForward({required bool rightArrow, required bool rtl}) => rightArrow != rtl;
