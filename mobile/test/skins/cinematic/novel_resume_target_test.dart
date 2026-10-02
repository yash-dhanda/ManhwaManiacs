import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/quick_look_builders.dart';

void main() {
  test('a novel resume target carries the saved bucket', () {
    expect(readerTargetFor('src', 's', 'c7', novel: true, page: 60).location, contains('page=60'));
    expect(readerTargetFor('src', 's', 'c7', novel: false, page: 12).location, contains('page=12'));
  });
}
