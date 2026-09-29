import 'dart:async';

import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/skins/cinematic/cine_grain.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_icon_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_menu.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/streak_flame.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/tonight_layout.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/transitions.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// Everything the cover story's parts need from the screen.
class CoverStoryData {
  const CoverStoryData({
    required this.feed,
    required this.cover,
    required this.imageUrl,
    required this.heroTag,
    required this.now,
    required this.animateHeadline,
    required this.headlineFocus,
    required this.typed,
    required this.onTyped,
    required this.onContinue,
    required this.onDwell,
    required this.onRecap,
    required this.onDetails,
    required this.onLightbox,
    required this.onRefresh,
  });

  final HomeFeed feed;
  final HomeCover cover;

  /// The cover's absolute URL, or null for the plate.
  final String? imageUrl;
  final (String, String)? heroTag;
  final DateTime now;

  /// The Front page moment: the headline types itself (once per day per profile).
  final bool animateHeadline;
  final FocusNode headlineFocus;
  final TypedHeadlineController typed;
  final VoidCallback onTyped;
  final VoidCallback onContinue, onDwell, onRecap, onDetails, onLightbox, onRefresh;

  bool get hasRecap => cover.recap?.available ?? false;

  /// Where `Continue` goes: null when the cover names no chapter (it opens the series instead).
  bool get canContinue => cover.chapterKey != null;

  /// `Start` for a pick, `Continue` for a series in progress.
  String get primaryLabel => !canContinue ? 'Open' : (cover.isStart ? 'Start' : 'Continue');

  /// `CH 143 · p.1`, `CH 213 · 42%` (novels), `CH 1`.
  String? get primaryFolio {
    if (!canContinue) return null;
    final n = cover.chapterNumber;
    final ch = chapterFolio(cover.isStart ? (n ?? 1) : n);
    if (cover.isStart) return ch;
    if (cover.isNovel) {
      final pct = cover.pageCount > 0 ? (cover.lastPage * 100 / cover.pageCount).round() : 0;
      return '$ch · $pct%';
    }
    return '$ch · p.${cover.lastPage}';
  }

  /// The kicker: `TONIGHT · No. 184`, and the series title when the headline dropped it.
  String get kicker {
    final k = feed.kickerTitle;
    return 'TONIGHT · No. ${feed.issueNo}${k == null ? '' : ' · ${k.toUpperCase()}'}';
  }

  String get progressLabel => cover.progress == null ? '' : 'Chapter ${cover.chapterNumber?.toInt() ?? ''}, ${(cover.progress! * 100).round()} percent read';
}

/// The sharp cover: Hero, rack focus on decode (in [CineImage]), Drift, grain at 0.06 over the art
/// only. Tap opens the series; a 450 ms long-press opens the Lightbox.
class CoverArt extends StatelessWidget {
  const CoverArt({super.key, required this.data, this.drift = true, this.alignment = Alignment.center, this.opens = true});
  final CoverStoryData data;
  final bool drift;
  final Alignment alignment;

  /// False in the frozen frame of the pinned strip, where the strip owns the taps.
  final bool opens;

  @override
  Widget build(BuildContext context) {
    final image = CineImage(url: data.imageUrl, title: data.cover.title, alignment: alignment);
    Widget art = ClipRect(child: drift ? CineDrift(child: image) : image);
    art = CineGrain(child: art);
    if (data.heroTag != null) art = CineHero(tag: data.heroTag!, child: art);
    return Semantics(
      button: true,
      label: 'Cover of ${data.cover.title}. Opens the series.',
      excludeSemantics: true,
      onTap: data.onDetails,
      onLongPress: data.onLightbox,
      child: CinePressable(
        hit: false,
        enabled: opens,
        onTap: data.onDetails,
        onLongPress: data.onLightbox,
        builder: (_, __) => art,
      ),
    );
  }
}

/// The kicker line, with the 16 px at-risk flame in `spot` before it while the streak is at risk.
class CoverKicker extends StatelessWidget {
  const CoverKicker({super.key, required this.data});
  final CoverStoryData data;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (data.feed.streak.atRisk) ...[
        StreakFlame(streak: data.feed.streak, size: 16, now: data.now, ignite: false),
        SizedBox(width: c.space2),
      ],
      Flexible(child: CineRoleText(data.kicker, c.typeKicker, color: c.colorInk60, maxLines: 1, overflow: TextOverflow.ellipsis)),
    ],);
  }
}

