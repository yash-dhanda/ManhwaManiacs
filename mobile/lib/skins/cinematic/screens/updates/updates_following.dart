import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_icon_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_menu.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_row.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/hub/hub_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// A followed series in the FOLLOWING tab (cinematic 7.16 standard row): the 48 x 72 cover, the
/// title, the source and when it was last checked, the Notify bell and the row menu.
class FollowingRow extends StatelessWidget {
  const FollowingRow({
    super.key,
    required this.series,
    required this.coverUrl,
    required this.sourceName,
    required this.now,
    required this.onOpen,
    required this.onNotify,
    required this.onCheck,
    required this.onUnfollow,
    this.enabled = true,
    this.focusNode,
  });

  final FollowedSeries series;
  final String? coverUrl;
  final String sourceName;
  final DateTime now;
  final VoidCallback onOpen, onNotify, onCheck, onUnfollow;
  final bool enabled;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final s = series;
    final checked = s.lastCheckedAt == null ? 'Not checked yet' : 'Checked ${agoWords(s.lastCheckedAt!, now)}';
    final bell = Semantics(
      button: true,
      toggled: s.notify,
      label: s.notify ? 'Turn off notifications for ${s.title}' : 'Notify me of new chapters of ${s.title}',
      excludeSemantics: true,
      onTap: enabled ? onNotify : null,
      child: CineIconButton(
        label: s.notify ? 'Turn off notifications' : 'Notify me of new chapters',
        role: CineIconRole.notify,
        selected: s.notify,
        onPressed: enabled ? onNotify : null,
      ),
    );
    return CineRowShell(
      minHeight: 96,
      focusNode: focusNode,
      onTap: onOpen,
      handle: bell,
      menu: [
        CineMenuEntry<Object?>(label: 'Check this series', disabled: !enabled, disabledReason: 'Needs a connection.', onSelected: onCheck),
        CineMenuEntry<Object?>(label: 'Unfollow', destructive: true, disabled: !enabled, disabledReason: 'Needs a connection.', onSelected: onUnfollow),
      ],
      semanticLabel: '${s.title}, $sourceName, $checked',
      child: Row(children: [
        SizedBox(
          width: 48,
          height: 72,
          child: Hero(tag: (s.sourceId, s.seriesKey), child: DecoratedBox(decoration: BoxDecoration(border: Border.all(color: c.colorRule2)), child: CineImage(url: coverUrl, title: s.title))),
        ),
        SizedBox(width: c.space4),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            CineRoleText(s.title, c.typeTitle, maxLines: 2, overflow: TextOverflow.ellipsis),
            CineRoleText(sourceName, c.typeCaption, color: c.colorInk60, maxLines: 1, overflow: TextOverflow.ellipsis),
            CineRoleText(checked, c.typeCaption, color: c.colorInk45, maxLines: 1),
          ],),
        ),
      ],),
    );
  }
}
