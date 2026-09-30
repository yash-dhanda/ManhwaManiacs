import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_badge.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_icon_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_tooltip.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// Bar height without the inset (cinematic 8.15.3).
const double kNovelBarHeight = 52;

/// The solid stock bar of the novel reader: the ground, a 1 px rule at the muted ink's 30 % on the
/// inside edge.
class NovelBar extends StatelessWidget {
  const NovelBar({super.key, required this.stock, required this.top, required this.child});
  final CineStockColors stock;

  /// True for the top bar (rule below), false for the bottom bar (rule above).
  final bool top;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final inset = top ? MediaQuery.viewPaddingOf(context).top : MediaQuery.viewPaddingOf(context).bottom;
    final rule = Border(
      bottom: top ? BorderSide(color: stock.muted.withValues(alpha: 0.3)) : BorderSide.none,
      top: top ? BorderSide.none : BorderSide(color: stock.muted.withValues(alpha: 0.3)),
    );
    return Container(
      height: kNovelBarHeight + inset,
      padding: EdgeInsets.only(top: top ? inset : 0, bottom: top ? 0 : inset, left: MediaQuery.viewPaddingOf(context).left, right: MediaQuery.viewPaddingOf(context).right),
      decoration: BoxDecoration(color: stock.page, border: rule),
      child: child,
    );
  }
}

/// The top bar (cinematic 8.15.3): back, the running title, the offline mark and the saved-copy
/// badge, then [actions] as an ordered list: contents, bookmark, type, and on tablets margins.
/// `mobile/15` inserts voices after bookmark and `mobile/23` the soundscape indicator.
class NovelTopBar extends StatelessWidget {
  const NovelTopBar({
    super.key,
    required this.stock,
    required this.runningTitle,
    required this.onBack,
    required this.actions,
    this.offline = false,
    this.savedCopyAgo,
  });

  final CineStockColors stock;

  /// `{SERIES} · CHAPTER 12`.
  final String runningTitle;
  final VoidCallback onBack;
  final List<Widget> actions;

  /// Reading a saved copy: the `wifi-slash` mark.
  final bool offline;

  /// `cache.stale`: `3 H` for the `SAVED COPY · 3 H` micro badge; null when the text is fresh.
  final String? savedCopyAgo;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return NovelBar(
      stock: stock,
      top: true,
      child: Row(
        children: [
          CineIconButton(label: 'Back to the book', role: CineIconRole.back, onPressed: onBack),
          Expanded(
            flex: 2,
            child: CineRoleText(runningTitle, c.typeNav, color: stock.muted, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          if (offline)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: _OfflineMark(),
            ),
          if (savedCopyAgo != null)
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: CineTooltip(message: 'The source is down; this is the last copy we saved.', child: CineBadge.stale(savedCopyAgo!)),
                ),
              ),
            ),
          ...actions,
        ],
      ),
    );
  }
}

class _OfflineMark extends StatelessWidget {
  const _OfflineMark();

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Reading a saved copy, offline',
        child: ExcludeSemantics(child: Icon(_offlineIcon, size: 20, color: context.cine.colorInk60)),
      );
}

final IconData _offlineIcon = cineIcons[CineIconRole.offline]![CineIconWeight.regular]!;
