import 'dart:async';

import 'package:flutter/material.dart' show Theme;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/downloads/utils/active_download_count.dart';
import 'package:manhwamaniacs/features/novels/providers/novels_gate_provider.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/settings/providers/server_capabilities_provider.dart';
import 'package:manhwamaniacs/features/sources/providers/source_pins_provider.dart';
import 'package:manhwamaniacs/features/updates/providers/unread_count_provider.dart';
import 'package:manhwamaniacs/skins/glass/icons/glass_icon.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/content_mode_switch.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart' show GlassButtonIcon;
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs_more.dart';
import 'package:manhwamaniacs/skins/glass/primitives/icon_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/keycap.dart' show keycapLabel;
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/search_field.dart';
import 'package:manhwamaniacs/skins/glass/primitives/tooltip.dart';
import 'package:manhwamaniacs/skins/glass/shell/account_menu.dart';
import 'package:manhwamaniacs/skins/glass/shell/command_palette.dart';
import 'package:manhwamaniacs/skins/glass/shell/desktop_accessory.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_common.dart';
import 'package:manhwamaniacs/skins/glass/shell/sidebar_geometry.dart';
import 'package:manhwamaniacs/skins/glass/shell/sidebar_item.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/splash/glass_mark.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';
import 'package:manhwamaniacs/skins/skins.dart';

class _Row {
  const _Row(this.id, this.label, this.path, this.icon, {this.indent = 0, this.badge, this.dot = false, this.expandable = false}) : warn = false, loading = false;
  final String id;
  final String label;
  final String? path;
  final Widget Function(Color) icon;
  final double indent;
  final int? badge;
  final bool dot;
  final bool warn;
  final bool loading;
  final bool expandable;
}

Widget _role(GlassIconRole r, Color c) => GlassIcon(r, size: 20, color: c);
Widget _glyph(Glyph g, Color c) => Icon(g.regular, size: 20, color: c);

/// The inset sidebar of tablet and desktop frames (glass 7.16, 8.0.1): a `glassRegular` panel 12 px from the top, left and bottom,
/// 280 px wide (76 collapsed, animated on `springMinimize`), radius 26. [overlay] draws it over the content (the shell adds the dim).
class GlassSidebar extends ConsumerStatefulWidget {
  const GlassSidebar({super.key, required this.expanded, required this.location, required this.onToggle, this.overlay = false, this.onNavigated});
  final bool expanded;

  /// The location beneath any sheet route (activity follows it).
  final String location;
  final VoidCallback onToggle;
  final bool overlay;
  final VoidCallback? onNavigated;

  @override
  ConsumerState<GlassSidebar> createState() => _GlassSidebarState();
}

class _GlassSidebarState extends ConsumerState<GlassSidebar> with TickerProviderStateMixin {
  late final AnimationController _w = AnimationController(vsync: this, value: widget.expanded ? 1 : 0);
  late final AnimationController _drop = AnimationController.unbounded(vsync: this);
  bool _libraryOpen = true;
  int _lastRow = -1;
  final FocusNode _expandFocus = FocusNode(debugLabel: 'sidebar toggle');

  @override
  void didUpdateWidget(GlassSidebar old) {
    super.didUpdateWidget(old);
    if (old.expanded != widget.expanded) unawaited(GlassMotion.play(MotionName.minimise, controller: _w, target: widget.expanded ? 1 : 0));
  }

  @override
  void dispose() {
    _w.dispose();
    _drop.dispose();
    _expandFocus.dispose();
    super.dispose();
  }

