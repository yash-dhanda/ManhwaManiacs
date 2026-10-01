import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/glass/ambient_field.dart' show GlassAmbientSpec;
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/badge.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart' show gt;
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart' show GlassButtonIcon;
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart' show Glyph;
import 'package:manhwamaniacs/skins/glass/primitives/poster.dart';
import 'package:manhwamaniacs/skins/glass/type.dart' show GlassTypeStyle;

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

/// The Library hub's ambient field (glass 2.1.8): the cover palette of the first visible item, set by the active section once the list
/// has been still for 600 ms; null falls back to the aurora.
final libraryAmbientProvider = StateProvider<GlassAmbientSpec?>((ref) => null, name: 'libraryAmbient');

/// A novel's title: Literata at the `headline` role.
class BookTitle extends StatelessWidget {
  const BookTitle(this.text, {super.key, this.maxLines = 2, this.italic = false, this.size});
  final String text;
  final int maxLines;
  final bool italic;
  final double? size;

  @override
  Widget build(BuildContext context) => Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: GlassTypeStyle.style(context, gt.typeHeadline, size: size).copyWith(fontFamily: 'Literata', color: gt.colorLabel1, fontStyle: italic ? FontStyle.italic : null), textScaler: TextScaler.noScaling,);
}

/// The current location's query parameters, read from inside a `?sheet=` sheet. A sheet is a route the host pushes, not a GoRoute
/// page, so `GoRouterState.of` cannot answer there; the router's current configuration can.
Map<String, String> sheetParams(BuildContext context) => GoRouter.of(context).routerDelegate.currentConfiguration.uri.queryParameters;
