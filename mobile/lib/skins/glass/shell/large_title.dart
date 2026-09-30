import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/letter_reveal.dart';

/// The large title (glass 3.2, 7.14): `largeTitle` 34/40 phone up to 44/50 wide at `wght` 700, 16 px below the nav row, a heading with
/// a focus node (the route focus target), revealed letter by letter once per session per screen. Pulling past the top stretches it up
/// to 1.08 anchored at its leading edge.
class GlassLargeTitle extends ConsumerStatefulWidget {
  const GlassLargeTitle(
      {super.key,
      required this.title,
      required this.margin,
      required this.offset,});
  final String title;
  final double margin;
  final ValueListenable<double> offset;

  /// The scroll offset at which the title has scrolled under the nav row and the capsule takes over.
  static const double capsuleAt = 40;

  @override
  ConsumerState<GlassLargeTitle> createState() => _GlassLargeTitleState();
}

class _GlassLargeTitleState extends ConsumerState<GlassLargeTitle> {
  final FocusNode _focus = FocusNode(debugLabel: 'large title');

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(activeProfileProvider.select((p) => p?.id));
    final reduced =
        ref.watch(glassMotionPrefsProvider.select((m) => m.reduced));
    return Semantics(
      header: true,
      child: Focus(
        focusNode: _focus,
        child: ValueListenableBuilder<double>(
          valueListenable: widget.offset,
          builder: (context, off, child) {
            final stretch = off < 0 ? (1 + (-off / 400)).clamp(1.0, 1.08) : 1.0;
            final fade =
                reduced ? (1 - ((off - 16) / 24)).clamp(0.0, 1.0) : 1.0;
            return Opacity(
              opacity: reduced ? fade : 1,
              child: Transform.scale(
                  scale: reduced ? 1 : stretch,
                  alignment: Alignment.centerLeft,
                  child: child,),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: LetterReveal(
              widget.title,
              role: gt.typeLargeTitle,
              revealKey: '${profile ?? 0}:${widget.title}:title',
              screenId: widget.title,
              headingLevel: 1,
              maxLines: 2,
            ),
          ),
        ),
      ),
    );
  }
}
