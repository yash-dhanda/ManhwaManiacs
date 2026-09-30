import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/skins/glass/dev/demo_cover.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/poster.dart';
import 'package:manhwamaniacs/skins/glass/routes/nav_extra.dart';
import 'package:manhwamaniacs/skins/glass/shell/accessory_controller.dart';
import 'package:manhwamaniacs/skins/glass/shell/glass_scaffold.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_common.dart';
import 'package:manhwamaniacs/skins/glass/transitions/dive.dart';
import 'package:manhwamaniacs/skins/glass/transitions/poster_zoom.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// `/dev/glass/shell`: the Glass shell with a scaffold, a trailing group of three, 80 rows, a poster rail that pushes `feature` sheet
/// routes, buttons that publish each accessory slot, a chapter-row button that runs the Dive and links that push three levels.
class GlassShellDemo extends ConsumerWidget {
  const GlassShellDemo({super.key, this.level = 0});
  final int level;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final acc = ref.read(glassAccessoryProvider.notifier);
    final title = level == 0 ? 'Shell' : 'Level $level';
    return GlassScaffold(
      title: title,
      mature: level == 3,
      leading: level == 0 ? GlassLeading.profile : GlassLeading.back,
      trailing: [
        GlassBarAction(id: 'a', label: 'Search', glyph: GlassGlyph.magnifyingGlass, onPress: () {}),
        GlassBarAction(id: 'b', label: 'Notifications', glyph: GlassGlyph.bellSimple, onPress: () {}, badge: 3),
        GlassBarAction(id: 'c', label: 'More', glyph: GlassGlyph.dotsThree, onPress: () {}, foldable: true),
      ],
      slivers: [
        SliverToBoxAdapter(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              GlassButton(variant: GlassButtonVariant.plain, size: GlassButtonSize.large, label: 'Push a level', onPressed: () => unawaited(context.push<void>('/dev/glass/shell?level=${level + 1}'))),
              GlassButton(
                variant: GlassButtonVariant.plain, size: GlassButtonSize.large,
                label: 'Narrating',
                onPressed: () => acc.setNarration(
                  GlassNarrationAccessory(title: 'Chapter 12 · Aurora', playing: true, progress: 0.4, onPlayPause: () {}, openPlayer: (_) {}),
                ),
              ),
              GlassButton(variant: GlassButtonVariant.plain, size: GlassButtonSize.large, label: 'Downloading', onPressed: () => acc.setDownloading(GlassDownloadingAccessory(chapters: 3, progress: 0.42, paused: false, onToggle: () {}))),
              GlassButton(variant: GlassButtonVariant.plain, size: GlassButtonSize.large, label: 'Continue', onPressed: () => acc.setContinue(GlassContinueAccessory(title: 'Continue Solo Leveling', subtitle: 'Ch 143', coverUrl: null, onOpen: (_) {}))),
              GlassButton(
                variant: GlassButtonVariant.plain, size: GlassButtonSize.large,
                label: 'Clear accessory',
                onPressed: () {
                  acc
                    ..setNarration(null)
                    ..setDownloading(null)
                    ..setContinue(null);
                },
              ),
              Builder(
                builder: (c) => GlassButton(variant: GlassButtonVariant.plain, size: GlassButtonSize.large, label: 'Dive into a chapter', onPressed: () => unawaited(enterReader(c, ref, '/reader/demo/demo/1', fromRect: globalRectOf(c)))),
              ),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 210,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: 8,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) => SizedBox(
                width: 110,
                child: GlassCoverHero(
                  sourceId: 'demo',
                  seriesKey: 'series-$i',
                  child: GlassPoster(
                    cover: Image(image: kGlassDemoCover, fit: BoxFit.cover),
                    title: 'Series $i',
                    onTap: () => unawaited(context.push<void>('/sources/demo/series/series-$i', extra: GlassNavExtra(originRect: globalRectOf(context)))),
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverList.builder(
          itemCount: 80,
          itemBuilder: (context, i) => SizedBox(height: 56, child: Align(alignment: Alignment.centerLeft, child: GlassText('Row $i', role: gt.typeBody))),
        ),
      ],
    );
  }
}
