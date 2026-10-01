import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/downloads/providers/mature_gate_provider.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/copy/settings_index.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/grouped_list.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/list_row.dart';
import 'package:manhwamaniacs/skins/glass/primitives/search_field.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/about_section.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/account_section.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/admin_section.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/ai_recaps_section.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/appearance_section.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/backup_section.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/circle_privacy_section.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/content_section.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/diagnostics_section.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/feedback_section.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/members_section.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/notifications_section.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/reader_defaults_section.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/security_section.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/server_section.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_index_filter.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_keys.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_row.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_search_overlay.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_sections.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/shortcuts_section.dart';
import 'package:manhwamaniacs/skins/glass/screens/system/not_found.dart';
import 'package:manhwamaniacs/skins/glass/shell/glass_scaffold.dart';
import 'package:manhwamaniacs/skins/glass/shell/global_keys.dart' show registerSearchFocus;
import 'package:manhwamaniacs/skins/glass/type.dart';

/// True once a hardware key event has been seen this session (the Shortcuts section shows only then).
final hardwareKeySeenProvider = StateProvider<bool>((ref) => false);

/// The body a section route renders (`storage` leaves for Downloads -> Storage before any Settings widget builds).
Widget settingsSectionBody(SettingsSection s) {
  if (sectionsBuiltLater.contains(s)) return const SettingsPendingBody();
  return switch (s) {
    SettingsSection.appearance => const AppearanceSection(),
    SettingsSection.readingManga || SettingsSection.readingNovels || SettingsSection.listen || SettingsSection.ambient => const ReaderDefaultsSection(),
    SettingsSection.content => const ContentSection(),
    SettingsSection.circle => const CirclePrivacySection(),
    SettingsSection.ai => const AiRecapsSection(),
    SettingsSection.feedback => const FeedbackSection(),
    SettingsSection.keyboard => const ShortcutsSection(),
    SettingsSection.profile => const AccountSection(),
    SettingsSection.about => const AboutSection(),
    SettingsSection.notifications => const NotificationsSection(),
    SettingsSection.security => const SecuritySection(),
    SettingsSection.members => const MembersSection(),
    SettingsSection.backup => const BackupSection(),
    SettingsSection.server => const ServerSection(),
    SettingsSection.diagnostics => const DiagnosticsSection(),
    SettingsSection.admin => const AdminSection(),
    _ => const SettingsPendingBody(),
  };
}

/// What a section listed in [sectionsBuiltLater] shows until it lands.
class SettingsPendingBody extends StatelessWidget {
  const SettingsPendingBody({super.key});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(24), child: GlassText('This section arrives in the next update.', role: gt.typeBody, color: gt.colorLabel2));
}

String _labelOf(SettingsSection s) {
  if (s == SettingsSection.about) return kAboutSection.label;
  if (s == SettingsSection.profile) return 'Account';
  if (readerGroupSections.contains(s)) return 'Reader';
  if (s == SettingsSection.admin) return 'Administration';
  if (s == SettingsSection.members) return 'Members';
  for (final e in kSettingsSections) {
    if (e.section == s) return e.label;
  }
  return s.slug;
}

/// Settings (glass 8.25): the root (phones: a pushed page; wider frames: the section list at the left and the section at the right)
/// and its sections. [section] is the route's `:section` slug, [row] the index row a search hit scrolls to and flashes.
class GlassSettingsScreen extends ConsumerStatefulWidget {
  const GlassSettingsScreen({super.key, this.section, this.row, this.platform});
  final String? section, row;
  final TargetPlatform? platform;

  @override
  ConsumerState<GlassSettingsScreen> createState() => _GlassSettingsScreenState();
}

class _GlassSettingsScreenState extends ConsumerState<GlassSettingsScreen> {
  bool _searching = false;
  final TextEditingController _panelQuery = TextEditingController();

  /// The `/` target (the shell's focus-search key): the wide frames' search capsule, or the phone's search well, whose focus opens the
  /// overlay. One node; only one of the two is built at a time.
  final FocusNode _panelFocus = FocusNode(debugLabel: 'settings search');
  late final VoidCallback _unregisterSearch;
  final FocusNode _pageFocus = FocusNode(debugLabel: 'settings page', skipTraversal: true);

