import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/utils/contrast.dart';
import 'package:manhwamaniacs/skins/cinematic/tint.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

const _black = Color(0xFF000000);
const _white = Color(0xFFFFFFFF);
const _yellow = Color(0xFFF5F547);

/// Filled by mobile/15 (cinematic 8.16.5): the Listen voice field rows.
const List<(String, Color, Color)> voiceFieldRows = [];

/// (component, ink, alpha): a black scrim of [alpha] over the art with [ink] text on top
/// (cinematic 2.1.4). Later steps append rows (mobile/08 adds the Tonight rows).
const List<(String, Color, double)> overArtRows = [
  ('ink.100 minimum', CineColors.ink100, 0.60),
  ('ink.80 minimum', CineColors.ink80, 0.68),
  ('spot minimum', CineColors.spot, 0.66),
  ('set minimum', CineColors.colorSet, 0.70),
  ('ink.60 minimum', CineColors.ink60, 0.82),
  ('proof minimum', CineColors.proof, 0.84),
  ('onArt fill, ink.100', CineColors.ink100, 0.64),
  ('running head flat, ink.60', CineColors.ink60, 0.88),
  ('running head flat, spot', CineColors.spot, 0.88),
  ('running head flat, ink.100', CineColors.ink100, 0.88),
  ('folio bar flat, ink.60', CineColors.ink60, 0.90),
  ('folio bar flat, spot', CineColors.spot, 0.90),
  ('folio bar flat, ink.100', CineColors.ink100, 0.90),
  ('badge, ink.45', CineColors.ink45, 1.0),
  ('badge, ink.60', CineColors.ink60, 1.0),
  ('badge, ink.100', CineColors.ink100, 1.0),
  // mobile/08: the Tonight phone text block sits on the solid end of scrim.foot (alpha 1), and its
  // overflow button is an on-art fill.
  ('Tonight text block on scrim.foot, ink.100', CineColors.ink100, 1.0),
  ('Tonight text block on scrim.foot, ink.60', CineColors.ink60, 1.0),
  ('Tonight text block on scrim.foot, spot', CineColors.spot, 1.0),
  ('Tonight on-art overflow button, ink.100', CineColors.ink100, 0.64),
];

Color _scrimmed(Color art, double alpha) => compositeOver(Color.fromRGBO(0, 0, 0, alpha), art);

