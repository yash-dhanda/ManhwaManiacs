import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_storage_providers.dart';
import 'package:manhwamaniacs/features/downloads/providers/storage_settings_provider.dart';
import 'package:manhwamaniacs/features/downloads/utils/storage_meter.dart';
import 'package:manhwamaniacs/skins/cinematic/a11y/folio.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/downloads/downloads_copy.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The word for this device: `TABLET` from 600 dp.
String deviceNounOf(BuildContext context) => MediaQuery.sizeOf(context).shortestSide >= 600 ? 'TABLET' : 'PHONE';

/// The storage meter (cinematic 7.18): one typographic folio line over an 8 px bar of three
/// segments (other apps `ink.60`, this app `spot`, free `rule.1`) with a 2 px `ink.100` cap tick.
/// The `spot` segment grows by exactly a finished chapter's size in 240 ms (`easeSet`).
class DownloadsStorageMeter extends ConsumerWidget {
  const DownloadsStorageMeter({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bytes = ref.watch(totalDeviceDownloadBytesProvider).valueOrNull ?? 0;
    final space = ref.watch(deviceSpaceProvider).valueOrNull;
    final model = storageMeter(
      appBytes: bytes,
      capBytes: ref.watch(storageCapProvider).bytes,
      deviceFree: space?.free,
      deviceTotal: space?.total,
      deviceNoun: deviceNounOf(context),
    );
    if (model == null) return const SizedBox.shrink();
    return StorageMeterView(model: model, onTap: onTap, noun: deviceNounOf(context).toLowerCase());
  }
}

class StorageMeterView extends StatelessWidget {
  const StorageMeterView({super.key, required this.model, this.onTap, this.noun = 'phone'});
  final StorageMeterModel model;
  final VoidCallback? onTap;
  final String noun;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final d = CineMotion.reduced(context) ? Duration.zero : c.durLine;
    final note = model.capReached ? capFullNoteFor(model) : (model.nearFloor ? floorNote(noun) : null);
    Widget seg(double f, double w, Color color, {Key? key}) => AnimatedContainer(
          key: key,
          duration: d,
          curve: c.easeSet,
          width: (w * f).clamp(0.0, w),
          height: 8,
          color: color,
        );
    Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        CineRoleText(model.folio, c.typeFolio, color: c.colorInk80),
        SizedBox(height: c.space3),
        LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            final tick = model.capTick;
            return SizedBox(
              height: 14,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: ColoredBox(
                      color: c.colorRule1,
                      child: Row(
                        children: [
                          seg(model.otherFraction, w, c.colorInk60, key: const Key('meter-other')),
                          seg(model.appFraction, w, c.colorSpot, key: const Key('meter-app')),
                        ],
                      ),
                    ),
                  ),
                  if (tick != null)
                    Positioned(
                      key: const Key('meter-tick'),
                      left: (w * tick - 1).clamp(0.0, w - 2),
                      top: 0,
                      bottom: 0,
                      child: SizedBox(width: 2, child: ColoredBox(color: c.colorInk100)),
                    ),
                ],
              ),
            );
          },
        ),
        if (note != null) ...[
          SizedBox(height: c.space3),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'NOTE  ', style: CineText.style(context, c.typeKicker).copyWith(color: c.colorSpot)),
                TextSpan(text: note, style: CineText.style(context, c.typeCaption).copyWith(color: c.colorInk60)),
              ],
            ),
          ),
        ],
      ],
    );
    final core = body;
    body = Semantics(
      container: true,
      label: folioLabel(model.folio),
      value: model.capBytes == null ? null : '${(model.appBytes / (model.capBytes!)).clamp(0.0, 1.0) * 100 ~/ 1} percent of the limit',
      button: onTap != null,
      excludeSemantics: true,
      onTap: onTap,
      child: onTap == null ? core : CinePressable(onTap: onTap, hit: false, builder: (_, __) => core),
    );
    return body;
  }
}

String capFullNoteFor(StorageMeterModel m) {
  final cap = m.capBytes ?? 0;
  const gb = 1024 * 1024 * 1024;
  final g = cap / gb;
  return 'Your ${g == g.roundToDouble() ? g.toInt() : g.toStringAsFixed(1)} GB limit is full.';
}
