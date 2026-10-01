import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/slab.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/screens/wrapped/wrapped_origin.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// "Your {year} in chapters" (glass 8.24): shown only when `wrappedCardYear` gives a year (1 December to 31 January). Opens the
/// annual Wrapped, which grows out of this card's rect.
class WrappedCard extends ConsumerWidget {
  const WrappedCard({super.key, required this.year});
  final int year;

  @override
  Widget build(BuildContext context, WidgetRef ref) => GlassSlab(
        padding: const EdgeInsets.all(16),
        semanticsLabel: 'Your $year in chapters',
        onTap: () {
          final box = context.findRenderObject() as RenderBox?;
          ref.read(wrappedOriginProvider.notifier).state = box == null || !box.hasSize ? null : box.localToGlobal(Offset.zero) & box.size;
          GoRouter.of(context).go(Routes.annual(year));
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 132),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
            GlassText('$year', role: gt.typeDisplay),
            GlassText('Your $year in chapters', role: gt.typeHeadline),
          ],),
        ),
      );
}
