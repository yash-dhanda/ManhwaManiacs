import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/novels/providers/novels_gate_provider.dart';
import 'package:manhwamaniacs/features/onboarding/models/taste.dart';
import 'package:manhwamaniacs/features/onboarding/providers/onboarding_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/cine_grain.dart';
import 'package:manhwamaniacs/skins/cinematic/duotone.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/layout/cine_grid.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/onboarding/onboarding_common.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/onboarding/onboarding_flow.dart';
import 'package:manhwamaniacs/skins/cinematic/tint.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

const _names = {FormatId.manhwa: 'Manhwa', FormatId.manga: 'Manga', FormatId.manhua: 'Manhua', FormatId.novel: 'Novels'};

/// Step 2: which formats the reader reads. A sliver. Multi-select; `Next` is always enabled.
class FormatsStep extends ConsumerWidget {
  const FormatsStep({super.key, required this.catalogKey});
  final CatalogKey catalogKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final novels = ref.watch(novelsEnabledProvider);
    final flow = ref.watch(onboardingFlowProvider);
    final catalog = ref.watch(onboardingCatalogProvider(catalogKey));
    final grid = CineGrid.of(context);
    final span = grid.span(onboardingWide(context) ? 4 : 2);
    final formats = [FormatId.manhwa, FormatId.manga, FormatId.manhua, if (novels) FormatId.novel];
    final loading = catalog.isLoading && !catalog.hasValue;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: FocusScope(
          child: Wrap(spacing: grid.gutter, runSpacing: grid.gutter, children: [
            for (final f in formats)
              SizedBox(
                width: span,
                child: FormatTile(
                  format: f,
                  covers: catalog.valueOrNull?.formats.where((e) => e.format == f).firstOrNull?.covers ?? const [],
                  loading: loading,
                  selected: flow.hasFormat(f),
                  onTap: () {
                    cineFeedback(context, HapticEvent.select, sound: SoundEvent.select);
                    ref.read(onboardingFlowProvider.notifier).toggleFormat(f);
                  },
                ),
              ),
          ],),
        ),
      ),
    );
  }
}

/// One format plate: 2:3, three cover strips in duotone, grain, the foot scrim and the word.
class FormatTile extends StatelessWidget {
  const FormatTile({super.key, required this.format, required this.covers, required this.loading, required this.selected, required this.onTap});
  final FormatId format;
  final List<String> covers;
  final bool loading, selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final name = _names[format]!;
    return CinePressable(
      onTap: onTap,
      hit: false,
      builder: (context, st) => Semantics(
        button: true,
        toggled: selected,
        label: name,
        excludeSemantics: true,
        child: Impression(
          pressed: st.pressed,
          child: SelectFrame(
            selected: selected,
            child: AspectRatio(
              aspectRatio: 2 / 3,
              child: LayoutBuilder(builder: (context, box) {
                final h = box.maxHeight;
                Widget mosaic = const SizedBox.expand();
                if (loading) {
                  mosaic = CineFlicker(index: format.index, child: ColoredBox(color: c.colorPaper1, child: const SizedBox.expand()));
                } else if (covers.isNotEmpty) {
                  mosaic = CineGrain(
                    child: CineDuotone(
                      duo: c.colorAmbientFallbackDuo,
                      child: Row(children: [
                        for (var i = 0; i < 3; i++)
                          Expanded(
                            child: i < covers.length
                                ? SizedBox.expand(child: CineImage(url: covers[i], withCredentials: false, flickerIndex: i))
                                : ColoredBox(color: c.colorPaper1, child: const SizedBox.expand()),
                          ),
                      ],),
                    ),
                  );
                } else {
                  // Catalog unreachable: a typographic plate, still selectable.
                  mosaic = DecoratedBox(
                    decoration: BoxDecoration(color: c.colorPaper1, border: Border.all(color: c.colorRule2)),
                    child: const SizedBox.expand(),
                  );
                }
                return Stack(fit: StackFit.expand, children: [
                  mosaic,
                  if (covers.isNotEmpty && !loading)
                    DecoratedBox(decoration: BoxDecoration(gradient: cineScrimFoot(solidAtPx: h - 16 - 36 - 24, height: h, tint: c.colorAmbientFallbackTint))),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: CineLit(name, CineFace.bodoni, 32, 36, italic: true, wght: 600, tracking: -0.015, color: c.colorInk100),
                  ),
                ],);
              },),
            ),
          ),
        ),
      ),
    );
  }
}
