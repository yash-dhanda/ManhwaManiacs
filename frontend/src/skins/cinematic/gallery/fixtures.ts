/** Gallery fixture data: invented titles, procedural demo covers (brand/demo, shared/04), no 18+ art, no real profile names. */
export const COVER = (n: number) => `/gallery/covers/${["01-salt-and-iron", "02-ember-ledger", "03-the-ninth-regression", "04-red-lantern-pact", "05-dune-courier", "06-copper-saints", "07-moonlit-bakery", "08-glass-tide", "09-frost-archive", "10-blue-hour-duel", "11-harbour-of-echoes", "12-cold-orbit"][(n - 1) % 12]}.webp`;

export const DUOS = ["#B8B2A4", "#D98A4E", "#6F8FD9", "#8FD9B6", "#D96F8F"] as const;

export const SERIES = [
  { id: "s1", title: "Salt and Iron", n: 1, kicker: "MANHWA · ONGOING · 142 CHAPTERS", deck: "A harbour tax collector inherits the debts of a drowned fleet.", why: "Because you finished three slow-burn harbour stories.", folio: "CH 142 · 3 NEW", progress: 63 },
  { id: "s2", title: "Ember Ledger", n: 2, kicker: "MANHWA · COMPLETED · 88 CHAPTERS", deck: "Every debt in the city is written in a book that burns.", folio: "NOT STARTED", progress: 0 },
  { id: "s3", title: "The Ninth Regression", n: 3, kicker: "MANHWA · ONGOING · 210 CHAPTERS", deck: "The ninth time back, she stops trying to win.", folio: "CH 12 OF 40", progress: 30 },
  { id: "s4", title: "Red Lantern Pact", n: 4, kicker: "MANHWA · HIATUS · 64 CHAPTERS", deck: "A pact sealed with paper lanterns and one honest lie.", folio: "CAUGHT UP", progress: 100 },
  { id: "s5", title: "Dune Courier", n: 5, kicker: "MANHWA · ONGOING · 31 CHAPTERS", deck: "Letters cross a desert that moves at night.", folio: "CH 31 · 1 NEW", progress: 90 },
  { id: "s6", title: "Copper Saints", n: 6, kicker: "MANHWA · ONGOING · 55 CHAPTERS", deck: "Statues in a mining town start keeping score.", folio: "NOT STARTED", progress: 0 },
  { id: "s7", title: "Moonlit Bakery", n: 7, kicker: "MANHWA · COMPLETED · 40 CHAPTERS", deck: "The oven only works when nobody is watching.", folio: "CH 12 OF 40", progress: 30 },
  { id: "s8", title: "Glass Tide", n: 8, kicker: "MANHWA · ONGOING · 19 CHAPTERS", deck: "The sea goes out and leaves a staircase.", folio: "NOT STARTED", progress: 0 },
  { id: "s9", title: "Frost Archive", n: 9, kicker: "MANHWA · ONGOING · 77 CHAPTERS", deck: "A librarian at the end of the world lends out winters.", folio: "CH 77 · 2 NEW", progress: 50 },
  { id: "s10", title: "Blue Hour Duel", n: 10, kicker: "MANHWA · ONGOING · 120 CHAPTERS", deck: "Two swordsmen agree to meet only at dusk.", folio: "CAUGHT UP", progress: 100 },
  { id: "s11", title: "Harbour of Echoes", n: 11, kicker: "MANHWA · ONGOING · 44 CHAPTERS", deck: "Every ship returns carrying somebody else's name.", folio: "NOT STARTED", progress: 0 },
  { id: "s12", title: "Cold Orbit", n: 12, kicker: "MANHWA · COMPLETED · 96 CHAPTERS", deck: "A station keeper counts the stars that stopped.", folio: "CH 96 · 0%", progress: 0 },
] as const;

export const LONG_LIST = Array.from({ length: 36 }, (_, i) => ({ ...SERIES[i % 12], id: `long-${i}`, title: `${SERIES[i % 12].title}${i >= 12 ? ` ${Math.floor(i / 12) + 1}` : ""}` }));

export const HEADLINE_40 = "The night the city forgot its own names.";
export const CREDITS = [
  { label: "Written by", value: "Ilse Marrow" }, { label: "Art by", value: "Tobias Wren" },
  { label: "Published", value: "2024 – present" }, { label: "Format", value: "Manhwa · 142 chapters" },
];