  List<_Row> _rows() {
    final caps = ref.watch(serverCapabilitiesProvider).valueOrNull ?? const ServerCapabilities();
    final unread = ref.watch(unreadNotificationCountProvider);
    final letters = ref.watch(lettersProvider);
    final downloads = ref.watch(glassActiveDownloadCountProvider);
    final novel = ref.watch(novelsEnabledProvider) && ref.watch(contentModeControllerProvider) == ContentMode.novel;
    final pins = ref.watch(sourcePinsProvider).valueOrNull?.pins ?? const [];
    final rows = <_Row>[
      _Row('home', 'Home', '/', (c) => _role(GlassIconRole.home, c)),
      _Row('forYou', 'For you', '/library/recommendations', (c) => _glyph(GlassGlyph.sparkle, c), indent: 16),
      _Row('library', 'Library', null, (c) => _role(GlassIconRole.library, c), expandable: true),
      if (_libraryOpen) ...[
        _Row('shelf', 'Shelf', '/library', (c) => _role(GlassIconRole.library, c), indent: 16),
        if (caps.collections) _Row('collections', 'Collections', '/library/collections', (c) => _glyph(GlassGlyph28.stack, c), indent: 16),
        _Row('history', 'History', '/library/history', (c) => _glyph(GlassGlyph28.clockCounterClockwise, c), indent: 16),
        if (caps.bookmarks) _Row('bookmarks', 'Bookmarks', '/library/bookmarks', (c) => _role(GlassIconRole.bookmark, c), indent: 16),
        if (caps.clientDownloads) _Row('downloads', 'Downloads', '/downloads', (c) => _role(GlassIconRole.download, c), indent: 16, badge: downloads),
      ],
      if (caps.onlineSources) _Row('sources', 'Sources', '/sources', (c) => _role(GlassIconRole.sources, c)),
      _Row('updates', 'Updates', '/updates', (c) => _role(GlassIconRole.updates, c), badge: unread),
      if (letters.hasValue) _Row('circle', 'Circle', '/circle', (c) => _role(GlassIconRole.circle, c), dot: (letters.valueOrNull ?? const []).any((l) => l.state == LetterState.newLetter)),
      _Row('stats', 'Stats', '/library/statistics', (c) => _role(GlassIconRole.stats, c)),
      if (!novel && caps.ocr) _Row('dialogue', 'Dialogue search', '/ocr', (c) => _role(GlassIconRole.dialogueSearch, c)),
      if (caps.onlineSources)
        for (final p in pins.take(5))
          _Row('pin:${p.sourceId}', p.name, '/sources/${Uri.encodeComponent(p.sourceId)}', (c) => _Favicon(name: p.name, url: p.iconUrl)),
    ];
    return rows;
  }

