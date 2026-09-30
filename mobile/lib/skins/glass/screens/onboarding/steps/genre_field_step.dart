import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/downloads/providers/mature_gate_provider.dart';
import 'package:manhwamaniacs/skins/glass/copy/genres.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/letter_reveal.dart';
import 'package:manhwamaniacs/skins/glass/screens/onboarding/genre_field_view.dart';

/// Step 4, the genre field (glass 8.7): 24 bodies; the five mature genres only while this profile's gate is open.
class GlassGenreStep extends ConsumerWidget {
  const GlassGenreStep({super.key, required this.weights, required this.onWeight, required this.visible});
  final Map<String, int> weights;
  final void Function(String name, int weight) onWeight;
  final bool visible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mature = ref.watch(matureGateOpenProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(alignment: Alignment.centerLeft, child: LetterReveal('Which genres pull you in?', role: gt.typeTitle1, screenId: 'onboarding', revealKey: '4', headingLevel: 1)),
        const SizedBox(height: 12),
        Expanded(
          child: GenreFieldView(names: glassGenres(matureOpen: mature), weights: weights, onWeight: onWeight, visible: visible),
        ),
      ],
    );
  }
}