/// The main headline: typed once a day (with the caret), else set at rest. Always a level-1
/// heading whose label holds the whole string from the first frame.
class TonightHeadline extends StatelessWidget {
  const TonightHeadline({super.key, required this.data, required this.role});
  final CoverStoryData data;
  final CineTextRole role;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final style = CineText.style(context, role).copyWith(color: c.colorInk100);
    final text = data.feed.headline;
    final Widget body = data.animateHeadline
        ? TypedHeadline(text, style: style, cap: role.cap, level: 1, controller: data.typed, onDone: data.onTyped)
        : Semantics(
            header: true,
            headingLevel: 1,
            label: text,
            excludeSemantics: true,
            child: Text(text, style: style, textScaler: CineText.scaler(context, role)),
          );
    return Focus(focusNode: data.headlineFocus, skipTraversal: true, child: body);
  }
}

/// The deck under the headline: `type.deck` in `ink.60`, two lines, ellipsis.
class TonightDeck extends StatelessWidget {
  const TonightDeck({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    if (text.isEmpty) return const SizedBox.shrink();
    return CineRoleText(text, c.typeDeck, color: c.colorInk60, maxLines: 2, overflow: TextOverflow.ellipsis);
  }
}

/// `Continue │ CH 143 · p.1`, `Previously on…`, `Details` (cinematic 8.8).
class CoverActions extends StatelessWidget {
  const CoverActions({super.key, required this.data, this.wide = false});
  final CoverStoryData data;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final size = wide ? CineButtonSize.lg : CineButtonSize.md;
    final primary = _Dwell(
      onDwell: data.onDwell,
      child: CineButton(
        key: const Key('tonight-continue'),
        label: data.primaryLabel,
        folio: data.primaryFolio,
        variant: data.primaryFolio == null ? CineButtonVariant.primary : CineButtonVariant.split,
        size: size,
        onPressed: data.canContinue ? data.onContinue : data.onDetails,
      ),
    );
    final recap = data.hasRecap && data.canContinue
        ? CineButton(key: const Key('tonight-recap'), label: 'Previously on…', variant: CineButtonVariant.secondary, size: size, onPressed: data.onRecap)
        : null;
    final details = data.canContinue
        ? CineButton(key: const Key('tonight-details'), label: 'Details', variant: CineButtonVariant.quiet, size: size, onPressed: data.onDetails)
        : null;
    if (wide) {
      return Wrap(spacing: c.space4, runSpacing: c.space3, crossAxisAlignment: WrapCrossAlignment.center, children: [primary, if (recap != null) recap, if (details != null) details]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      primary,
      if (recap != null || details != null) ...[
        SizedBox(height: c.space3),
        Row(children: [
          if (recap != null) Expanded(child: recap),
          if (recap != null && details != null) SizedBox(width: c.space3),
          if (details != null) Expanded(child: recap == null ? Align(alignment: Alignment.centerLeft, child: details) : details),
        ],),
      ],
    ],);
  }
}

/// Fires [onDwell] after a 150 ms hardware-keyboard focus or pointer dwell (cinematic 15.6).
class _Dwell extends StatefulWidget {
  const _Dwell({required this.onDwell, required this.child});
  final VoidCallback onDwell;
  final Widget child;

  @override
  State<_Dwell> createState() => _DwellState();
}

class _DwellState extends State<_Dwell> {
  Timer? _t;

  void _start() {
    _t?.cancel();
    _t = Timer(const Duration(milliseconds: 150), widget.onDwell);
  }

  void _stop() => _t?.cancel();

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => _start(),
        onExit: (_) => _stop(),
        child: Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onFocusChange: (f) => f ? _start() : _stop(),
          child: widget.child,
        ),
      );
}

/// The `dots-three` `on-art` overflow at the art's top-right: `View cover` and `Refresh`, the
/// non-gesture paths of the long-press and the pull.
class CoverOverflow extends StatelessWidget {
  const CoverOverflow({super.key, required this.data});
  final CoverStoryData data;

  @override
  Widget build(BuildContext context) => Builder(
        builder: (ctx) => CineIconButton(
          key: const Key('tonight-overflow'),
          label: 'More',
          role: CineIconRole.overflow,
          variant: CineIconButtonVariant.onArt,
          onPressed: () => showCineMenu<String>(ctx, anchor: cineAnchorRect(ctx), entries: [
            CineMenuEntry(label: 'View cover', value: 'view', icon: CineIconRole.fullscreenEnter, onSelected: data.onLightbox),
            CineMenuEntry(label: 'Refresh', value: 'refresh', icon: CineIconRole.refresh, onSelected: data.onRefresh),
          ],),
        ),
      );
}
