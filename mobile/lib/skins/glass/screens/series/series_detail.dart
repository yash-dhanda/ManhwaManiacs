import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart' as keys show ShortcutRegistry, shortcutRegistryProvider;
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/features/novels/utils/toc_window.dart';
import 'package:manhwamaniacs/features/sources/providers/source_progress_provider.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/glass/ambient_field.dart';
import 'package:manhwamaniacs/skins/glass/glass/follow_ring.dart';
import 'package:manhwamaniacs/skins/glass/parts/ai/more_like_this_rail.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/fast_scroll.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart' show GlassButtonIcon;
import 'package:manhwamaniacs/skins/glass/primitives/glyphs_more.dart';
import 'package:manhwamaniacs/skins/glass/primitives/icon_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/image_viewer.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_form_route.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_sheet_route.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_common.dart' show paletteOf, HomeCoverImage;
import 'package:manhwamaniacs/skins/glass/screens/series/book_page.dart' show kTocRowExtent;
import 'package:manhwamaniacs/skins/glass/screens/series/chapter_extents.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/chapters_section.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/collapse.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/download_card.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/series_actions.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/series_data.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/series_header.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/series_keys.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/series_states.dart';
import 'package:manhwamaniacs/skins/glass/transitions/dive.dart';

/// The layout the page takes (glass 8.12 Presentation): the phone sheet, the tablet window (one column, full content width), the
/// 960 px desktop detail window (two columns), or a full page when nothing is beneath.
enum SeriesLayout { phone, tablet, desktop }

SeriesLayout seriesLayoutOf(Size size) {
  if (size.shortestSide < 600) return SeriesLayout.phone;
  return size.width >= 1024 ? SeriesLayout.desktop : SeriesLayout.tablet;
}

/// What a page variant (the manga series detail, the book page) contributes to the shared page.
abstract class SeriesVariant {
  /// The header block under (and overlapping) the band.
  Widget header(BuildContext context, SeriesPageState page);

  /// The chapter or contents slivers.
  List<Widget> chapterSlivers(BuildContext context, SeriesPageState page);

  /// What the primary does (Continue dives; the book opens).
  void primary(BuildContext context, SeriesPageState page);
}

/// The Glass series page for both identities (glass 8.12; 8.13 through [variant]).
class GlassSeriesPage extends ConsumerStatefulWidget {
  const GlassSeriesPage({super.key, required this.data, required this.variant, this.focusChapter, this.sheet, this.velocity, this.mature = false});
  final GlassSeriesData data;
  final SeriesVariant variant;
  final String? focusChapter;
  final String? sheet;
  final Offset? velocity;
  final bool mature;

  @override
  ConsumerState<GlassSeriesPage> createState() => SeriesPageState();
}

class SeriesPageState extends ConsumerState<GlassSeriesPage> {
  final chapters = SeriesChapters();
  final commands = SeriesCommands();
  final ring = GlassFollowRingController();
  final bandKey = GlobalKey(debugLabel: 'series band');
  final followKey = GlobalKey(debugLabel: 'series follow');
  final coverKey = GlobalKey(debugLabel: 'series cover');
  final titleFocus = FocusNode(debugLabel: 'series title');
  final ScrollController _own = ScrollController();
  final ValueNotifier<double> leftTop = ValueNotifier(120);
  final Object _shortcutToken = Object();
  late final keys.ShortcutRegistry _shortcuts;
  GlassAmbientSpec? _prevAmbient;
  StateController<GlassAmbientSpec?>? _amb;
  bool _warmed = false;

  GlassSeriesData get data => widget.data;
  SeriesLayout get layout => seriesLayoutOf(MediaQuery.sizeOf(context));

  /// The page sits in a phone sheet (its scroll view hands off to the sheet).
  bool get inSheet => ModalRoute.of(context) is GlassSheetRoute;

  SeriesActionsLogic get logic => SeriesActionsLogic(context, ref, data, ring: ring, bandKey: bandKey, followKey: followKey);

