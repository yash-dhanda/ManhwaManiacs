import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/letter_reveal.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_rails.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/spotlight_card.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// The letter-reveal key of a rail header: `{profileId}:tonight:{railId}`.
String railRevealKey(WidgetRef ref, String railId) => '${ref.watch(activeProfileProvider.select((p) => p?.id)) ?? 0}:$kHomeScreenId:$railId';

/// Pushes a See all target.
VoidCallback? seeAllOf(WidgetRef ref, HomeRailSpec r) => r.seeAll == null ? null : () => ref.read(skinRouterProvider).go(r.seeAll!);

/// What every rail of Home shares: the handlers the cards need (the magnet targets for friend orbs, the lift phases).
class HomeRailEnv {
  const HomeRailEnv({required this.handlers, this.aiReason, required this.now});
  final SpotlightHandlers handlers;

  /// The server's reason the AI is off (for the unavailable notice).
  final String? aiReason;
  final DateTime now;
}

/// A rail header on its own (the chip rows and the mini rails of pinned sources, which are not [GlassRail]s).
class HomeRailHeader extends ConsumerWidget {
  const HomeRailHeader({super.key, required this.title, required this.railId, this.leading, this.trailing, this.onSeeAll});
  final String title, railId;
  final Widget? leading, trailing;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final margin = GlassFrame.screenMargin(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: margin),
      child: Row(
        children: [
          if (leading != null) Padding(padding: const EdgeInsets.only(right: 8), child: leading),
          Flexible(child: LetterReveal(title, role: gt.typeTitle2, revealKey: railRevealKey(ref, railId), screenId: kHomeScreenId, headingLevel: 2)),
          if (trailing != null) Padding(padding: const EdgeInsets.only(left: 8), child: trailing),
          const Spacer(),
        ],
      ),
    );
  }
}
