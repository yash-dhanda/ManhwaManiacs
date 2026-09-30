import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/downloads/utils/download_mark.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// The per-chapter download mark (DESIGN §7.18): a 16 px square, seven states,
/// a `Tooltip` from [downloadMarkTooltip], the [downloadMarkLabel] semantics
/// name and a 44 x 48 hit box (48 wide on Android). `onTap` retries a failed one and starts a
/// download from `none` / `stale`. The shared CineDownloadMark (cine_progress.dart) has a different state set, so this one takes the model's DownloadMarkState.
class CineDownloadMark extends StatelessWidget {
  const CineDownloadMark({
    super.key,
    required this.state,
    this.reason,
    this.page,
    this.pageTotal,
    this.onTap,
  });

  final DownloadMarkState state;
  final DownloadQueuePauseReason? reason;
  final int? page;
  final int? pageTotal;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<CineTokens>()!;
    return Tooltip(
      message: downloadMarkTooltip(state, reason: reason, page: page, pageTotal: pageTotal),
      child: Semantics(
        button: true,
        label: downloadMarkLabel(state),
        excludeSemantics: true,
        onTap: onTap,
        child: InkResponse(
          onTap: onTap,
          radius: 24,
          child: SizedBox(
            width: cineHitMin(context),
            height: 48,
            child: Center(
              child: CustomPaint(
                size: const Size.square(16),
                painter: DownloadMarkPainter(
                  state: state,
                  ink: t.colorInk45,
                  spot: t.colorSpot,
                  set: t.colorSet,
                  proof: t.colorProof,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DownloadMarkPainter extends CustomPainter {
  DownloadMarkPainter({
    required this.state,
    required this.ink,
    required this.spot,
    required this.set,
    required this.proof,
  });

  final DownloadMarkState state;
  final Color ink, spot, set, proof;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    final box = r.deflate(0.5);
    Paint line(Color c, [double w = 1]) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = w;
    switch (state) {
      case MarkNone() || MarkStale():
        final c = state is MarkStale ? spot : ink;
        final p = line(c, 1.5);
        final m = size.width / 2;
        canvas
          ..drawLine(Offset(m, 3), Offset(m, 11), p)
          ..drawLine(Offset(m - 3.5, 7.5), Offset(m, 11), p)
          ..drawLine(Offset(m + 3.5, 7.5), Offset(m, 11), p)
          ..drawLine(const Offset(2, 14.5), Offset(size.width - 2, 14.5), p);
      case MarkQueued():
        final p = line(ink);
        for (var x = 0.0; x < size.width; x += 5) {
          canvas
            ..drawLine(Offset(x, 0.5), Offset((x + 3).clamp(0, size.width), 0.5), p)
            ..drawLine(Offset(x, size.height - 0.5),
                Offset((x + 3).clamp(0, size.width), size.height - 0.5), p,);
        }
        for (var y = 0.0; y < size.height; y += 5) {
          canvas
            ..drawLine(Offset(0.5, y), Offset(0.5, (y + 3).clamp(0, size.height)), p)
            ..drawLine(Offset(size.width - 0.5, y),
                Offset(size.width - 0.5, (y + 3).clamp(0, size.height)), p,);
        }
      case MarkDownloading(:final progress):
        canvas
          ..drawRect(box, line(spot))
          ..drawRect(
            Rect.fromLTWH(0, size.height * (1 - progress), size.width, size.height * progress),
            Paint()..color = spot,
          );
      case MarkSaved():
        canvas.drawRect(r, Paint()..color = set);
        final p = line(const Color(0xFF000000), 2)..strokeCap = StrokeCap.square;
        canvas.drawPath(
          Path()
            ..moveTo(4, 8.5)
            ..lineTo(7, 11.5)
            ..lineTo(12, 4.5),
          p,
        );
      case MarkFailed():
        canvas.drawRect(box, line(proof));
        final p = line(proof, 1.5);
        canvas
          ..drawLine(const Offset(8, 3.5), const Offset(8, 9), p)
          ..drawCircle(const Offset(8, 12), 0.9, Paint()..color = proof);
      case MarkPaused():
        final p = Paint()..color = spot;
        canvas
          ..drawRect(const Rect.fromLTWH(3.5, 2, 2, 12), p)
          ..drawRect(const Rect.fromLTWH(10.5, 2, 2, 12), p);
    }
  }

  @override
  bool shouldRepaint(DownloadMarkPainter old) =>
      old.state.runtimeType != state.runtimeType ||
      (state is MarkDownloading &&
          old.state is MarkDownloading &&
          (state as MarkDownloading).progress != (old.state as MarkDownloading).progress) ||
      old.ink != ink;
}
