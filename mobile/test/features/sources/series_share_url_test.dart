import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/sources/utils/series_share_url.dart';

void main() {
  test('series links go to the web app, not the API host', () {
    expect(seriesShareUrl('https://app.manhwamaniacs.xyz', '/sources/asurascans/series/x'), 'https://manhwamaniacs.xyz/sources/asurascans/series/x');
    expect(seriesShareUrl('https://manhwamaniacs.xyz/api/', '/sources/a/series/b%20c'), 'https://manhwamaniacs.xyz/sources/a/series/b%20c');
    expect(seriesShareUrl('http://127.0.0.1:8000', '/sources/a/series/b'), 'http://127.0.0.1:8000/sources/a/series/b');
  });
}
