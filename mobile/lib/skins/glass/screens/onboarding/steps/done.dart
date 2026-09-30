import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/letter_reveal.dart';

/// Step 7, Done: "Your shelf is ready." Its dots merge into a droplet that falls into Home (the screen runs the merge).
class GlassDoneStep extends ConsumerWidget {
  const GlassDoneStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Center(
        child: LetterReveal('Your shelf is ready.', role: gt.typeLargeTitle, screenId: 'onboarding', revealKey: '7', headingLevel: 1, textAlign: TextAlign.center),
      );
}
