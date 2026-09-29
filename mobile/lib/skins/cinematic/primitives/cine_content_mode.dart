import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/novels/providers/novels_gate_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/sheet_route.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The typographic `MANGA / NOVELS` toggle (cinematic 7.29): the active word `ink.100` with a 2 px
/// `spot` underline, the other `ink.45`. Reads and writes [contentModeControllerProvider]; renders
/// nothing while the novels gate is shut.
class CineContentModeToggle extends ConsumerWidget {
  const CineContentModeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(novelsEnabledProvider)) return const SizedBox.shrink();
    final mode = ref.watch(contentModeControllerProvider);
    final c = context.cine;
    Widget word(ContentMode m, String label) {
      final on = mode == m;
      return Semantics(
        inMutuallyExclusiveGroup: true,
        checked: on,
        button: true,
        label: label,
        excludeSemantics: true,
        onTap: () => _set(context, ref, m),
        child: CinePressable(
          onTap: () => _set(context, ref, m),
          builder: (context, st) => Container(
            padding: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: on ? c.colorSpot : const Color(0x00000000), width: 2))),
            child: CineRoleText(label.toUpperCase(), c.typeNav, color: on || st.hovered ? c.colorInk100 : c.colorInk45),
          ),
        ),
      );
    }

    return Row(mainAxisSize: MainAxisSize.min, children: [
      word(ContentMode.manga, 'Manga'),
      Padding(padding: EdgeInsets.symmetric(horizontal: c.space2), child: CineRoleText('/', c.typeNav, color: c.colorInk45)),
      word(ContentMode.novel, 'Novels'),
    ],);
  }

  static void _set(BuildContext context, WidgetRef ref, ContentMode m) {
    if (ref.read(contentModeControllerProvider) == m) return;
    cineFeedback(context, HapticEvent.select);
    ref.read(contentModeControllerProvider.notifier).setMode(m);
  }
}

/// The running-head chip `MANGA ▾` / `NOVELS ▾`: opens a small sheet with the toggle.
class CineContentModeChip extends ConsumerWidget {
  const CineContentModeChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(novelsEnabledProvider)) return const SizedBox.shrink();
    final mode = ref.watch(contentModeControllerProvider);
    final c = context.cine;
    final word = mode == ContentMode.novel ? 'NOVELS' : 'MANGA';
    return Semantics(
      button: true,
      label: 'Reading mode, $word',
      excludeSemantics: true,
      onTap: () => _open(context),
      child: CinePressable(
        onTap: () => _open(context),
        builder: (context, st) => Row(mainAxisSize: MainAxisSize.min, children: [
          CineRoleText(word, c.typeNav, color: st.hovered ? c.colorInk100 : c.colorInk60),
          SizedBox(width: c.space1),
          CineGlyphIcon(CineGlyph.caretDown, size: 16, color: c.colorInk60),
        ],),
      ),
    );
  }

  void _open(BuildContext context) {
    showCineSheet<void>(
      context,
      kicker: 'READING MODE',
      title: 'Reading mode',
      builder: (ctx) {
        final c = ctx.cine;
        return Padding(
          padding: EdgeInsets.all(c.space4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const CineContentModeToggle(),
            SizedBox(height: c.space4),
            CineRoleText('One setting for the whole app: library, sources, search, downloads and updates all follow it.', c.typeCaption, color: c.colorInk60),
          ],),
        );
      },
    );
  }
}
