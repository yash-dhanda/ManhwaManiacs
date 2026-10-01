import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/features/admin/utils/status_summary.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart' show GlassIconWeight;
import 'package:manhwamaniacs/skins/glass/primitives/cards/health_bead.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/screens/you/you_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// A state's colour (glass 8.26): `success`, `warning`, `danger`, `g600` for unknown.
Color statusColour(StatusState s) => switch (s) {
      StatusState.healthy => gt.colorSuccess,
      StatusState.warning => gt.colorWarning,
      StatusState.down => gt.colorDanger,
      StatusState.unknown => GlassColors.g600,
    };

Glyph statusGlyph(StatusState s) => switch (s) {
      StatusState.healthy => YouGlyphs.checkCircle,
      StatusState.warning => YouGlyphs.warning,
      StatusState.down => YouGlyphs.warningCircle,
      StatusState.unknown => YouGlyphs.question,
    };

/// "Healthy", "Warning", "Down", "Unknown".
String statusWord(StatusState s) => switch (s) {
      StatusState.healthy => 'Healthy',
      StatusState.warning => 'Warning',
      StatusState.down => 'Down',
      StatusState.unknown => 'Unknown',
    };

/// The bead of a state.
GlassSourceHealth beadOf(StatusState s) => switch (s) {
      StatusState.healthy => GlassSourceHealth.ok,
      StatusState.warning => GlassSourceHealth.failing,
      StatusState.down => GlassSourceHealth.dead,
      StatusState.unknown => GlassSourceHealth.unknown,
    };

/// "Everything is running", "1 problem needs attention", "2 problems need attention" (glass 8.26).
String glassStatusHeadline(StatusSummary s) {
  final n = s.problems.length;
  if (n == 0) return s.worst == StatusState.unknown ? 'Checking the system…' : 'Everything is running';
  return n == 1 ? '1 problem needs attention' : '$n problems need attention';
}

/// A status card: a `surface1` slab, radius 26, padding 16, with its title.
class StatusCard extends StatelessWidget {
  const StatusCard({super.key, required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(color: gt.colorSurface1, borderRadius: BorderRadius.circular(26), border: Border.all(color: gt.colorSeparator)),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Expanded(child: Semantics(header: true, headingLevel: 2, child: GlassText(title, role: gt.typeHeadline))),
            if (trailing != null) trailing!,
          ],),
          const SizedBox(height: 12),
          child,
        ],),
      );
}

/// A `mono` block (`surface2`, radius 12, padding 12) that scrolls sideways inside itself.
class MonoBlock extends StatelessWidget {
  const MonoBlock(this.text, {super.key, this.color});
  final String text;
  final Color? color;
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(color: gt.colorSurface2, borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: GlassText(text, role: gt.typeMono, color: color ?? gt.colorLabel2)),
      );
}

/// The per-card error (glass 8.26): "Couldn't load this" and a plain "Retry".
class StatusCardError extends StatelessWidget {
  const StatusCardError({super.key, required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: GlassText("Couldn't load this", role: gt.typeCallout, color: gt.colorLabel2)),
        GlassButton(label: 'Retry', variant: GlassButtonVariant.plain, size: GlassButtonSize.small, onPressed: onRetry),
      ],);
}

/// The summary banner: a `surface1` slab with a 3 px leading bar and the glyph in the worst state's colour, the headline and the
/// problems as bullets.
class SummaryBanner extends StatelessWidget {
  const SummaryBanner({super.key, required this.summary});
  final StatusSummary summary;

  @override
  Widget build(BuildContext context) {
    final c = statusColour(summary.worst);
    return Semantics(
      container: true,
      liveRegion: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Container(
          decoration: BoxDecoration(color: gt.colorSurface1, border: Border(left: BorderSide(color: c, width: 3))),
          child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    GlyphIcon(statusGlyph(summary.worst), weight: GlassIconWeight.fill, color: c),
                    const SizedBox(width: 8),
                    Expanded(child: GlassText(glassStatusHeadline(summary), role: gt.typeHeadline)),
                  ],),
                  for (final p in summary.problems)
                    Padding(padding: const EdgeInsets.only(top: 6), child: GlassText('•  $p', role: gt.typeCallout, color: gt.colorLabel2)),
                ],),
          ),
        ),
      ),
    );
  }
}
