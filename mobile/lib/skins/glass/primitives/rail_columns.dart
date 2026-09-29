/// `↑` and `↓` between rails of a group keep the column (glass 7.9): the item at the same horizontal
/// position in the viewport. [fromIndex] sits at `fromIndex * stride - fromScroll` from the rail's start.
int railColumn(int fromIndex, double fromScroll, double toScroll, double stride) {
  final column = fromIndex * stride - fromScroll;
  return ((toScroll + column) / stride).round().clamp(0, 1 << 30);
}
