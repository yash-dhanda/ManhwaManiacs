import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/keyboard/fuzzy_rank.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/library/providers/dashboard_providers.dart';
import 'package:manhwamaniacs/features/novels/providers/novels_gate_provider.dart';
import 'package:manhwamaniacs/features/sources/providers/sources_provider.dart';
import 'package:manhwamaniacs/features/updates/providers/updates_provider.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/navigation.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_confirm_dialog.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_search_field.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/dialog_route.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/stock.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// One row of the palette.
class PaletteItem {
  const PaletteItem({required this.group, required this.title, this.subtitle, this.leading, required this.onSelect});
  final String group;
  final String title;
  final String? subtitle;
  final Widget? leading;
  final void Function() onSelect;
}

/// The group order of the palette (cinematic 8.33.1); `EDITION` is absent while Glass is not
/// available.
const List<String> paletteGroupOrder = ['LIBRARY', 'SOURCES', 'GO TO', 'ACTIONS', 'EDITION', 'SETTINGS'];

/// The section names of `SETTINGS`.
const List<(String, SettingsSection)> paletteSettings = [
  ('Profile & account', SettingsSection.profile),
  ('Appearance', SettingsSection.appearance),
  ('Reading: manga', SettingsSection.readingManga),
  ('Reading: novels', SettingsSection.readingNovels),
  ('Listen', SettingsSection.listen),
  ('Ambient', SettingsSection.ambient),
  ('Downloads & storage', SettingsSection.storage),
  ('Content', SettingsSection.content),
  ('Circle & privacy', SettingsSection.circle),
  ('Feedback', SettingsSection.feedback),
  ('Notifications', SettingsSection.notifications),
  ('Keyboard', SettingsSection.keyboard),
  ('Server', SettingsSection.server),
  ('Admin', SettingsSection.admin),
  ('Diagnostics', SettingsSection.diagnostics),
  ('About', SettingsSection.about),
];

/// Ranked, grouped results: at most [limit] rows, groups in [paletteGroupOrder], rows in rank
/// order inside a group. [libraryHits] are already the server's answer and keep its order.
List<(PaletteItem, List<int>)> rankPalette(String query, List<PaletteItem> items, {int limit = 40}) {
  final out = <(PaletteItem, List<int>)>[];
  for (final g in paletteGroupOrder) {
    final inGroup = [for (final i in items) if (i.group == g) i];
    if (g == 'LIBRARY') {
      for (final i in inGroup) {
        out.add((i, const []));
      }
      continue;
    }
    for (final r in rankItems<PaletteItem>(query, inGroup, (i) => i.title, limit: limit)) {
      out.add((r.item, r.matches));
    }
  }
  return out.length > limit ? out.sublist(0, limit) : out;
}

final ValueNotifier<bool> _open = ValueNotifier(false);
bool get cinePaletteIsOpen => _open.value;

/// `mod+k`: opens the palette, or closes it when it is open.
void togglePalette(BuildContext navContext, WidgetRef ref) {
  if (_open.value) {
    Navigator.of(navContext, rootNavigator: true).maybePop();
    return;
  }
  showCineCommandPalette(navContext, ref);
}

/// The command palette "Index" (cinematic 8.33.1): a `CineDialogRoute` at `z.dialog`.
Future<void> showCineCommandPalette(BuildContext navContext, WidgetRef ref) {
  final trigger = FocusManager.instance.primaryFocus;
  _open.value = true;
  return showCineDialog<void>(navContext, builder: (_) => const CinePalette()).whenComplete(() {
    _open.value = false;
    if (trigger != null && trigger.context != null && trigger.canRequestFocus) trigger.requestFocus();
  });
}

class CinePalette extends ConsumerStatefulWidget {
  const CinePalette({super.key, this.fixture});

  /// Items for the gallery and the tests; when set no provider is read.
  final List<PaletteItem>? fixture;

  @override
  ConsumerState<CinePalette> createState() => _CinePaletteState();
}

