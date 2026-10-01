import 'dart:async';

import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/reaction_stamps.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/sheet_route.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';

/// `React to this chapter` (cinematic 8.14.13): a `[0.5]` sheet, kicker `REACT`, title "Chapter 142",
/// with the stamps (guarded while the chapter is unfinished).
Future<void> showReactSheet(BuildContext context, {required String sourceId, required String seriesKey, required String chapterKey, double? chapterNumber}) {
  final n = chapterNumber;
  final title = n == null ? 'This chapter' : 'Chapter ${n == n.roundToDouble() ? n.toInt() : n}';
  return showCineSheet<void>(
    context,
    kicker: 'REACT',
    title: title,
    livePreview: true,
    builder: (ctx) => Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: EdgeInsets.only(top: ctx.cine.space2, bottom: ctx.cine.space6), // the sheet body sets the gutter
        child: Align(alignment: Alignment.topLeft, child: ReactionStamps(sourceId: sourceId, seriesKey: seriesKey, chapterKey: chapterKey, chapterNumber: chapterNumber)),
      ),
    ),
  );
}

/// For callers that prefer not to await.
void openReactSheet(BuildContext context, {required String sourceId, required String seriesKey, required String chapterKey, double? chapterNumber}) =>
    unawaited(showReactSheet(context, sourceId: sourceId, seriesKey: seriesKey, chapterKey: chapterKey, chapterNumber: chapterNumber));
