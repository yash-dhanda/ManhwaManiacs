/// A chapter row's height (glass 7.17): 56, or 68 with a secondary title, times the `body` role's capped text scale. From 1.6 the row
/// stacks its trailing controls (reactions, the download control) under the text: one more 48 px control line.
double chapterRowExtent({required bool hasSecondary, double textScale = 1}) =>
    (hasSecondary ? 68 : 56) * (textScale < 1 ? 1 : textScale) + (textScale >= 1.6 ? 48 : 0);
