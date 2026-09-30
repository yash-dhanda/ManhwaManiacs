import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/badge.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart' show GlassButtonIcon;
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart' show Glyph;
import 'package:manhwamaniacs/skins/glass/primitives/poster.dart';

/// The status tag of a followed row's `reading_status` (glass 7.20), null for `all` or an unknown value.
GlassStatus? glassStatusOf(String? readingStatus) => switch (readingStatus) {
      'reading' => GlassStatus.reading,
      'completed' => GlassStatus.completed,
      'on_hold' => GlassStatus.onHold,
      'plan_to_read' => GlassStatus.planToRead,
      'dropped' => GlassStatus.dropped,
      'unread' => GlassStatus.unread,
      _ => null,
    };

/// What a shelf poster wears: status top-left, "N new" top-right, favourite, the downloaded droplet, the 18+ capsule when the gate is
/// open and the series is mature, and the progress bar.
GlassPosterMeta shelfPosterMeta(FollowedSeries s, {required bool downloaded, required bool gateOpen}) {
  final r = s.readState;
  final total = r?.total ?? 0;
  final pos = r?.position;
  return GlassPosterMeta(
    status: glassStatusOf(s.readingStatus),
    newCount: r?.newCount ?? 0,
    downloaded: downloaded,
    mature: gateOpen && s.rating == 'mature',
    favourite: s.isFavorite,
    progress: r != null && r.started && total > 0 && pos != null ? (pos / total).clamp(0.0, 1.0) : null,
  );
}

/// The global rect of [context]'s render box (where a menu or a zoom starts), or [Rect.zero].
Rect globalRectOf(BuildContext context) {
  final ro = context.findRenderObject();
  return ro is RenderBox && ro.attached && ro.hasSize ? ro.localToGlobal(Offset.zero) & ro.size : Rect.zero;
}

/// "1 series" / "12 series".
String seriesCount(int n) => '$n series';

/// Plural helper for small counts: `plural(1, 'chapter')` is "1 chapter", `plural(3, 'chapter')` is "3 chapters".
String plural(int n, String one, [String? many]) => '$n ${n == 1 ? one : (many ?? '${one}s')}';

/// The glyph of an icon role at [w].
IconData roleIcon(GlassIconRole r, [GlassIconWeight w = GlassIconWeight.regular]) => glassIcons[r]![w]!;

/// A button icon for [r]: Regular at rest, Fill when selected.
GlassButtonIcon roleButtonIcon(GlassIconRole r) => GlassButtonIcon(roleIcon(r), fill: roleIcon(r, GlassIconWeight.fill));

/// A `Glyph` (the bar actions' type) for [r].
Glyph roleGlyph(GlassIconRole r) => Glyph(
      regular: roleIcon(r),
      fill: roleIcon(r, GlassIconWeight.fill),
      bold: roleIcon(r, GlassIconWeight.bold),
      light: roleIcon(r, GlassIconWeight.light),
    );

/// Sheet bodies read `onGlass` in the wide window form and on `solid1` on the phone sheet.
bool sheetOnGlass(BuildContext context) => GlassFrame.of(context) != GlassFrameKind.phone;

/// The caption under a shelf poster: "Not started", "Caught up", or "Ch 12 of 40".
String shelfCaption(FollowedSeries s) {
  final r = s.readState;
  String n(double v) => v % 1 == 0 ? '${v.toInt()}' : '$v';
  if (r == null) return s.chapterCount > 0 ? '${s.chapterCount} chapters' : '';
  if (!r.started) return 'Not started';
  if (r.newCount == 0) return 'Caught up';
  final ch = r.chapterNumber ?? r.position?.toDouble();
  final of = r.latestNumber ?? r.total.toDouble();
  if (ch == null) return '${r.total} chapters';
  return of <= 0 ? 'Ch ${n(ch)}' : 'Ch ${n(ch)} of ${n(of)}';
}
