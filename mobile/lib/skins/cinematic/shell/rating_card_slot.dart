import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// The rating card the running head's neighbour shows (cinematic 8.33.5). The card and its callers
/// are mobile/07, mobile/11 and mobile/12; this is only the slot.
class RatingCardNotifier extends Notifier<Widget?> {
  @override
  Widget? build() => null;

  void show(Widget card) => state = card;
  void hide() => state = null;
}

final ratingCardProvider = NotifierProvider<RatingCardNotifier, Widget?>(RatingCardNotifier.new, name: 'ratingCard');

void showRatingCard(WidgetRef ref, Widget card) => ref.read(ratingCardProvider.notifier).show(card);
void hideRatingCard(WidgetRef ref) => ref.read(ratingCardProvider.notifier).hide();

/// Top-left under the running head, at `z.toast`.
class CineRatingCardSlot extends ConsumerWidget {
  const CineRatingCardSlot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = ref.watch(ratingCardProvider);
    if (card == null) return const SizedBox.shrink();
    final c = context.cine;
    final mq = MediaQuery.of(context);
    final left = mq.viewPadding.left + 8 > c.space4 ? mq.viewPadding.left + 8 : c.space4;
    return Positioned(
      top: mq.viewPadding.top + cineHitMin(context) + c.space2,
      left: left,
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 320), child: card),
    );
  }
}
