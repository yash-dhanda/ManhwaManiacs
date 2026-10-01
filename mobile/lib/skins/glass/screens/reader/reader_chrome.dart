import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart' show Material, MaterialType, TextField, InputDecoration, InputBorder;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_state.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/ambient/cruise.dart' show formatSpeed;
import 'package:manhwamaniacs/skins/glass/ambient/cruise_pill.dart';
import 'package:manhwamaniacs/skins/glass/ambient/rain_on_glass.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/glass/light_angle.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/glass/motion.dart';
import 'package:manhwamaniacs/skins/glass/motion_names.g.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/scrub_rail.dart';
import 'package:manhwamaniacs/skins/glass/primitives/slider.dart';
import 'package:manhwamaniacs/skins/glass/primitives/status_capsule.dart';
import 'package:manhwamaniacs/skins/glass/primitives/tooltip.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/band_lb.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/page_thumb.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/page_tint_chrome.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/reader_download.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/reader_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/reader_host.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/reader_more_menu.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/reader_system_ui.dart';
import 'package:manhwamaniacs/skins/glass/shell/bar_icon.dart';
import 'package:manhwamaniacs/skins/glass/shell/glass_back_button.dart';
import 'package:manhwamaniacs/skins/glass/shell/nav_row.dart' show statusCapsuleWidth;
import 'package:manhwamaniacs/skins/glass/shell/shell_common.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The positions every chrome element derives from (glass 8.14.11 "Reader system UI", B3 of mobile/35).
class ReaderChromeGeometry {
  ReaderChromeGeometry.of(BuildContext context, {required this.column})
      : size = MediaQuery.sizeOf(context),
        inset = GlassReaderInsets.of(context),
        side = math.max(44.0, GlassFrame.hitMin(context)),
        hit = GlassFrame.hitMin(context),
        gestureBottom = MediaQuery.systemGestureInsetsOf(context).bottom;

  final Size size;
  final EdgeInsets inset;

  /// The strip column the bottom capsule centres on.
  final Rect column;
  final double side, hit, gestureBottom;

  double get top => inset.top + 8;
  double get left => math.max(inset.left, 16);
  double get right => math.max(inset.right, 16);

  /// Distance from the bottom edge of the bottom capsule, the pill and the match capsule.
  double get bottom => math.max(inset.bottom, gestureBottom) + 16;

  bool get landscapePhone => size.shortestSide < 600 && size.width > size.height;
}

/// The Glass manga reader's chrome (glass 8.14.2), built by the engine's `chromeBuilder`: the two top groups (one layer), the
/// bottom capsule that minimises into the pill, the scrub rail, the go-to-page popover, the zoom and seam chips, the micro-progress
/// line of cinema mode and the lock pulse. Every surface is `glassRegular` with the legibility dim and the page tint.
class GlassReaderChrome extends ConsumerStatefulWidget {
  const GlassReaderChrome({super.key, required this.host, required this.state, required this.column});
  final GlassReaderHost host;
  final ReaderEngineState state;
  final Rect column;

  @override
  ConsumerState<GlassReaderChrome> createState() => _GlassReaderChromeState();
}

class _GlassReaderChromeState extends ConsumerState<GlassReaderChrome> with TickerProviderStateMixin {
  late final AnimationController _shown = AnimationController(vsync: this, value: widget.state.chromeVisible ? 1 : 0);
  late final AnimationController _pill = AnimationController(vsync: this, value: widget.state.chromeVisible ? 0 : 1);
  Timer? _cinemaIdle;
  bool _pillGone = false;

  @override
  void didUpdateWidget(GlassReaderChrome old) {
    super.didUpdateWidget(old);
    final v = widget.state.chromeVisible;
    if (v != old.state.chromeVisible) {
      unawaited(GlassMotion.play(v ? MotionName.materialise : MotionName.dematerialise, controller: _shown, target: v ? 1 : 0));
      unawaited(GlassMotion.play(MotionName.minimise, controller: _pill, target: v ? 0 : 1));
    }
    _syncCinema();
  }

  @override
  void initState() {
    super.initState();
    _syncCinema();
  }

