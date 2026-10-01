/// The listen family's `?sheet=` ids (glass 8.0.3): `player`, `voices`, `cast` and `audiobook`, registered once by the Glass router.
library;

import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/novels/utils/audiobook_plan.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/listen/audiobook_sheet.dart';
import 'package:manhwamaniacs/skins/glass/listen/cast_sheet.dart';
import 'package:manhwamaniacs/skins/glass/listen/glass_narration_host.dart';
import 'package:manhwamaniacs/skins/glass/listen/player_sheet.dart';
import 'package:manhwamaniacs/skins/glass/listen/voice_orbit.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_sheet_route.dart';
import 'package:manhwamaniacs/skins/glass/routes/sheet_registry.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The book a listen sheet is about: `?series=source:key` (Downloads, the book page) or the location / narration (the reader).
GlassListenScope? listenScopeOf(BuildContext context, WidgetRef ref) {
  final q = GoRouter.of(context).routerDelegate.currentConfiguration.uri.queryParameters;
  final s = q['series'];
  if (s != null && s.contains(':')) {
    final cut = s.indexOf(':');
    return (sourceId: s.substring(0, cut), seriesKey: s.substring(cut + 1), chapterKey: q['chapter']);
  }
  final scope = ref.read(glassListenScopeProvider);
  if (scope == null) return null;
  return q['chapter'] == null ? scope : (sourceId: scope.sourceId, seriesKey: scope.seriesKey, chapterKey: q['chapter']);
}

class _NoBook extends StatelessWidget {
  const _NoBook();

  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: GlassText('Open a chapter to see its voices.', role: gt.typeCallout, onGlass: true, textAlign: TextAlign.center)));
}

bool _onGlass(BuildContext context) => GlassFrame.of(context) != GlassFrameKind.phone;

final GlassSheetSpec glassCastSheetSpec = GlassSheetSpec(
  title: 'Voices in this chapter',
  builder: (context) => Consumer(
    builder: (context, ref, _) {
      final s = listenScopeOf(context, ref);
      final key = s?.chapterKey == null ? ref.watch(narrationControllerProvider.select((n) => n.key)) : (sourceId: s!.sourceId, seriesKey: s.seriesKey, chapterKey: s.chapterKey!);
      return key == null ? const _NoBook() : GlassCastBody(chapter: key, onGlass: _onGlass(context));
    },
  ),
  wideForm: GlassWideForm.panel,
);

final GlassSheetSpec glassVoicesSheetSpec = GlassSheetSpec(
  title: 'Voices',
  builder: (context) => Consumer(
    builder: (context, ref, _) {
      final s = listenScopeOf(context, ref);
      final q = GoRouter.of(context).routerDelegate.currentConfiguration.uri.queryParameters;
      final key = s?.chapterKey == null ? ref.watch(narrationControllerProvider.select((n) => n.key)) : (sourceId: s!.sourceId, seriesKey: s.seriesKey, chapterKey: s.chapterKey!);
      if (key == null) return const _NoBook();
      final c = q['character'];
      return Material(type: MaterialType.transparency, child: GlassVoiceOrbit(chapter: key, target: c == null ? const VoiceTarget.narrator() : VoiceTarget.character(c, gender: q['gender'])));
    },
  ),
  wideForm: GlassWideForm.panel,
  trailing: const GlassVoicesMore(),
);

final GlassSheetSpec glassAudiobookSheetSpec = GlassSheetSpec(
  title: 'Audiobook',
  builder: (context) => Consumer(
    builder: (context, ref, _) {
      final s = listenScopeOf(context, ref);
      if (s == null) return const _NoBook();
      final q = GoRouter.of(context).routerDelegate.currentConfiguration.uri.queryParameters;
      final title = ref.watch(sourceSeriesDetailProvider((sourceId: s.sourceId, seriesId: s.seriesKey))).valueOrNull?.series.title;
      return GlassAudiobookBody(
        sourceId: s.sourceId,
        seriesKey: s.seriesKey,
        seriesTitle: title,
        currentChapterKey: s.chapterKey,
        initialMode: q['mode'] == 'save' ? AudiobookMode.save : (q['mode'] == 'narrate' ? AudiobookMode.narrate : null),
        onGlass: _onGlass(context),
      );
    },
  ),
  wideForm: GlassWideForm.panel,
);

/// Registers the four ids; called by the Glass router.
void registerListenSheets() {
  registerPlayerSheet();
  registerGlobalSheet('cast', glassCastSheetSpec);
  registerGlobalSheet('voices', glassVoicesSheetSpec);
  registerGlobalSheet('audiobook', glassAudiobookSheetSpec);
}
