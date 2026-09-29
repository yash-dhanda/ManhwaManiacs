import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/library/providers/intelligence_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/ai_copy.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_poster.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// ASK scope body: the thinking line, then World cards one column, or the
/// §9.1.8 copy for an unavailable / failed ask (never `proof`).
class AskScope extends ConsumerWidget {
  const AskScope({super.key, required this.query, required this.onSearchInstead});

  final String query;
  final VoidCallback onSearchInstead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.cine;
    final state = ref.watch(suggestionsProvider);
    if (state.isLoading) {
      return Padding(
        padding: const EdgeInsets.all(CineSpace.s4),
        child: Row(
          children: [
            TypedText('Reading your shelf…', style: cineText(context, t.typePull)),
            const SizedBox(width: CineSpace.s3),
            const LeaderDial(size: 24),
          ],
        ),
      );
    }
    if (state.hasError) {
      final copy = aiCopyForError(state.error!);
      return CineNotice(
        kicker: copy.kicker,
        kickerColor: t.colorSpot,
        headline: copy.text,
        actions: [QuietButton('Search sources for "$query" instead', onPressed: onSearchInstead)],
      );
    }
    final items = state.valueOrNull?.items;
    if (items == null) {
      return Padding(
        padding: const EdgeInsets.all(CineSpace.s4),
        child: Text(
          'Press search to ask the editors.',
          style: cineText(context, t.typeCaption, color: t.colorInk60),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final it in items)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: CineSpace.s4, vertical: CineSpace.s3),
            child: InkWell(
              onTap: () => context.push(
                Routes.discover({'q': it.title, 'scope': 'sources'}),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 64,
                    height: 96,
                    child: CineCover(url: it.coverUrl, displayWidth: 64),
                  ),
                  const SizedBox(width: CineSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(it.title, style: cineText(context, t.typeSubhead)),
                        if (it.why != null)
                          Text(it.why!, style: cineText(context, t.typeDeck, color: t.colorInk60)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        QuietButton('Search sources for "$query" instead', onPressed: onSearchInstead),
      ],
    );
  }
}
