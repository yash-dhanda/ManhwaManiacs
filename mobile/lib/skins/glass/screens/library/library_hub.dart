import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/tab_pager.dart';
import 'package:manhwamaniacs/skins/glass/screens/downloads/downloads_page.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/bookmarks_page.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/collections_page.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/history_page.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/library_common.dart' show libraryAmbientProvider;
import 'package:manhwamaniacs/skins/glass/screens/library/library_section.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/shelf_page.dart';
import 'package:manhwamaniacs/skins/glass/shell/glass_scaffold.dart';

/// The page key every Library hub route shares: a pager settle replaces the location and the Navigator updates this page in place.
const ValueKey<String> kGlassLibraryHubKey = ValueKey('glass.library.hub');

/// `/downloads?tab=` names.
const List<String> kDownloadsTabs = ['chapters', 'queue', 'storage'];

/// The hub (glass 8.0.3): on phones one page with the five sections as in-page tabs on a pager; on tablet and desktop frames the
/// section page of [initial] (each section is its own route under the sidebar's Library children).
class GlassLibraryHub extends ConsumerStatefulWidget {
  const GlassLibraryHub({super.key, required this.initial, this.browseAll = false, this.downloadsTab, this.aliasReplace = false});
  final LibrarySection initial;

  /// `/library/browse`: the shelf with its toolbar expanded.
  final bool browseAll;
  final String? downloadsTab;

  /// Reached through `/library?tab=...`: the location is replaced with the section's canonical path once.
  final bool aliasReplace;

  @override
  ConsumerState<GlassLibraryHub> createState() => _GlassLibraryHubState();
}

class _GlassLibraryHubState extends ConsumerState<GlassLibraryHub> {
  late final GlassTabPagerController _pager = GlassTabPagerController(initialIndex: widget.initial.index);
  late final ValueNotifier<LibrarySection> _active = ValueNotifier(widget.initial);
  final Map<LibrarySection, LibraryChromeSpec> _chrome = {};
  late final List<Widget> _panels;

  @override
  void initState() {
    super.initState();
    _panels = [
      const _KeepAlive(child: GlassShelfPage()),
      const _KeepAlive(child: GlassCollectionsPage()),
      const _KeepAlive(child: GlassHistoryPage()),
      const _KeepAlive(child: GlassBookmarksPage()),
      _KeepAlive(child: GlassDownloadsPage(initialTab: widget.downloadsTab)),
    ];
    if (widget.aliasReplace) {
      Future.microtask(() {
        if (mounted) GoRouter.of(context).replace<void>(widget.initial.path);
      });
    }
  }

  @override
  void didUpdateWidget(GlassLibraryHub old) {
    super.didUpdateWidget(old);
    if (old.initial != widget.initial && _active.value != widget.initial) {
      _active.value = widget.initial;
      if (_pager.pages.hasClients) _pager.pages.jumpToPage(widget.initial.index);
    }
  }

  @override
  void dispose() {
    _active.dispose();
    _pager.dispose();
    super.dispose();
  }

  void _publish(LibrarySection section, LibraryChromeSpec spec) {
    _chrome[section] = spec;
    if (mounted && section == _active.value) setState(() {});
  }

  void _changed(int i) {
    final section = LibrarySection.values[i];
    if (_active.value == section) return;
    _active.value = section;
    setState(() {});
    // The location always names the section on screen; the same page key means the Navigator updates this page in place.
    GoRouter.of(context).replace<void>(section.path);
  }

  @override
  Widget build(BuildContext context) {
    if (GlassFrame.of(context) != GlassFrameKind.phone) {
      return switch (widget.initial) {
        LibrarySection.shelf => GlassShelfPage(browseAll: widget.browseAll),
        LibrarySection.collections => const GlassCollectionsPage(),
        LibrarySection.history => const GlassHistoryPage(),
        LibrarySection.bookmarks => const GlassBookmarksPage(),
        LibrarySection.downloads => GlassDownloadsPage(initialTab: widget.downloadsTab),
      };
    }
    final spec = _chrome[_active.value] ?? const LibraryChromeSpec();
    return GlassScaffold(
      title: 'Library',
      contentModeSwitch: true,
      slivers: const [],
      ambient: ref.watch(libraryAmbientProvider),
      trailing: spec.trailing,
      overflow: spec.overflow,
      bodyBuilder: (context, insets, offset) => LibraryChrome(
        active: _active,
        offset: offset,
        publish: _publish,
        child: Padding(
          padding: EdgeInsets.only(top: insets.top - 8),
          child: GlassTabPager(
            controller: _pager,
            initialIndex: widget.initial.index,
            onChanged: _changed,
            tabs: [for (final s in LibrarySection.values) GlassTabSpec(s.label)],
            panels: _panels,
          ),
        ),
      ),
    );
  }
}

class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});
  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
