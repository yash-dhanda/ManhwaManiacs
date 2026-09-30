import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/recap/models/recap_origin.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/add_to_shelf_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/quick_look_builders.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_badge.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_radio.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/quick_look.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/quick_look_actions.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/reorder_announce.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/sheet_route.dart';
import 'package:manhwamaniacs/skins/cinematic/recap/continue_to.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/library/shelf_actions.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The six reading statuses in the order the status sheet lists them.
const List<String> kReadingStatuses = ['reading', 'unread', 'completed', 'on_hold', 'plan_to_read', 'dropped'];

/// The series page of a followed row, by the match cut (`/library/{followedId}`).
void openFollowed(BuildContext context, FollowedSeries s) => unawaited(context.push(Routes.featureByFollow(s.id)));

/// Quick look for a shelf series (cinematic 7.22, 8.9): Open, Continue (Dip), Favourite, Status,
/// Notify, Add to collection, Download next 5, Remove from library, and in Manual order the four
/// Move actions. Offline it keeps only Open and Continue.
Future<void> openShelfQuickLook(
  BuildContext context,
  WidgetRef ref,
  FollowedSeries s, {
  required String? coverUrl,
  required ShelfActions actions,
  required bool offline,
  int? moveIndex,
  int moveCount = 0,
  void Function(int from, int to)? onMove,
}) {
  final chapter = continueChapterKey(s);
  final list = <QuickLookAction>[
    QuickLookAction(QuickLookId.open, 'Open', CineIconRole.external, onSelected: () => openFollowed(context, s)),
    if (chapter != null)
      QuickLookAction(QuickLookId.continueReading, 'Continue', CineIconRole.play, onSelected: () => unawaited(continueTo(context, ref, sourceId: s.sourceId, seriesKey: s.seriesKey, chapterKey: chapter, title: s.title, lastReadAt: s.readState?.lastReadAt, origin: RecapEntry.dip))),
    if (!offline) ...[
      QuickLookAction(QuickLookId.favourite, s.isFavorite ? 'Unfavourite' : 'Favourite', CineIconRole.favourite, onSelected: () => unawaited(actions.favourite(s))),
      QuickLookAction('status', 'Status', CineIconRole.edit, onSelected: () => unawaited(showStatusSheet(context, title: s.title, current: s.readingStatus, onPick: (v) => unawaited(actions.setStatus(s, v))))),
      QuickLookAction('notify', s.notify ? 'Turn off notifications' : 'Notify', CineIconRole.notify, onSelected: () => unawaited(actions.notify(s))),
      QuickLookAction(QuickLookId.addToCollection, 'Add to collection', CineIconRole.collections, onSelected: () => unawaited(showAddToShelfSheet(context, sourceId: s.sourceId, seriesKey: s.seriesKey, title: s.title))),
      QuickLookAction(QuickLookId.downloadNext, 'Download next 5', CineIconRole.download, onSelected: () => unawaited(downloadNextFive(context, ref, s))),
      if (moveIndex != null && onMove != null)
        for (final m in CineMove.values)
          QuickLookAction('move-${m.name}', m.label, CineIconRole.sort, disabled: m.target(moveIndex, moveCount) == null, onSelected: () {
            final to = m.target(moveIndex, moveCount);
            if (to != null) onMove(moveIndex, to);
          },),
      QuickLookAction('remove', 'Remove from library', CineIconRole.delete, destructive: true, onSelected: () => unawaited(actions.remove(s))),
    ],
  ];
  return openQuickLook(
    context,
    title: s.title,
    kicker: 'QUICK LOOK',
    heroTag: (s.sourceId, s.seriesKey),
    cover: CineImage(url: coverUrl, title: s.title),
    credits: readingStatusLabel(s.readingStatus),
    actions: list,
  );
}

/// A radio list of the six reading statuses (cinematic 7.21); picking one applies it and closes.
Future<void> showStatusSheet(BuildContext context, {required String title, required ValueChanged<String> onPick, String? current}) => showCineSheet<void>(
      context,
      kicker: 'STATUS',
      title: title,
      builder: (ctx) {
        final c = ctx.cine;
        return Padding(
          padding: EdgeInsets.fromLTRB(c.space4, 0, c.space4, c.space4),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final st in kReadingStatuses)
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: CineRadio<String>(
                  value: st,
                  groupValue: current,
                  label: readingStatusLabel(st),
                  onChanged: (v) {
                    Navigator.of(ctx).pop();
                    onPick(v);
                  },
                ),
              ),
          ],),
        );
      },
    );
