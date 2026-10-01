import 'dart:async';

import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart' show CineIconWeight;
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/layout/cine_measure.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

enum CineNoticeTone { empty, error, offline, caution, rateLimit }

/// One action of a notice: a label and its handler.
class CineNoticeAction {
  const CineNoticeAction(this.label, this.onPressed);
  final String label;
  final VoidCallback onPressed;
}

/// A notice set like a short article (cinematic 7.23): a 3 px heavy rule drawn on entrance, a
/// kicker by tone, a typed headline, a deck at 48ch and up to two actions. It never shows a count
/// or placeholder for content the 18+ gate hides.
class CineNotice extends StatefulWidget {
  const CineNotice({
    super.key,
    required this.tone,
    required this.headline,
    this.deck,
    this.kicker,
    this.primary,
    this.quiet,
    this.glyph,
    this.wholeScreen = false,
    this.retryAfter,
    this.onRetry,
  });

  /// The offline preset: adds "Saved chapters still open." and a `Go to Downloads` action.
  factory CineNotice.offline({
    Key? key,
    required VoidCallback onGoToDownloads,
    String headline = 'You are offline.',
    String? deck,
    bool wholeScreen = false,
  }) =>
      CineNotice(
        key: key,
        tone: CineNoticeTone.offline,
        headline: headline,
        deck: deck == null ? 'Saved chapters still open.' : '$deck Saved chapters still open.',
        wholeScreen: wholeScreen,
        primary: CineNoticeAction('Go to Downloads', onGoToDownloads),
      );

  final CineNoticeTone tone;
  final String headline;
  final String? deck;

  /// Overrides the tone's kicker (`EMPTY SHELF` or `NOTHING HERE YET` for empty).
  final String? kicker;
  final CineNoticeAction? primary, quiet;
  final int? glyph;
  final bool wholeScreen;

  /// Rate limit: the live "Retrying in 12 s" countdown, from `ApiError.retryAfter`.
  final Duration? retryAfter;
  final VoidCallback? onRetry;

  @override
  State<CineNotice> createState() => _CineNoticeState();
}

class _CineNoticeState extends State<CineNotice> {
  Timer? _tick;
  int _left = 0;

  @override
  void initState() {
    super.initState();
    if (widget.tone == CineNoticeTone.rateLimit && widget.retryAfter != null) {
      _left = widget.retryAfter!.inSeconds;
      _tick = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        setState(() => _left = _left > 0 ? _left - 1 : 0);
        if (_left == 0) {
          t.cancel();
          widget.onRetry?.call();
        }
      });
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  String _kicker() =>
      widget.kicker ??
      switch (widget.tone) {
        CineNoticeTone.empty => 'NOTHING HERE YET',
        CineNoticeTone.error => 'CORRECTION',
        CineNoticeTone.offline => 'OFFLINE EDITION',
        CineNoticeTone.caution => 'NOTE',
        CineNoticeTone.rateLimit => 'SLOW DOWN',
      };

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final tone = widget.tone;
    final kickerColor = tone == CineNoticeTone.error ? c.colorProof : (tone == CineNoticeTone.caution ? c.colorSpot : c.colorInk60);
    final deckStyle = CineText.style(context, c.typeDeck);
    var deck = widget.deck;
    if (tone == CineNoticeTone.rateLimit && widget.retryAfter != null) {
      final live = 'Retrying in $_left s';
      deck = deck == null ? live : '$deck $live.';
    }
    final primary = widget.primary;
    final top = widget.wholeScreen ? MediaQuery.sizeOf(context).height * 0.15 : 0.0;

    return Padding(
      padding: EdgeInsets.only(top: top),
      child: Semantics(
        container: true,
        liveRegion: tone == CineNoticeTone.error || tone == CineNoticeTone.rateLimit,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(height: c.ruleHeavy.width, child: const CineRuleDraw(kind: CineRuleKind.heavy)),
          SizedBox(height: c.space4),
          if (widget.glyph != null) ...[
            CineGlyphIcon(widget.glyph!, size: 32, weight: CineIconWeight.light, color: c.colorInk45),
            SizedBox(height: c.space3),
          ],
          CineRoleText(_kicker(), c.typeKicker, color: kickerColor),
          SizedBox(height: c.space2),
          // TypedHeadline types headlines only (<= 60 graphemes); a longer line (a quoted query) is set whole.
          if (widget.headline.characters.length <= 60)
            TypedHeadline(widget.headline, style: CineText.style(context, c.typeSubhead), cap: c.typeSubhead.cap, level: widget.wholeScreen ? 1 : 2)
          else
            Semantics(header: true, headingLevel: widget.wholeScreen ? 1 : 2, child: CineRoleText(widget.headline, c.typeSubhead)),
          if (deck != null) ...[
            SizedBox(height: c.space3),
            CineMeasure(ch: 48, style: deckStyle, child: CineRoleText(deck, c.typeDeck, color: c.colorInk60)),
          ],
          if (primary != null || widget.quiet != null) ...[
            SizedBox(height: c.space6),
            Wrap(spacing: c.space4, runSpacing: c.space2, crossAxisAlignment: WrapCrossAlignment.center, children: [
              if (primary != null) CineButton(label: primary.label, onPressed: primary.onPressed),
              if (widget.quiet != null) CineButton(label: widget.quiet!.label, variant: CineButtonVariant.quiet, onPressed: widget.quiet!.onPressed),
            ],),
          ],
        ],),
      ),
    );
  }
}
