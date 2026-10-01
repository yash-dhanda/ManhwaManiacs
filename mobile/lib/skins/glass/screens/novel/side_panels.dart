import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/tab_pager.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/papers.dart';

/// The desktop frame's panels (D2): left 300 (Contents), right 360 (Aa · Voices · Listen); inset 12, radius 26, each gap 24.
const double kNovelLeftPanel = 300, kNovelRightPanel = 360, kNovelPanelInset = 12, kNovelPanelRadius = 26, kNovelPanelGap = 24;

/// `materialThick`'s alpha for the panel fill (D2).
const double kNovelPanelAlpha = 0.84;

/// The panel fill: `oklabMix(paper.bg, #131317, 0.30)` at `materialThick` alpha 0.84. Content-layer surfaces, never Liquid Glass and no
/// `BackdropFilter`: a panel never covers text and the paper beneath it is flat.
Color novelPanelFill(Color paperBg) => oklabMix(paperBg, const Color(0xFF131317), 0.30).withValues(alpha: kNovelPanelAlpha);

/// The desktop frame (glass 8.0.1): shortest side >= 600 and width >= 1024.
bool novelDesktopFrame(Size s) => s.shortestSide >= 600 && s.width >= 1024;

/// The column's width in ch with panels open (D3): `min(measure, viewport - sum(open panel + 24) - 40)` in px, as ch of [zeroAdvance].
double fitMeasureCh({required double measure, required double viewport, required double zeroAdvance, required bool left, required bool right}) {
  final room = viewport - (left ? kNovelLeftPanel + kNovelPanelGap : 0) - (right ? kNovelRightPanel + kNovelPanelGap : 0) - 40;
  return zeroAdvance <= 0 ? measure : math.min(measure, room / zeroAdvance);
}

/// Opening the second panel closes the first when the column would fall below 48 ch (D3).
bool panelsFitTogether({required double viewport, required double zeroAdvance}) =>
    fitMeasureCh(measure: 1e9, viewport: viewport, zeroAdvance: zeroAdvance, left: true, right: true) >= 48;

/// One right-panel tab, from an ordered list (`mobile/37` appends Voices and Listen).
class NovelPanelTab {
  const NovelPanelTab(this.label, this.builder);
  final String label;
  final WidgetBuilder builder;
}

/// A panel: a non-modal region with its label, the paper-mixed fill, its own focus scope.
class NovelSidePanel extends StatelessWidget {
  const NovelSidePanel({super.key, required this.label, required this.paperBg, required this.focus, required this.child});
  final String label;
  final Color paperBg;
  final FocusScopeNode focus;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        explicitChildNodes: true,
        label: label,
        child: FocusScope(
          node: focus,
          child: DecoratedBox(
            decoration: BoxDecoration(color: novelPanelFill(paperBg), borderRadius: BorderRadius.circular(kNovelPanelRadius)),
            child: ClipRRect(borderRadius: BorderRadius.circular(kNovelPanelRadius), child: child),
          ),
        ),
      );
}

/// The right panel's tab strip (`mobile/27`'s in-page tabs) over its panels.
class NovelRightPanelTabs extends StatelessWidget {
  const NovelRightPanelTabs({super.key, required this.tabs, this.controller});
  final List<NovelPanelTab> tabs;

  /// Lets the reader open a tab (the listen button opens Listen, `v` opens Voices).
  final GlassTabPagerController? controller;

  @override
  Widget build(BuildContext context) {
    if (tabs.length < 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 4), child: Semantics(header: true, child: Text(tabs.first.label, style: roleStyle(context, gt.typeHeadline, onGlass: true, maxScale: 1.3).copyWith(color: gt.colorOnGlass)))),
          Expanded(child: Builder(builder: tabs.first.builder)),
        ],
      );
    }
    return GlassTabPager(controller: controller, tabs: [for (final t in tabs) GlassTabSpec(t.label)], panels: [for (final t in tabs) Builder(builder: t.builder)]);
  }
}
