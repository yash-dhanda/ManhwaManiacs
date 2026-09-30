import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/settings/providers/server_capabilities_provider.dart';
import 'package:manhwamaniacs/features/settings/utils/settings_search.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_masthead.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_pull_to_reprint.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_search_field.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/pages/licenses_page.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/section_pane.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_contents.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_keys.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_registry.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_search_page.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/cine_scaffold.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// Footer under the table of contents (one pane) or the section (two panes). The restart sentence
/// only exists once a second edition does.
String settingsFooter({bool glassAvailable = Flags.glassAvailable}) =>
    'Settings save as you change them.${glassAvailable ? ' Changing the edition restarts the app.' : ''}';

/// Settings (`/settings`, `/settings/:section`, cinematic 8.30): a credits-list contents and a
/// pushed page per section below 900 dp; two panes from 900 dp.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, this.slug, this.jumpRow, this.licenses = false});

  /// The section or pushed page; null is the table of contents.
  final String? slug;

  /// A row the search picked: the pane jumps to it once built.
  final String? jumpRow;
  final bool licenses;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final SettingsJump _jump = SettingsJump();
  final FocusNode _head = FocusNode(debugLabel: 'settings-heading');
  final FocusNode _searchFocus = FocusNode(debugLabel: 'settings-search');
  final TextEditingController _query = TextEditingController();
  final Map<String, FocusNode> _tocNodes = {};
  String? _slug;
  bool _licenses = false;
  int _sel = -1;

  @override
  void initState() {
    super.initState();
    _slug = widget.slug;
    _licenses = widget.licenses;
    if (widget.jumpRow != null) _afterFrame(() => _jump.run(context, widget.jumpRow!));
  }

  @override
  void didUpdateWidget(SettingsScreen old) {
    super.didUpdateWidget(old);
    if (old.slug != widget.slug || old.licenses != widget.licenses) {
      _slug = widget.slug;
      _licenses = widget.licenses;
    }
  }

  @override
  void dispose() {
    _jump.dispose();
    _head.dispose();
    _searchFocus.dispose();
    _query.dispose();
    for (final n in _tocNodes.values) {
      n.dispose();
    }
    super.dispose();
  }

  void _afterFrame(VoidCallback f) => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) f();
      });

  SettingsEnv _env(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final caps = ref.watch(serverCapabilitiesProvider).valueOrNull ?? const ServerCapabilities();
    return SettingsEnv(
      admin: auth is AuthAuthenticated && auth.user.isAdmin,
      novels: ref.watch(contentModeScopeProvider).novelsEnabled,
      clientDownloads: caps.clientDownloads,
      tablet: MediaQuery.sizeOf(context).shortestSide >= 600,
      android: Theme.of(context).platform == TargetPlatform.android,
    );
  }

  FocusNode _nodeFor(String slug) => _tocNodes.putIfAbsent(slug, () => FocusNode(debugLabel: 'settings-toc-$slug'));

  /// Opens [slug], jumping to [row] when given.
  void _open(String slug, {String? row, required bool two}) {
    if (two) {
      setState(() {
        _slug = slug;
        _licenses = false;
        _query.clear();
        _sel = -1;
      });
      if (row != null) _afterFrame(() => _jump.run(context, row));
    } else {
      final section = SettingsSection.values.where((s) => s.slug == slug).firstOrNull;
      if (section == null) return;
      unawaited(context.push<void>(Routes.settings(section), extra: <String, String>{if (row != null) 'jump': row}));
    }
  }

  Future<void> _openSearchPage(SettingsEnv env) async {
    final picked = await openSettingsSearch(context, searchRows(env), visibleSettingsSections(env));
    if (picked == null || !mounted) return;
    _open(picked.section, row: picked.id, two: false);
  }

  void _step(List<SettingsSectionDef> sections, int dir) {
    final slugs = [for (final s in sections) s.slug];
    final focused = slugs.indexWhere((s) => _tocNodes[s]?.hasFocus ?? false);
    final current = focused >= 0 ? focused : slugs.indexOf(parentSectionOf(_slug ?? slugs.first));
    final next = ((current < 0 ? 0 : current) + dir).clamp(0, slugs.length - 1);
    _nodeFor(slugs[next]).requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final env = _env(context);
    final sections = visibleSettingsSections(env);
    final width = MediaQuery.sizeOf(context).width;
    final two = width >= 900;
    final side = width >= 600 ? c.space8 : c.space4;
    final footer = Padding(
      padding: EdgeInsets.only(top: c.space6),
      child: CineRoleText(settingsFooter(), c.typeCaption, color: c.colorInk60),
    );

    final Widget content;
    if (two) {
      content = _twoPane(context, env, sections, side, footer);
    } else if (widget.slug == null) {
      content = _contents(context, env, sections, side, footer);
    } else {
      final slug = widget.slug!;
      final scroll = SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(side, CineScaffoldScope.topExtentOf(context) + c.space6, side, c.space12),
        child: SectionPane(
          slug: widget.slug!,
          env: env,
          twoPane: false,
          headingFocus: _head,
          bodyOverride: _licenses && widget.slug == 'about' ? const LicensesPage() : null,
          overrideTitle: _licenses && widget.slug == 'about' ? 'Licenses' : null,
        ),
      );
      content = settingsPageOf(slug) == null ? scroll : CinePullToReprint(onRefresh: () => refreshSettingsPage(ref, slug), child: scroll);
    }

    return SettingsKeys(
      onSearch: () => two ? _searchFocus.requestFocus() : unawaited(_openSearchPage(env)),
      onNext: () => _step(sections, 1),
      onPrevious: () => _step(sections, -1),
      onOpen: () {
        final slug = sections.where((s) => _tocNodes[s.slug]?.hasFocus ?? false).firstOrNull?.slug;
        if (slug != null) _open(slug, two: two);
      },
      onEscape: () {
        if (_query.text.isNotEmpty) {
          setState(() {
            _query.clear();
            _sel = -1;
          });
        }
        _nodeFor(parentSectionOf(_slug ?? sections.first.slug)).requestFocus();
      },
      child: SettingsJumpScope(
        jump: _jump,
        child: CineScaffold(
          tabletLayout: true,
          firstRunNote: false,
          mastheadFocusNode: _head,
          back: !two && widget.slug != null ? const CineBack() : null,
          trailing: !two && widget.slug == null
              ? [CineHeadAction(role: CineIconRole.search, label: 'Search settings', onPressed: () => unawaited(_openSearchPage(env)))]
              : const [],
          body: content,
        ),
      ),
    );
  }

  Widget _contents(BuildContext context, SettingsEnv env, List<SettingsSectionDef> sections, double side, Widget footer) {
    final c = context.cine;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(side, CineScaffoldScope.topExtentOf(context) + c.space6, side, c.space12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        CineMasthead(kicker: 'No. 00 — THE HOUSE', title: 'Settings', focusNode: _head, id: 'settings'),
        SettingsContentsList(sections: sections, onOpen: (slug) => _open(slug, two: false)),
        footer,
      ],),
    );
  }

  Widget _twoPane(BuildContext context, SettingsEnv env, List<SettingsSectionDef> sections, double side, Widget footer) {
    final c = context.cine;
    final width = MediaQuery.sizeOf(context).width - 2 * side;
    final gutter = c.space6;
    final col = (width - 7 * gutter) / 8;
    final left = 3 * col + 2 * gutter;
    final current = widget.licenses && _licenses ? 'about' : (_slug ?? sections.first.slug);
    final page = settingsPageOf(current);
    final lit = page?.parent ?? current;
    final rows = searchRows(env);
    final results = matchSettings(_query.text, rows);
    final top = CineScaffoldScope.topExtentOf(context) + c.space6;

    final toc = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: c.space3),
          child: CineSearchField(
            semanticLabel: 'Search settings',
            placeholder: 'Search settings',
            variant: CineSearchVariant.compact,
            controller: _query,
            focusNode: _searchFocus,
            onChanged: (_) => setState(() => _sel = -1),
            onArrowDown: () => setState(() => _sel = results.isEmpty ? -1 : (_sel + 1).clamp(0, results.length - 1)),
            onArrowUp: () => setState(() => _sel = results.isEmpty ? -1 : (_sel - 1).clamp(0, results.length - 1)),
            onSubmitNow: (_) {
              if (results.isEmpty) return;
              final r = results[_sel < 0 ? 0 : _sel];
              _open(r.section, row: r.id, two: true);
            },
          ),
        ),
        if (_query.text.trim().isNotEmpty)
          SettingsSearchResults(
            query: _query.text,
            results: results,
            sections: sections,
            selected: _sel,
            onPick: (r) => _open(r.section, row: r.id, two: true),
          )
        else
          for (final s in sections)
            SettingsPaneTocRow(
              key: Key('settings-toc-${s.slug}'),
              folio: folioOf(sections, s.slug),
              title: s.title,
              current: s.slug == lit,
              focusNode: _nodeFor(s.slug),
              onTap: () => _open(s.slug, two: true),
            ),
      ],
    );

    final parentLink = page == null
        ? const SizedBox.shrink()
        : Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(bottom: c.space3),
              child: quietAction('← ${settingsSectionOf(page.parent)?.title ?? 'Settings'}', () => _open(page.parent, two: true)),
            ),
          );

    return Padding(
      padding: EdgeInsets.fromLTRB(side, top, side, 0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: left, child: SingleChildScrollView(padding: EdgeInsets.only(bottom: c.space12), child: toc)),
        SizedBox(width: gutter),
        Expanded(
          child: _reprint(current, SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(bottom: c.space12),
            child: Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  parentLink,
                  SectionPane(
                    key: ValueKey('pane-$current-$_licenses'),
                    slug: current,
                    env: env,
                    twoPane: true,
                    headingFocus: _head,
                    bodyOverride: _licenses && current == 'about' ? const LicensesPage() : null,
                    overrideTitle: _licenses && current == 'about' ? 'Licenses' : null,
                  ),
                  footer,
                ],),
              ),
            ),
          ),),
        ),
      ],),
    );
  }

  Widget _reprint(String slug, Widget scroll) =>
      settingsPageOf(slug) == null ? scroll : CinePullToReprint(onRefresh: () => refreshSettingsPage(ref, slug), child: scroll);
}