void main() {
  test('1,440 cases: page.light, Issue ink and muted ink hold their ratios, under a second', () {
    final sw = Stopwatch()..start();
    var cases = 0;
    for (var h = 0; h < 360; h++) {
      for (final s in const [0.08, 0.35, 0.60, 0.90]) {
        cases++;
        final light = pageLight(h.toDouble(), s);
        expect(contrastRatio(light, _black), greaterThanOrEqualTo(4.5), reason: 'pageLight h=$h s=$s');
        final stock = issueStock(ambientRoles(h.toDouble(), s));
        expect(contrastRatio(stock.ink, stock.page), greaterThanOrEqualTo(13), reason: 'issue ink h=$h s=$s');
        expect(contrastRatio(stock.muted, stock.page), greaterThanOrEqualTo(5.5), reason: 'issue muted h=$h s=$s');
      }
    }
    expect(cases, 1440);
    expect(sw.elapsedMilliseconds, lessThan(1000));
  });

  test('no ambient: Nitrate; a null seed: the ambient fallback ink; ambient ink reaches 7:1', () {
    final n = issueStock(null);
    expect((n.page, n.ink, n.muted), (const Color(0xFF000000), const Color(0xFFD9D6D0), const Color(0xFF8A877F)));
    expect(CineTint.light(null), CineColors.ambientFallbackInk);
    expect(contrastRatio(CineTint.light('#3355aa'), _black), greaterThanOrEqualTo(4.5));
    for (var h = 0; h < 360; h += 7) {
      expect(contrastRatio(ambientRoles(h.toDouble(), 0.5).ink, _black), greaterThanOrEqualTo(7));
    }
  });

  test('surface x ink loop (2.1.1)', () {
    final paper = [CineColors.paper0, CineColors.paper1, CineColors.paper2, CineColors.paper3, CineColors.paper4];
    final raised = <String, Color>{
      for (var i = 1; i < paper.length; i++) 'paper.$i': paper[i],
      'moodRomantic': CineColors.moodRomantic,
      'moodAction': CineColors.moodAction,
      'moodComedy': CineColors.moodComedy,
      'moodHorror': CineColors.moodHorror,
      'moodSliceOfLife': CineColors.moodSliceOfLife,
      'moodFantasy': CineColors.moodFantasy,
      'ambient fallback tint': CineColors.ambientFallbackTint,
      'ground.ink': CineColors.groundInk,
      'ground.slate': CineColors.groundSlate,
      'nitrate': CineColors.stockNitratePage,
      'ink': CineColors.stockInkPage,
      'sepiaNight': CineColors.stockSepiaNightPage,
      'dusk': CineColors.stockDuskPage,
      'moss': CineColors.stockMossPage,
      'rosewood': CineColors.stockRosewoodPage,
    };
    final wash = <String, Color>{
      for (var i = 0; i < 4; i++) 'spot.wash over paper.$i': compositeOver(CineColors.spotWash, paper[i]),
      for (var i = 0; i < 4; i++) 'proof.wash over paper.$i': compositeOver(CineColors.proofWash, paper[i]),
    };
    const semantic = {'spot': CineColors.spot, 'set': CineColors.colorSet, 'info': CineColors.info, 'proof': CineColors.proof};
    void check(String ground, Color bg, Map<String, Color> inks) {
      inks.forEach((name, ink) => expect(contrastRatio(ink, bg), greaterThanOrEqualTo(4.5), reason: '$name on $ground'));
    }

    // paper.0 is the only ground where ink.45 renders as itself.
    check('paper.0', paper[0], {'ink.45': CineColors.ink45, 'ink.60': CineColors.ink60, 'ink.80': CineColors.ink80, 'ink.100': CineColors.ink100, ...semantic});
    raised.forEach((g, bg) => check(g, bg, {'ink.45 -> ink.60': CineColors.ink60, 'ink.80': CineColors.ink80, 'ink.100': CineColors.ink100, ...semantic}));
    // A wash carries its own colour's text (spot on spot.wash, proof on proof.wash), not the other's.
    wash.forEach((g, bg) => check(g, bg, {
          'ink.45/60 -> ink.80': CineColors.ink80,
          'ink.100': CineColors.ink100,
          if (g.startsWith('spot')) 'spot': CineColors.spot else 'proof': CineColors.proof,
        }),);

    final avatars = [
      CineColors.avatarViolet, CineColors.avatarCyan, CineColors.avatarRose, CineColors.avatarAmber, CineColors.avatarEmerald, CineColors.avatarEmber,
      CineColors.avatarBlade, CineColors.avatarPhantom, CineColors.avatarArcane, CineColors.avatarLunar, CineColors.avatarStar, CineColors.avatarReader,
    ];
    expect(avatars, hasLength(12));
    for (final f in avatars) {
      expect(contrastRatio(CineColors.ink100, f), greaterThanOrEqualTo(4.5), reason: 'ink.100 on avatar $f');
    }
    expect(voiceFieldRows, isEmpty); // mobile/15 fills it
  });

  test('over-art table (2.1.4): every row reaches 4.5:1 over white and over #F5F547', () {
    for (final (name, ink, alpha) in overArtRows) {
      for (final art in const [_white, _yellow]) {
        expect(contrastRatio(ink, _scrimmed(art, alpha)), greaterThanOrEqualTo(4.5), reason: '$name over $art');
      }
    }
  });

  test('compositeOver', () {
    expect(compositeOver(const Color(0x80FFFFFF), _black).r, closeTo(0.5, 0.01));
    expect(compositeOver(_white, _black), _white);
  });
}
