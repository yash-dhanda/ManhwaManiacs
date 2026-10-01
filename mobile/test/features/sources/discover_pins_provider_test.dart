import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/models/source_pin.dart';
import 'package:manhwamaniacs/features/sources/providers/discover_providers.dart';
import 'package:manhwamaniacs/features/sources/providers/source_pins_provider.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';

import '../../support/test_overrides.dart';

class _Pins extends SourcePinsNotifier {
  @override
  Future<SourcePinsState> build() async => const SourcePinsState(
        pins: [
          SourcePin(sourceId: 'manga', sortOrder: 0, name: 'Manga'),
          SourcePin(sourceId: 'novel', sortOrder: 1, name: 'Novel'),
        ],
        synced: true,
      );
}

SourceSummary _src(String id, String kind) =>
    SourceSummary(id: id, name: id, description: '', browsable: true, supportsImport: false, contentKind: kind);

void main() {
  test('Discover in Novels mode builds only from novel pins', () async {
    final container = ProviderContainer(overrides: [
      sourcePinsProvider.overrideWith(_Pins.new),
      sourcesListProvider.overrideWith((ref) async => [_src('manga', kMangaContentKind), _src('novel', kNovelContentKind)]),
      ...contentModeOverrides(mode: ContentMode.novel, novelsEnabled: true),
    ],);
    addTearDown(container.dispose);
    final sub = container.listen(discoverPinsProvider, (_, __) {});
    addTearDown(sub.close);
    await container.read(sourcePinsProvider.future);
    await container.read(sourcesListProvider.future);
    expect(container.read(discoverPinsProvider).map((p) => p.sourceId), ['novel']);
  });
}
