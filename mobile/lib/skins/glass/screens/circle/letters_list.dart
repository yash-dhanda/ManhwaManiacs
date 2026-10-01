import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/chip.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/screens/circle/circle_states.dart';
import 'package:manhwamaniacs/skins/glass/screens/circle/letter_card.dart';

/// Whether the Letters section shows what this profile sent.
final circleSentFilterProvider = StateProvider.autoDispose<bool>((ref) => false, name: 'glassCircleSent');

/// Letters (glass 9.3.1): received letters, or with the "Sent" chip what this profile recommended.
class CircleLetters extends ConsumerWidget {
  const CircleLetters({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sent = ref.watch(circleSentFilterProvider);
    final m = GlassFrame.screenMargin(context);
    final Widget body;
    if (sent) {
      final a = ref.watch(sentLettersProvider);
      body = a.when(
        data: (list) => list.isEmpty
            ? const CircleEmpty('Nothing sent yet. Lift a poster onto a friend to recommend it.')
            : Column(children: [for (final l in list) Padding(padding: const EdgeInsets.only(bottom: 12), child: GlassSentLetterCard(key: ValueKey(l.id), letter: l))]),
        loading: () => const GlassSkeletonGroup(label: 'Loading letters', child: Column(children: [GlassSkeleton(height: 160, radius: 26), SizedBox(height: 12), GlassSkeleton(height: 160, radius: 26, index: 1)])),
        error: (_, __) => CircleError(title: "Couldn't load your letters", onRetry: () => ref.invalidate(sentLettersProvider)),
      );
    } else {
      final a = ref.watch(lettersProvider);
      body = a.when(
        data: (list) {
          final shown = [for (final l in list) if (l.state != LetterState.dismissed) l];
          return shown.isEmpty
              ? const CircleEmpty(CircleEmpty.letters)
              : Column(children: [for (final l in shown) Padding(padding: const EdgeInsets.only(bottom: 12), child: GlassLetterCard(key: ValueKey(l.id), letter: l))]);
        },
        loading: () => const GlassSkeletonGroup(label: 'Loading letters', child: Column(children: [GlassSkeleton(height: 200, radius: 26), SizedBox(height: 12), GlassSkeleton(height: 200, radius: 26, index: 1)])),
        error: (_, __) => CircleError(title: "Couldn't load your letters", onRetry: () => ref.invalidate(lettersProvider)),
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: m),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassChip(label: 'Sent', selected: sent, onPressed: () => ref.read(circleSentFilterProvider.notifier).state = !sent),
        ),
        body,
      ],),
    );
  }
}
