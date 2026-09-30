/// The genres of the onboarding genre field (glass 8.7), ranked; identical to the web twin's `genres.ts`.
const List<String> kGlassGenres = [
  'Action',
  'Fantasy',
  'Romance',
  'Drama',
  'Comedy',
  'Adventure',
  'Martial Arts',
  'Isekai',
  'Regression',
  'Slice of Life',
  'Supernatural',
  'Mystery',
  'Psychological',
  'Thriller',
  'Horror',
  'School Life',
  'Historical',
  'Sci-Fi',
  'Sports',
  'Murim',
  'System',
  'Tragedy',
  'Revenge',
  'Cooking',
];

/// The five mature genres: they exist only while the profile's 18+ gate is open, taking ranks 20 to 24.
const List<String> kMatureGenres = ['Adult', 'Ecchi', 'Hentai', 'Mature', 'Smut'];

/// The 24 bodies of the field: the ranked list, or with [matureOpen] the first 19 and the five mature genres.
List<String> glassGenres({required bool matureOpen}) => matureOpen ? [...kGlassGenres.take(19), ...kMatureGenres] : kGlassGenres;

/// `r = 52 - (rank - 1) * 16 / 23` px: the first genre 52, the last 36.
double genreRadius(int rank, {int total = 24}) => total <= 1 ? 52 : 52 - (rank - 1) * 16 / (total - 1);
