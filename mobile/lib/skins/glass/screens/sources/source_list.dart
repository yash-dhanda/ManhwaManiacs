import 'dart:async';

import 'package:flutter/services.dart' show KeyDownEvent, LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/sources/models/source.dart';
import 'package:manhwamaniacs/features/sources/models/source_health.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/health_bead.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/source_row_card.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/swipe_row.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_common.dart';
import 'package:manhwamaniacs/skins/skins.dart';

GlassSourceHealth healthOf(SourceSummary s) => switch (s.health?.status) {
      SourceHealthStatus.ok => GlassSourceHealth.ok,
      SourceHealthStatus.failing => GlassSourceHealth.failing,
      SourceHealthStatus.dead => GlassSourceHealth.dead,
      _ => GlassSourceHealth.unknown,
    };

/// One source row: the row card with its swipe actions (Pin / Unpin), a menu on the trailing long press and a `p` key to pin.
class GlassSourceListRow extends ConsumerWidget {
  const GlassSourceListRow({
    super.key,
    required this.source,
    required this.pinned,
    required this.pinEnabled,
    required this.onPin,
    this.offline = false,
    this.trailingHandle,
    this.extraMenu = const [],
  });
  final SourceSummary source;
  final bool pinned;
  final bool pinEnabled;
  final VoidCallback onPin;
  final bool offline;
  final Widget? trailingHandle;
  final List<GlassMenuEntry> extraMenu;

  static const _reason = 'Pinning is unavailable until your pins load';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = pinEnabled && !offline;
    void open() => unawaited(ref.read(skinRouterProvider).push<void>(Routes.source(source.id)));
    final card = GlassSourceRowCard(
      sourceId: source.id,
      name: source.name,
      description: offline ? 'Needs a connection' : source.description,
      language: (source.language ?? 'en').toUpperCase(),
      health: healthOf(source),
      demoted: source.health?.demoted ?? false,
      mature: source.mature,
      pinned: pinned,
      logo: source.iconUrl == null || source.iconUrl!.isEmpty ? null : HomeCoverImage(url: source.iconUrl, width: 44),
      onTap: open,
      onPin: enabled ? onPin : null,
      enabled: enabled,
      disabledReason: offline ? 'Needs a connection' : _reason,
    );
    return Focus(
      onKeyEvent: (n, e) {
        if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.keyP && enabled) {
          onPin();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GlassSwipeRow(
        name: source.name,
        trailing: enabled
            ? [SwipeAction(id: 'pin', label: pinned ? 'Unpin' : 'Pin', glyph: GlassGlyph.pushPin.regular, tone: SwipeTone.iris, run: () async => onPin())]
            : const [],
        child: Row(children: [Expanded(child: card), if (trailingHandle != null) trailingHandle!]),
      ),
    );
  }
}