  @override
  void initState() {
    super.initState();
    _shortcuts = ref.read(keys.shortcutRegistryProvider.notifier);
    chapters.order = initialOrder(ref, data);
    chapters.selection.addListener(_changed);
    chapters.addListener(_changed);
    _own.addListener(() => leftTop.value = math.max(24, 120 - _own.offset));
    _wire();
    Future.microtask(() {
      if (!mounted) return;
      _shortcuts.register(_shortcutToken, seriesShortcutEntries(book: data.novel));
      _ambient();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!inSheet) titleFocus.requestFocus();
      _openSheetParam();
      if (widget.focusChapter != null) jumpTo(widget.focusChapter!);
    });
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _ambient() {
    final pal = paletteOf(null, data.series.ambient);
    final notifier = ref.read(glassAmbientProvider.notifier);
    _amb = notifier;
    _prevAmbient = notifier.state;
    if (pal != null) notifier.state = GlassAmbientSpec.palette(pal, opacity: 0.28);
  }

  @override
  void dispose() {
    final reg = _shortcuts, t = _shortcutToken, prev = _prevAmbient;
    final amb = _amb;
    Future.microtask(() {
      reg.unregister(t);
      try {
        if (amb != null && prev != null) amb.state = prev;
      } catch (_) {}
    });
    chapters.dispose();
    ring.dispose();
    titleFocus.dispose();
    _own.dispose();
    leftTop.dispose();
    super.dispose();
  }

  void _wire() {
    final c = commands;
    c.continueReading = () => widget.variant.primary(context, this);
    c.readAll =
        data.chapters.length > 1 && !data.novel ? () => unawaited(enterReader(context, ref, Routes.readAll(data.sourceId, data.seriesKey), fromRect: Offset.zero & MediaQuery.sizeOf(context))) : null;
    c.toggleFollow = () => fire(logic.toggleFollow());
    c.favorite = () => fire(logic.favorite());
    c.notify = () => fire(logic.notify());
    c.downloadNext10 = () => fire(enqueueSeriesChapters(ref, data, next10Keys(ref, data)));
    c.pickChapter = focusGoTo;
    c.previouslyOn = () {
      if (ref.read(sourceSeriesProgressProvider(data.progressKey)).isNotEmpty) openPreviouslyOn(ref, data);
    };
    c.tags = () => openTagsSheet(context, data);
    c.share = () => copySeriesLink(ref, data);
    c.toggleSort = () => chapters.setOrder(chapters.order == 'newest' ? 'oldest' : 'newest');
    c.select = toggleSelect;
    c.focusGoTo = focusGoTo;
    c.more = () => openMenu(rectOf(bandKey.currentContext ?? context));
  }

  void openMenu(Rect anchor) => unawaited(showSeriesMenu(context, ref, data, anchor));

  void toggleSelect() {
    final s = chapters.selection;
    if (s.isActive) {
      s.end();
    } else {
      s.begin();
    }
  }

  void focusGoTo() {
    chapters.goToFocus.requestFocus();
    final ctx = chapters.goToFocus.context;
    if (ctx != null) unawaited(Scrollable.ensureVisible(ctx, alignment: 0.2, duration: const Duration(milliseconds: 400)));
  }

