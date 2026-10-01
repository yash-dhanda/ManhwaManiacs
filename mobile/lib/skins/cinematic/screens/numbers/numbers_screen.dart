import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/features/library/models/library_statistics.dart';
import 'package:manhwamaniacs/features/library/providers/numbers_providers.dart';
import 'package:manhwamaniacs/features/library/utils/numbers_rules.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/milestone_card_host.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_announce.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_contents_tabs.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/layout/cine_grid.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/numbers/chart_math.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/numbers/numbers_panel.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/numbers/sections.dart';
import 'package:manhwamaniacs/skins/cinematic/share/press_run.dart';
import 'package:manhwamaniacs/skins/cinematic/share/share_card_model.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/cine_scaffold.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The Numbers (ScreenId `numbers`, `/library/statistics`; cinematic 9.2.1): the magazine's
/// back-of-book numbers, the ranges as a swipeable contents-tab pager.
class NumbersScreen extends ConsumerStatefulWidget {
  const NumbersScreen({super.key});

  @override
  ConsumerState<NumbersScreen> createState() => _NumbersScreenState();
}

class _NumbersScreenState extends ConsumerState<NumbersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final ValueNotifier<int?> _selection = ValueNotifier<int?>(null);
  final FocusNode _mastheadFocus = FocusNode(debugLabel: 'numbers-masthead');
  bool _signatureClaimed = false;
  int _dailyLength = 0;
  int _lastIndex = 0;

  int get _range => kNumbersRanges[_tabs.index];

  @override
  void initState() {
    super.initState();
    _lastIndex =
        kNumbersRanges.indexOf(ref.read(statsRangeProvider)).clamp(0, 3);
    _tabs = TabController(length: 4, vsync: this, initialIndex: _lastIndex)
      ..addListener(_onTab);
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
    _mastheadFocus.dispose();
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

  void _goto(int i) =>
      _tabs.animateTo(i, duration: CineDur.column, curve: CineCurves.settle);

  void _move(int delta) {
    if (_dailyLength == 0) return;
    final next = ((_selection.value ?? _dailyLength - 1) + delta)
        .clamp(0, _dailyLength - 1);
    _selection.value = next;
    final stats = ref.read(numbersStatisticsProvider(_range)).valueOrNull?.data;
    if (stats != null && next < stats.daily.length) {
      cineAnnounce(context, dayReadout(stats.daily[next]));
    }
  }

  void _openAnnual([int? year]) =>
      context.push(Routes.annual(year ??
          annualDefaultYear(ref.read(clockProvider)(),
              ref.read(annualIndexProvider).valueOrNull,),),);

  void _share() {
    final stats = ref.read(numbersStatisticsProvider(_range)).valueOrNull;
    if (stats == null || stats.offline || !stats.data.hasReadingHistory) return;
    showPressRun(
        context,
        ShareInput.range(
            stats.data, _range, ref.read(activeProfileProvider)?.name ?? '',),);
  }

  void _reprint() => ref.invalidate(numbersStatisticsProvider(_range));

  ShortcutEntry _key(LogicalKeyboardKey k, String description, VoidCallback f,
          {List<String>? keys,}) =>
      ShortcutEntry(
          group: 'The Numbers',
          activator: SingleActivator(k),
          description: description,
          singleKey: true,
          keys: keys,
          onInvoke: f,);

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    final grid = CineGrid.of(context);
    final pad = grid.left;
    final current = ref.watch(numbersStatisticsProvider(_range)).valueOrNull;
    final annual = ref.watch(annualIndexProvider).valueOrNull;
    final now = ref.watch(clockProvider)();
    final showAnnual = annualAvailable(now, annual);
    final canShare =
        current != null && !current.offline && current.data.hasReadingHistory;
    final years = annual == null || annual.availableYears.isEmpty
        ? <int>[now.year]
        : annual.availableYears;

    return CineScaffold(
      runningTitle: 'No. 10 · THE NUMBERS',
      firstRunNote: false,
      mastheadFocusNode: _mastheadFocus,
      body: MilestoneCardHost(
        streak: current?.data.streak,
        shareable: current?.data.shareable,
        child: RegisteredShortcuts(
          group: 'The Numbers',
          entries: [
            _key(LogicalKeyboardKey.digit1, '7 days', () => _goto(0),
                keys: const ['1'],),
            _key(LogicalKeyboardKey.digit2, '30 days', () => _goto(1),
                keys: const ['2'],),
            _key(LogicalKeyboardKey.digit3, '90 days', () => _goto(2),
                keys: const ['3'],),
            _key(LogicalKeyboardKey.digit4, 'Year', () => _goto(3),
                keys: const ['4'],),
            _key(LogicalKeyboardKey.arrowLeft, 'Move the selected day back',
                () => _move(-1),),
            _key(LogicalKeyboardKey.arrowRight, 'Move the selected day forward',
                () => _move(1),),
            if (_range >= 365)
              _key(LogicalKeyboardKey.arrowUp, 'Up a week (year)',
                  () => _move(-7),),
            if (_range >= 365)
              _key(LogicalKeyboardKey.arrowDown, 'Down a week (year)',
                  () => _move(7),),
            _key(LogicalKeyboardKey.keyA, 'Open The Annual', () {
              if (showAnnual) _openAnnual();
            }),
            _key(LogicalKeyboardKey.keyS, 'Share', _share),
            _key(LogicalKeyboardKey.keyR, 'Reprint', _reprint),
          ],
          child: CineBelowHead(
            child: NestedScrollView(
              headerSliverBuilder: (context, inner) => [
                SliverOverlapAbsorber(
                  handle:
                      NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                  sliver: SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  EdgeInsets.fromLTRB(pad, t.space4, pad, 0),
                              child: Row(
                                children: [
                                  Flexible(
                                      child: CineRoleText(
                                          'No. 10 — THE NUMBERS', t.typeKicker,
                                          color: context.cine.colorInk45,
                                          maxLines: 2,),),
                                  if (current?.offline ?? false) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2,),
                                        decoration: BoxDecoration(
                                            border: Border.all(
                                                color: CineColors.rule2,),),
                                        child: CineRoleText(
                                            'OFFLINE EDITION', t.typeMicro,
                                            color: CineColors.ink60,),),
                                  ],
                                  const SizedBox(width: 8),
                                  const Spacer(),
                                  if (canShare)
                                    CineButton(
                                        label: 'Share',
                                        size: CineButtonSize.sm,
                                        variant: CineButtonVariant.secondary,
                                        icon: CineIconRole.share,
                                        onPressed: _share,),
                                ],
                              ),
                            ),
                            Padding(
                              padding:
                                  EdgeInsets.fromLTRB(pad, t.space2, pad, 0),
                              child: SetHeading(
                                'The Numbers',
                                id: 'masthead-numbers',
                                style: CineText.style(context, t.typeMasthead)
                                    .copyWith(color: CineColors.ink100),
                                cap: t.typeMasthead.cap,
                                level: 1,
                                trigger: SetTrigger.mount,
                                focusNode: _mastheadFocus,
                              ),
                            ),
                            Padding(
                                padding:
                                    EdgeInsets.fromLTRB(pad, t.space2, pad, 0),
                                child: CineRoleText(
                                    "What you've actually read on this profile.",
                                    t.typeDeck,
                                    color: CineColors.ink60,),),
                            Padding(
                                padding: EdgeInsets.fromLTRB(
                                    pad, t.space4, pad, t.space4,),
                                child: const CineRuleDraw(
                                    kind: CineRuleKind.heavy,
                                    delay: Duration(milliseconds: 1200),),),
                            if (showAnnual)
                              AnnualBanner(
                                  year: annualDefaultYear(now, annual),
                                  december: now.month == 12,
                                  years: years,
                                  onOpen: _openAnnual,),
                          ],
                        ),
                      ),
                      cineStickyContentsTabs(
                        controller: _tabs,
                        tabs: [
                          for (var i = 0; i < 4; i++)
                            CineTab(
                                folio: '0${i + 1}',
                                label: kNumbersRangeLabels[kNumbersRanges[i]]!,),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              body: Builder(
                builder: (context) {
                  final handle =
                      NestedScrollView.sliverOverlapAbsorberHandleFor(context);
                  return CineTabPanels(
                    controller: _tabs,
                    children: [
                      for (final d in kNumbersRanges)
                        RangePanel(
                            key: ValueKey(d),
                            days: d,
                            selection: _selection,
                            claimSignature: _claimSignature,
                            report: _report,
                            overlap: handle,),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