  /// Cinema mode: the pill hides too after 3 s idle with the chrome hidden.
  void _syncCinema() {
    final want = widget.host.cinema && !widget.state.chromeVisible;
    if (!want) {
      _cinemaIdle?.cancel();
      _cinemaIdle = null;
      if (_pillGone) setState(() => _pillGone = false);
      return;
    }
    _cinemaIdle ??= Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _pillGone = true);
    });
  }

  @override
  void dispose() {
    _cinemaIdle?.cancel();
    _shown.dispose();
    _pill.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final host = widget.host;
    final s = widget.state;
    final g = ReaderChromeGeometry.of(context, column: widget.column);
    final visible = s.chromeVisible;
    // One tween per chrome root; transparent stands for "no tint" (a tween needs an end).
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: host.tint ?? const Color(0x00000000)),
      // Reduce Motion: tint changes cross-fade over 200 ms linear (glass 4.11).
      duration: host.reducedMotion ? const Duration(milliseconds: 200) : gt.curveTintShift.duration,
      curve: host.reducedMotion ? Curves.linear : gt.curveTintShift.curve,
      builder: (context, tint, _) {
        final t = host.pageTinted && tint != null && tint.a > 0.01 ? tint.withValues(alpha: 1) : null;
        return RainOnGlassHost(
          active: host.rainOn && visible,
          light: ref.watch(glassLightAngleProvider).valueOrNull ?? kLightAngleRest,
          child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Soft edges, fading with the chrome, tinted at 30 %.
            _SoftEdges(shown: _shown, tint: t, top: g.top + g.side + 24, bottom: g.bottom + 56 + 24),
            if (g.landscapePhone)
              ..._landscape(context, g, s, t, visible)
            else
              ..._portrait(context, g, s, t, visible),
            if (host.zoomChipPercent != null)
              Positioned(top: g.top, left: 0, right: 0, child: Center(child: _Chip(text: '${host.zoomChipPercent} %', lb: _lb(g, Rect.fromLTWH(0, g.top, 100, 32), s), tint: t))),
            if (host.seamChip != null)
              Positioned(top: g.top + g.side + 8, left: 0, right: 0, child: Center(
                  child: _SeamChip(
                      key: ValueKey(host.seamChip),
                      reduced: host.reducedMotion,
                      child: _Chip(text: host.seamChip!, lb: _lb(g, Rect.fromLTWH(0, g.top + g.side + 8, 100, 32), s), tint: t),),),),
            if (host.cinema && !host.hideCinemaProgress && !visible)
              Positioned(left: 0, right: 0, bottom: 0, height: 2, child: _MicroProgress(progress: s.progress, tint: t)),
            if (host.lockPulse > 0) Center(child: _LockPulse(key: ValueKey(host.lockPulse))),
          ],
          ),
        );
      },
    );
  }

  double _lb(ReaderChromeGeometry g, Rect r, ReaderEngineState s) => bandLb(r, g.size, widget.host.lbSample);

  /// Hidden chrome is out of focus, semantics and pointers (glass 8.14.2).
  Widget _live(bool visible, Widget child) =>
      ExcludeFocus(excluding: !visible, child: ExcludeSemantics(excluding: !visible, child: IgnorePointer(ignoring: !visible, child: child)));

  /// Dematerialise: lensing out, blur 8, scale 0.92 (the library's own lensing; here opacity, scale and blur).
  Widget _materialised(Widget child) => AnimatedBuilder(
        animation: _shown,
        child: child,
        builder: (context, child) {
          final v = _shown.value.clamp(0.0, 1.0);
          if (v >= 1) return child!;
          return Opacity(
            opacity: v,
            child: Transform.scale(
              scale: 0.92 + 0.08 * v,
              child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 8 * (1 - v), sigmaY: 8 * (1 - v)), child: child),
            ),
          );
        },
      );

  List<Widget> _portrait(BuildContext context, ReaderChromeGeometry g, ReaderEngineState s, Color? t, bool visible) {
    final host = widget.host;
    final topLb = bandLb(Rect.fromLTWH(0, g.top, g.size.width, g.side), g.size, host.lbSample);
    final bottomRect = Rect.fromLTWH(0, g.size.height - g.bottom - 56, g.size.width, 56);
    final bottomLb = bandLb(bottomRect, g.size, host.lbSample);
    final railTop = g.top + g.side + 16;
    final railBottom = g.bottom + 56 + 16;
    final railH = math.max(0.0, g.size.height - railTop - railBottom);
    return [
      Positioned(
        left: g.left,
        right: g.right,
        top: g.top,
        child: _live(visible, _materialised(_TopGroups(host: host, state: s, g: g, lb: topLb, tint: t))),
      ),
      if (s.pageCount > 1 && railH > 80)
        Positioned(
          right: g.right - (g.hit - 3) / 2,
          top: railTop,
          height: railH,
          child: _live(visible, _materialised(_Rail(host: host, state: s, height: railH, railTop: railTop))),
        ),
      // The match capsule takes the bottom line while the hit lens shows.
      if (!_pillGone && !host.matchesShown && !host.guidedOn)
        Positioned(
          left: widget.column.left,
          width: widget.column.width,
          bottom: g.bottom,
          height: 56,
          child: Center(child: _BottomCapsule(host: host, state: s, pill: _pill, visible: visible, lb: bottomLb, tint: t, maxWidth: math.min(520, widget.column.width - 32))),
        ),
      if (host.goToOpen)
        Positioned.fill(child: _GoToLayer(host: host, state: s, g: g, tint: t)),
    ];
  }

  List<Widget> _landscape(BuildContext context, ReaderChromeGeometry g, ReaderEngineState s, Color? t, bool visible) {
    final host = widget.host;
    final topLb = bandLb(Rect.fromLTWH(0, g.top, g.size.width, g.side), g.size, host.lbSample);
    return [
      Positioned(
        left: g.left,
        right: g.right,
        top: g.top,
        child: _live(visible, _materialised(_TopGroups(host: host, state: s, g: g, lb: topLb, tint: t, landscape: true))),
      ),
      if (s.pageCount > 1)
        Positioned(
          left: g.left,
          right: g.right,
          bottom: math.max(g.inset.bottom, 8),
          height: g.hit,
          child: _live(visible, _materialised(LandscapeScrubRail(host: host, state: s))),
        ),
      // A running cruise shows its pill above the rail's trailing end (glass 8.14.11).
      if (host.cruiseAvailable && host.cruise.running)
        Positioned(
          right: math.max(g.inset.right, 16),
          bottom: math.max(g.inset.bottom, 8) + g.hit + 8,
          child: _live(
            visible,
            _LandscapeCruise(host: host, lb: bandLb(Rect.fromLTWH(g.size.width - 140, g.size.height - 120, 124, 44), g.size, host.lbSample), tint: t),
          ),
        ),
      if (host.goToOpen) Positioned.fill(child: _GoToLayer(host: host, state: s, g: g, tint: t)),
    ];
  }
}

