import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/features/ai/utils/ai_state.dart';
import 'package:manhwamaniacs/skins/glass/copy/ai.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The stale stamp beside a rail title or footnote (glass 7.38): "Picked 3 days ago" in `caption1` `label3` (`label2` over fields above
/// 20 % opacity), shown only when the answer is at least 24 h old (`staleDays()`).
class AiStamp extends StatelessWidget {
  const AiStamp({super.key, required this.generatedAt, this.now, this.overField = false});
  final DateTime? generatedAt;
  final DateTime? now;
  final bool overField;

  @override
  Widget build(BuildContext context) {
    final days = staleDays(generatedAt, now ?? DateTime.now());
    if (days == null) return const SizedBox.shrink();
    return GlassText(glassAiStaleLine(days), role: gt.typeCaption1, color: overField ? gt.colorLabel2 : gt.colorLabel3);
  }
}
