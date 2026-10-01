import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/slab.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// "Your {year} in chapters" (glass 8.24): shown only when `wrappedCardYear` gives a year (1 December to 31 January). Opens the
/// annual Wrapped; `mobile/42` adds the entry rect.
class WrappedCard extends StatelessWidget {
  const WrappedCard({super.key, required this.year});
  final int year;

  @override
  Widget build(BuildContext context) => GlassSlab(
        padding: const EdgeInsets.all(16),
        semanticsLabel: 'Your $year in chapters',
        onTap: () => GoRouter.of(context).go(Routes.annual(year)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 132),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
            GlassText('$year', role: gt.typeDisplay),
            GlassText('Your $year in chapters', role: gt.typeHeadline),
          ],),
        ),
      );
}