/// The landscape cruise pill in its own capsule of glass.
class _LandscapeCruise extends StatelessWidget {
  const _LandscapeCruise({required this.host, required this.lb, required this.tint});
  final GlassReaderHost host;
  final double lb;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final text = formatSpeed(host.cruise.speed);
    final w = 16 + 20 + 6 + measureText(context, text, roleStyle(context, gt.typeMono, onGlass: true)).width + 16;
    return SkinGlass(
      size: Size(w, math.max(44.0, GlassFrame.hitMin(context))),
      tier: GlassTierId.t3,
      lb: lb,
      tint: tint,
      rimTint: tint == null ? null : rimTint(tint!),
      debugLabel: 'reader cruise pill',
      child: CruisePill(
        state: host.cruise,
        onToggle: host.toggleCruise,
        onResume: host.cruiseResume,
        onPreview: host.cruisePreview,
        onCommit: host.cruiseCommit,
        onStep: host.cruiseStep,
        reduced: host.reducedMotion,
        lb: lb,
        tint: tint,
      ),
    );
  }
}

class _SoftEdges extends StatelessWidget {
  const _SoftEdges({required this.shown, required this.tint, required this.top, required this.bottom});
  final Animation<double> shown;
  final Color? tint;
  final double top, bottom;

  @override
  Widget build(BuildContext context) {
    final c = tint == null ? const Color(0xFF000000) : Color.lerp(const Color(0xFF000000), tint, PageTint.edge)!;
    Widget edge(Alignment from, double h) => IgnorePointer(
          child: SizedBox(
            height: h,
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: LinearGradient(begin: from, end: -from, colors: [c.withValues(alpha: 0.55), c.withValues(alpha: 0)])),
            ),
          ),
        );
    return Positioned.fill(
      child: FadeTransition(
        opacity: shown,
        child: Column(children: [edge(Alignment.topCenter, top), const Spacer(), edge(Alignment.bottomCenter, bottom)]),
      ),
    );
  }
}

/// The two top groups (glass 8.14.2), one `SkinGlassGroup` layer: back with the depth glyph and the title capsule on the left;
/// the compact download control, bookmark and settings on the right (landscape: the page capsule and bookmark, settings, more).
class _TopGroups extends ConsumerWidget {
  const _TopGroups({required this.host, required this.state, required this.g, required this.lb, required this.tint, this.landscape = false});
  final GlassReaderHost host;
  final ReaderEngineState state;
  final ReaderChromeGeometry g;
  final double lb;
  final Color? tint;
  final bool landscape;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final side = g.side;
    final avail = g.size.width - g.left - g.right;
    final title = '${host.seriesTitle} · ${host.chapterShort(state.chapterId)}';
    final readAllText = state.readAll == null ? null : '${state.readAll!.index} of ${state.readAll!.total}';
    final style = roleStyle(context, gt.typeSubhead, onGlass: true, wght: 600);
    final mono = roleStyle(context, gt.typeMono, onGlass: true);
    final textW = measureText(context, title, style).width + (readAllText == null ? 0 : measureText(context, readAllText, mono).width + 8);
    final focus = host.guidedAvailable || host.guidedOn;
    final trailingCount = (landscape ? 3 : 2) + (focus ? 1 : 0);
    // The chapter part of the title always shows; on a narrow phone the download control gives way first.
    final chapterW = measureText(context, ' · ${host.chapterShort(state.chapterId)}', style).width;
    final minTitle = chapterW + 32 + 48;
    var download = landscape ? null : ReaderDownloadControl.widthFor(context, ref, host, state.chapterId, side);
    final fixedW = side + 8 + (2 * side + 8) + 8 + (host.offline ? 88 : 0);
    if (download != null && avail - fixedW - download - 8 < minTitle) download = null;
    final pageText = '${state.page} / ${state.pageCount}';
    final pageW = landscape ? measureText(context, pageText, mono).width + 32 : 0.0;
    final trailingW = trailingCount * side + (trailingCount - 1) * 8 + (download ?? 0) + (download == null ? 0 : 8);
    final maxTitle = landscape ? avail * 0.4 : avail - side - 8 - trailingW - 8 - (host.offline ? 88 : 0);
    final titleW = (textW + 32).clamp(math.min(minTitle, math.max(56.0, maxTitle)), math.max(56.0, maxTitle)).toDouble();

