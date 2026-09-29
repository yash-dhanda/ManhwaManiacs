import 'package:flutter/material.dart';
import 'package:manhwamaniacs/core/error/fatal_error.dart';
import 'package:manhwamaniacs/skins/cinematic/navigation.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_notice.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/layout/cine_measure.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/typed_headline.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/cine_scaffold.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The status screens (cinematic 8.32 "In the app"): an unknown route inside the frame, and the
/// route-error notice the app frame lays over everything after an uncaught error.
class CineErrorScreen extends StatelessWidget {
  const CineErrorScreen.notFound({super.key, this.location})
      : report = null,
        onRetry = null,
        onRestart = null;

  const CineErrorScreen.routeError({super.key, required FatalErrorReport this.report, required VoidCallback this.onRetry, required VoidCallback this.onRestart})
      : location = null;

  final String? location;
  final FatalErrorReport? report;
  final VoidCallback? onRetry, onRestart;

  bool get _notFound => report == null;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    if (!_notFound) {
      return ColoredBox(
        color: const Color(0xFF000000),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(c.space4),
            child: Align(
              alignment: Alignment.topLeft,
              child: SingleChildScrollView(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  CineNotice(
                    tone: CineNoticeTone.error,
                    wholeScreen: true,
                    headline: 'Something broke on this page.',
                    deck: 'Nothing was lost; trying again usually fixes it.',
                    primary: CineNoticeAction('Try again', onRetry!),
                    quiet: CineNoticeAction('Restart the app', onRestart!),
                  ),
                  SizedBox(height: c.space6),
                  Semantics(
                    label: 'Reference ${report!.ref}',
                    excludeSemantics: true,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      constraints: const BoxConstraints(minHeight: 20),
                      decoration: BoxDecoration(border: Border.all(color: c.colorInk30)),
                      child: CineLit('REF ${report!.ref}', CineFace.plexMono, 12, 16, color: c.colorInk100),
                    ),
                  ),
                ],),
              ),
            ),
          ),
        ),
      );
    }
    return CineScaffold(
      location: location ?? '/',
      runningTitle: 'NOT IN THIS ISSUE',
      back: const CineBack(),
      firstRunNote: false,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(c.space4, c.space8, c.space4, c.space8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ExcludeSemantics(
            child: Text(
              'p. 404',
              style: CineText.literal(context, CineFace.bodoni, 64 * 1.5, 72 * 1.5).copyWith(color: c.colorInk30),
              textScaler: CineText.literalScaler(context, CineFace.bodoni),
            ),
          ),
          SizedBox(height: c.space4),
          CineRoleText('NOT IN THIS ISSUE', c.typeKicker, color: c.colorInk60),
          SizedBox(height: c.space2),
          TypedHeadline("This page doesn't exist.", style: CineText.style(context, c.typeMasthead), cap: c.typeMasthead.cap, level: 1),
          SizedBox(height: c.space3),
          CineMeasure(
            ch: 48,
            style: CineText.style(context, c.typeDeck),
            child: CineRoleText(
              'It may have been renamed, or the series it pointed to left your library. Search everything from',
              c.typeDeck,
              color: c.colorInk60,
            ),
          ),
          CineButton(label: 'Discover', variant: CineButtonVariant.link, onPressed: () => goSection(context, 2)),
          SizedBox(height: c.space6),
          Wrap(spacing: c.space4, runSpacing: c.space2, children: [
            CineButton(label: 'Back to Tonight', onPressed: () => goSection(context, 0)),
            CineButton(label: 'Open library', variant: CineButtonVariant.quiet, onPressed: () => goSection(context, 1)),
          ],),
        ],),
      ),
    );
  }
}
