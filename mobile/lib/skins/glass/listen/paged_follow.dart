/// Narration-driven page turns (glass 8.15.4, 8.16.7, B6).
library;

/// The page turns when the active sentence's first line lies below the current page's last line.
bool shouldTurn({required double activeFirstLineTop, required double pageBottom}) => activeFirstLineTop >= pageBottom;

/// A manual turn decouples the page from the voice until "Back to the voice".
class PagedFollow {
  bool decoupled = false;

  void manualTurn() => decoupled = true;

  void backToTheVoice() => decoupled = false;

  /// Whether the reader should turn now.
  bool turnFor({required double activeFirstLineTop, required double pageBottom}) => !decoupled && shouldTurn(activeFirstLineTop: activeFirstLineTop, pageBottom: pageBottom);
}
