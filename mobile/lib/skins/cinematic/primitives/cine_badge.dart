import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/a11y/folio.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

enum CineBadgeVariant {
  newCount,
  status,
  reading,
  certificate,
  saved,
  text,
  stale,
  picked,
  pickedAgo,
  smart,
  shared,
  now,
  count,
  admin,
  you,
  deactivated,
}

/// `unread` -> NOT STARTED, `reading` -> READING, `on_hold` -> ON HOLD, `plan_to_read` -> PLAN TO
/// READ (short PLAN), `completed` -> DONE, `dropped` -> DROPPED. COMPLETED is publication status.
String readingStatusLabel(String status, {bool short = false}) => switch (status) {
      'unread' => 'NOT STARTED',
      'reading' => 'READING',
      'on_hold' => 'ON HOLD',
      'plan_to_read' => short ? 'PLAN' : 'PLAN TO READ',
      'completed' => 'DONE',
      'dropped' => 'DROPPED',
      _ => status.toUpperCase(),
    };

/// Square badges (cinematic 7.19): min height 16, 4 px horizontal padding, `typeMicro`, stacked 4 px
/// apart. `onArt` puts a `#000` fill inside the outline.
class CineBadge extends StatelessWidget {
  const CineBadge(this.label, {super.key, required this.variant, this.onArt = false, this.large = false, this.semanticLabel});

  /// `NEW` / `3 NEW` / `99+ NEW`.
  factory CineBadge.newCount(int? n, {Key? key, bool onArt = false}) =>
      CineBadge(n == null || n <= 0 ? 'NEW' : (n > 99 ? '99+ NEW' : '$n NEW'), key: key, variant: CineBadgeVariant.newCount, onArt: onArt);

  /// ONGOING, COMPLETED, HIATUS, CANCELLED, UPCOMING.
  factory CineBadge.status(String s, {Key? key, bool onArt = false}) => CineBadge(s.toUpperCase(), key: key, variant: CineBadgeVariant.status, onArt: onArt);

  /// READING, ON HOLD, PLAN, DROPPED, DONE: the Library wall only.
  factory CineBadge.reading(String status, {Key? key, bool onArt = false}) =>
      CineBadge(readingStatusLabel(status, short: true), key: key, variant: CineBadgeVariant.reading, onArt: onArt);

  /// The 18+ certificate; render only when the caller says the gate is open.
  factory CineBadge.certificate({Key? key, bool large = false, bool onArt = false}) =>
      CineBadge('18', key: key, variant: CineBadgeVariant.certificate, large: large, onArt: onArt, semanticLabel: 'Mature, 18 plus');

  /// `SAVED COPY · 3 H`.
  factory CineBadge.stale(String ago, {Key? key}) => CineBadge('SAVED COPY · $ago', key: key, variant: CineBadgeVariant.stale, semanticLabel: 'Saved copy, ${folioLabel(ago)}');

  /// `PICKED 3 DAYS AGO`.
  factory CineBadge.pickedAgo(String ago, {Key? key}) => CineBadge('PICKED $ago', key: key, variant: CineBadgeVariant.pickedAgo);

  /// `99+` cap.
  factory CineBadge.count(int n, {Key? key, bool onArt = false}) => CineBadge(n > 99 ? '99+' : '$n', key: key, variant: CineBadgeVariant.count, onArt: onArt);

  final String label;
  final CineBadgeVariant variant;
  final bool onArt;

  /// The certificate at 20 px (feature pages).
  final bool large;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    const black = Color(0xFF000000);
    Color? fill;
    late Color line, ink;
    switch (variant) {
      case CineBadgeVariant.newCount:
      case CineBadgeVariant.count:
        fill = c.colorSpot;
        line = c.colorSpot;
        ink = black;
      case CineBadgeVariant.now:
      case CineBadgeVariant.you:
        fill = c.colorInk100;
        line = c.colorInk100;
        ink = black;
      case CineBadgeVariant.status:
      case CineBadgeVariant.text:
      case CineBadgeVariant.smart:
      case CineBadgeVariant.shared:
        line = c.colorInk45;
        ink = c.colorInk60;
      case CineBadgeVariant.pickedAgo:
        line = c.colorInk45;
        ink = c.colorInk60;
      case CineBadgeVariant.reading:
      case CineBadgeVariant.picked:
      case CineBadgeVariant.admin:
        line = c.colorInk100;
        ink = c.colorInk100;
      case CineBadgeVariant.saved:
        line = c.colorSet;
        ink = c.colorSet;
      case CineBadgeVariant.stale:
        line = c.colorSpot;
        ink = c.colorSpot;
      case CineBadgeVariant.certificate:
      case CineBadgeVariant.deactivated:
        line = c.colorProof;
        ink = c.colorProof;
    }
    if (onArt && fill == null) fill = black;

    if (variant == CineBadgeVariant.certificate) {
      final d = large ? 20.0 : 16.0;
      return Semantics(
        label: semanticLabel,
        excludeSemantics: true,
        child: Container(
          width: d,
          height: d,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: fill, border: Border.all(color: line)),
          child: CineLit('18', CineFace.archivo, large ? 12 : 10, large ? 14 : 12, wght: 800, wdth: 62, color: ink),
        ),
      );
    }
    final mono = variant == CineBadgeVariant.count;
    final text = mono
        ? CineLit(label, CineFace.plexMono, 10, 12, color: ink)
        : CineRoleText(label, c.typeMicro, color: ink);
    return Semantics(
      label: semanticLabel ?? folioLabel(label),
      excludeSemantics: true,
      child: Container(
        constraints: BoxConstraints(minHeight: 16, minWidth: mono ? 16 : 0),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        alignment: mono ? Alignment.center : null,
        decoration: BoxDecoration(color: fill, border: fill == null || onArt ? Border.all(color: line) : null),
        child: text,
      ),
    );
  }
}
