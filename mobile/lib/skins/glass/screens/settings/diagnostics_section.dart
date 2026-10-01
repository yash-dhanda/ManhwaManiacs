import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/diagnostics/diagnostics_snapshot.dart';
import 'package:manhwamaniacs/core/diagnostics/performance_monitor.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_display_mode.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_row.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The calibration page (`mobile/25`), reachable from Diagnostics in every build.
const String kGlassCalibrationRoute = '/dev/glass/calibration';

/// The jank colour (glass 8.25.12).
Color jankColour(double percent) => switch (jankTone(percent)) {
      JankTone.good => gt.colorSuccess,
      JankTone.warn => gt.colorWarning,
      JankTone.bad => gt.colorDanger,
    };

/// "4 / 6 layers · 5 / 8 shapes · 1 scrim" and whether it is over the budget (glass 15.7).
({String text, bool over}) glassLayersLine(int layers, int shapes, int scrims) => (
      text: '$layers / $kGlassLayerBudget layers · $shapes / $kGlassShapeBudget shapes · $scrims ${scrims == 1 ? 'scrim' : 'scrims'}',
      over: layers > kGlassLayerBudget || shapes > kGlassShapeBudget,
    );

/// Settings -> Diagnostics (glass 8.25.12): frame timings are collected only while this is visible; readouts update at most once a
/// second.
class DiagnosticsSection extends ConsumerStatefulWidget {
  const DiagnosticsSection({super.key, this.platform});
  final TargetPlatform? platform;
  @override
  ConsumerState<DiagnosticsSection> createState() => _DiagnosticsSectionState();
}

class _DiagnosticsSectionState extends ConsumerState<DiagnosticsSection> {
  late final PerformanceMonitor _monitor = ref.read(performanceMonitorProvider);
  Timer? _tick;
  int _seconds = 0;
  DisplayModeInfo? _display;

  TargetPlatform get _platform => widget.platform ?? defaultTargetPlatform;

  @override
  void initState() {
    super.initState();
    _monitor.start();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
    if (_platform == TargetPlatform.android) {
      unawaited(ref.read(readerDisplayModeProvider).describe().then((d) {
        if (mounted) setState(() => _display = d);
      }),);
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    _monitor.stop();
    super.dispose();
  }

  /// A readout: short values trail in `mono`; long ones wrap under the title.
  Widget _row(String id, String title, String value, {Color? color}) => value.length > 14
      ? SettingsAnchor(
          id: id,
          child: Semantics(
            container: true,
            label: '$title, $value',
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                GlassText(title, role: gt.typeBody),
                GlassText(value, role: gt.typeMono, color: color ?? gt.colorLabel2),
              ],),
            ),
          ),
        )
      : SettingsRow(id: id, title: title, trailing: GlassText(value, role: gt.typeMono, color: color ?? gt.colorLabel2));

  @override
  Widget build(BuildContext context) {
    final p = _monitor.snapshot;
    final reg = ref.watch(glassRegistryProvider);
    final layers = glassLayersLine(reg.layers, reg.shapes, reg.scrims);
    final info = ref.watch(packageInfoProvider).valueOrNull;
    final mq = MediaQuery.of(context);
    final cache = ImageCacheFigures.read();
    final facts = DeviceFacts.read();
    final waiting = _seconds < 1 ? 'Starting profiler…' : (p.sampleCount < 60 ? 'Scroll a screen to sample' : null);
    String ms(double v) => '${v.toStringAsFixed(1)} ms';
    return Semantics(
      container: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SettingsGroup(id: 'diag-rendering', header: 'Rendering performance', children: [
          if (waiting != null) Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: GlassText(waiting, role: gt.typeFootnote, color: gt.colorLabel2)),
          _row('diag-fps', 'FPS', p.hasData ? p.fps.toStringAsFixed(0) : '—', color: gt.colorIris400),
          _row('diag-jank', 'Jank', p.hasData ? '${p.jankPercent.toStringAsFixed(1)} %' : '—', color: p.hasData ? jankColour(p.jankPercent) : null),
          _row('diag-worst', 'Worst frame', p.hasData ? ms(p.worstFrameMs) : '—'),
          _row('diag-average', 'Average frame', p.hasData ? ms(p.avgFrameMs) : '—'),
          _row('diag-build', 'CPU build', p.hasData ? ms(p.avgBuildMs) : '—'),
          _row('diag-raster', 'GPU raster', p.hasData ? ms(p.avgRasterMs) : '—'),
          _row('diag-samples', 'Samples', '${p.sampleCount}'),
        ],),
        SettingsGroup(id: 'diag-display', header: 'Display', children: [
          if (_platform == TargetPlatform.android) ...[
            _row('diag-refresh', 'Refresh rate', _display == null ? '—' : '${_display!.activeRefreshRate.toStringAsFixed(0)} Hz'),
            _row('diag-capability', 'Capability', _display == null ? '—' : 'up to ${_display!.maxRefreshRate.toStringAsFixed(0)} Hz'),
            _row('diag-resolution', 'Resolution', _display == null ? '—' : '${_display!.activeWidth} × ${_display!.activeHeight}'),
          ] else
            Padding(padding: const EdgeInsets.all(16), child: GlassText('Display modes are only switchable on Android', role: gt.typeCallout, color: gt.colorLabel2)),
        ],),
        SettingsGroup(id: 'diag-device', header: 'Device', children: [
          _row('diag-platform', 'Platform', '${facts.platform} ${facts.osVersion}'),
          _row('diag-cores', 'CPU cores', kIsWeb ? '—' : '${Platform.numberOfProcessors}'),
          _row('diag-screen', 'Screen', '${mq.size.width.round()} × ${mq.size.height.round()} @${mq.devicePixelRatio.toStringAsFixed(0)}x'),
          _row('diag-version', 'App version', info == null ? '—' : '${info.version} (${info.buildNumber})'),
          _row('diag-build-mode', 'Build mode', kReleaseMode ? 'release' : (kProfileMode ? 'profile' : 'debug')),
        ],),
        SettingsGroup(id: 'diag-image-cache', header: 'Image cache', children: [
          _row('diag-live', 'Live images', '${cache.live}'),
          _row('diag-cached', 'Cached', '${cache.cached} / ${cache.maxCached}'),
          _row('diag-memory', 'Memory', cache.memoryLabel),
        ],),
        SettingsGroup(id: 'diag-glass', header: 'Glass', children: [
          _row('diag-renderer', 'Renderer', 'Impeller'),
          _row('diag-quality', 'Glass quality', 'premium (chrome) · standard (page controls in scroll views)'),
          _row('diag-refraction', 'Refraction', ref.watch(glassRendererProvider) == GlassRenderer.liquid ? 'on' : 'frosted'),
          _row('diag-layers', 'Glass layers on screen', layers.text, color: layers.over ? gt.colorWarning : null),
        ],),
        SettingsGroup(header: 'Development', children: [
          SettingsRow(id: 'diag-calibration', title: 'Glass calibration', caret: true, onTap: () => GoRouter.of(context).push(kGlassCalibrationRoute)),
          SettingsSwitchRow(
            id: 'diag-motion-timings',
            title: 'Show motion timings',
            value: ref.watch(glassShowMotionTimingsProvider),
            onChanged: (v) => ref.read(glassShowMotionTimingsProvider.notifier).state = v,
          ),
        ],),
      ],),
    );
  }
}