    final shapes = <SkinGlassShape>[
      SkinGlassShape(size: Size(side, side), shape: const GlassShape.circle(), child: const GlassBackButton(inGroup: true, showDepth: true)),
      SkinGlassShape(
        size: Size(titleW, side),
        child: _TitleCapsule(series: host.seriesTitle, chapter: host.chapterShort(state.chapterId), readAll: readAllText, onTap: host.openSeries, onLongPress: host.openChapterList),
      ),
      if (host.offline)
        SkinGlassShape(size: Size(statusCapsuleWidth(context, 'Offline'), 36), child: const GlassStatusCapsule(kind: GlassStatusKind.offline, inGroup: true)),
      if (landscape)
        SkinGlassShape(size: Size(pageW, side), child: _PageReadout(text: pageText, page: state.page, count: state.pageCount, onTap: () => host.setGoTo(true))),
      if (download != null)
        SkinGlassShape(size: Size(download, side), child: ReaderDownloadControl(host: host, chapterId: state.chapterId)),
      SkinGlassShape(
        size: Size(trailingCount * side + (trailingCount - 1) * 8, side),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (focus) ...[
              GlassBarIcon(icon: roleIcon(GlassIconRole.guidedView), label: host.guidedOn ? 'Close guided view' : 'Guided view', toggled: host.guidedOn, onPressed: host.toggleGuided),
              const SizedBox(width: 8),
            ],
            _BookmarkButton(saved: state.bookmarks.isNotEmpty, onPressed: host.toggleBookmark),
            const SizedBox(width: 8),
            GlassBarIcon(icon: roleIcon(GlassIconRole.readerSettings), label: 'Reader settings', onPressed: host.openSettings),
            if (landscape) ...[
              const SizedBox(width: 8),
              Builder(builder: (c) => GlassBarIcon(icon: GlassButtonIcon.glyph(GlassGlyph.dotsThree), label: 'More', onPressed: () => _more(c))),
            ],
          ],
        ),
      ),
    ];
    final aligns = [
      Alignment.centerLeft,
      Alignment.centerLeft,
      if (host.offline) Alignment.centerLeft,
      if (landscape) Alignment.centerRight,
      if (download != null) Alignment.centerRight,
      Alignment.centerRight,
    ];
    return RainOnGlass(
      radius: BorderRadius.circular(side / 2),
      child: SizedBox(
        height: side,
        child: _GroupRow(
          shapes: shapes,
          aligns: aligns,
          lb: lb,
          tint: tint,
          leftCount: host.offline ? 3 : 2,
        ),
      ),
    );
  }

  /// The landscape ... menu: Download, Cruise, Previous chapter, Next chapter.
  void _more(BuildContext c) => unawaited(presentReaderMore(c, host, state));
}

/// Places a left run and a right run of shapes in one group layer.
class _GroupRow extends StatelessWidget {
  const _GroupRow({required this.shapes, required this.aligns, required this.lb, required this.tint, required this.leftCount});
  final List<SkinGlassShape> shapes;
  final List<Alignment> aligns;
  final double lb;
  final Color? tint;
  final int leftCount;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        // Offsets: the left run packs from the left edge, the right run from the right edge, 8 px apart.
        final offsets = <Offset>[];
        var x = 0.0;
        for (var i = 0; i < leftCount; i++) {
          offsets.add(Offset(x, (c.maxHeight - shapes[i].size.height) / 2));
          x += shapes[i].size.width + 8;
        }
        var r = c.maxWidth;
        final right = <Offset>[];
        for (var i = shapes.length - 1; i >= leftCount; i--) {
          r -= shapes[i].size.width;
          right.insert(0, Offset(r, (c.maxHeight - shapes[i].size.height) / 2));
          r -= 8;
        }
        offsets.addAll(right);
        // One layer for both groups (glass 2.4.1): each shape placed by its alignment inside the full-width group.
        final w = c.maxWidth;
        return SkinGlassGroup(
          shapes: shapes,
          aligns: [
            for (var i = 0; i < shapes.length; i++)
              Alignment(w - shapes[i].size.width <= 0 ? -1 : offsets[i].dx / (w - shapes[i].size.width) * 2 - 1, 0),
          ],
          height: c.maxHeight,
          lb: lb,
          tint: tint,
          rimTint: tint == null ? null : rimTint(tint!),
          debugLabel: 'reader top groups',
        );
      },);
}

