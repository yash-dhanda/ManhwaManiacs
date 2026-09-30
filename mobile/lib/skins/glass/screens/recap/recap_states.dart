import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/ocr/controllers/ocr_run_controller.dart';
import 'package:manhwamaniacs/skins/glass/primitives/ai/ai_notice.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/lens_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/object_lens.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

enum RecapProblem { noSourceText, notEnoughRead, aiUnavailable, offline, error }

/// A recap that is not coming: quiet, never an error for a missing AI answer (glass 9.1.3, 9.1.5). Always offers Continue.
class RecapProblemView extends ConsumerWidget {
  const RecapProblemView({super.key, required this.problem, required this.onContinue, this.reason, this.onTryAgain, this.onHowItWorks, this.onExtract, this.extractLine});
  final RecapProblem problem;
  final String? reason;
  final VoidCallback onContinue;
  final VoidCallback? onTryAgain, onHowItWorks, onExtract;

  /// "Extracting text · page 3 of 40" while an OCR run is going.
  final String? extractLine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (problem) {
      case RecapProblem.noSourceText:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlassObjectLens(
              situation: LensSituation.noRecapSource,
              title: 'No recap yet',
              description: 'Recaps are written from chapter text. Extract text from downloaded chapters, or just continue.',
              placement: GlassLensPlacement.inline,
              primary: LensAction('Continue', onContinue),
              secondary: onHowItWorks == null ? null : LensAction('How it works', onHowItWorks!),
            ),
            if (extractLine != null) Padding(padding: const EdgeInsets.only(top: 12), child: GlassText(extractLine!, role: gt.typeFootnote, color: gt.colorLabel2)),
            if (onExtract != null && extractLine == null) GlassButton(label: 'Extract text', onPressed: onExtract),
          ],
        );
      case RecapProblem.notEnoughRead:
        return _note("Read a couple of chapters first; there's nothing to recap yet.");
      case RecapProblem.aiUnavailable:
        return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [AiNotice(reason: reason, long: true), const SizedBox(height: 12), GlassButton(label: 'Continue', variant: GlassButtonVariant.primary, onPressed: onContinue)]);
      case RecapProblem.offline:
        return _note('Recaps need a connection.');
      case RecapProblem.error:
        return _note("Couldn't write a recap.", tryAgain: true);
    }
  }

  Widget _note(String text, {bool tryAgain = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassText(text, role: gt.typeCallout),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: [if (tryAgain && onTryAgain != null) GlassButton(label: 'Try again', onPressed: onTryAgain), GlassButton(label: 'Continue', variant: GlassButtonVariant.primary, onPressed: onContinue)]),
          ],
        ),
      );
}

/// "Extracting text · page 3 of 40" from the OCR run (glass 8.22).
String? extractLineOf(OcrRunState s) => s.isBusy ? 'Extracting text · page ${s.completedPages} of ${s.totalPages}' : null;
