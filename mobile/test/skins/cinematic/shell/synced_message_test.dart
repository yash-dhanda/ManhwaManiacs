import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/auth/providers/offline_edition_controller.dart';

void main() {
  test('Synced {n} reads and {m} bookmarks', () {
    expect(syncedMessage(3, 2), 'Synced 3 reads and 2 bookmarks.');
    expect(syncedMessage(1, 1), 'Synced 1 read and 1 bookmark.');
    expect(syncedMessage(12, 1), 'Synced 12 reads and 1 bookmark.');
  });

  test('a zero part is dropped, none when both are zero', () {
    expect(syncedMessage(3, 0), 'Synced 3 reads.');
    expect(syncedMessage(1, 0), 'Synced 1 read.');
    expect(syncedMessage(0, 2), 'Synced 2 bookmarks.');
    expect(syncedMessage(0, 1), 'Synced 1 bookmark.');
    expect(syncedMessage(0, 0), isNull);
  });
}
