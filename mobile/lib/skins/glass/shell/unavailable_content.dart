import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/lens_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/object_lens.dart';

/// Content that cannot be shown (glass 8.0.8): the `eye-slash` lens with its line and "Back". A followed series whose source is dead
/// or removed gets "Move to another source…" (only once `?sheet=move-source` is registered) and "Remove from library" (with Undo).
/// A series the local data says is mature while the gate is closed says "This isn't available on this profile" with no title or cover.
class GlassUnavailableContent extends StatelessWidget {
  const GlassUnavailableContent({super.key, required this.onBack, this.line = "The source doesn't have this series any more.", this.onMove, this.onRemove, this.matureBlocked = false, this.onHome});
  final VoidCallback onBack;
  final String line;
  final VoidCallback? onMove;
  final VoidCallback? onRemove;
  final bool matureBlocked;
  final VoidCallback? onHome;

  @override
  Widget build(BuildContext context) {
    if (matureBlocked) {
      return Center(
        child: GlassObjectLens(situation: LensSituation.unavailable, title: "This isn't available on this profile", primary: LensAction('Back home', onHome ?? onBack)),
      );
    }
    return Center(
      child: GlassObjectLens(
        situation: LensSituation.unavailable,
        title: line,
        primary: onMove != null ? LensAction('Move to another source…', onMove!) : LensAction('Back', onBack),
        secondary: onRemove != null ? LensAction('Remove from library', onRemove!) : (onMove != null ? LensAction('Back', onBack) : null),
      ),
    );
  }
}