  /// Scrolls to [key] and pulses its row.
  void jumpTo(String key) {
    final shown = shownChapters(data, chapters.order);
    final i = shown.indexWhere((c) => c.id == key);
    if (i < 0) return;
    chapters.pulse = key;
    chapters.ping();
    final scale = rowTextScale(context);
    // The book's contents build a 400-row window around the focus (glass 8.13), so the row's index is relative to it.
    final idx = data.novel ? i - tocWindow(shown.length, i).start : i;
    final ext = List<double>.filled(idx + 1, data.novel ? kTocRowExtent * scale : chapterRowExtent(hasSecondary: false, textScale: scale));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) scrollToRow(context, chapters, ext, idx);
    });
  }

  /// Esc: clear the selection, then end select mode, then close.
  bool escape() {
    final s = chapters.selection;
    if (s.isActive && s.count > 0) {
      s.clearSelection();
      return true;
    }
    if (s.isActive) {
      s.end();
      return true;
    }
    seriesBack(ref, sourceId: data.sourceId);
    return true;
  }

  void _openSheetParam() {
    switch (widget.sheet) {
      case 'tags':
        openTagsSheet(context, data);
      case 'move-source':
        if (data.isFollowed) openMoveSource(context, data);
      case 'image':
        openCover();
    }
  }

  /// The image viewer, zooming from the cover's rect (`?sheet=image`).
  void openCover() {
    final url = resolveCover(ref, data.series.coverUrl);
    if (url.isEmpty) return;
    final rect = rectOf(coverKey.currentContext ?? context);
    unawaited(Navigator.of(context, rootNavigator: true).push<void>(GlassImageViewerRoute<void>(image: NetworkImage(url), thumbRect: rect, description: 'Cover of ${data.title}')));
  }

  /// Warm the Continue chapter's manifest once the sheet first settles.
  void warm(String? chapterKey) {
    if (_warmed) return;
    _warmed = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) warmContinue(ref, data, chapterKey);
    });
  }

  /// Downloads every unsaved chapter.
  void downloadSeries() => fire(enqueueSeriesChapters(ref, data, [for (final c in data.chapters) c.id]));

  Widget _below() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if ((data.series.description ?? '').isNotEmpty) ...[SeriesDescription(text: data.series.description!), const SizedBox(height: 16)],
          if (layout == SeriesLayout.desktop) const SizedBox.shrink() else ...[OfficialLinks(data: data), const SizedBox(height: 12)],
          SeriesDownloadCard(data: data),
          const SizedBox(height: 8),
          PreviouslyOnRow(data: data),
          const SizedBox(height: 8),
          MoreLikeThisRail(sourceId: data.sourceId, seriesKey: data.seriesKey, title: data.title),
          const SizedBox(height: 8),
        ],
      );

  List<Widget> _chapterSlivers() => [
        PinnedHeaderSliver(child: ChaptersHeader(data: data, chapters: chapters, onSelect: toggleSelect)),
        if (data.chapters.length > 50) SliverToBoxAdapter(child: GoToField(data: data, chapters: chapters, onJump: jumpTo)),
        if (chapters.selection.isActive) SliverToBoxAdapter(child: SelectHelpers(data: data, chapters: chapters)),
        ...widget.variant.chapterSlivers(context, this),
        const SliverToBoxAdapter(child: SizedBox(height: 160)),
      ];

  @override
  Widget build(BuildContext context) {
    watchRun(ref, data, chapters);
    final size = MediaQuery.sizeOf(context);
    final l = layout;
    final margin = GlassFrame.screenMargin(context);
    final bandH = l == SeriesLayout.desktop ? 240.0 : 280.0;
    final route = ModalRoute.of(context);
    final leading = route is GlassSheetRoute || route is GlassFormRoute ? null : GlassBackChevron(onTap: () => seriesBack(ref, sourceId: data.followed == null ? data.sourceId : null));
    final band = GlassFollowRing(
      controller: ring,
      child: KeyedSubtree(key: bandKey, child: SeriesBand(data: data, height: bandH + (leading == null ? 0 : MediaQuery.paddingOf(context).top), topInset: leading == null ? 0 : MediaQuery.paddingOf(context).top, leading: leading, onMore: openMenu)),
    );
    final offline = !isOnline(ref);

    Widget scroll;
    Widget? left;
    if (l == SeriesLayout.desktop) {
      final cols = math.min(960.0, size.width - (route is GlassFormRoute ? 48 : 0));
      final rightW = math.min(544.0, cols - 352 - 32);
      scroll = CustomScrollView(
        controller: _own,
        slivers: [
          SliverToBoxAdapter(child: band),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(352 + 32, 24, 32, 0),
            sliver: SliverConstrainedCrossAxis(maxExtent: rightW, sliver: SliverToBoxAdapter(child: _below())),
          ),
          SliverPadding(padding: const EdgeInsets.only(left: 352 + 16), sliver: SliverConstrainedCrossAxis(maxExtent: rightW + 32, sliver: SliverMainAxisGroup(slivers: _chapterSlivers()))),
        ],
      );
      left = ValueListenableBuilder<double>(
        valueListenable: leftTop,
        builder: (context, top, child) => Positioned(key: const ValueKey('series-left-column'), left: 32, top: top, width: 320, bottom: 24, child: child!),
        child: SingleChildScrollView(
          primary: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              widget.variant.header(context, this),
              const SizedBox(height: 16),
              OfficialLinks(data: data),
            ],
          ),
        ),
      );
    } else {
      scroll = CustomScrollView(
        controller: inSheet ? null : _own,
        slivers: [
          SliverToBoxAdapter(child: band),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: margin),
            sliver: SliverToBoxAdapter(child: Transform.translate(offset: const Offset(0, -96), child: widget.variant.header(context, this))),
          ),
          SliverPadding(padding: EdgeInsets.symmetric(horizontal: margin), sliver: SliverToBoxAdapter(child: Transform.translate(offset: const Offset(0, -80), child: _below()))),
          ..._chapterSlivers(),
        ],
      );
    }

    final count = data.chapters.length;
    if (count > 200 && !data.novel) {
      // ponytail: the phone sheet's scroll controller is the sheet's shared primary one, which the fast-scroll thumb cannot own;
      // the thumb shows on the full page and the windows only. Give the sheet its own controller hand-off if owners want it there.
      final ScrollController? ctl = inSheet ? null : _own;
      if (ctl != null) {
        final shown = shownChapters(data, chapters.order);
        scroll = GlassFastScroll(
          controller: ctl,
          itemCount: count,
          rowExtent: chapterRowExtent(hasSecondary: false, textScale: rowTextScale(context)),
          labelAt: (i) => chapterNum(shown[i.clamp(0, count - 1)].number) ?? '·',
          semanticsLabel: 'Chapter fast scroll',
          child: scroll,
        );
      }
    }

    final page = SeriesKeys(
      commands: commands,
      onEscape: escape,
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            Positioned.fill(child: scroll),
            if (left != null) left,
            if (inSheet) Positioned(top: 0, left: 0, right: 0, child: CollapseCapsule(data: data)),
            if (offline) const Positioned(top: 12, left: 0, right: 0, child: Center(child: SeriesOfflineCapsule())),
            ChapterSelectToolbar(data: data, chapters: chapters),
          ],
        ),
      ),
    );
    if (l != SeriesLayout.desktop || route is GlassFormRoute) return page;
    return Align(alignment: Alignment.topCenter, child: SizedBox(width: math.min(960.0, size.width), child: page));
  }
}

