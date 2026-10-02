import 'package:flutter/material.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart' show CineFlicker;
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_notice.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/layout/cine_grid.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// Exact copy of the Circle's states (cinematic 9.3.2).
abstract final class CircleCopy {
  static const quietKicker = 'THE CIRCLE IS QUIET';
  static const quiet = (headline: 'Nobody has shared their reading yet.', deck: 'Turn on sharing to be the first.');
  static const sharingSettings = 'Sharing settings';
  static const privateLine = "You're reading privately. Others can't see your activity.";
  static const share = 'Share';
  static const sharingOn = 'Sharing is on.';
  static const onlyMe = "You're the only reader sharing so far.";
  static const emptyReading = (headline: 'Nobody is reading right now.', deck: null as String?);
  static const emptyReactions = (headline: 'No reactions yet.', deck: 'They appear here when someone stamps a chapter.');
  static const emptyLetters = (headline: 'No letters yet.', deck: 'When someone passes a series to you, it lands here.');
  static const emptyShelves = (headline: 'No shared shelves yet.', deck: null as String?);
  static const emptyAll = (headline: 'Nothing yet.', deck: 'What the others read shows up here.');
  static const newShelf = 'New shelf';
  static const errorKicker = 'CORRECTION';
  static const errorHeadline = "The circle didn't load.";
  static const tryAgain = 'Try again';
  static const needsConnection = 'Needs a connection.';
}

/// A notice across four columns (phones) or six of eight (tablets).
class CircleNoticeBox extends StatelessWidget {
  const CircleNoticeBox({super.key, required this.notice, this.top = 32});
  final Widget notice;

  /// Space above the notice's own rule.
  final double top;

  @override
  Widget build(BuildContext context) {
    final grid = CineGrid.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 600;
    return Padding(
      padding: EdgeInsets.fromLTRB(grid.left, top, grid.right, 48),
      child: Align(alignment: Alignment.topLeft, child: SizedBox(width: wide ? grid.span(6) : double.infinity, child: notice)),
    );
  }
}

/// A tab's empty line, at subhead size and left-aligned (the notice tone), with an optional action.
class CircleTabEmpty extends StatelessWidget {
  const CircleTabEmpty({super.key, required this.copy, this.action, this.onAction});
  final ({String headline, String? deck}) copy;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return CircleNoticeBox(
      notice: CineNotice(
        tone: CineNoticeTone.empty,
        kicker: 'NOTHING HERE YET',
        headline: copy.headline,
        deck: copy.deck,
        primary: action == null ? null : CineNoticeAction(action!, onAction ?? () {}),
      ),
    );
  }
}

/// The loading state: six greeked dispatches, flickering.
class CircleGalley extends StatelessWidget {
  const CircleGalley({super.key, this.count = 6});
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final grid = CineGrid.of(context);
    return Semantics(
      label: 'Loading',
      child: Padding(
        padding: EdgeInsets.fromLTRB(grid.left, c.space4, grid.right, 0),
        child: Column(children: [
          for (var i = 0; i < count; i++)
            Padding(
              padding: EdgeInsets.symmetric(vertical: c.space3),
              child: Row(children: [
                _Bar(width: 32, height: 32, index: i, round: true),
                SizedBox(width: c.space3),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _Bar(width: double.infinity, height: 12, index: i),
                  SizedBox(height: c.space2),
                  _Bar(width: 140, height: 12, index: i),
                ],),),
                SizedBox(width: c.space3),
                _Bar(width: 40, height: 60, index: i),
              ],),
            ),
        ],),
      ),
    );
  }
}

/// The correction for a failed load: `CORRECTION` "The circle didn't load." + `Try again`.
class CircleErrorNotice extends StatelessWidget {
  const CircleErrorNotice({super.key, required this.error, required this.onRetry, this.top = 32});
  final Object error;
  final VoidCallback onRetry;
  final double top;

  @override
  Widget build(BuildContext context) {
    final e = error;
    if (e is NetworkError) {
      return CircleNoticeBox(
        top: top,
        notice: CineNotice(
          key: const Key('circle-offline'),
          tone: CineNoticeTone.offline,
          kicker: 'OFFLINE EDITION',
          headline: 'The circle needs a connection.',
          primary: CineNoticeAction(CircleCopy.tryAgain, onRetry),
        ),
      );
    }
    return CircleNoticeBox(
      top: top,
      notice: CineNotice(
        key: const Key('circle-error'),
        tone: CineNoticeTone.error,
        kicker: CircleCopy.errorKicker,
        headline: CircleCopy.errorHeadline,
        primary: CineNoticeAction(CircleCopy.tryAgain, onRetry),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.width, required this.height, required this.index, this.round = false});
  final double width, height;
  final int index;
  final bool round;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: CineFlicker(
          index: index,
          child: SizedBox(width: width, height: height, child: DecoratedBox(decoration: BoxDecoration(color: context.cine.colorGalley, shape: round ? BoxShape.circle : BoxShape.rectangle))),
        ),
      );
}
