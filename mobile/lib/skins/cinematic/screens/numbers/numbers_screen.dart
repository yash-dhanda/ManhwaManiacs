import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart';
import 'package:manhwamaniacs/features/library/providers/numbers_providers.dart';
import 'package:manhwamaniacs/features/library/utils/numbers_rules.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/cine_icon.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/buttons.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/cine_text.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/contents_tabs.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/keys.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/letter_reveal.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/rules.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/milestone_card_host.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/numbers/chart_math.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/numbers/numbers_panel.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/numbers/sections.dart';
import 'package:manhwamaniacs/skins/cinematic/share/press_run.dart';
import 'package:manhwamaniacs/skins/cinematic/share/share_card_model.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The Numbers (ScreenId `numbers`, `/library/statistics`; cinematic 9.2.1): the
/// magazine's back-of-book numbers, the ranges as a swipeable contents-tab pager.
class NumbersScreen extends ConsumerStatefulWidget {
  const NumbersScreen({super.key});

  @override
  ConsumerState<NumbersScreen> createState() => _NumbersScreenState();
}

class _NumbersScreenState extends ConsumerState<NumbersScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final ValueNotifier<int?> _selection = ValueNotifier<int?>(null);
  final FocusNode _focus = FocusNode(debugLabel: 'numbers');
  bool _signatureClaimed = false;
  int _dailyLength = 0;
  int _lastIndex = 0;

  int get _range => kNumbersRanges[_tabs.index];

  @override
  void initState() {
    super.initState();
    _lastIndex = kNumbersRanges.indexOf(ref.read(statsRangeProvider)).clamp(0, 3);
    _tabs = TabController(length: 4, vsync: this, initialIndex: _lastIndex)..addListener(_onTab);
  }

  void _onTab() {
    if (_tabs.indexIsChanging || _tabs.index == _lastIndex) return;
    _lastIndex = _tabs.index;
    _selection.value = null;
    ref.read(statsRangeProvider.notifier).set(kNumbersRanges[_tabs.index]);
    setState(() {});
  }

  @override
  void dispose() {
    _tabs.dispose();
    _selection.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool _claimSignature() {
    if (_signatureClaimed) return false;
    _signatureClaimed = true;
    return true;
  }

  void _report(int days, LibraryStatistics stats, {required bool offline}) {
    if (days == _range) _dailyLength = stats.daily.length;
  }

  void _move(int delta) {
    if (_dailyLength == 0) return;
    final next = ((_selection.value ?? _dailyLength - 1) + delta).clamp(0, _dailyLength - 1);
    _selection.value = next;
    final stats = ref.read(numbersStatisticsProvider(_range)).valueOrNull?.data;
    if (stats != null && next < stats.daily.length) {
      SemanticsService.announce(dayReadout(stats.daily[next]), TextDirection.ltr);
    }
  }

  void _openAnnual([int? year]) => context.push(Routes.annual(year ?? DateTime.now().year));

  void _share() {
    final stats = ref.read(numbersStatisticsProvider(_range)).valueOrNull;
    if (stats == null || stats.offline || !stats.data.hasReadingHistory) return;
    showPressRun(context, ShareInput.range(stats.data, _range, ref.read(activeProfileProvider)?.name ?? ''));
  }

  void _reprint() {
    ref.invalidate(numbersStatisticsProvider(_range));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    final wide = MediaQuery.sizeOf(context).width >= 600;
    final pad = wide ? 40.0 : 20.0;
    final current = ref.watch(numbersStatisticsProvider(_range)).valueOrNull;
    final annual = ref.watch(annualIndexProvider).valueOrNull;
    final now = ref.watch(numbersNowProvider)();
    final showAnnual = annualAvailable(now, annual);
    final canShare = current != null && !current.offline && current.data.hasReadingHistory;
    final years = annual == null || annual.availableYears.isEmpty ? <int>[now.year] : annual.availableYears;

    return Scaffold(
      backgroundColor: CineColors.paper0,
      body: MilestoneCardHost(
        streak: current?.data.streak,
        shareable: current?.data.shareable,
        child: KeyMap(
          focusNode: _focus,
          actions: {
            LogicalKeyboardKey.digit1: () => _tabs.animateTo(0, duration: CineDur.column, curve: CineCurves.settle),
            LogicalKeyboardKey.digit2: () => _tabs.animateTo(1, duration: CineDur.column, curve: CineCurves.settle),
            LogicalKeyboardKey.digit3: () => _tabs.animateTo(2, duration: CineDur.column, curve: CineCurves.settle),
            LogicalKeyboardKey.digit4: () => _tabs.animateTo(3, duration: CineDur.column, curve: CineCurves.settle),
            LogicalKeyboardKey.arrowLeft: () => _move(-1),
            LogicalKeyboardKey.arrowRight: () => _move(1),
            if (_range >= 365) LogicalKeyboardKey.arrowUp: () => _move(-7),
            if (_range >= 365) LogicalKeyboardKey.arrowDown: () => _move(7),
            LogicalKeyboardKey.keyA: () {
              if (showAnnual) _openAnnual();
            },
            LogicalKeyboardKey.keyS: _share,
            LogicalKeyboardKey.keyR: _reprint,
          },
          child: SafeArea(
            bottom: false,
            child: NestedScrollView(
              headerSliverBuilder: (context, inner) => [
                SliverOverlapAbsorber(
                  handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                  sliver: SliverMainAxisGroup(slivers: [
                    SliverToBoxAdapter(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _RunningHead(pad: pad),
                        Padding(
                          padding: EdgeInsets.fromLTRB(pad, 8, pad, 0),
                          child: Row(children: [
                            CineText('No. 10 — THE NUMBERS', t.typeKicker, color: CineColors.ink60),
                            if (current?.offline ?? false) ...[
                              const SizedBox(width: 8),
                              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(border: Border.all(color: CineColors.rule2)), child: CineText('OFFLINE EDITION', t.typeMicro, color: CineColors.ink60)),
                            ],
                            const Spacer(),
                            if (canShare) CineButton('Share', small: true, kind: CineButtonKind.secondary, icon: CineIconRole.share, onPressed: _share),
                          ],),
                        ),
                        Padding(padding: EdgeInsets.fromLTRB(pad, 4, pad, 0), child: SetHeading('The Numbers', role: t.typeMasthead, level: 1)),
                        Padding(padding: EdgeInsets.fromLTRB(pad, 4, pad, 0), child: CineText("What you've actually read on this profile.", t.typeDeck, color: CineColors.ink60)),
                        Padding(padding: EdgeInsets.fromLTRB(pad, 12, pad, 16), child: const DrawnRule(delay: Duration(milliseconds: 600))),
                        if (showAnnual) AnnualBanner(year: now.year, december: now.month == 12, years: years, onOpen: _openAnnual),
                      ],),
                    ),
                    SliverPersistentHeader(pinned: true, delegate: _TabsDelegate(height: minHit(context) + 2, tabs: _tabs)),
                  ],),
                ),
              ],
              body: Builder(
                builder: (context) {
                  final handle = NestedScrollView.sliverOverlapAbsorberHandleFor(context);
                  return TabBarView(controller: _tabs, children: [
                    for (final d in kNumbersRanges) RangePanel(key: ValueKey(d), days: d, selection: _selection, claimSignature: _claimSignature, report: _report, overlap: handle),
                  ],);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RunningHead extends StatelessWidget {
  const _RunningHead({required this.pad});
  final double pad;

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    return Padding(
      padding: EdgeInsets.only(left: pad - 12, right: pad),
      child: Row(children: [
        CineTap(
          label: 'Back',
          onTap: () => context.canPop() ? context.pop() : context.go(Routes.indexHub()),
          child: const CineIcon(CineIconRole.back, color: CineColors.ink100),
        ),
        const SizedBox(width: 4),
        CineText('No. 10 · THE NUMBERS', t.typeFolio, color: CineColors.ink45),
      ],),
    );
  }
}

class _TabsDelegate extends SliverPersistentHeaderDelegate {
  _TabsDelegate({required this.height, required this.tabs});
  final double height;
  final TabController tabs;

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => ColoredBox(
        color: CineColors.paper0,
        child: ContentsTabs(
          labels: [for (final d in kNumbersRanges) kNumbersRangeLabels[d]!],
          index: tabs.index,
          animation: tabs.animation!,
          onTap: (i) => tabs.animateTo(i, duration: CineDur.column, curve: CineCurves.settle),
        ),
      );

  @override
  bool shouldRebuild(_TabsDelegate old) => old.tabs != tabs || old.height != height;
}
