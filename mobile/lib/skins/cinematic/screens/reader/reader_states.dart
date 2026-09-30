import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/not_available.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_frames.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart' show CineFlicker;
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_icon_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_not_available_notice.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_notice.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_series.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

Widget _ground(BuildContext context, Widget child) => ColoredBox(
      color: context.cine.colorPaper0,
      child: Material(color: const Color(0x00000000), child: child),
    );

/// The chapter loading: three galley page plates at the manifest's (or 2:3) aspect in the strip
/// column (Flicker), the running head visible with `LOADING CH 142` and a 24 px leader dial after
/// 400 ms (cinematic 8.14.11).
class ReaderLoading extends ConsumerWidget {
  const ReaderLoading({super.key, this.chapterKey});

  final String? chapterKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    final top = MediaQuery.viewPaddingOf(context).top;
    final width = MediaQuery.sizeOf(context).width;
    final column = width >= 600 ? 720.0 : width;
    return _ground(
      context,
      Stack(
        children: [
          Center(
            child: SizedBox(
              width: column,
              child: ListView(
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (var i = 0; i < 3; i++)
                    AspectRatio(
                      aspectRatio: 2 / 3,
                      child: CineFlicker(index: i, child: ColoredBox(color: c.colorGalley)),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            top: top,
            left: 8,
            right: 8,
            child: Row(
              children: [
                CineIconButton(label: 'Back to the series', role: CineIconRole.back, onPressed: () => _back(context)),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: cineHitMin(context)),
                  child: Center(child: CineRoleText('LOADING ${chapterFolio(_number(context, ref))}', c.typeFolio, color: c.colorSpot)),
                ),
              ],
            ),
          ),
          const Center(child: CineLeaderDial(size: 24)),
        ],
      ),
    );
  }

  double? _number(BuildContext context, WidgetRef ref) {
    try {
      final params = GoRouterState.of(context).pathParameters;
      final source = params['sourceId'], series = params['seriesKey'] ?? params['seriesId'], chapter = params['chapterKey'] ?? params['chapterId'] ?? chapterKey;
      if (source == null || series == null || chapter == null) return null;
      return ref.watch(readerSeriesProvider((sourceId: source, seriesKey: series)))?.chapterOf(chapter)?.number;
    } catch (_) {
      return null;
    }
  }

  void _back(BuildContext context) {
    final router = GoRouter.of(context);
    if (router.canPop()) router.pop();
  }
}

/// What a chapter that did not open shows: the `NOT IN THIS ISSUE` notice for a removed or gated
/// series (worded identically for both), "This chapter has no pages." with `Back to the series`,
/// or a `CORRECTION` with the API message, `Try again` and `Go to the series`.
class ReaderFailureView extends StatelessWidget {
  const ReaderFailureView({super.key, required this.failure});

  final ReaderFailure failure;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final kind = failure.error == null ? null : notAvailableKind(failure.error!);
    final Widget notice;
    if (kind != null) {
      notice = CineNotAvailableNotice(kind: kind);
    } else if (failure.noPages) {
      notice = CineNotice(
        tone: CineNoticeTone.empty,
        headline: 'This chapter has no pages.',
        wholeScreen: true,
        primary: CineNoticeAction('Back to the series', failure.back),
      );
    } else {
      notice = CineNotice(
        tone: CineNoticeTone.error,
        headline: failure.error?.userMessage ?? "This chapter didn't load.",
        wholeScreen: true,
        primary: CineNoticeAction('Try again', failure.retry),
        quiet: CineNoticeAction('Go to the series', failure.back),
      );
    }
    return _ground(
      context,
      SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: c.space4),
          child: SingleChildScrollView(child: notice),
        ),
      ),
    );
  }
}
