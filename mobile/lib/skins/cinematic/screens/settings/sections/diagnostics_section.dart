import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/app/display/high_refresh_rate.dart';
import 'package:manhwamaniacs/app/skin_boot.dart' show kSkinDebugKey;
import 'package:manhwamaniacs/app/switch_skin.dart';
import 'package:manhwamaniacs/core/diagnostics/debug_overlays.dart';
import 'package:manhwamaniacs/core/diagnostics/diagnostics_snapshot.dart';
import 'package:manhwamaniacs/core/diagnostics/performance_monitor.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_display_mode.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/overlays/stop_the_press.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_credits_row.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/edition/edition_picker.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/skin_audio.dart' show AudioSessionProbe, audioSessionProbeProvider;
import 'package:manhwamaniacs/skins/skins.dart';

/// Diagnostics (cinematic 8.30.7): rendering numbers, display, device, image cache, the developer
/// switches and the pre-flip `Edition (debug)` row.
class DiagnosticsSection extends ConsumerStatefulWidget {
  const DiagnosticsSection({super.key});

  @override
  ConsumerState<DiagnosticsSection> createState() => _DiagnosticsSectionState();
}

class _DiagnosticsSectionState extends ConsumerState<DiagnosticsSection> {
  PerformanceMonitor? _monitor;
  DisplayModeInfo? _display;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final m = ref.read(performanceMonitorProvider)..start();
      _monitor = m;
      final info = await ref.read(readerDisplayModeProvider).describe();
      if (!mounted) return;
      setState(() => _display = info);
      if (info.activeRefreshRate > 0) m.setTargetRefreshRate(info.activeRefreshRate);
    });
  }

  @override
  void dispose() {
    _monitor?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final monitor = ref.watch(performanceMonitorProvider);
    final android = Theme.of(context).platform == TargetPlatform.android;
    final facts = DeviceFacts.read();
    final cache = ImageCacheFigures.read();
    final mq = MediaQuery.of(context);
    final info = ref.watch(packageInfoProvider).valueOrNull;
    final running = ref.watch(skinIdProvider);
    String? override;
    try {
      override = ref.watch(sharedPrefsProvider).getString(kSkinDebugKey);
    } on UnimplementedError {
      override = null;
    }
    Widget numeral(String label, String value, Color color) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CineLit(value, CineFace.bodoni, 56, 56, wght: 900, color: color, maxLines: 1, overflow: TextOverflow.fade),
            CineRoleText(label, c.typeKicker, color: c.colorInk60),
          ],),
        );

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SettingsKicker('RENDERING'),
      AnimatedBuilder(
        animation: monitor,
        builder: (context, _) {
          final s = monitor.snapshot;
          final tone = switch (jankTone(s.jankPercent)) { JankTone.good => c.colorSet, JankTone.warn => c.colorSpot, JankTone.bad => c.colorProof };
          return JumpRow(
            id: 'rendering',
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                numeral('FPS', s.hasData ? s.fps.round().toString() : '–', c.colorInk100),
                numeral('JANK', s.hasData ? '${s.jankPercent.toStringAsFixed(1)} %' : '–', s.hasData ? tone : c.colorInk100),
                numeral('WORST', s.hasData ? '${s.worstFrameMs.round()} MS' : '–', c.colorInk100),
              ],),
              SizedBox(height: c.space3),
              if (!s.hasData)
                CineRoleText('Collecting frames… scroll a screen to sample.', c.typeCaption, color: c.colorInk60)
              else ...[
                CineCreditsRow(label: 'Average frame time', value: '${s.avgFrameMs.toStringAsFixed(2)} ms'),
                CineCreditsRow(label: 'Build', value: '${s.avgBuildMs.toStringAsFixed(2)} ms'),
                CineCreditsRow(label: 'Raster', value: '${s.avgRasterMs.toStringAsFixed(2)} ms'),
                CineCreditsRow(label: 'Samples', value: '${s.sampleCount}'),
              ],
            ],),
          );
        },
      ),
      const SettingsKicker('DISPLAY'),
      if (android) ...[
        CineCreditsRow(label: 'Current refresh rate', value: _display == null ? '–' : '${_display!.activeRefreshRate.round()} Hz'),
        CineCreditsRow(label: 'Panel capability', value: _display == null ? '–' : '${_display!.maxRefreshRate.round()} Hz'),
        CineCreditsRow(label: 'Resolution', value: _display == null ? '–' : '${_display!.activeWidth} × ${_display!.activeHeight}'),
        switchRow('high-refresh', 'Use the highest refresh rate everywhere', ref.watch(highRefreshRateProvider), ref.read(highRefreshRateProvider.notifier).setEnabled,
            description: 'Saved on this device.',),
      ] else
        const SettingsCaption('Display modes can only be switched on Android.'),
      const SettingsKicker('DEVICE'),
      CineCreditsRow(label: 'Platform', value: '${facts.platform} (${facts.osVersion})'),
      CineCreditsRow(label: 'CPU cores', value: '${facts.cores}'),
      CineCreditsRow(label: 'Screen', value: screenLabel(mq.size, mq.devicePixelRatio)),
      CineCreditsRow(label: 'App version', value: info == null ? '–' : 'v${info.version} (${info.buildNumber})'),
      CineCreditsRow(label: 'Build mode', value: facts.buildMode),
      const SettingsKicker('IMAGE CACHE'),
      CineCreditsRow(label: 'Live images', value: '${cache.live}'),
      CineCreditsRow(label: 'Cached images', value: '${cache.cached} / ${cache.maxCached}'),
      CineCreditsRow(label: 'Memory used', value: cache.memoryLabel),
      const SettingsKicker('DEVELOPER'),
      switchRow('grid', 'Show the layout grid', ref.watch(layoutGridOverlayProvider), (v) => ref.read(layoutGridOverlayProvider.notifier).state = v,
          description: 'Resets when the app restarts.',),
      switchRow('timings', 'Show motion timings', ref.watch(motionTimingsOverlayProvider), (v) => ref.read(motionTimingsOverlayProvider.notifier).state = v,
          description: 'Resets when the app restarts.',),
      segmentedRow(
        'edition-debug',
        'Edition (debug)',
        const ['LEGACY', 'CINEMATIC'],
        running == SkinId.legacy ? 0 : 1,
        (i) => unawaited(debugSwitchSkin(context, ref, i == 0 ? SkinId.legacy : SkinId.cinematic)),
        description: "A device override for this phone. It never changes the profile's edition. Showing ${running.name}${override == null ? '' : ', override $override'}.",
      ),
      if (defaultTargetPlatform == TargetPlatform.iOS) _audioSessionRow(ref),
      if (override != null) quietAction('Clear override', () => unawaited(debugSwitchSkin(context, ref, null))),
      if (kDebugMode) ...[
        const SettingsKicker('PROOF (DEBUG BUILDS)'),
        quietAction('Stop the press (dry run)', () => unawaited(StopThePress.dryRun(context, onError: (_) {}))),
        quietAction('Stop the press (failure)',
            () => unawaited(StopThePress.dryRun(context, failure: true, onError: (m) => ref.read(cineToastsProvider.notifier).error(m))),),
        quietAction('Edition picker (flag on)', () => unawaited(Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const EditionPickerDemoPage())))),
      ],
    ],);
  }
}


/// One row: the iPhone audio-session category after sound init and after a Hear sample.
Widget _audioSessionRow(WidgetRef ref) => ValueListenableBuilder<AudioSessionProbe>(
      valueListenable: ref.watch(audioSessionProbeProvider),
      builder: (context, p, _) {
        final ok = p.afterInit == 'ambient' && p.afterHear == 'ambient';
        return CineCreditsRow(
          label: 'Audio session (iOS)',
          value: 'After sound init: ${p.afterInit ?? '–'} · After a sample: ${p.afterHear ?? '–'}',
          valueColor: ok ? context.cine.colorSet : context.cine.colorProof,
        );
      },
    );
