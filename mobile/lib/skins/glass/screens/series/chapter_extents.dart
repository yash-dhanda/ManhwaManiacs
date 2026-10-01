/// A chapter row's height (glass 7.17): 56, or 68 with a secondary title, times the `body` role's capped text scale.
double chapterRowExtent({required bool hasSecondary, double textScale = 1}) => (hasSecondary ? 68 : 56) * (textScale < 1 ? 1 : textScale);
