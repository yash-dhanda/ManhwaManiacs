import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/novels/providers/novels_gate_provider.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/icons/glass_glyphs.g.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/radio_list.dart';
import 'package:manhwamaniacs/skins/glass/primitives/segmented.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The global position of the last content-mode switch: screens run their entrance wave from it.
final lastModeSwitchOriginProvider = StateProvider<Offset?>((ref) => null);

enum GlassContentModeVariant { sidebar, navRow, menu }

/// The two menu rows for the Library tab's long-press menu: a mutually exclusive pair.
List<GlassMenuEntry> glassContentModeMenuEntries(WidgetRef ref, {Rect? origin}) {
  final mode = ref.read(contentModeControllerProvider);
  return [
    for (final m in ContentMode.values)
      GlassMenuEntry(
        label: m.label,
        icon: m == ContentMode.novel ? GlassGlyph.bookOpen.regular : GlassGlyphs.stripScrollRegular,
        checked: mode == m,
        onSelected: () {
          if (origin != null) ref.read(lastModeSwitchOriginProvider.notifier).state = origin.center;
          unawaited(ref.read(contentModeControllerProvider.notifier).setMode(m));
        },
      ),
  ];
}

/// The Manga | Novels switch (glass 7.36). Rendered only when the server enables novels. `sidebar`: both segments
/// (a [GlassSegmented] with the glyphs `strip-scroll` and `book-open`); `navRow`: a compact 32 px capsule ("Manga" with a
/// `caret-down`, hit `hitMin`) that expands on press into the two segments (`springMorph`) with the line "One setting for
/// the whole app"; `menu`: a mutually exclusive pair of rows. Switching fires `select`, persists per profile through the
/// shared content-mode provider and records the switch's global position for the entrance wave.
class GlassContentModeSwitch extends ConsumerStatefulWidget {
  const GlassContentModeSwitch({super.key, this.variant = GlassContentModeVariant.sidebar});
  final GlassContentModeVariant variant;

  @override
  ConsumerState<GlassContentModeSwitch> createState() => _GlassContentModeSwitchState();
}

class _GlassContentModeSwitchState extends ConsumerState<GlassContentModeSwitch> {
  final GlobalKey _key = GlobalKey();
  bool _open = false;

  Offset? get _origin {
    final box = _key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  void _switch(ContentMode m) {
    if (m == ref.read(contentModeControllerProvider)) return;
    glassFire(ref, HapticEvent.select);
    ref.read(lastModeSwitchOriginProvider.notifier).state = _origin;
    unawaited(ref.read(contentModeControllerProvider.notifier).setMode(m));
    if (widget.variant == GlassContentModeVariant.navRow) setState(() => _open = false);
  }

  List<GlassSegment<ContentMode>> get _segments => [
        GlassSegment(value: ContentMode.manga, label: ContentMode.manga.label, icon: GlassGlyphs.stripScrollRegular),
        GlassSegment(value: ContentMode.novel, label: ContentMode.novel.label, icon: GlassGlyph.bookOpen.regular),
      ];

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(novelsEnabledProvider)) return const SizedBox.shrink();
    final mode = ref.watch(contentModeControllerProvider);
    switch (widget.variant) {
      case GlassContentModeVariant.sidebar:
        return KeyedSubtree(
          key: _key,
          child: SizedBox(width: 248, child: GlassSegmented<ContentMode>(segments: _segments, selected: mode, onSelected: _switch)),
        );
      case GlassContentModeVariant.menu:
        return KeyedSubtree(
          key: _key,
          child: GlassRadioList<ContentMode>(
            options: [for (final m in ContentMode.values) GlassRadioOption(value: m, label: m.label)],
            value: mode,
            onChanged: _switch,
          ),
        );
      case GlassContentModeVariant.navRow:
        final reduced = ref.watch(glassMotionPrefsProvider.select((m) => m.reduced));
        return KeyedSubtree(
          key: _key,
          child: AnimatedSize(
            duration: reduced ? const Duration(milliseconds: 150) : const Duration(milliseconds: 434),
            curve: reduced ? Curves.linear : SpringCurve(gt.springMorph, settleMs: 434),
            alignment: Alignment.topLeft,
            child: _open
                ? GlassHost(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 248, child: GlassSegmented<ContentMode>(segments: _segments, selected: mode, onSelected: _switch)),
                        const SizedBox(height: 6),
                        GlassText('One setting for the whole app', role: gt.typeFootnote, onGlass: true, color: gt.colorLabel2),
                      ],
                    ),
                  )
                : GlassPressable(
                    material: GlassMaterial.glass,
                    growth: GlassGrowth.light,
                    shape: const GlassShape.capsule(),
                    onTap: () => setState(() => _open = true),
                    semanticsLabel: '${mode.label}, content mode',
                    builder: (context, info) => SizedBox(
                      height: GlassFrame.hitMin(context),
                      child: Center(
                        child: SkinGlass(
                          size: Size(measureText(context, mode.label, roleStyle(context, gt.typeSubhead, onGlass: true, wght: 620)).width + 14 + 4 + 24, 32),
                          tier: GlassTierId.t2,
                          glow: info.glow,
                          layer: GlassLayerKind.controls,
                          debugLabel: 'GlassContentModeSwitch',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GlassText(mode.label, role: gt.typeSubhead, wght: 620, onGlass: true),
                              const SizedBox(width: 4),
                              GlyphIcon(GlassGlyph.caretDown, size: 14, color: gt.colorOnGlass),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        );
    }
  }
}
