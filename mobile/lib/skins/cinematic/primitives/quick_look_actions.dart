import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';

/// The standard Quick look action ids, labels and icon roles, in the order the sheet shows them
/// (cinematic 7.22). Callers pass the subset that applies, with handlers.
abstract final class QuickLookId {
  static const open = 'open';
  static const continueReading = 'continue';
  static const previouslyOn = 'previously-on';
  static const addToCollection = 'add-to-collection';
  static const favourite = 'favourite';
  static const markRead = 'mark-read';
  static const downloadNext = 'download-next-5';
  static const recommend = 'recommend';
  static const moreLikeThis = 'more-like-this';
  static const notForMe = 'not-for-me';
  static const removeFromRow = 'remove-from-row';
  static const unfollow = 'unfollow';
}

class QuickLookAction {
  const QuickLookAction(this.id, this.label, this.icon, {this.destructive = false, this.disabled = false, this.onSelected});
  final String id, label;
  final CineIconRole icon;
  final bool destructive;

  /// Shown dimmed and not tappable (`Move up` on the first poster).
  final bool disabled;
  final VoidCallback? onSelected;
}

const _catalogue = <(String, String, CineIconRole, bool)>[
  (QuickLookId.open, 'Open', CineIconRole.external, false),
  (QuickLookId.continueReading, 'Continue', CineIconRole.play, false),
  (QuickLookId.previouslyOn, 'Previously on', CineIconRole.history, false),
  (QuickLookId.addToCollection, 'Add to collection', CineIconRole.collections, false),
  (QuickLookId.favourite, 'Favourite', CineIconRole.favourite, false),
  (QuickLookId.markRead, 'Mark read', CineIconRole.select, false),
  (QuickLookId.downloadNext, 'Download next 5', CineIconRole.download, false),
  (QuickLookId.recommend, 'Recommend to…', CineIconRole.recommend, false),
  (QuickLookId.moreLikeThis, 'More like this', CineIconRole.picks, false),
  (QuickLookId.notForMe, 'Not for me', CineIconRole.close, false),
  (QuickLookId.removeFromRow, 'Remove from row', CineIconRole.delete, false),
  (QuickLookId.unfollow, 'Unfollow', CineIconRole.following, true),
];

/// The actions in the standard order for the ids present in [handlers].
List<QuickLookAction> quickLookActions(Map<String, VoidCallback> handlers) => [
      for (final a in _catalogue)
        if (handlers.containsKey(a.$1)) QuickLookAction(a.$1, a.$2, a.$3, destructive: a.$4, onSelected: handlers[a.$1]),
    ];
