import 'dart:ui';

/// What a tap does in the paged novel layout (cinematic 8.15.4).
enum NovelTapAction { back, menu, forward }

/// The stored tap-zone presets.
const kNovelTapZonePresets = ['standard', 'bothMargins', 'oneHand'];

/// Which zone [position] falls in, inside a page of [size]. `standard` is 25 / 50 / 25 % (back /
/// menu / forward); `bothMargins` sends both 25 % side zones forward; `oneHand` puts back in the
/// left 25 % and the menu in the top 12 % across the full width, everything else forward.
NovelTapAction novelTapAction(String preset, Offset position, Size size) {
  final fx = size.width <= 0 ? 0.5 : position.dx / size.width;
  final fy = size.height <= 0 ? 0.5 : position.dy / size.height;
  switch (preset) {
    case 'bothMargins':
      return fx < 0.25 || fx >= 0.75 ? NovelTapAction.forward : NovelTapAction.menu;
    case 'oneHand':
      if (fy < 0.12) return NovelTapAction.menu;
      return fx < 0.25 ? NovelTapAction.back : NovelTapAction.forward;
    default:
      if (fx < 0.25) return NovelTapAction.back;
      return fx >= 0.75 ? NovelTapAction.forward : NovelTapAction.menu;
  }
}
