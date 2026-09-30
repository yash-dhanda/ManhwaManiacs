import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloaded_series_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_storage_providers.dart';
import 'package:manhwamaniacs/features/downloads/providers/storage_settings_provider.dart';
import 'package:manhwamaniacs/features/downloads/utils/storage_meter.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/liquid_progress.dart';
import 'package:manhwamaniacs/skins/glass/primitives/spring_value.dart';

/// The storage meter (glass 8.22): a liquid capsule 44 tall. This profile (`iris600` at 60 %), other app data (frosted `fill2`) and
/// free (clear) share one scale; a 1 px marker stands at the cap; the levels move with Liquid fill on `springLens` with a 3 px meniscus
/// that sloshes once. `Semantics(label: "Storage", value: ...)` carries the exact reading.
class GlassDownloadsMeter extends ConsumerWidget {
  const GlassDownloadsMeter({super.key, this.model});

  /// A fixed model (captures); otherwise read from the providers.
  final GlassStorageMeter? model;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = model ?? _read(context, ref);
    if (m == null) return const SizedBox.shrink();
    return Semantics(
      label: 'Storage',
      value: m.semanticsValue,
      container: true,
      child: ExcludeSemantics(
        child: SizedBox(
          height: 44,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(fit: StackFit.expand, children: [
              ColoredBox(color: gt.colorFill1),
              SpringValue(
                value: (m.profileFraction + m.otherFraction).clamp(0.0, 1.0),
                spring: gt.springLens,
                name: MotionName.liquidFill,
                builder: (context, v, vel) => CustomPaint(painter: LiquidPainter(level: v, velocity: vel, color: gt.colorFill2, meniscus: false)),
              ),
              SpringValue(
                value: m.profileFraction.clamp(0.0, 1.0),
                spring: gt.springLens,
                name: MotionName.liquidFill,
                builder: (context, v, vel) => CustomPaint(painter: LiquidPainter(level: v, velocity: vel, color: const Color(0x997563F2))),
              ),
              if (m.capMarker != null) Positioned(right: 0, top: 6, bottom: 6, width: 1, child: ColoredBox(color: gt.colorLabel1)),
              Center(child: GlassLabel(m.label, role: gt.typeFootnote, wght: 600)),
            ],),
          ),
        ),
      ),
    );
  }

  GlassStorageMeter? _read(BuildContext context, WidgetRef ref) {
    final shelf = ref.watch(downloadedShelfProvider).valueOrNull ?? const [];
    final profile = shelf.fold<int>(0, (n, g) => n + g.totalBytes);
    final app = ref.watch(totalDeviceDownloadBytesProvider).valueOrNull ?? profile;
    final space = ref.watch(deviceSpaceProvider).valueOrNull;
    return glassStorageMeter(
      profileBytes: profile,
      appDownloadBytes: app < profile ? profile : app,
      capBytes: ref.watch(storageCapProvider).bytes,
      deviceFree: space?.free,
      deviceNoun: MediaQuery.sizeOf(context).shortestSide >= 600 ? 'tablet' : 'phone',
    );
  }
}
