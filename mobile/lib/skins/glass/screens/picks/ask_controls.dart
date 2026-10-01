import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/liquid_progress.dart';
import 'package:manhwamaniacs/skins/glass/primitives/switch.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The daily quota meter shows at this many asks left or fewer; it turns `warning` at [kQuotaWarn].
const int kQuotaShow = 10, kQuotaWarn = 3;

/// "7 of 10 asks left today": a 72 x 8 liquid capsule and the line, both `warning` at 3 or fewer.
class QuotaMeter extends StatelessWidget {
  const QuotaMeter({super.key, required this.remaining, this.total = 10});
  final int remaining;
  final int total;

  @override
  Widget build(BuildContext context) {
    final warn = remaining <= kQuotaWarn;
    final color = warn ? gt.colorWarning : gt.colorLabel2;
    final text = '$remaining of $total asks left today';
    return Semantics(
      label: text,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
              child: SizedBox(
                  width: 72,
                  height: 8,
                  child: LiquidProgress(
                      value: (remaining / total).clamp(0.0, 1.0),
                      height: 8,
                      color: warn ? gt.colorWarning : null,
                      meniscus: false,),),),
          const SizedBox(width: 8),
          ExcludeSemantics(
              child: GlassText(text, role: gt.typeCaption1, color: color),),
        ],
      ),
    );
  }
}

/// The Ask button and the two switches ("Only my sources" hidden in Novels mode, "Use my taste").
class AskControls extends ConsumerWidget {
  const AskControls({
    super.key,
    required this.buttonKey,
    required this.canAsk,
    required this.asking,
    required this.onAsk,
    required this.onlyMine,
    required this.onOnlyMine,
    required this.useTaste,
    required this.onUseTaste,
    required this.novels,
    this.remaining,
    this.retryIn,
  });
  final GlobalKey buttonKey;
  final bool canAsk, asking, onlyMine, useTaste, novels;
  final VoidCallback onAsk;
  final ValueChanged<bool> onOnlyMine, onUseTaste;
  final int? remaining;
  final int? retryIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget sw(String label, bool v, ValueChanged<bool> on) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(children: [
            Expanded(child: GlassText(label, role: gt.typeCallout)),
            GlassSwitch(value: v, label: label, onChanged: on),
          ],),
        );
    final waiting = retryIn != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // The button and the quota share a line while they fit, and stack when they don't (large text, a countdown).
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            KeyedSubtree(
              key: buttonKey,
              child: GlassButton(
                label: waiting ? 'Try again in $retryIn s' : 'Ask',
                mono: waiting,
                variant: GlassButtonVariant.primary,
                size: GlassButtonSize.large,
                loading: asking,
                tooltip: canAsk || asking ? null : 'Type at least 3 characters',
                disabledReason: canAsk || asking || waiting
                    ? null
                    : 'Type at least 3 characters',
                onPressed: canAsk && !asking && !waiting ? onAsk : null,
              ),
            ),
            if (remaining != null && remaining! <= kQuotaShow)
              QuotaMeter(remaining: remaining!),
          ],
        ),
        if (!novels) sw('Only my sources', onlyMine, onOnlyMine),
        sw('Use my taste', useTaste, onUseTaste),
      ],
    );
  }
}
