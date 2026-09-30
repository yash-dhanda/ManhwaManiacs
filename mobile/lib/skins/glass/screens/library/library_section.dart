import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/glass_scroll_behavior.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/shell/glass_scaffold.dart';
import 'package:manhwamaniacs/skins/glass/shell/insets.dart';

/// The five sections of the Library hub (glass 8.0.3). On phones they are in-page tabs of one pager; on wider frames each is a page.
enum LibrarySection {
  shelf('Shelf', '/library'),
  collections('Collections', '/library/collections'),
  history('History', '/library/history'),
  bookmarks('Bookmarks', '/library/bookmarks'),
  downloads('Downloads', '/downloads');

  const LibrarySection(this.label, this.path);
  final String label;

  /// The canonical path written with `replace` when the pager settles.
  final String path;
}

/// What the active section asks the hub's nav row to show (phone, embedded mode).
@immutable
class LibraryChromeSpec {
  const LibraryChromeSpec({this.trailing = const [], this.overflow = const []});
  final List<GlassBarAction> trailing;
  final List<GlassMenuEntry> overflow;
}

/// Provided by the hub on phones. Sections find it with [LibraryChrome.maybeOf]; null means the section is its own page.
class LibraryChrome extends InheritedWidget {
  const LibraryChrome({super.key, required this.active, required this.offset, required this.publish, required super.child});

  /// The section on screen; only it may drive [offset] and [publish].
  final ValueListenable<LibrarySection> active;
  final ValueNotifier<double> offset;
  final void Function(LibrarySection section, LibraryChromeSpec spec) publish;

  static LibraryChrome? maybeOf(BuildContext c) => c.getInheritedWidgetOfExactType<LibraryChrome>();

  @override
  bool updateShouldNotify(LibraryChrome old) => false;
}

/// One section's frame. Embedded in the hub (phone) it is a scroll view with the hub's insets that publishes its chrome; as a page
/// (tablet and desktop frames) it is a [GlassScaffold] titled [title] (glass 8.0.1).
class LibrarySectionFrame extends ConsumerStatefulWidget {
  const LibrarySectionFrame({
    super.key,
    required this.section,
    required this.slivers,
    this.trailing = const [],
    this.overflow = const [],
    this.refreshSliver,
    this.title,
    this.contentModeSwitch = true,
    this.scrollController,
    this.physics,
  });

  final LibrarySection section;
  final List<Widget> slivers;
  final List<GlassBarAction> trailing;
  final List<GlassMenuEntry> overflow;
  final Widget? refreshSliver;

  /// The page title when not embedded; defaults to the section label.
  final String? title;
  final bool contentModeSwitch;
  final ScrollController? scrollController;
  final ScrollPhysics? physics;

  @override
  ConsumerState<LibrarySectionFrame> createState() => _LibrarySectionFrameState();
}

class _LibrarySectionFrameState extends ConsumerState<LibrarySectionFrame> {
  ScrollController? _own;
  ScrollController get _scroll => widget.scrollController ?? (_own ??= ScrollController());
  LibraryChrome? _chrome;

  void _report() {
    final c = _chrome;
    if (c == null || c.active.value != widget.section) return;
    c.offset.value = _scroll.hasClients ? _scroll.offset : 0;
  }

  void _publish() {
    final c = _chrome;
    if (c == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) c.publish(widget.section, LibraryChromeSpec(trailing: widget.trailing, overflow: widget.overflow));
    });
  }

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_report);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chrome = LibraryChrome.maybeOf(context);
    _chrome?.active.addListener(_report);
    _publish();
  }

  @override
  void didUpdateWidget(LibrarySectionFrame old) {
    super.didUpdateWidget(old);
    _publish();
  }

  @override
  void dispose() {
    _chrome?.active.removeListener(_report);
    _scroll.removeListener(_report);
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_chrome == null) {
      return GlassScaffold(
        title: widget.title ?? widget.section.label,
        trailing: widget.trailing,
        overflow: widget.overflow,
        contentModeSwitch: widget.contentModeSwitch,
        refreshSliver: widget.refreshSliver,
        slivers: widget.slivers,
      );
    }
    final insets = GlassInsets.watch(context, ref);
    final margin = GlassFrame.screenMargin(context);
    return CustomScrollView(
      controller: _scroll,
      physics: widget.physics ?? glassScrollPhysics,
      keyboardDismissBehavior: glassKeyboardDismiss,
      slivers: [
        if (widget.refreshSliver != null) widget.refreshSliver!,
        const SliverPadding(padding: EdgeInsets.only(top: 8)),
        SliverPadding(padding: EdgeInsets.symmetric(horizontal: margin), sliver: SliverMainAxisGroup(slivers: widget.slivers)),
        SliverPadding(padding: EdgeInsets.only(bottom: insets.bottom)),
      ],
    );
  }
}
