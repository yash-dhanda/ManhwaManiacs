import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/onboarding/utils/art_styles.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/onboarding/onboarding_common.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/onboarding/onboarding_flow.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// Step 4: a 3 x 3 grid of square plates, 12 px apart, across columns 1-4 (phone) or 2-7 (tablet).
/// While the nine crops are not bundled each plate is typographic. A sliver.
class ArtStyleStep extends ConsumerStatefulWidget {
  const ArtStyleStep({super.key});

  @override
  ConsumerState<ArtStyleStep> createState() => _ArtStyleStepState();
}

class _ArtStyleStepState extends ConsumerState<ArtStyleStep> {
  final FocusScopeNode _scope = FocusScopeNode(debugLabel: 'styles');

  @override
  void dispose() {
    _scope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(onboardingFlowProvider);
    final wide = onboardingWide(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(wide ? 8 + 64 : 8, 8, wide ? 8 + 64 : 8, 8),
        child: FocusScope(
          node: _scope,
          child: GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final s in kArtStyles)
                _Plate(
                  style: s,
                  selected: flow.hasStyle(s.id),
                  wide: wide,
                  scope: _scope,
                  onTap: () {
                    cineFeedback(context, HapticEvent.select, sound: SoundEvent.select);
                    ref.read(onboardingFlowProvider.notifier).toggleStyle(s.id);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Plate extends StatelessWidget {
  const _Plate({required this.style, required this.selected, required this.wide, required this.scope, required this.onTap});
  final ArtStyle style;
  final bool selected, wide;
  final FocusScopeNode scope;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Focus(
      canRequestFocus: false,
      onKeyEvent: (node, e) => rovingKey(FocusManager.instance.primaryFocus ?? node, e, scope: scope, grid: true),
      child: CinePressable(
        onTap: onTap,
        hit: false,
        builder: (context, st) => Semantics(
          button: true,
          toggled: selected,
          label: '${style.name}. ${style.description}',
          excludeSemantics: true,
          child: Impression(
            pressed: st.pressed,
            child: SelectFrame(
              selected: selected,
              child: kStyleArtBundled
                  ? Image.asset(style.asset, fit: BoxFit.cover)
                  : CineStock.raised(
                      DecoratedBox(
                        decoration: BoxDecoration(color: c.colorPaper1, border: Border.all(color: c.colorRule2)),
                        child: Padding(
                          padding: EdgeInsets.all(wide ? 16 : 12),
                          child: wide
                              ? Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  CineLit(style.name, CineFace.bodoni, 24, 28, italic: true, wght: 600, color: c.colorInk100),
                                  const SizedBox(height: 4),
                                  CineRoleText(style.description, c.typeCaption, color: c.colorInk60),
                                ],)
                              : SizedBox.expand(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.bottomLeft,
                                    child: CineLit(style.name, CineFace.bodoni, 16, 20, italic: true, wght: 600, color: c.colorInk100),
                                  ),
                                ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