class _TitleCapsule extends StatelessWidget {
  const _TitleCapsule({required this.series, required this.chapter, required this.readAll, required this.onTap, required this.onLongPress});
  final String series, chapter;
  final String? readAll;
  final VoidCallback onTap, onLongPress;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '$series · $chapter',
        hint: 'Opens the series; hold for the chapter list',
        excludeSemantics: true,
        onTap: onTap,
        onLongPress: onLongPress,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            // One line while "series · chapter" fits; otherwise two compact lines (the series over the chapter), so the series keeps
            // its whole width instead of collapsing to "Tower…" beside the chapter.
            child: LayoutBuilder(builder: (context, c) {
              final one = measureText(context, '$series · $chapter', roleStyle(context, gt.typeSubhead, onGlass: true, wght: 600, maxScale: 1.3)).width;
              if (readAll != null || one <= c.maxWidth) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // The series name gives way first; the chapter always shows (the capsule's minimum fits it).
                    Flexible(flex: 3, child: GlassText(series, role: gt.typeSubhead, wght: 600, onGlass: true, maxLines: 1, overflow: TextOverflow.ellipsis, maxScale: 1.3)),
                    GlassText(' · $chapter', role: gt.typeSubhead, wght: 600, onGlass: true, maxLines: 1, maxScale: 1.3),
                    if (readAll != null) ...[const SizedBox(width: 8), Flexible(child: GlassText(readAll!, role: gt.typeMono, onGlass: true, maxLines: 1, overflow: TextOverflow.ellipsis, maxScale: 1.3))],
                  ],
                );
              }
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GlassText(series, role: gt.typeFootnote, wght: 600, onGlass: true, maxLines: 1, overflow: TextOverflow.ellipsis, maxScale: 1.15),
                  GlassText(chapter, role: gt.typeCaption1, onGlass: true, maxLines: 1, maxScale: 1.15),
                ],
              );
            },),
          ),
        ),
      );
}

class _BookmarkButton extends StatelessWidget {
  const _BookmarkButton({required this.saved, required this.onPressed});
  final bool saved;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => GlassBarIcon(
        icon: saved ? GlassButtonIcon(GlassGlyph.bookmarkSimple.fill) : roleIcon(GlassIconRole.bookmark),
        label: 'Bookmark',
        toggled: saved,
        onPressed: onPressed,
        iconBuilder: saved ? (c) => Icon(GlassGlyph.bookmarkSimple.fill, size: 22, color: gt.colorIris400) : null,
      );
}

class _PageReadout extends StatelessWidget {
  const _PageReadout({required this.text, required this.page, required this.count, required this.onTap});
  final String text;
  final int page, count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Page $page of $count, go to page',
        excludeSemantics: true,
        onTap: onTap,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Center(child: GlassText(text, role: gt.typeMono, onGlass: true)),
        ),
      );
}

/// At text scale above 1.3 the cruise button leaves the capsule for the first row of the reader settings sheet (glass 3.3 rule 4).
bool _cruiseInSheet(BuildContext context) => MediaQuery.textScalerOf(context).scale(17) / 17 > 1.3;

/// The bottom capsule (56 tall, at most 520 wide) and the pill it minimises into (32 tall, "18 / 40" only).
class _BottomCapsule extends StatelessWidget {
  const _BottomCapsule({
    required this.host,
    required this.state,
    required this.pill,
    required this.visible,
    required this.lb,
    required this.tint,
    required this.maxWidth,
  });
  final GlassReaderHost host;
  final ReaderEngineState state;
  final Animation<double> pill;
  final bool visible;
  final double lb;
  final Color? tint;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final text = '${state.page} / ${state.pageCount}';
    final pillW = measureText(context, text, roleStyle(context, gt.typeMono, onGlass: true)).width + 32;
    final side = math.max(44.0, GlassFrame.hitMin(context));
    return AnimatedBuilder(
      animation: pill,
      builder: (context, _) {
        final m = pill.value.clamp(0.0, 1.0);
        final w = maxWidth + (pillW - maxWidth) * m;
        final h = 56 + (32 - 56) * m;
        final full = Row(
          children: [
            _CapsuleIcon(
              icon: roleIcon(GlassIconRole.chapterPrevious),
              label: 'Previous chapter',
              onPressed: state.hasPrevious ? host.previousChapter : null,
              side: side,
            ),
            Expanded(child: _PageReadout(text: text, page: state.page, count: state.pageCount, onTap: () => host.setGoTo(true))),
            if (host.cruiseAvailable && !_cruiseInSheet(context))
              CruisePill(
                state: host.cruise,
                onToggle: host.toggleCruise,
                onResume: host.cruiseResume,
                onPreview: host.cruisePreview,
                onCommit: host.cruiseCommit,
                onStep: host.cruiseStep,
                reduced: host.reducedMotion,
                lb: lb,
                tint: tint,
              ),
            GlassTooltip(
              message: host.nextChapterLabel ?? 'No next chapter',
              child: _CapsuleIcon(
                icon: roleIcon(GlassIconRole.chapterNext),
                label: 'Next chapter',
                onPressed: state.hasNext ? host.nextChapter : null,
                side: side,
              ),
            ),
          ],
        );
        return RainOnGlass(
          radius: BorderRadius.circular(h / 2),
          child: SkinGlass(
          size: Size(w, h),
          tier: GlassTierId.t3,
          lb: lb,
          tint: tint,
          rimTint: tint == null ? null : rimTint(tint!),
          debugLabel: 'reader bottom capsule',
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (m < 1)
                Opacity(
                  opacity: (1 - m * 2).clamp(0.0, 1.0),
                  child: ExcludeFocus(
                    excluding: !visible,
                    child: ExcludeSemantics(excluding: !visible, child: IgnorePointer(ignoring: !visible, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: full))),
                  ),
                ),
              // The minimised pill's inner glow: a 12 px blurred inset glow of the tint at 30 % (glass 9.4.4).
              if (m > 0 && tint != null) Positioned.fill(child: IgnorePointer(child: Opacity(opacity: m, child: CustomPaint(painter: _InnerGlow(tint!.withValues(alpha: PageTint.edge)))))),
              if (m > 0)
                Opacity(
                  opacity: ((m - 0.5) * 2).clamp(0.0, 1.0),
                  child: Center(child: GlassText(text, role: gt.typeMono, onGlass: true)),
                ),
              // The 2 px progress hairline inside the bottom edge, following on springTrack.
              Positioned(
                left: 16,
                right: 16,
                bottom: 3,
                height: 2,
                child: _Hairline(progress: state.progress, color: Color.lerp(gt.colorIris500, tint ?? gt.colorIris500, m * PageTint.edge)!.withValues(alpha: 0.8)),
              ),
            ],
          ),
          ),
        );
      },
    );
  }
}

