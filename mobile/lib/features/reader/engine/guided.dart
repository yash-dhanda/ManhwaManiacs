enum GuidedHoldMode { paceByWords, fixed }

/// Guided view auto-advance hold: 1.2 s + 0.25 s per OCR word capped at 6 s (pace by words), else the fixed hold.
int panelHoldMs(int? words, GuidedHoldMode mode, int fixedMs) {
  if (mode == GuidedHoldMode.fixed || words == null) return fixedMs;
  return (1200 + 250 * words).clamp(1200, 6000);
}