  /// Closes the phone overlay and parks focus on the page, so the well (focused by `/`) never takes it back and reopens it.
  void _closeSearch() {
    setState(() => _searching = false);
    _pageFocus.requestFocus();
  }
  String _panelQ = '';
  int _cursor = 0;

  TargetPlatform get _platform => widget.platform ?? defaultTargetPlatform;

  bool _hwKey(KeyEvent e) {
    if (!ref.read(hardwareKeySeenProvider)) ref.read(hardwareKeySeenProvider.notifier).state = true;
    return false;
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_hwKey);
    _unregisterSearch = registerSearchFocus(_panelFocus);
    _scheduleReveal();
  }

  @override
  void didUpdateWidget(GlassSettingsScreen old) {
    super.didUpdateWidget(old);
    if (old.row != widget.row || old.section != widget.section) _scheduleReveal();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_hwKey);
    _panelQuery.dispose();
    _unregisterSearch();
    _panelFocus.dispose();
    _pageFocus.dispose();
    super.dispose();
  }

  SettingsSection? get _section => widget.section == null ? null : SettingsSection.values.where((s) => s.slug == widget.section).firstOrNull;

  void _scheduleReveal() {
    final id = widget.row ?? (const {'reading-novels', 'listen', 'ambient'}.contains(widget.section) ? widget.section : null);
    if (id == null) return;
    // The section body may still be loading; retry a few frames.
    var tries = 0;
    void attempt() {
      if (!mounted) return;
      if (ref.read(settingsAnchorsProvider).reveal(id) || ++tries > 12) return;
      WidgetsBinding.instance.addPostFrameCallback((_) => attempt());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => attempt());
  }

  List<SettingsIndexEntry> _filter(String q) {
    final auth = ref.read(authControllerProvider);
    return filterSettingsIndex(
      q,
      platform: _platform,
      admin: auth is AuthAuthenticated && auth.user.isAdmin,
      matureGateOpen: ref.read(matureGateOpenProvider),
    );
  }

  void _open(SettingsIndexEntry e) {
    setState(() {
      _searching = false;
      _panelQuery.clear();
      _panelQ = '';
    });
    _pageFocus.requestFocus();
    GoRouter.of(context).go(settingsLocationFor(e));
  }

  void _openSection(SettingsSection s) {
    if (s == SettingsSection.storage) {
      GoRouter.of(context).go(Routes.downloads({'tab': 'storage'}));
      return;
    }
    GoRouter.of(context).go('/settings/${s.slug}');
  }

  @override
  Widget build(BuildContext context) {
    final wide = GlassFrame.of(context) != GlassFrameKind.phone;
    final auth = ref.watch(authControllerProvider);
    final admin = auth is AuthAuthenticated && auth.user.isAdmin;
    final section = _section;
    if (widget.section != null && section == null) return GlassNotFound(location: '/settings/${widget.section}');
    if (section == SettingsSection.storage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openSection(SettingsSection.storage);
      });
      return const SizedBox.shrink();
    }
    final specs = visibleSettingsSections(platform: _platform, admin: admin, keyboardSeen: ref.watch(hardwareKeySeenProvider), wide: wide);
    final list = [...specs, kAboutSection];
    final selected = section ?? SettingsSection.appearance;
    final selectedIndex = list.indexWhere((s) => s.section == selected || (readerGroupSections.contains(selected) && s.section == SettingsSection.readingManga));

    Widget page;
    if (wide) {
      page = _wide(list, selected, selectedIndex, admin);
    } else if (section == null) {
      page = _root(specs, admin);
    } else {
      page = GlassScaffold(title: _labelOf(section), leading: GlassLeading.back, slivers: [SliverToBoxAdapter(child: settingsSectionBody(section))]);
    }

    return PopScope(
      canPop: !_searching,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _searching) _closeSearch();
      },
      child: SettingsKeys(
        onSearch: () => wide ? _panelFocus.requestFocus() : setState(() => _searching = true),
        onMove: (d) {
          if (!wide) return;
          final i = (selectedIndex + d).clamp(0, list.length - 1);
          _cursor = i;
          _openSection(list[i].section);
        },
        onOpen: () {
          if (wide) _openSection(list[_cursor.clamp(0, list.length - 1)].section);
        },
        onEscape: () {
          if (_searching) {
            _closeSearch();
          } else if (wide && _panelQ.isNotEmpty) {
            setState(() {
              _panelQuery.clear();
              _panelQ = '';
            });
          } else if (section != null && !wide) {
            GoRouter.of(context).go('/settings');
          }
        },
        // Holds focus when nothing inside has it, so the Settings keys work as soon as the page opens (glass 8.25 M2).
        child: Focus(
          focusNode: _pageFocus,
          autofocus: true,
          child: Stack(
            children: [
              Positioned.fill(child: page),
              if (_searching && !wide) Positioned.fill(child: GlassSettingsSearchOverlay(filter: _filter, onOpen: _open, onClose: _closeSearch)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _root(List<SettingsSectionSpec> specs, bool admin) => GlassScaffold(
        title: 'Settings',
        leading: GlassLeading.back,
        slivers: [
          SliverToBoxAdapter(child: _searchWell()),
          SliverToBoxAdapter(child: GlassGroupedList(children: [AccountHeader(onTap: () => GoRouter.of(context).go('/settings/profile'))])),
          SliverToBoxAdapter(
            child: GlassGroupedList(
              header: 'Settings',
              children: [
                for (final s in specs) _navRow(s),
              ],
            ),
          ),
          SliverToBoxAdapter(child: GlassGroupedList(header: 'About', children: [_navRow(kAboutSection)])),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
              child: GlassText('Settings save as you change them. Switching skin restarts the app.', role: gt.typeFootnote, color: gt.colorLabel2),
            ),
          ),
        ],
      );

  Widget _navRow(SettingsSectionSpec s) => GlassListRow(title: s.label, icon: s.glyph.regular, iconColor: s.tile, caret: true, onTap: () => _openSection(s.section));

  Widget _searchWell() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Focus(
          focusNode: _panelFocus,
          onFocusChange: (f) {
            if (f && !_searching) setState(() => _searching = true);
          },
          child: Semantics(
            button: true,
            label: 'Search settings',
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _searching = true),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: gt.colorFill3, borderRadius: BorderRadius.circular(22)),
                child: Row(
                  children: [
                    Icon(const IconData(0xe30c, fontFamily: 'PhosphorRegular'), size: 20, color: gt.colorLabel2),
                    const SizedBox(width: 8),
                    GlassText('Search settings', role: gt.typeBody, color: gt.colorLabel2),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  Widget _wide(List<SettingsSectionSpec> list, SettingsSection selected, int selectedIndex, bool admin) {
    final searching = _panelQ.trim().isNotEmpty;
    final left = SizedBox(
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: GlassSearchField(
              variant: GlassSearchVariant.filter, // a real field: typing filters the list in place (the sidebar variant is the palette launcher)
              controller: _panelQuery,
              focusNode: _panelFocus,
              placeholder: 'Search settings',
              onQuery: (q) => setState(() => _panelQ = q),
              onSubmitted: (q) {
                final m = _filter(q);
                if (m.isNotEmpty) _open(m.first);
              },
            ),
          ),
          if (searching)
            SettingsResults(query: _panelQ.trim(), matches: _filter(_panelQ), onOpen: _open)
          else ...[
            GlassGroupedList(
              children: [
                for (final s in list)
                  GlassListRow(
                      title: s.label,
                      icon: s.glyph.regular,
                      iconColor: s.tile,
                      selected: s.section == selected || (readerGroupSections.contains(selected) && s.section == SettingsSection.readingManga),
                      onTap: () => _openSection(s.section),),
              ],
            ),
            GlassGroupedList(
              children: [
                GlassListRow(title: 'Reading history', caret: true, onTap: () => GoRouter.of(context).go(Routes.history())),
                if (admin) GlassListRow(title: 'System status', caret: true, onTap: () => GoRouter.of(context).go(Routes.status())),
              ],
            ),
          ],
        ],
      ),
    );
    return GlassScaffold(
      title: 'Settings',
      leading: GlassLeading.back,
      slivers: [
        SliverToBoxAdapter(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              left,
              Expanded(child: settingsSectionBody(selected)),
            ],
          ),
        ),
      ],
    );
  }
}