/// A 12 px blurred inset glow along the capsule's edge.
class _InnerGlow extends CustomPainter {
  const _InnerGlow(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rr = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(size.height / 2));
    canvas
      ..save()
      ..clipRRect(rr)
      ..drawRRect(rr, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 12..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6))
      ..restore();
  }

  @override
  bool shouldRepaint(_InnerGlow old) => old.color != color;
}

class _CapsuleIcon extends StatelessWidget {
  const _CapsuleIcon({required this.icon, required this.label, required this.onPressed, required this.side});
  final GlassButtonIcon icon;
  final String label;
  final VoidCallback? onPressed;
  final double side;

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: onPressed == null ? 0.3 : 1,
        child: SizedBox(width: side, height: side, child: GlassBarIcon(icon: icon, label: label, onPressed: onPressed)),
      );
}

class _Hairline extends StatelessWidget {
  const _Hairline({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(end: progress),
        duration: const Duration(milliseconds: 160),
        builder: (context, v, _) => Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(widthFactor: v.clamp(0.0, 1.0), child: ColoredBox(color: color)),
        ),
      );
}

class _MicroProgress extends StatelessWidget {
  const _MicroProgress({required this.progress, required this.tint});
  final double progress;
  final Color? tint;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            child: ColoredBox(color: (tint == null ? gt.colorIris500 : rimTint(tint!)).withValues(alpha: 0.8)),
          ),
        ),
      );
}

/// A `glassThin` capsule (the zoom chip, the seam chip).
class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.lb, required this.tint});
  final String text;
  final double lb;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final w = measureText(context, text, roleStyle(context, gt.typeFootnote, onGlass: true, wght: 600)).width + 32;
    return IgnorePointer(
      child: SkinGlass(
        size: Size(w, 32),
        tier: GlassTierId.t2,
        lb: lb,
        tint: tint,
        layer: GlassLayerKind.overlays,
        debugLabel: 'reader chip',
        child: Center(child: GlassText(text, role: gt.typeFootnote, wght: 600, onGlass: true)),
      ),
    );
  }
}

/// The Seam chip move (glass 4.10): materialises on `seamChip`, holds, and dematerialises so it is gone at 1,200 ms, when the
/// host removes it; reduced motion swaps both for 150 ms fades.
class _SeamChip extends StatefulWidget {
  const _SeamChip({super.key, required this.reduced, required this.child});
  final bool reduced;
  final Widget child;

  @override
  State<_SeamChip> createState() => _SeamChipState();
}

class _SeamChipState extends State<_SeamChip> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  Timer? _out;

  @override
  void initState() {
    super.initState();
    unawaited(GlassMotion.play(MotionName.seamChip, controller: _c, target: 1));
    _out = Timer(Duration(milliseconds: widget.reduced ? 1050 : 850), () {
      if (mounted) unawaited(GlassMotion.play(MotionName.dematerialise, controller: _c, target: 0));
    });
  }

  @override
  void dispose() {
    _out?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (context, child) {
          final t = _c.value.clamp(0.0, 1.0);
          if (widget.reduced) return Opacity(opacity: t, child: child);
          return Opacity(opacity: t, child: Transform.scale(scale: 0.92 + 0.08 * t, child: child));
        },
      );
}

class _LockPulse extends StatefulWidget {
  const _LockPulse({super.key});

  @override
  State<_LockPulse> createState() => _LockPulseState();
}

class _LockPulseState extends State<_LockPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: FadeTransition(
          opacity: ReverseAnimation(_c),
          child: Icon(ReaderGlyph.lock.fill, size: 28, color: const Color(0xFFFFFFFF)),
        ),
      );
}