  void _go(String path) {
    ref.read(skinRouterProvider).go(path);
    widget.onNavigated?.call();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows();
    final pinned = [for (final r in rows) if (r.id.startsWith('pin:')) r.id.substring(4)];
    var active = sidebarActiveId(widget.location, pinnedSources: pinned);
    if (!rows.any((r) => r.id == active) && active != 'settings' && active != 'status') active = _libraryOpen ? 'home' : 'library';
    final isAdmin = ref.watch(authControllerProvider.select((a) => a is AuthAuthenticated && a.user.isAdmin));
    final height = MediaQuery.sizeOf(context).height - kSidebarInset * 2;

    final idx = rows.indexWhere((r) => r.id == active);
    if (idx != _lastRow && idx >= 0) {
      final first = _lastRow < 0;
      _lastRow = idx;
      if (first) {
        _drop.value = idx.toDouble();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) => GlassMotion.play(MotionName.tabDroplet, controller: _drop, target: idx.toDouble(), travelPx: 50));
      }
    }

    return AnimatedBuilder(
      animation: _w,
      builder: (context, _) {
        final t = _w.value.clamp(0.0, 1.0);
        final width = kSidebarCollapsed + (kSidebarExpanded - kSidebarCollapsed) * t;
        final expanded = t > 0.5;
        return Positioned(
          left: kSidebarInset,
          top: kSidebarInset,
          width: width,
          height: height,
          child: Semantics(
            container: true,
            label: 'Sections',
            child: SkinGlass(
              size: Size(width, height),
              shape: const GlassShape.superellipse(kSidebarRadius),
              tier: GlassTierId.t3,
              moving: _w.isAnimating,
              debugLabel: 'GlassSidebar',
              child: _content(context, rows, active, expanded, width, isAdmin),
            ),
          ),
        );
      },
    );
  }

  Widget _content(BuildContext context, List<_Row> rows, String active, bool expanded, double width, bool isAdmin) {
    const pad = 8.0;
    final idx = rows.indexWhere((r) => r.id == active);
    Widget item(_Row r) {
      final isActive = r.id == active;
      return GlassSidebarItem(
        icon: r.icon,
        label: r.label,
        active: isActive,
        expanded: expanded,
        indent: r.indent,
        badge: r.badge,
        dot: r.dot,
        warn: r.warn,
        loading: r.loading,
        onDisc: widget.overlay,
        trailing: r.expandable && expanded ? Icon(_libraryOpen ? GlassGlyph.caretDown.regular : GlassGlyph.caretRight.regular, size: 16, color: gt.colorOnGlass) : null,
        onTap: () {
          if (r.expandable) {
            if (expanded) {
              setState(() => _libraryOpen = !_libraryOpen);
            } else {
              unawaited(_libraryFlyout(context));
            }
          } else if (r.path != null) {
            _go(r.path!);
          }
        },
      );
    }

    final profile = ref.watch(activeProfileProvider);
    return GlassHost(
      child: Padding(
        padding: const EdgeInsets.all(pad),
        child: Column(
          children: [
            _header(context, expanded),
            const SizedBox(height: 8),
            if (expanded)
              GlassSearchField(variant: GlassSearchVariant.sidebar, onOpenPalette: () => unawaited(openGlassPalette(context, ref)))
            else
              GlassIconButton(icon: roleIcon(GlassIconRole.search), label: 'Search · ${_paletteKeyLabel(context)}', onPressed: () => unawaited(openGlassPalette(context, ref))),
            if (ref.watch(novelsEnabledProvider)) ...[const SizedBox(height: 8), const GlassContentModeSwitch()],
            const SizedBox(height: 8),
            Expanded(
              child: Stack(
                children: [
                  if (idx >= 0)
                    AnimatedBuilder(
                      animation: _drop,
                      builder: (context, _) => Positioned(
                        top: _drop.value * 50,
                        left: expanded ? 0 : 6,
                        right: expanded ? 0 : 6,
                        height: 48,
                        child: IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(color: const Color(0x24FFFFFF), borderRadius: BorderRadius.circular(12), border: Border.all(width: 0.5, color: const Color(0x40FFFFFF))))),
                      ),
                    ),
                  ListView(
                    padding: EdgeInsets.zero,
                    children: [for (final r in rows) Padding(padding: const EdgeInsets.only(bottom: 2), child: item(r))],
                  ),
                ],
              ),
            ),
            GlassDesktopAccessory(expanded: expanded),
            GlassSidebarItem(icon: (c) => _role(GlassIconRole.settings, c), label: 'Settings', active: active == 'settings', expanded: expanded, onDisc: widget.overlay, onTap: () => _go('/settings')),
            if (isAdmin) GlassSidebarItem(icon: (c) => _role(GlassIconRole.status, c), label: 'Status', active: active == 'status', expanded: expanded, onDisc: widget.overlay, onTap: () => _go('/admin/status')),
            const SizedBox(height: 4),
            Builder(
              builder: (context) => GlassPressable(
                material: GlassMaterial.content,
                sink: 0.98,
                minHit: false,
                onTap: () => unawaited(showAccountMenu(context, ref, globalRectOf(context))),
                semanticsLabel: 'Account, ${profile?.name ?? ''}',
                builder: (context, info) => Container(
                  height: expanded ? 48 : 44,
                  padding: EdgeInsets.symmetric(horizontal: expanded ? 8 : 0),
                  decoration: BoxDecoration(color: info.states.hovered ? gt.colorFill3 : gt.colorFill2, borderRadius: BorderRadius.circular(24)),
                  child: expanded
                      ? Row(children: [const GlassMyOrb(size: 32), const SizedBox(width: 10), Expanded(child: GlassText(profile?.name ?? 'Profile', role: gt.typeSidebarItem, wght: 600, onGlass: true, maxLines: 1, overflow: TextOverflow.ellipsis))])
                      : const Center(child: GlassMyOrb(size: 32)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _paletteKeyLabel(BuildContext context) => keycapLabel(const SingleActivator(LogicalKeyboardKey.keyK, meta: true), platform: Theme.of(context).platform).join(' ');

  Future<void> _libraryFlyout(BuildContext context) => showGlassMenu(
        context,
        anchor: globalRectOf(context),
        title: 'Library',
        entries: [
          GlassMenuEntry(label: 'Shelf', onSelected: () => _go('/library')),
          GlassMenuEntry(label: 'Collections', onSelected: () => _go('/library/collections')),
          GlassMenuEntry(label: 'History', onSelected: () => _go('/library/history')),
          GlassMenuEntry(label: 'Bookmarks', onSelected: () => _go('/library/bookmarks')),
          GlassMenuEntry(label: 'Downloads', onSelected: () => _go('/downloads')),
        ],
      );

  Widget _header(BuildContext context, bool expanded) {
    if (!expanded) {
      return Column(
        children: [
          const SizedBox(height: 8),
          const GlassTooltip(message: 'ManhwaManiacs', level: GlassTooltipLevel.bar, above: false, child: GlassMark(height: 32)),
          const SizedBox(height: 8),
          Semantics(
            button: true,
            label: 'Expand sidebar',
            expanded: false,
            excludeSemantics: true,
            onTap: widget.onToggle,
            child: GlassIconButton(icon: GlassButtonIcon.glyph(GlassGlyph.caretRight), label: 'Expand sidebar', onPressed: widget.onToggle),
          ),
        ],
      );
    }
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          const SizedBox(width: 8),
          const Expanded(child: _Wordmark()),
          Semantics(
            button: true,
            label: 'Collapse sidebar',
            expanded: true,
            excludeSemantics: true,
            onTap: widget.onToggle,
            child: GlassIconButton(icon: GlassButtonIcon.glyph(GlassGlyph28.caretLeft), label: 'Collapse sidebar', onPressed: widget.onToggle),
          ),
        ],
      ),
    );
  }
}

/// "ManhwaManiacs" on one line in the display face (`ROND 100`, `wght 640`), the two M's in `iris400` (glass 12.1).
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(fontFamily: 'GoogleSansFlexMM', fontSize: 20, height: 1.1, fontVariations: [FontVariation('wght', 640), FontVariation('ROND', 100)], color: Color(0xFFF5F7FA), decoration: TextDecoration.none);
    final accent = base.copyWith(color: gt.colorIris400);
    return Semantics(
      label: 'ManhwaManiacs',
      excludeSemantics: true,
      child: Text.rich(TextSpan(children: [TextSpan(text: 'M', style: accent), const TextSpan(text: 'anhwa'), TextSpan(text: 'M', style: accent), const TextSpan(text: 'aniacs')], style: base), maxLines: 1, overflow: TextOverflow.fade, softWrap: false, textScaler: TextScaler.noScaling),
    );
  }
}

class _Favicon extends StatelessWidget {
  const _Favicon({required this.name, required this.url});
  final String name;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final mono = Container(
      width: 16,
      height: 16,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: gt.colorFill3, borderRadius: BorderRadius.circular(4)),
      child: Text(name.isEmpty ? '?' : name.characters.first.toUpperCase(), textScaler: TextScaler.noScaling, style: TextStyle(fontSize: 10, color: gt.colorOnGlass, decoration: TextDecoration.none)),
    );
    if (url == null) return mono;
    return ClipRRect(borderRadius: BorderRadius.circular(4), child: SizedBox(width: 16, height: 16, child: Image.network(url!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => mono)));
  }
}
