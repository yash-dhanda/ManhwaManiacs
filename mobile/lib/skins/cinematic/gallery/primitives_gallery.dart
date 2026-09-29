import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/downloads/utils/download_mark.dart';
import 'package:manhwamaniacs/skins/cinematic/gallery/fixtures.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_download_mark.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/dashed_token.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/drop_cap_paragraph.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// The series-page primitives on one plate: the seven download marks, the
/// drop cap and the dashed suggestion token. TODO(mobile/04): mounted by the
/// Diagnostics gallery when it lands.
class SeriesPrimitivesGallery extends StatelessWidget {
  const SeriesPrimitivesGallery({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<CineTokens>()!;
    final label = TextStyle(fontSize: 11, letterSpacing: 1.4, color: t.colorInk60);
    return ColoredBox(
      color: t.colorPaper0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DOWNLOAD MARKS', style: label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (name, m) in galleryMarks)
                  Column(
                    children: [
                      CineDownloadMark(
                        state: m,
                        reason: m is MarkPaused ? DownloadQueuePauseReason.freeSpaceFloor : null,
                        onTap: () {},
                      ),
                      Text(name, style: label.copyWith(fontSize: 9)),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text('DROP CAP', style: label),
            const SizedBox(height: 8),
            SizedBox(
              width: 340,
              child: DropCapParagraph(
                text: galleryBlurb,
                style: TextStyle(fontSize: 16, height: 24 / 16, color: t.colorInk80),
                capStyle: TextStyle(
                  fontSize: 72,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: t.colorInk100,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('DASHED TOKEN', style: label),
            const SizedBox(height: 8),
            const Wrap(
              spacing: 8,
              children: [DashedToken(label: 'dungeon'), DashedToken(label: 'rivals')],
            ),
          ],
        ),
      ),
    );
  }
}
