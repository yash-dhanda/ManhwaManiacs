import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/onboarding/models/taste.dart';
import 'package:manhwamaniacs/features/onboarding/providers/onboarding_providers.dart';
import 'package:manhwamaniacs/features/onboarding/utils/genre_paragraph.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/onboarding/genre_word.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/onboarding/onboarding_common.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/onboarding/onboarding_flow.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/onboarding/onboarding_states.dart';

/// Step 3: the genre paragraph (cinematic 13, moment 11). A sliver.
class GenresStep extends ConsumerStatefulWidget {
  const GenresStep({super.key, required this.catalogKey});
  final CatalogKey catalogKey;

  @override
  ConsumerState<GenresStep> createState() => _GenresStepState();
}

class _GenresStepState extends ConsumerState<GenresStep> {
  final FocusScopeNode _scope = FocusScopeNode(debugLabel: 'genres');

  @override
  void dispose() {
    _scope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(onboardingCatalogProvider(widget.catalogKey));
    final flow = ref.watch(onboardingFlowProvider);
    final size = onboardingWide(context) ? 26.0 : 22.0;
    final Widget body;
    final data = catalog.valueOrNull;
    if (data == null && catalog.isLoading) {
      body = const AfterWait(child: GenresGalley());
    } else if (data == null || data.genres.isEmpty) {
      body = GenresUnreachable(onRetry: () => ref.invalidate(onboardingCatalogProvider(widget.catalogKey)));
    } else {
      final names = genreParagraph(data.genres);
      final style = genreStyle(context, size: size);
      body = Semantics(
        label: 'Genres',
        container: true,
        child: FocusScope(
          node: _scope,
          child: Text.rich(
            TextSpan(style: style, children: [
              for (final n in names) ...[
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: GenreWord(
                    name: n,
                    mark: flow.genreMark(n),
                    size: size,
                    scope: _scope,
                    onChange: (m, {required announce}) {
                      ref.read(onboardingFlowProvider.notifier).setGenre(n, m);
                      if (announce) {
                        final state = switch (m) {
                          GenreMark.like => 'liked',
                          GenreMark.love => 'loved',
                          GenreMark.skip => 'skipped',
                          null => 'cleared',
                        };
                        SemanticsService.sendAnnouncement(View.of(context), '$n: $state', TextDirection.ltr);
                      }
                    },
                  ),
                ),
                const TextSpan(text: ' ', style: TextStyle(wordSpacing: 4)),
              ],
            ],),
            textAlign: TextAlign.justify,
          ),
        ),
      );
    }
    return SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(8), child: body));
  }
}
