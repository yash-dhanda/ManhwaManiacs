import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/providers/shelf_provider.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/rail.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/continue_rail.dart' show ContinueCard;

/// The shelf's Continue rail (glass 8.17): up to 12 Continue stacks (280 x 132 on phones, 320 x 148 on desktop frames) from
/// `GET /library/continue-reading?limit=12`. Hidden when empty, while searching or while a filter is on (the caller passes [show]).
class ShelfContinueRail extends ConsumerWidget {
  const ShelfContinueRail({super.key, required this.show});
  final bool show;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!show) return const SizedBox.shrink();
    final items = ref.watch(shelfContinueProvider).valueOrNull ?? const [];
    if (items.isEmpty) return const SizedBox.shrink();
    final wide = GlassFrame.of(context).index >= GlassFrameKind.desktop.index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassRail(
        title: 'Continue reading',
        screenId: 'library',
        itemCount: items.length,
        itemWidth: wide ? 320 : 280,
        itemHeight: (wide ? 148 : 132) * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.5),
        itemBuilder: (context, i) => ContinueCard(item: items[i]),
      ),
    );
  }
}
