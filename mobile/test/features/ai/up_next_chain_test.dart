import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/ai/utils/up_next_chain.dart';

void main() {
  test('the first source with items wins: similar, then because, then the shelf', () {
    UpNextSource? at;
    expect(upNextChain(similar: [1], because: [2], shelf: [3], onPicked: (s) => at = s), [1]);
    expect(at, UpNextSource.similar);
    expect(upNextChain(similar: <int>[], because: [2], shelf: [3], onPicked: (s) => at = s), [2]);
    expect(at, UpNextSource.because);
    expect(upNextChain(similar: <int>[], because: <int>[], shelf: [3], onPicked: (s) => at = s), [3]);
    expect(at, UpNextSource.shelf);
    expect(upNextChain(similar: <int>[], because: <int>[], shelf: <int>[]), isEmpty);
  });
}
