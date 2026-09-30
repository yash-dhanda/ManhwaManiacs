import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/lens_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/object_lens.dart';
import 'package:manhwamaniacs/skins/skins.dart';

class CatalogueEmptyLens extends StatelessWidget {
  const CatalogueEmptyLens({super.key, this.q});
  final String? q;
  @override
  Widget build(BuildContext context) => GlassObjectLens(situation: LensSituation.nothingFound, title: q == null || q!.isEmpty ? 'No series found' : 'No results for “$q” on this source', placement: GlassLensPlacement.inline);
}

class CatalogueErrorLens extends StatelessWidget {
  const CatalogueErrorLens({super.key, required this.message, required this.onRetry});
  final String? message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => GlassObjectLens(situation: LensSituation.loadError, tone: GlassLensTone.error, title: "Couldn't load this catalogue", description: message, placement: GlassLensPlacement.inline, primary: LensAction('Try again', onRetry));
}

class CatalogueOfflineLens extends ConsumerWidget {
  const CatalogueOfflineLens({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => GlassObjectLens(
        situation: LensSituation.offline,
        tone: GlassLensTone.offline,
        title: 'This catalogue needs a connection',
        primary: LensAction('Open downloads', () => ref.read(skinRouterProvider).go(Routes.downloads())),
      );
}

enum CatalogueUnavailable { notBrowsable, notFound, gated }

class CatalogueUnavailableLens extends ConsumerWidget {
  const CatalogueUnavailableLens({super.key, required this.kind});
  final CatalogueUnavailable kind;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void back() => ref.read(skinRouterProvider).canPop() ? ref.read(skinRouterProvider).pop() : ref.read(skinRouterProvider).go(Routes.sources());
    return switch (kind) {
      CatalogueUnavailable.notBrowsable => GlassObjectLens(situation: LensSituation.unavailable, title: "This source can't be browsed; open its series from search or your library.", primary: LensAction('Back', back)),
      CatalogueUnavailable.notFound => GlassObjectLens(situation: LensSituation.notFound, title: 'This source was removed from the server.', primary: LensAction('Back', back)),
      CatalogueUnavailable.gated => GlassObjectLens(situation: LensSituation.unavailable, title: "This isn't available on this profile", primary: LensAction('Back home', () => ref.read(skinRouterProvider).go(Routes.tonight()))),
    };
  }
}
