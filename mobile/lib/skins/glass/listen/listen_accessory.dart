/// Which content the bottom accessory shows (glass 7.15, B3): Now narrating, then Downloading, then Continue.
library;

enum GlassAccessoryKind { narrating, downloading, continueItem, none }

/// Continue shows only on Home once its hero has scrolled away.
GlassAccessoryKind accessoryFor({
  required bool narration,
  required bool downloads,
  required bool continueItem,
  required bool onHome,
  required bool heroVisible,
}) {
  if (narration) return GlassAccessoryKind.narrating;
  if (downloads) return GlassAccessoryKind.downloading;
  if (continueItem && onHome && !heroVisible) return GlassAccessoryKind.continueItem;
  return GlassAccessoryKind.none;
}
