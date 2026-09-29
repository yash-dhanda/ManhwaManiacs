import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/reorder_announce.dart';

void main() {
  test('the announcement', () {
    expect(moveAnnouncement('Solo Leveling', 3, 12), 'Solo Leveling moved to position 3 of 12');
  });
  test('moves are disabled at the ends', () {
    expect(CineMove.up.target(0, 5), isNull);
    expect(CineMove.top.target(0, 5), isNull);
    expect(CineMove.down.target(4, 5), isNull);
    expect(CineMove.bottom.target(4, 5), isNull);
    expect(CineMove.up.target(2, 5), 1);
    expect(CineMove.down.target(2, 5), 3);
    expect(CineMove.top.target(2, 5), 0);
    expect(CineMove.bottom.target(2, 5), 4);
  });
  test('labels', () {
    expect([for (final m in CineMove.values) m.label], ['Move up', 'Move down', 'Move to top', 'Move to bottom']);
  });
}
