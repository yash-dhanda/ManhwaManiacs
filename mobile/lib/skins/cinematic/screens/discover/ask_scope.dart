import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/library/providers/intelligence_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/ai_copy.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_extras.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_poster.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// ASK scope body: the thinking line, then World cards one column, or the
/// §9.1.8 copy for an unavailable / failed ask (never `proof`).
class AskScope extends ConsumerWidget {
  const AskScope({
    super.key,
    required this.query,
    required this.onSearchInstead,
  });

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
            Expanded(
              child: TypedText(
                'Reading your shelf…',
                style: cineText(context, t.typePull),
              ),
            ),
            const SizedBox(width: CineSpace.s3),
            const DelayedShow(child: LeaderDial(size: 24)),
          ],
        ),
      );
    }
    if (state.hasError) {
      final copy = aiCopyForError(state.error!);
      final err = state.error;
      final after = err is ApiError ? retryAfterSeconds(err) : null;
      return CineNotice(
        kicker: copy.kicker,
        kickerColor: t.colorSpot,
        headline: copy.rateLimited ? 'Too many asks at once.' : copy.text,
        folio: copy.rateLimited
            ? RetryCountdown(
                seconds: after ?? 12,
                style: cineText(context, t.typeFolio, color: t.colorSpot),
              )
            : null,
        actions: [
          QuietButton(
            'Search sources for "$query" instead',
            onPressed: onSearchInstead,
          ),
        ],
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
        for (var i = 0; i < items.length; i++)
          _WorldCard(
            key: ValueKey('world-$i'),
            index: i,
            title: items[i].title,
            coverUrl: items[i].coverUrl,
            why: items[i].why,
            onTap: () => context.push(
              Routes.discover({'q': items[i].title, 'scope': 'sources'}),
            ),
          ),
        QuietButton(
          'Search sources for "$query" instead',
          onPressed: onSearchInstead,
        ),
      ],
    );
  }
}

/// §7.6 World card without an image band: cover, title and the editors' why,
/// fading in 160 ms each, 30 ms apart (a plain fade under reduced motion).
class _WorldCard extends StatelessWidget {
  const _WorldCard({
    super.key,
    required this.index,
    required this.title,
    required this.coverUrl,
    required this.why,
    required this.onTap,
  });

  final int index;
  final String title;
  final String? coverUrl;
  final String? why;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    final reduced = cineReduced(context);
    final card = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CineSpace.s4,
        vertical: CineSpace.s2,
      ),
      child: Semantics(
        button: true,
        label: why == null ? title : '$title. $why',
        excludeSemantics: true,
        child: ChildFocusRing(child: InkWell(
            onTap: onTap,
            child: Container(
              color: t.colorPaper1,
              padding: const EdgeInsets.all(CineSpace.s3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 64,
                    height: 96,
                    child: CineCover(url: coverUrl, displayWidth: 64),
                  ),
                  const SizedBox(width: CineSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: cineText(context, t.typeSubhead)),
                        if (why != null)
                          Text(
                            why!,
                            style: cineText(
                              context,
                              t.typeDeck,
                              color: t.colorInk60,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final totalMs = 160 + 30 * index;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: reduced ? Duration.zero : Duration(milliseconds: totalMs),
      curve: Interval(30 * index / totalMs, 1, curve: Curves.easeOut),
      builder: (_, v, child) => Opacity(opacity: v, child: child),
      child: card,
    );
  }
}
