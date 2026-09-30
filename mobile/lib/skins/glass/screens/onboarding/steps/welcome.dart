import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/typed_headline.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// Step 1, Welcome: "Hi, {name}." typed at 50 ms per grapheme, then the body line (glass 8.7).
class GlassWelcomeStep extends ConsumerWidget {
  const GlassWelcomeStep({super.key, required this.name});
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TypedHeadline('Hi, $name.', role: gt.typeLargeTitle, placement: 'onboarding.first', headingLevel: 1),
          const SizedBox(height: 12),
          GlassText("Let's set up what this profile likes. It takes a minute.", role: gt.typeBody, color: gt.colorLabel2),
        ],
      );
}
