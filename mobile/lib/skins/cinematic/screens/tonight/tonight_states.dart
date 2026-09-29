import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/home/models/home_feed.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_galley.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_notice.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/layout/cine_grid.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/cover_story_parts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/tonight/tonight_layout.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The galley proof of the whole page (cinematic 7.17, 8.8 "Loading"): the kicker live, headline
/// bars at the cover's line height, the flickering art plate, rail plates. Appears after 120 ms.
class TonightGalley extends StatelessWidget {
  const TonightGalley({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final size = MediaQuery.sizeOf(context);
    final wide = tonightWide(context);
    final grid = CineGrid.of(context);
    final h = wide ? spreadHeight(size) : phoneCoverHeight(size);
    final cover = CineText.style(context, c.typeCover);
    final line = (cover.fontSize ?? 44) * (cover.height ?? 1) * CineText.scaler(context, c.typeCover).scale(1);
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          height: h,
          child: Stack(fit: StackFit.expand, children: [
            const CineDelayed(child: CineGalleyPlate()),
            Positioned(
              left: grid.left,
              right: wide ? size.width - grid.left - grid.span(4) : grid.right,
              bottom: 16,
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                CineRoleText('TONIGHT', c.typeKicker, color: c.colorInk60),
                SizedBox(height: c.space2),
                CineDelayed(child: CineGalleyHeadline(lineHeight: line)),
              ],),
            ),
          ],),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(grid.left, c.space6, grid.right, 0),
          child: CineDelayed(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (var r = 0; r < 2; r++) ...[
                Container(height: 1, color: c.colorRule1),
                SizedBox(height: c.space3),
                const CineGalleyLine(lineHeight: 28),
                SizedBox(height: c.space3),
                SizedBox(
                  height: 180,
                  child: Row(children: [
                    for (var i = 0; i < 3; i++) ...[
                      Expanded(child: AspectRatio(aspectRatio: 2 / 3, child: CineFlicker(index: r * 3 + i, child: const CineGalleyPlate()))),
                      if (i < 2) SizedBox(width: c.space2),
                    ],
                  ],),
                ),
                SizedBox(height: c.space10),
              ],
            ],),
          ),
        ),
      ],),
    );
  }
}

/// The whole-feed failure (cinematic 8.8 "Error", "Rate limited"): the 7.23 notice across four
/// columns (phone) or six of eight (tablet) at 15 % of the screen height.
class TonightErrorNotice extends StatelessWidget {
  const TonightErrorNotice({super.key, required this.onRetry, required this.onDownloads, this.retryAfter});
  final VoidCallback onRetry, onDownloads;
  final Duration? retryAfter;

  @override
  Widget build(BuildContext context) {
    final grid = CineGrid.of(context);
    final wide = tonightWide(context);
    final notice = retryAfter != null
        ? CineNotice(
            key: const Key('tonight-rate-limited'),
            tone: CineNoticeTone.rateLimit,
            headline: 'Too many asks at once.',
            deck: 'The server asked us to wait.',
            retryAfter: retryAfter,
            onRetry: onRetry,
            wholeScreen: true,
            primary: CineNoticeAction('Try again', onRetry),
          )
        : CineNotice(
            key: const Key('tonight-error'),
            tone: CineNoticeTone.error,
            headline: "This issue didn't print.",
            deck: "The server didn't answer. Saved chapters still open.",
            wholeScreen: true,
            primary: CineNoticeAction('Try again', onRetry),
            quiet: CineNoticeAction('Go to Downloads', onDownloads),
          );
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(grid.left, MediaQuery.viewPaddingOf(context).top + 64, grid.right, 0),
        child: Align(alignment: Alignment.topLeft, child: SizedBox(width: wide ? grid.span(6) : double.infinity, child: notice)),
      ),
    );
  }
}

/// The headline block of a feed with no cover story (a new profile, an empty feed, an offline
/// edition with nothing saved): kicker, headline, deck and one primary action, no art.
class TonightHeadBlock extends StatelessWidget {
  const TonightHeadBlock({super.key, required this.feed, required this.headline, required this.actionLabel, required this.onAction});
  final HomeFeed feed;

  /// The screen's headline widget (typed or at rest).
  final Widget headline;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final grid = CineGrid.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(grid.left, MediaQuery.viewPaddingOf(context).top + 64 + c.space10, grid.right, c.space8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CineRoleText('TONIGHT · No. ${feed.issueNo}', c.typeKicker, color: c.colorInk60),
        SizedBox(height: c.space2),
        headline,
        if (feed.deck.isNotEmpty) ...[SizedBox(height: c.space2), TonightDeck(text: feed.deck)],
        SizedBox(height: c.space6),
        CineButton(key: const Key('tonight-head-action'), label: actionLabel, onPressed: onAction),
      ],),
    );
  }
}

/// The section rule and `Refresh R` footer line: "Issue No. 184 · compiled 21:04 · Refresh R".
String compiledAt(HomeFeed feed) {
  DateTime? newest = feed.generatedAt;
  for (final s in feed.sections) {
    final g = s.generatedAt;
    if (g != null && (newest == null || g.isAfter(newest))) newest = g;
  }
  final t = (newest ?? DateTime.now()).toLocal();
  return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
