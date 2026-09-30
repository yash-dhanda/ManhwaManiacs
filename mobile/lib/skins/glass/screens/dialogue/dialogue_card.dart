import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/ocr/models/ocr_search_result.dart';
import 'package:manhwamaniacs/features/ocr/services/ocr_snippet.dart';
import 'package:manhwamaniacs/features/ocr/utils/engine_label.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_common.dart';

/// One dialogue hit (glass 8.23): the cover (44 x 66) and title joined from the followed library, "Ch 12", the snippet with its
/// matched terms on `iris600` at 30 % behind `label1` (never raw markup), and "212 words · Vision". Used inline by Search's Dialogue
/// scope and by the Dialogue screen.
class GlassDialogueCard extends ConsumerWidget {
  const GlassDialogueCard({super.key, required this.hit, required this.title, required this.coverUrl, required this.onOpen});
  final OcrSearchResult hit;
  final String? title;
  final String? coverUrl;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spans = ocrSnippetSpans(hit.snippet);
    final snippetStyle = TextStyle(fontSize: 15, height: 1.35, color: gt.colorLabel1);
    return Semantics(
      button: true,
      label: '${title ?? 'Series'}, chapter ${hit.chapterKey}, ${spans.map((s) => s.text).join()}',
      excludeSemantics: true,
      onTap: onOpen,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onOpen,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: DecoratedBox(
            decoration: BoxDecoration(color: gt.colorSurface1, borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(width: 44, height: 66, child: HomeCoverImage(url: coverUrl, width: 44))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GlassLabel(title ?? hit.seriesKey, role: gt.typeHeadline),
                        GlassLabel('Ch ${hit.chapterKey}${hit.page == null ? '' : ' · page ${hit.page}'}', role: gt.typeFootnote, color: gt.colorLabel2),
                        const SizedBox(height: 6),
                        RichText(
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            children: [
                              for (final s in spans)
                                TextSpan(text: s.text, style: snippetStyle.copyWith(backgroundColor: s.highlighted ? gt.colorIris600.withValues(alpha: 0.3) : null)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        GlassLabel('${hit.wordCount} words · ${engineName(hit.engine)}', role: gt.typeCaption1, color: gt.colorLabel3),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
