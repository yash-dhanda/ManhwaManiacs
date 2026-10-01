import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/ocr/controllers/ocr_run_controller.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/liquid_progress.dart';

String _words(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

/// The OCR run banner (glass 8.22): shown while a run exists; "Extracting text · page 3 of 40" with a 6 px liquid bar, the paused,
/// uploading, done, cancelled and failed lines, and Cancel while busy.
class GlassOcrBanner extends ConsumerWidget {
  const GlassOcrBanner({super.key, this.stateOverride});
  final OcrRunState? stateOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final OcrRunState s = stateOverride ?? ref.watch(ocrRunControllerProvider);
    if (s.phase == OcrRunPhase.idle) return const SizedBox.shrink();
    final line = switch (s.phase) {
      OcrRunPhase.recognizing => 'Extracting text · page ${s.completedPages + 1 > s.totalPages && s.totalPages > 0 ? s.totalPages : s.completedPages + 1}${s.totalPages > 0 ? ' of ${s.totalPages}' : ''}',
      OcrRunPhase.paused => 'Text extraction pauses while the app is in the background',
      OcrRunPhase.uploading => 'Uploading the transcript…',
      OcrRunPhase.done => 'Text extracted: ${_words(s.wordCount)} words are now searchable',
      OcrRunPhase.cancelled => 'Text extraction cancelled',
      OcrRunPhase.failed => s.message == null || s.message!.isEmpty ? "Couldn't extract the text" : "Couldn't extract the text: ${s.message}",
      OcrRunPhase.idle => '',
    };
    return Semantics(
      container: true,
      liveRegion: true,
      label: line,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0x9E131317), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0x38FFFFFF), width: 0.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: GlassLabel(line, role: gt.typeSubhead, maxLines: 3, color: s.phase == OcrRunPhase.failed ? gt.colorDanger : null)),
            if (s.isBusy) GlassButton(label: 'Cancel', variant: GlassButtonVariant.plain, size: GlassButtonSize.small, onPressed: () => ref.read(ocrRunControllerProvider.notifier).cancel()),
          ],),
          if (s.phase == OcrRunPhase.recognizing || s.phase == OcrRunPhase.uploading || s.phase == OcrRunPhase.paused) ...[
            const SizedBox(height: 8),
            ClipRRect(borderRadius: BorderRadius.circular(3), child: DecoratedBox(decoration: BoxDecoration(color: gt.colorFill2), child: LiquidProgress(value: s.phase == OcrRunPhase.uploading ? 1 : (s.progress ?? 0), height: 6))),
          ],
        ],),
      ),
    );
  }
}
