import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/novels/controllers/novel_auto_scroll.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_profile_settings.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_settings_row.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/speed_ruler.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/novel/type_rows.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/soundscape/soundscape_picker.dart';

/// What the Type sheet's `AMBIENT` group needs from the reader: the running auto-scroll, the
/// profile's measured pace and the layout.
class NovelAutoHandle {
  const NovelAutoHandle({required this.auto, required this.paceWpm, required this.paged, required this.onToggle, required this.onSpeed});

  final NovelAutoScroll auto;
  final double Function() paceWpm;
  final bool paged;

  /// Starts or stops auto-scroll (pausing narration when it starts).
  final VoidCallback onToggle;

  /// A speed from the ruler: live while dragging, persisted for this book on commit.
  final void Function(double speedX, {required bool persist}) onSpeed;
}

/// The key of the group's kicker: the waveform opens the sheet scrolled to it.
final GlobalKey kNovelAmbientKey = GlobalKey(debugLabel: 'novel ambient group');

/// The `AMBIENT` group of `Text and page` (cinematic 8.15.5): auto-scroll play and its speed
/// ruler (per book), `Resume after I let go`, the house sound and its narration switch.
List<NovelTypeRow> novelAmbientRows(NovelAutoHandle h) => [
      (c) => KeyedSubtree(key: kNovelAmbientKey, child: const SettingsKicker('AMBIENT')),
      (c) => ListenableBuilder(
            listenable: h.auto,
            builder: (context, _) => JumpRow(
              id: 'type-autoscroll',
              child: CineSettingsRow(
                label: 'Auto-scroll',
                description: h.paged ? 'Auto-scroll needs the scroll layout.' : NovelScope.session,
                disabled: h.paged,
                control: CineButton(
                  label: h.auto.running ? 'Stop' : 'Play',
                  variant: CineButtonVariant.quiet,
                  size: CineButtonSize.sm,
                  disabledReason: h.paged ? 'Auto-scroll needs the scroll layout.' : null,
                  onPressed: h.paged ? null : h.onToggle,
                ),
              ),
            ),
          ),
      (c) => ListenableBuilder(
            listenable: h.auto,
            builder: (context, _) => SettingsBlock(
              id: 'type-autoscroll-speed',
              label: 'Auto-scroll speed',
              description: 'Saved for this book',
              child: SpeedRuler(
                value: h.auto.speedX,
                onChanged: (x) => h.onSpeed(x, persist: false),
                onCommit: (x) => h.onSpeed(x, persist: true),
                pxCaption: (x) => '≈ ${(h.paceWpm() * x).round()} WPM',
              ),
            ),
          ),
      (c) => switchRow('type-resume-after', 'Resume after I let go', c.ref.watch(readerSettingsProvider).resumeAfterRelease,
          (v) => c.ref.read(readerSettingsProvider.notifier).put({'resumeAfterRelease': v}),
          description: 'Resumes 0.8 s after you lift your finger. ${NovelScope.profile}.',),
      (c) => const SoundscapePicker(),
      (c) => switchRow('type-pause-narration', 'Pause the soundscape during narration', c.ref.watch(readerSettingsProvider).pauseSoundscapeForNarration,
          (v) => c.ref.read(readerSettingsProvider.notifier).put({'pauseSoundscapeForNarration': v}),
          description: 'Otherwise it drops to 30 % while a chapter is read aloud.',),
    ];
