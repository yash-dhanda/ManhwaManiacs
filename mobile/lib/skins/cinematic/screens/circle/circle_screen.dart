import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/collections/providers/shared_collections_provider.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/circle_poll_scope.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_banner_strip.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_contents_tabs.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_notice.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_pull_to_reprint.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/layout/cine_grid.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/circle/activity_list.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/circle/circle_states.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/circle/circle_tabs.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/circle/letters_list.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/circle/readers_strip.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/circle/shelves_tab.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/hub/hub_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/cine_scaffold.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The Circle (ScreenId `circle`, `/circle`; cinematic 9.3.2): the magazine's letters page. The
/// readers strip, then the activity, letters and shared shelves as a swipeable contents-tab pager.
/// `?tab=all|reading|reactions|letters|shelves` opens a tab.
class CircleScreen extends ConsumerStatefulWidget {
  const CircleScreen({super.key, this.initialTab = CircleTab.all});
  final CircleTab initialTab;

  @override
  ConsumerState<CircleScreen> createState() => _CircleScreenState();
}

class _CircleScreenState extends ConsumerState<CircleScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: CircleTab.values.length, vsync: this, initialIndex: widget.initialTab.index)..addListener(_onTab);
  final _mastheadFocus = FocusNode(debugLabel: 'circle-masthead');
  final _asideFirstLetter = FocusNode(debugLabel: 'circle-aside-letter');
  final Map<String?, List<FocusNode>> _nodes = {null: [], 'reading': [], 'reaction': []};

  CircleTab get _tab => CircleTab.values[_tabs.index];

  void _onTab() {
    if (!_tabs.indexIsChanging) setState(() {});
  }

  @override
  void dispose() {
    _tabs
      ..removeListener(_onTab)
      ..dispose();
    _mastheadFocus.dispose();
    _asideFirstLetter.dispose();
    for (final l in _nodes.values) {
      for (final n in l) {
        n.dispose();
      }
    }
    super.dispose();
  }

  void _goto(CircleTab t) => _tabs.animateTo(t.index, duration: CineMotion.reduced(context) ? CineDur.reduced : CineDur.column, curve: CineCurves.settle);

  List<FocusNode> get _list => _nodes[feedKindOf(_tab)] ?? const [];

  void _step(int d) {
    final n = _list;
    if (n.isEmpty) return;
    var cur = -1;
    for (var i = 0; i < n.length; i++) {
      if (n[i].hasFocus) cur = i;
    }
    final to = (cur < 0 ? (d > 0 ? 0 : n.length - 1) : cur + d).clamp(0, n.length - 1);
    n[to].requestFocus();
    final ctx = n[to].context;
    if (ctx != null) unawaited(Scrollable.ensureVisible(ctx, duration: hubScroll(context), alignment: 0.3));
  }

  void _lettersKey() {
    if (MediaQuery.sizeOf(context).width >= 900) {
      _goto(CircleTab.all);
      _asideFirstLetter.requestFocus();
    } else {
      _goto(CircleTab.letters);
    }
  }

  Future<void> _reprint() async {
    ref
      ..invalidate(circleMembersProvider)
      ..invalidate(lettersProvider)
      ..invalidate(sharedCollectionsProvider)
      ..invalidate(circleFeedProvider(feedKindOf(_tab)));
    try {
      await ref.read(circleMembersProvider.future);
    } catch (_) {}
  }

  Future<void> _shareOn(int profileId) async {
    final s = ref.read(sharingProvider(profileId)).valueOrNull;
    if (s == null) return;
    final ok = await ref.read(sharingProvider(profileId).notifier).patch(s.copyWith(activity: true));
    if (!mounted) return;
    final toasts = ref.read(cineToastsProvider.notifier);
    if (ok) {
      toasts.success(CircleCopy.sharingOn);
      ref
        ..invalidate(circleMembersProvider)
        ..invalidate(circleFeedProvider);
    } else {
      toasts.error("Couldn't save. Try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    final grid = CineGrid.of(context);
    final pad = grid.left;
    final membersAsync = ref.watch(circleMembersProvider);
    final members = membersAsync.valueOrNull;
    final letters = ref.watch(lettersProvider).valueOrNull ?? const <Letter>[];
    final newLetters = ref.watch(newLetterCountProvider);
    final profileId = ref.watch(activeProfileProvider)?.id;
    final sharing = profileId == null ? null : ref.watch(sharingProvider(profileId)).valueOrNull;
    final online = ref.watch(deviceOnlineProvider).valueOrNull ?? true;
    final offline = !online || (membersAsync.hasError && membersAsync.error is NetworkError);
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final top = MediaQuery.paddingOf(context).top;
    final dup = duplicateMemberNames(members ?? const []);
    final quiet = members != null && members.isEmpty;
    final viewerShares = sharing?.activity ?? false;

    Widget header() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: EdgeInsets.fromLTRB(pad, t.space4, pad, 0),
            child: Row(children: [
              Flexible(child: CineRoleText('No. 11 — THE CIRCLE', t.typeKicker, color: t.colorInk45, maxLines: 2)),
              if (offline) ...[
                SizedBox(width: t.space2),
                Container(
                  key: const Key('circle-offline-edition'),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(border: Border.all(color: t.colorRule2)),
                  child: CineRoleText('OFFLINE EDITION', t.typeMicro, color: t.colorInk60),
                ),
              ],
            ],),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(pad, t.space2, pad, 0),
            child: SetHeading('The Circle', id: 'masthead-circle', style: CineText.style(context, t.typeMasthead).copyWith(color: t.colorInk100), cap: t.typeMasthead.cap, level: 1, trigger: SetTrigger.mount, focusNode: _mastheadFocus),
          ),
          Padding(padding: EdgeInsets.fromLTRB(pad, t.space2, pad, 0), child: CineRoleText('What the other readers on this server are reading.', t.typeDeck, color: t.colorInk60)),
          Padding(padding: EdgeInsets.fromLTRB(pad, t.space4, pad, t.space4), child: const CineRuleDraw(kind: CineRuleKind.heavy, delay: Duration(milliseconds: 1200))),
          if (members != null && members.isNotEmpty) ReadersStrip(members: members),
          if (members != null && members.isNotEmpty && sharing != null && !sharing.activity && profileId != null)
            Padding(
              padding: EdgeInsets.only(top: t.space3),
              child: CineBannerStrip(line: CircleCopy.privateLine, actions: [CineBannerAction(CircleCopy.share, () => unawaited(_shareOn(profileId)))]),
            ),
          if (quiet && viewerShares)
            Padding(padding: EdgeInsets.fromLTRB(pad, t.space3, pad, 0), child: CineRoleText(CircleCopy.onlyMe, t.typeSubhead, color: t.colorInk60)),
        ],);

    Widget body() {
      if (members == null) {
        if (membersAsync.hasError) return SingleChildScrollView(child: Column(children: [header(), CircleErrorNotice(error: membersAsync.error!, onRetry: () => ref.invalidate(circleMembersProvider))]));
        return SingleChildScrollView(child: Column(children: [header(), const CircleGalley()]));
      }
      if (quiet && !viewerShares) {
        return SingleChildScrollView(
          child: Column(children: [
            header(),
            CircleNoticeBox(
              notice: CineNotice(
                key: const Key('circle-quiet'),
                tone: CineNoticeTone.empty,
                kicker: CircleCopy.quietKicker,
                headline: CircleCopy.quietHeadline,
                primary: CineNoticeAction(CircleCopy.sharingSettings, () => unawaited(context.push(Routes.settings(SettingsSection.circle)))),
              ),
            ),
          ],),
        );
      }
      if (quiet) return SingleChildScrollView(child: header());
      return NestedScrollView(
        headerSliverBuilder: (context, inner) => [
          SliverOverlapAbsorber(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            sliver: SliverMainAxisGroup(slivers: [
              SliverToBoxAdapter(child: header()),
              cineStickyContentsTabs(controller: _tabs, tabs: circleCineTabs(newLetters)),
            ],),
          ),
        ],
        body: Builder(builder: (context) {
          final handle = NestedScrollView.sliverOverlapAbsorberHandleFor(context);
          final inject = [SliverOverlapInjector(handle: handle)];
          Widget activity(CircleTab tab, {String? empty}) {
            final kind = feedKindOf(tab);
            return CinePullToReprint(
              onRefresh: _reprint,
              child: ActivityList(
                kind: kind,
                scrollController: null,
                focusNodes: _nodes[kind]!,
                emptyText: empty,
                leading: inject,
                duplicateNames: dup,
              ),
            );
          }

          final lettersPanel = CinePullToReprint(onRefresh: _reprint, child: LettersList(letters: letters, duplicateNames: dup, leadingSlivers: inject));
          Widget allPanel() {
            if (!wide) return activity(CircleTab.all);
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 5, child: activity(CircleTab.all)),
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(right: grid.right, top: 49 + t.space4, bottom: 96),
                  child: LettersList(letters: letters, duplicateNames: dup, scrollable: false, focusFirst: _asideFirstLetter),
                ),
              ),
            ],);
          }

          return CineTabPanels(controller: _tabs, children: [
            allPanel(),
            activity(CircleTab.reading, empty: CircleCopy.emptyReading),
            activity(CircleTab.reactions, empty: CircleCopy.emptyReactions),
            lettersPanel,
            CinePullToReprint(onRefresh: _reprint, child: ShelvesTab(leadingSlivers: inject)),
          ],);
        },),
      );
    }

    ShortcutEntry key(LogicalKeyboardKey k, String d, VoidCallback f, {bool single = true}) => hubKey('Circle', k, d, f, single: single);
    return CineScaffold(
      runningTitle: 'No. 11 · CIRCLE',
      firstRunNote: false,
      mastheadFocusNode: _mastheadFocus,
      body: CirclePollScope(
        child: RegisteredShortcuts(
          group: 'Circle',
          entries: [
            key(LogicalKeyboardKey.keyJ, 'Next dispatch', () => _step(1)),
            key(LogicalKeyboardKey.keyK, 'Previous dispatch', () => _step(-1)),
            for (var i = 0; i < CircleTab.values.length; i++)
              key([LogicalKeyboardKey.digit1, LogicalKeyboardKey.digit2, LogicalKeyboardKey.digit3, LogicalKeyboardKey.digit4, LogicalKeyboardKey.digit5][i], 'Tab ${CircleTab.values[i].name}', () => _goto(CircleTab.values[i])),
            key(LogicalKeyboardKey.keyL, 'Letters', _lettersKey),
            key(LogicalKeyboardKey.keyR, 'Reprint', () => unawaited(_reprint())),
          ],
          child: Padding(padding: EdgeInsets.only(top: top), child: body()),
        ),
      ),
    );
  }
}