class _CinePaletteState extends ConsumerState<CinePalette> {
  final _ctl = TextEditingController();
  final _field = FocusNode(debugLabel: 'palette-field');
  final _scroll = ScrollController();
  Timer? _debounce;
  List<PaletteItem> _library = const [];
  int _active = 0;
  String _announced = '';
  List<(PaletteItem, List<int>)> _rows = const [];

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_hw);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_hw);
    _debounce?.cancel();
    _ctl.dispose();
    _field.dispose();
    _scroll.dispose();
    super.dispose();
  }

  GoRouter get _router => ref.read(skinRouterProvider);

  void _go(String path) => _router.go(path);

  List<PaletteItem> _items() {
    if (widget.fixture != null) return widget.fixture!;
    final admin = (ref.read(authControllerProvider) is AuthAuthenticated) && (ref.read(authControllerProvider) as AuthAuthenticated).user.isAdmin;
    final novels = ref.watch(novelsEnabledProvider);
    final mode = ref.watch(contentModeControllerProvider);
    final sources = ref.watch(sourcesListProvider).valueOrNull ?? const [];
    final cont = ref.watch(continueReadingProvider).valueOrNull;
    final go = <(String, String, String)>[
      ('01', 'Tonight', Routes.tonight()),
      ('02', 'Library', Routes.library()),
      ('03', 'Updates', Routes.updates()),
      ('04', 'Discover', Routes.discover()),
      ('05', 'Downloads', Routes.downloads()),
      ('06', 'Collections', Routes.collections()),
      ('07', 'History', Routes.history()),
      ('08', 'Bookmarks', Routes.bookmarks()),
      if (mode == ContentMode.manga) ('09', 'Dialogue', Routes.dialogue()),
      ('10', 'The Numbers', Routes.numbers()),
      ('11', 'Circle', Routes.circle()),
      ('12', 'Picks', Routes.picks()),
      ('', 'Index', Routes.indexHub()),
      ('', 'Profiles', Routes.profilesManage()),
      ('', 'Settings', Routes.settings()),
      if (admin) ('', 'Status', Routes.status()),
    ];
    return [
      ..._library,
      for (final s in sources)
        PaletteItem(
          group: 'SOURCES',
          title: s.name,
          subtitle: s.description,
          leading: SizedBox(width: 24, height: 24, child: CineImage(url: s.iconUrl)),
          onSelect: () => _go(Routes.source(s.id)),
        ),
      for (final g in go)
        PaletteItem(group: 'GO TO', title: g.$1.isEmpty ? g.$2 : '${g.$1} ${g.$2}', onSelect: () => _go(g.$3)),
      if (cont != null && cont.isNotEmpty)
        PaletteItem(
          group: 'ACTIONS',
          title: 'Continue ${cont.first.title ?? 'reading'}',
          onSelect: () {
            final i = cont.first;
            final ctx = _navContext();
            if (ctx != null) {
              enterReader(ctx, ReaderTarget.manifest(i.sourceId, i.seriesKey, i.chapterKey), entry: ReaderEntry.wipe);
            }
          },
        ),
      PaletteItem(
        group: 'ACTIONS',
        title: 'Check for updates',
        onSelect: () async {
          final err = await ref.read(updatesProvider.notifier).triggerCheck();
          final toasts = ref.read(cineToastsProvider.notifier);
          if (err == null) {
            toasts.info('Checking for updates.');
          } else {
            toasts.error(err.userMessage);
          }
        },
      ),
      PaletteItem(group: 'ACTIONS', title: 'Open settings', onSelect: () => _go(Routes.settings())),
      if (novels)
        PaletteItem(
          group: 'ACTIONS',
          title: 'Toggle reading mode',
          subtitle: mode == ContentMode.novel ? 'Novels to manga' : 'Manga to novels',
          onSelect: () => ref
              .read(contentModeControllerProvider.notifier)
              .setMode(mode == ContentMode.novel ? ContentMode.manga : ContentMode.novel),
        ),
      PaletteItem(
        group: 'ACTIONS',
        title: 'Sign out',
        onSelect: () async {
          final ctx = _navContext();
          if (ctx == null) return;
          final ok = await showCineConfirm(ctx, title: 'Sign out on this device?', confirmLabel: 'Sign out', destructive: true);
          if (ok) await ref.read(authControllerProvider.notifier).logout();
        },
      ),
      for (final s in paletteSettings)
        PaletteItem(group: 'SETTINGS', title: s.$1, onSelect: () => _go(Routes.settings(s.$2))),
    ];
  }

  BuildContext? _navContext() => _router.routerDelegate.navigatorKey.currentContext;

  void _onChanged(String q) {
    _debounce?.cancel();
    setState(() => _active = 0);
    if (widget.fixture != null) return;
    if (q.trim().isEmpty) {
      setState(() => _library = const []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 220), () async {
      final r = await ref.read(libraryRepositoryProvider).search(q.trim(), perPage: 8);
      if (!mounted || _ctl.text.trim() != q.trim() || r.isErr) return;
      setState(() {
        _library = [
          for (final s in r.value.items)
            PaletteItem(
              group: 'LIBRARY',
              title: s.title,
              subtitle: s.sourceId,
              leading: SizedBox(width: 40, height: 60, child: CineImage(url: s.coverUrl, title: s.title)),
              onSelect: () => _router.push<void>(Routes.feature(s.sourceId, s.seriesKey), extra: <String, String>{'transition': 'match'}),
            ),
        ];
      });
    });
  }

  void _select(List<(PaletteItem, List<int>)> rows) {
    if (rows.isEmpty) return;
    final item = rows[_active.clamp(0, rows.length - 1)].$1;
    Navigator.of(context, rootNavigator: true).maybePop();
    item.onSelect();
  }

  void _move(int delta, int n) {
    if (n == 0) return;
    setState(() => _active = (_active + delta) % n < 0 ? (_active + delta) % n + n : (_active + delta) % n);
    _ensureVisible();
  }

  void _ensureVisible() {
    final target = _active * 56.0;
    if (!_scroll.hasClients) return;
    final top = _scroll.offset;
    final h = _scroll.position.viewportDimension;
    if (target < top) {
      _scroll.jumpTo(target);
    } else if (target + 56 > top + h) {
      _scroll.jumpTo(target + 56 - h);
    }
  }

  /// Keys while the palette is open: `Esc`, `mod+k`, `Enter`, `Up` / `Down` (wrapping), `Home` and
  /// `End`. A hardware handler, so they work whatever holds focus (the field claims `Esc`).
  bool _hw(KeyEvent e) {
    if (e is KeyUpEvent) return false;
    final k = e.logicalKey;
    final rows = _rows;
    final n = rows.length;
    final hw = HardwareKeyboard.instance;
    if (k == LogicalKeyboardKey.arrowDown) {
      _move(1, n);
      return true;
    }
    if (k == LogicalKeyboardKey.arrowUp) {
      _move(-1, n);
      return true;
    }
    if (k == LogicalKeyboardKey.home) {
      setState(() => _active = 0);
      _ensureVisible();
      return true;
    }
    if (k == LogicalKeyboardKey.end) {
      setState(() => _active = math.max(0, n - 1));
      _ensureVisible();
      return true;
    }
    if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) {
      _select(rows);
      return true;
    }
    if (k == LogicalKeyboardKey.escape || ((hw.isMetaPressed || hw.isControlPressed) && k == LogicalKeyboardKey.keyK)) {
      Navigator.of(context, rootNavigator: true).maybePop();
      return true;
    }
    return false;
  }

  void _announce(int n, String q) {
    final text = q.trim().isEmpty ? '' : (n == 0 ? 'Nothing matches' : '$n results');
    if (text == _announced) return;
    _announced = text;
    if (text.isEmpty) return;
    SemanticsService.sendAnnouncement(View.of(context), text, TextDirection.ltr);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final q = _ctl.text;
    final rows = _rows = rankPalette(q, _items());
    if (_active >= rows.length) _active = math.max(0, rows.length - 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _announce(rows.length, q);
    });
    final h = MediaQuery.sizeOf(context).height;
    String? lastGroup;
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(top: h * 0.12, left: c.space4, right: c.space4),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 720, maxHeight: h * 0.7),
          child: Material(
            type: MaterialType.transparency,
            child: CineStock.raised(
              Container(
                  decoration: BoxDecoration(color: c.colorPaper2, border: Border.all(color: c.colorRule2)),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Padding(
                      padding: EdgeInsets.all(c.space3),
                      child: Row(children: [
                        Expanded(
                          child: CineSearchField(
                            semanticLabel: 'Search or jump',
                            placeholder: 'Search or jump…',
                            controller: _ctl,
                            focusNode: _field,
                            autofocus: true,
                            onChanged: _onChanged,
                          ),
                        ),
                        SizedBox(width: c.space2),
                        const _PaletteKey('Esc'),
                      ],),
                    ),
                    Divider(height: 1, color: c.colorRule2),
                    Flexible(
                      child: rows.isEmpty
                          ? Padding(
                              padding: EdgeInsets.all(c.space6),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: CineRoleText('Nothing matches “$q”.', c.typeBody, color: c.colorInk60),
                              ),
                            )
                          : ListView.builder(
                              controller: _scroll,
                              shrinkWrap: true,
                              itemCount: rows.length,
                              itemBuilder: (context, i) {
                                final (item, hits) = rows[i];
                                final header = item.group != lastGroup;
                                lastGroup = item.group;
                                return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                                  if (header)
                                    Padding(
                                      padding: EdgeInsets.fromLTRB(c.space4, c.space3, c.space4, c.space1),
                                      child: CineRoleText(item.group, c.typeKicker, color: c.colorInk45),
                                    ),
                                  _Row(
                                    item: item,
                                    matches: hits,
                                    active: i == _active,
                                    onTap: () {
                                      setState(() => _active = i);
                                      _select(rows);
                                    },
                                  ),
                                ],);
                              },
                            ),
                    ),
                    Divider(height: 1, color: c.colorRule2),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: c.space4, vertical: c.space2),
                      child: Row(children: [
                        const _PaletteKey('↑ ↓'),
                        SizedBox(width: c.space1),
                        CineRoleText('navigate', c.typeCaption, color: c.colorInk60),
                        SizedBox(width: c.space3),
                        const _PaletteKey('↵'),
                        SizedBox(width: c.space1),
                        CineRoleText('open', c.typeCaption, color: c.colorInk60),
                        const Spacer(),
                        CineRoleText(rows.length == 1 ? '1 result' : '${rows.length} results', c.typeCaption, color: c.colorInk60),
                      ],),
                    ),
                  ],),
                ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaletteKey extends StatelessWidget {
  const _PaletteKey(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(border: Border.all(color: c.colorInk30)),
      alignment: Alignment.center,
      child: CineLit(text, CineFace.plexMono, 12, 16, color: c.colorInk100),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.item, required this.matches, required this.active, required this.onTap});
  final PaletteItem item;
  final List<int> matches;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final base = CineText.style(context, c.typeUi).copyWith(color: c.colorInk100);
    final spans = <TextSpan>[
      for (var i = 0; i < item.title.length; i++)
        TextSpan(text: item.title[i], style: matches.contains(i) ? base.copyWith(color: c.colorSpot) : base),
    ];
    return Semantics(
      button: true,
      selected: active,
      label: item.subtitle == null ? item.title : '${item.title}, ${item.subtitle}',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(minHeight: math.max(56, cineHitMin(context))),
          decoration: BoxDecoration(
            color: active ? c.colorPaper4 : null,
            border: active ? Border(left: BorderSide(color: c.colorInk100, width: 2)) : null,
          ),
          padding: EdgeInsets.symmetric(horizontal: c.space4, vertical: c.space2),
          child: Row(children: [
            if (item.leading != null) ...[item.leading!, SizedBox(width: c.space3)],
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text.rich(TextSpan(children: spans), maxLines: 1, overflow: TextOverflow.ellipsis, textScaler: CineText.scaler(context, c.typeUi)),
                if (item.subtitle != null) CineRoleText(item.subtitle!, c.typeCaption, color: c.colorInk60, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],),
            ),
            if (active) CineLit('↵', CineFace.plexMono, 12, 16, color: c.colorInk60),
          ],),
        ),
      ),
    );
  }
}
