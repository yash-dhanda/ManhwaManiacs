/// Fixture data for the primitives gallery: invented titles, procedural demo covers, no 18+ art and
/// no real profile names.
const List<String> kGalleryCovers = [
  'assets/gallery/covers/01-salt-and-iron.webp',
  'assets/gallery/covers/02-ember-ledger.webp',
  'assets/gallery/covers/07-moonlit-bakery.webp',
  'assets/gallery/covers/13-night-ward.webp',
  'assets/gallery/covers/17-petal-almanac.webp',
  'assets/gallery/covers/23-white-room-protocol.webp',
];

const List<String> kGalleryTitles = [
  'Salt and Iron',
  'Ember Ledger',
  'Moonlit Bakery',
  'Night Ward',
  'Petal Almanac',
  'White Room Protocol',
];

String galleryCover(int i) => kGalleryCovers[i % kGalleryCovers.length];

String galleryTitle(int i) => kGalleryTitles[i % kGalleryTitles.length];

const List<String> kGalleryGenres = ['Romance', 'Action', 'Fantasy', 'Slice of life', 'Horror'];
