import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/storage/json_record.dart';
import 'package:manhwamaniacs/core/utils/contrast.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/stocks.dart';
import 'package:manhwamaniacs/skins/cinematic/tint.dart';

void main() {
  test('K26 palette ids migrate per the table', () {
    const map = {
      'black': 'nitrate', 'app': 'nitrate', null: 'nitrate', 'unknown': 'nitrate',
      'paper': 'ink', 'soft-grey': 'ink',
      'sepia': 'sepiaNight', 'cream': 'sepiaNight', 'dusk': 'sepiaNight',
      'midnight': 'dusk', 'solarized-dark': 'dusk', 'solarized-light': 'dusk',
      'forest': 'moss',
      'rose-pine': 'rosewood', 'dawn': 'rosewood',
    };
    map.forEach((k, v) => expect(stockFromPalette(k), v, reason: '$k'));
  });

  test('a stored stock wins over K26', () {
    expect(resolveStockId(const JsonRecord({'stock': 'moss'}), 'paper'), 'moss');
    expect(resolveStockId(const JsonRecord(), 'paper'), 'ink');
    expect(resolveStockId(const JsonRecord({'stock': 'bogus'}), null), 'nitrate');
  });

  test('every stock has readable ink and muted on its page; Issue falls back to Nitrate', () {
    for (final id in kNovelStockLabels.keys.where((k) => k != 'issue')) {
      final c = stockColorsFor(id);
      expect(contrastRatio(c.ink, c.page), greaterThanOrEqualTo(13), reason: '$id ink');
      expect(contrastRatio(c.muted, c.page), greaterThanOrEqualTo(4.5), reason: '$id muted');
    }
    expect(stockColorsFor('issue'), stockColorsFor('nitrate'));
    final a = ambientRoles(210, 0.5);
    final issue = stockColorsFor('issue', ambient: a);
    expect(issue.page, a.tint);
    expect(contrastRatio(issue.ink, issue.page), greaterThanOrEqualTo(13));
    expect(contrastRatio(issue.muted, issue.page), greaterThanOrEqualTo(5.5));
  });

  test('brightness layer alpha is |v|/100', () {
    expect(brightnessAlpha(0), 0);
    expect(brightnessAlpha(-75), 0.75);
    expect(brightnessAlpha(-40), 0.4);
  });
}
