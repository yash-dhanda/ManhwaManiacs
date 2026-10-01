/// The book page's Audiobook button (glass 8.13, C6): "Make audiobook", "Make audiobook · 12 done", "Making audiobook · 3 in progress, 5
/// waiting", "Make audiobook · 5 waiting for the narration PC", "Audiobook · 40 narrated"; on `narration_unavailable` the note
/// "Narration of new chapters is not available right now". The owner opens the sheet in Narrate mode; everyone else sees status only
/// (and Save where it exists).
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart';
import 'package:manhwamaniacs/features/novels/providers/series_audio_provider.dart';
import 'package:manhwamaniacs/features/novels/utils/audiobook_labels.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/glass/listen/glass_narration_host.dart';
import 'package:manhwamaniacs/skins/glass/listen/listen_common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

const String kNarrationNotAvailableNote = 'Narration of new chapters is not available right now';

class GlassAudiobookButton extends ConsumerWidget {
  const GlassAudiobookButton({super.key, required this.sourceId, required this.seriesKey});
  final String sourceId, seriesKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final series = (sourceId: sourceId, seriesKey: seriesKey);
    final owner = ref.watch(glassIsOwnerProvider);
    final audio = ref.watch(seriesAudioProvider(series)).valueOrNull;
    final jobs = ref.watch(novelAudioJobsProvider(series)).valueOrNull ?? const [];
    final rendered = audio?.rendered.length ?? 0;
    final canRender = owner && (audio?.canRender ?? true);
    final label = audiobookButtonLabel(canRender: canRender, running: jobs.where((j) => j.isRunning).length, waiting: jobs.where((j) => j.isWaiting).length, rendered: rendered);
    final hasSave = ref.watch(downloadsStoreProvider) != null && rendered > 0;
    final tappable = owner || hasSave;
    final unavailable = owner && audio?.canRender == false;
    void open() => ref.read(glassNarrationActionsProvider).openSheet('audiobook', extra: {'series': '$sourceId:$seriesKey', if (!owner) 'mode': 'save'});
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        GlassButton(
          label: label,
          icon: GlassButtonIcon(listenIcon(GlassIconRole.listen, GlassIconWeight.regular), fill: listenIcon(GlassIconRole.listen)),
          onPressed: tappable ? open : null,
          disabledReason: tappable ? null : 'Status only',
          fullWidth: true,
        ),
        if (unavailable) Padding(padding: const EdgeInsets.only(top: 6), child: GlassText(kNarrationNotAvailableNote, role: gt.typeCaption1, color: gt.colorLabel2, textAlign: TextAlign.center, maxLines: 2)),
      ],
    );
  }
}