/// The back chevron of the full page (nothing beneath).
class GlassBackChevron extends StatelessWidget {
  const GlassBackChevron({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) =>
      GlassIconButton(key: const ValueKey('series-back'), icon: GlassButtonIcon(GlassGlyph28.caretLeft.regular), label: 'Back', kind: GlassIconButtonKind.nav, onPressed: onTap);
}

/// The nav row's title capsule on phones (glass 8.12 Collapsing header): a 24 px cover thumbnail and the title, driven 1:1 by the
/// sheet offset between `medium` (hidden) and `large` (shown).
class CollapseCapsule extends StatelessWidget {
  const CollapseCapsule({super.key, required this.data});
  final GlassSeriesData data;

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route is! GlassSheetRoute) return const SizedBox.shrink();
    final ctl = route.sheetController;
    return ListenableBuilder(
      listenable: ctl,
      builder: (context, _) {
        final m = ctl.metrics;
        if (m == null) return const SizedBox.shrink();
        final vh = m.viewportSize.height;
        final large = sheetLargePx(vh, MediaQuery.paddingOf(context).top);
        final medium = sheetDetentPx(GlassDetent.medium, viewport: vh, large: large);
        final p = collapseProgress(vh - m.offset, vh - medium, vh - large);
        if (p <= 0.01) return const SizedBox.shrink();
        return IgnorePointer(
          child: Opacity(
            key: const ValueKey('series-collapse-capsule'),
            opacity: p,
            child: Container(
              height: 44,
              margin: const EdgeInsets.fromLTRB(56, 4, 56, 0),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: ShapeDecoration(color: gt.colorFill2, shape: const StadiumBorder()),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(4), child: SizedBox(width: 24, height: 36 * p.clamp(0.66, 1.0), child: HomeCoverImage(url: data.series.coverUrl, width: 24))),
                  const SizedBox(width: 8),
                  Flexible(child: GlassLabel(data.title, role: gt.typeHeadline, onGlass: true)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The page's progress value, for the sheet's opening detent and the warm-up.
SeriesResume resumeFor(WidgetRef ref, GlassSeriesData d) => seriesResume(d.readingOrder, ref.watch(sourceSeriesProgressProvider(d.progressKey)), novel: d.novel);
