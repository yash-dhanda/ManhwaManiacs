import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manhwamaniacs/core/diagnostics/motion_recorder.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The motion-timings panel (cinematic 15.9): 320 px, bottom-left, the last 20 entries.
class CineMotionTimingsPanel extends StatelessWidget {
  const CineMotionTimingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final r = MotionRecorder.instance;
    return SizedBox(
      width: 320,
      child: DecoratedBox(
        decoration: BoxDecoration(color: c.colorPaper2.withValues(alpha: 0.92), border: Border.all(color: c.colorRule2)),
        child: Padding(
          padding: EdgeInsets.all(c.space2),
          child: ListenableBuilder(
            listenable: r,
            builder: (context, _) {
              final rows = r.entries.reversed.take(20).toList();
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: CineRoleText('MOTION TIMINGS', c.typeKicker, color: c.colorInk60)),
                    CineButton(label: 'Clear', variant: CineButtonVariant.quiet, onPressed: r.clear),
                    CineButton(
                      label: 'Copy log',
                      variant: CineButtonVariant.quiet,
                      onPressed: () => Clipboard.setData(ClipboardData(text: r.exportJson())),
                    ),
                  ],),
                  for (final e in rows)
                    CineLit(formatEntry(e), CineFace.plexMono, 11, 16,
                        color: isLate(e, frameMs: r.frameMs) ? c.colorProof : c.colorSet, maxLines: 1, overflow: TextOverflow.clip,),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
