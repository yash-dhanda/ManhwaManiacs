import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rating_descriptors.dart';

void main() {
  test('descriptors from genres', () {
    expect(ratingDescriptors(['Action', 'Violence', 'Smut']), ['Violence', 'Sexual content']);
    expect(ratingDescriptors(['GORE', 'Horror', 'Psychological', 'Drugs']), ['Gore', 'Horror', 'Psychological themes']);
    expect(ratingDescriptors(['Romance']), ['Mature themes']);
    expect(ratingDescriptors(const []), ['Mature themes']);
    expect(ratingDescriptorLine(['Ecchi', 'Horror']), 'Sexual content · Horror');
    expect(ratingAnnouncement(['Violence', 'Ecchi']), 'Rated 18 plus: Violence, Sexual content');
  });
}