/// The scrub rail on the trailing edge (the `mobile/27` primitive); read-all segments the loaded window by chapter.
class _Rail extends StatelessWidget {
  const _Rail({required this.host, required this.state, required this.height, required this.railTop});
  final GlassReaderHost host;
  final ReaderEngineState state;
  final double height, railTop;

  @override
  Widget build(BuildContext context) {
    final count = state.pageCount;
    final page = (state.page - 1).clamp(0, count - 1);
    final rail = _scrubRail(count, page);
    if (!host.cruise.running) return rail;
    // While cruising the trailing-edge drag changes the speed instead of scrubbing (glass 9.4.1).
    return Stack(
      children: [
        IgnorePointer(child: rail),
        Positioned.fill(
          child: CruiseRailStrip(speed: host.cruise.speed, onPreview: host.cruisePreview, onCommit: host.cruiseCommit, child: const SizedBox.expand()),
        ),
      ],
    );
  }

  Widget _scrubRail(int count, int page) {
    return Listener(
      onPointerDown: (e) => host.scrubbing(true, thumbY: railTop + e.localPosition.dy),
      onPointerMove: (e) => host.scrubbing(true, thumbY: railTop + e.localPosition.dy),
      onPointerUp: (_) => host.scrubbing(false),
      onPointerCancel: (_) => host.scrubbing(false),
      child: GlassScrubRail(
        pageCount: count,
        page: page,
        height: height,
        bookmarks: [for (final b in state.bookmarks) b.page - 1],
        onCommit: (p) => host.jumpTo(p + 1),
        renderPreview: (p) => ReaderPageThumb(page: host.pageOf(state.chapterId, p + 1)),
      ),
    );
  }
}

/// The landscape phone's bottom rail (glass 8.14.11 "Landscape phone"): a hit strip along the bottom edge, a 3 px track and a
/// 12 px thumb; the 120 x 164 magnifier sits above the thumb while dragging.
class LandscapeScrubRail extends ConsumerStatefulWidget {
  const LandscapeScrubRail({super.key, required this.host, required this.state});
  final GlassReaderHost host;
  final ReaderEngineState state;

  @override
  ConsumerState<LandscapeScrubRail> createState() => _LandscapeScrubRailState();
}

class _LandscapeScrubRailState extends ConsumerState<LandscapeScrubRail> {
  int? _drag;

  int _pageAt(double x, double w) => ((x / w) * (widget.state.pageCount - 1)).round().clamp(0, widget.state.pageCount - 1);

  void _move(double x, double w) {
    final p = _pageAt(x, w);
    if (p != _drag) {
      glassFire(ref, p == 0 || p == widget.state.pageCount - 1 ? HapticEvent.scrubBoundary : HapticEvent.scrubTick);
      setState(() => _drag = p);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final shown = _drag ?? s.page - 1;
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final f = s.pageCount <= 1 ? 0.0 : shown / (s.pageCount - 1);
      return Semantics(
        slider: true,
        label: 'Page scrubber',
        value: 'Page ${shown + 1} of ${s.pageCount}',
        increasedValue: 'Page ${math.min(shown + 2, s.pageCount)} of ${s.pageCount}',
        decreasedValue: 'Page ${math.max(shown, 1)} of ${s.pageCount}',
        onIncrease: () => widget.host.jumpTo(math.min(s.pageCount, s.page + 1)),
        onDecrease: () => widget.host.jumpTo(math.max(1, s.page - 1)),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragDown: (d) {
            widget.host.scrubbing(true);
            _move(d.localPosition.dx, w);
          },
          onHorizontalDragUpdate: (d) => _move(d.localPosition.dx, w),
          onHorizontalDragEnd: (_) {
            final p = _drag;
            setState(() => _drag = null);
            widget.host.scrubbing(false);
            if (p != null) widget.host.jumpTo(p + 1);
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: c.maxHeight / 2 - (_drag == null ? 1.5 : 3),
                height: _drag == null ? 3 : 6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0x80FFFFFF),
                    border: Border.all(color: const Color(0x99000000)),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Align(alignment: Alignment.centerLeft, child: FractionallySizedBox(widthFactor: f, child: ColoredBox(color: gt.colorIris500))),
                ),
              ),
              Positioned(
                left: f * w - 6,
                top: c.maxHeight / 2 - 6,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: const Color(0xFFFFFFFF), shape: BoxShape.circle, border: Border.all(width: 1.5)),
                ),
              ),
              if (_drag != null)
                Positioned(
                  left: (f * w - 60).clamp(0.0, math.max(0.0, w - 120)),
                  bottom: c.maxHeight + 8,
                  child: SkinGlass(
                    size: const Size(120, 164),
                    tier: GlassTierId.t4,
                    shape: const GlassShape.superellipse(20),
                    layer: GlassLayerKind.overlays,
                    debugLabel: 'reader scrub lens',
                    child: Column(
                      children: [
                        Expanded(child: Padding(padding: const EdgeInsets.all(8), child: ReaderPageThumb(page: widget.host.pageOf(s.chapterId, shown + 1)))),
                        GlassText('${shown + 1}', role: gt.typeMonoLarge, onGlass: true),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },);
  }
}

