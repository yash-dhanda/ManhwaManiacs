import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/core/network/api_image.dart';
import 'package:manhwamaniacs/core/network/interceptors/auth_interceptor.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_poster.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/poster.dart';

import '../../support/test_overrides.dart';

/// Source logos are third-party favicons: the session token must stay home.
void main() {
  Future<Map<String, String>?> headersFor(WidgetTester tester, Widget cover) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authTokenStoreProvider.overrideWithValue(AuthTokenStore()..token = 'secret'),
          apiBaseUrlProvider.overrideWith((ref) => 'https://api.example.com'),
          activeProfileOverride(),
        ],
        child: MaterialApp(theme: ThemeData(extensions: const [cinematicTokens]), home: SizedBox(width: 40, height: 40, child: cover)),
      ),
    );
    return tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage)).httpHeaders;
  }

  test('isApiResourceUrl', () {
    expect(isApiResourceUrl('https://api.example.com', '/sources/a/cover'), isTrue);
    expect(isApiResourceUrl('https://api.example.com/', 'https://api.example.com/x'), isTrue);
    expect(isApiResourceUrl('https://api.example.com', 'https://api.example.com.evil.net/x'), isFalse);
    expect(isApiResourceUrl('https://api.example.com', 'https://nhentai.net/favicon.ico'), isFalse);
  });

  for (final (name, build) in <(String, Widget Function(String))>[
    ('CineCover', (u) => CineCover(url: u)),
    ('GlassCoverImage', (u) => GlassCoverImage(url: u)),
  ]) {
    testWidgets('$name sends no credentials to a third-party URL', (tester) async {
      expect(await headersFor(tester, build('https://asuracomic.net/favicon.ico')), isNull);
    });
    testWidgets('$name still authenticates API covers', (tester) async {
      final h = await headersFor(tester, build('https://api.example.com/sources/a/series/b/cover'));
      expect(h?['Authorization'], 'Bearer secret');
    });
  }
}