/// The go-to-page popover (glass 8.14.2): blooms from the readout on `springMorph`, `glassThick`, 280 wide; the number well, the
/// page slider with the target's thumbnail while dragging, and Go. Rises by the keyboard height.
class _GoToLayer extends StatelessWidget {
  const _GoToLayer({required this.host, required this.state, required this.g, required this.tint});
  final GlassReaderHost host;
  final ReaderEngineState state;
  final ReaderChromeGeometry g;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.viewInsetsOf(context).bottom;
    return Stack(
      children: [
        Positioned.fill(child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => host.setGoTo(false))),
        AnimatedPositioned(
          duration: Duration(milliseconds: springOf(gt.springSnappy).duration.inMilliseconds.clamp(120, 400)),
          curve: Curves.easeOutCubic,
          left: (g.column.center.dx - 140).clamp(8.0, math.max(8.0, g.size.width - 288)),
          bottom: g.bottom + 56 + 12 + kb,
          child: GoToPagePopover(host: host, state: state, tint: tint),
        ),
      ],
    );
  }
}

class GoToPagePopover extends ConsumerStatefulWidget {
  const GoToPagePopover({super.key, required this.host, required this.state, this.tint});
  final GlassReaderHost host;
  final ReaderEngineState state;
  final Color? tint;

  @override
  ConsumerState<GoToPagePopover> createState() => _GoToPagePopoverState();
}

class _GoToPagePopoverState extends ConsumerState<GoToPagePopover> with SingleTickerProviderStateMixin {
  late final TextEditingController _text = TextEditingController();
  late final AnimationController _bloom = AnimationController(vsync: this);
  late double _slider = widget.state.page.toDouble();
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    unawaited(GlassMotion.play(MotionName.bloom, controller: _bloom, target: 1));
  }

  @override
  void dispose() {
    _text.dispose();
    _bloom.dispose();
    super.dispose();
  }

  void _go(int page) {
    widget.host.jumpTo(page.clamp(1, widget.state.pageCount));
    widget.host.setGoTo(false);
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.state.pageCount;
    final target = _slider.round();
    return ScaleTransition(
      scale: Tween<double>(begin: 0.6, end: 1).animate(_bloom),
      alignment: Alignment.bottomCenter,
      child: FadeTransition(
        opacity: _bloom,
        child: Focus(
          onKeyEvent: (node, e) {
            if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
              widget.host.setGoTo(false);
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: SkinGlass(
            size: Size(280, _dragging ? 236 : 140),
            tier: GlassTierId.t4,
            shape: const GlassShape.superellipse(22),
            tint: widget.tint,
            layer: GlassLayerKind.overlays,
            debugLabel: 'reader go to page',
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 96,
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(color: gt.colorWellOnGlass, borderRadius: BorderRadius.circular(12)),
                        alignment: Alignment.centerLeft,
                        child: Material(
                          type: MaterialType.transparency,
                          // The styles are already scaled and capped (roleStyle): the field must not scale them again.
      child: MediaQuery.withNoTextScaling(child: TextField(
                            key: const ValueKey('reader-goto-field'),
                            controller: _text,
                            autofocus: true,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            style: roleStyle(context, gt.typeMono, onGlass: true, size: 15),
                            decoration: InputDecoration(
                              isCollapsed: true,
                              border: InputBorder.none,
                              hintText: '${widget.state.page}',
                              hintStyle: roleStyle(context, gt.typeMono, onGlass: true, size: 15).copyWith(color: gt.colorLabel3),
                            ),
                            onSubmitted: (v) => _go(int.tryParse(v.trim()) ?? widget.state.page),
                          ),),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GlassText('/ $n', role: gt.typeMono, onGlass: true),
                      const Spacer(),
                      GlassButton(
                        label: 'Go',
                        onPressed: () => _go(int.tryParse(_text.text.trim()) ?? target),
                        variant: GlassButtonVariant.primary,
                        twin: GlassTwin.tinted,
                        size: GlassButtonSize.small,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_dragging)
                    SizedBox(
                      height: 96,
                      child: Row(
                        children: [
                          SizedBox(width: 64, height: 96, child: ReaderPageThumb(page: widget.host.pageOf(widget.state.chapterId, target))),
                          const SizedBox(width: 12),
                          GlassText('$target', role: gt.typeMonoLarge, onGlass: true),
                        ],
                      ),
                    ),
                  GlassSlider(
                    label: 'Page',
                    value: _slider,
                    min: 1,
                    max: math.max(2, n).toDouble(),
                    divisions: math.max(1, n - 1),
                    format: (v) => '${v.round()}',
                    onChanged: (v) {
                      if (v.round() != _slider.round()) glassFire(ref, HapticEvent.detentTick);
                      setState(() {
                        _slider = v;
                        _dragging = true;
                      });
                    },
                    onChangeEnd: (v) {
                      setState(() => _dragging = false);
                      _go(v.round());
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
