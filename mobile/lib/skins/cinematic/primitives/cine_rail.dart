import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_badge.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_poster.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_rail_slate.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rail_math.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

enum CineRailState { ready, loading, empty, error, aiUnavailable }

enum CineAiReason { budget, notConfigured, rateLimited, failed }

/// The section 9.1.8 copy for an unavailable AI rail; the returned kicker is `NOTE` except for a rate limit.
({String kicker, String copy}) cineAiUnavailableCopy(CineAiReason r, {int? retryAfterSeconds}) => switch (r) {
      CineAiReason.budget => (kicker: 'NOTE', copy: 'The picks desk is closed tonight. Asks reset at midnight UTC.'),
      CineAiReason.notConfigured => (kicker: 'NOTE', copy: "The editors' desk isn't set up on this server."),
      CineAiReason.rateLimited => (kicker: 'SLOW DOWN', copy: 'Too many asks at once. Try again in ${retryAfterSeconds ?? 10} s.'),
      CineAiReason.failed => (kicker: 'NOTE', copy: "The editors couldn't answer that one. Try describing it differently."),
    };

typedef CineRailItemBuilder = Widget Function(BuildContext context, int index, double posterWidth, FocusNode node);

/// A section rail (cinematic 7.8): a drawn rule, a folio, a revealed heading, See all, and a
/// virtualised row of posters that snaps, with roving keyboard focus and the Slate on tablets.
class CineRail extends StatefulWidget {
  const CineRail({
    super.key,
    required this.headingId,
    required this.heading,
    required this.itemCount,
    required this.itemBuilder,
    this.folio,
    this.state = CineRailState.ready,
    this.onSeeAll,
    this.slateBuilder,
    this.emptyText = 'Nothing here yet.',
    this.optional = false,
    this.onRetry,
    this.aiReason,
    this.retryAfterSeconds,
    this.fallback,
    this.staleAgo,
    this.pickedAgo,
    this.placeholderTitles = const [],
    this.loadingCount = 6,
    this.captions = true,
  });

  final String headingId, heading;
  final String? folio;
  final int itemCount;
  final CineRailItemBuilder itemBuilder;
  final CineRailState state;
  final VoidCallback? onSeeAll;

  /// What the Slate shows for poster [i]; null means no Slate.
  final CineSlateData? Function(int i)? slateBuilder;
  final String emptyText;

  /// Optional rails render nothing when empty; core rails collapse to one line.
  final bool optional;
  final VoidCallback? onRetry;
  final CineAiReason? aiReason;
  final int? retryAfterSeconds;

  /// The caller's local rail that replaces the posters when the AI is unavailable.
  final Widget? fallback;
  final String? staleAgo, pickedAgo;
  final List<String> placeholderTitles;
  final int loadingCount;
  final bool captions;

  @override
  State<CineRail> createState() => _CineRailState();
}

class _CineRailState extends State<CineRail> {
  final _scroll = ScrollController();
  final Map<int, FocusNode> _nodes = {};
  final _viewKey = GlobalKey();
  int _roving = 0;
  Timer? _dwell;
  CineSlateHandle? _slate;
  int? _slateIndex;
  double _pw = 100, _gap = 8;

  FocusNode _node(int i) => _nodes.putIfAbsent(i, () {
        final n = FocusNode(debugLabel: 'rail-${widget.headingId}-$i');
        n.onKeyEvent = (_, e) => _onKey(i, e);
        n.addListener(() {
          if (n.hasFocus && _roving != i && mounted) setState(() => _roving = i);
        });
        return n;
      });

  KeyEventResult _onKey(int i, KeyEvent e) {
    if (e is KeyUpEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    final last = widget.itemCount - 1;
    if (k == LogicalKeyboardKey.arrowRight) {
      _focusIndex(i + 1);
    } else if (k == LogicalKeyboardKey.arrowLeft) {
      _focusIndex(i - 1);
    } else if (k == LogicalKeyboardKey.home) {
      _focusIndex(0);
    } else if (k == LogicalKeyboardKey.end) {
      _focusIndex(last);
    } else if (k == LogicalKeyboardKey.arrowDown || k == LogicalKeyboardKey.arrowUp) {
      final scope = FocusScope.of(context);
      final moved = scope.focusInDirection(k == LogicalKeyboardKey.arrowDown ? TraversalDirection.down : TraversalDirection.up);
      if (moved) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final f = FocusManager.instance.primaryFocus?.context;
          if (f != null && f.mounted) {
            Scrollable.ensureVisible(f, alignment: 0.3, duration: CineMotion.reduced(context) ? Duration.zero : CineDur.column, curve: CineCurves.settle);
          }
        });
      }
    } else if (k == LogicalKeyboardKey.space && e is KeyDownEvent) {
      _toggleSlate(i);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  void _focusIndex(int k) {
    final i = k.clamp(0, widget.itemCount - 1);
    setState(() => _roving = i);
    Future<void>? moved;
    if (_scroll.hasClients) {
      final target = railRevealOffset(
        index: i,
        offset: _scroll.offset,
        viewport: _scroll.position.viewportDimension,
        posterWidth: _pw,
        gap: _gap,
        maxExtent: _scroll.position.maxScrollExtent,
      );
      if (CineMotion.reduced(context)) {
        _scroll.jumpTo(target);
      } else {
        moved = _scroll.animateTo(target, duration: CineDur.column, curve: CineCurves.settle);
      }
    }
    final n = _node(i);
    if (n.context != null) {
      n.requestFocus();
    } else {
      (moved ?? Future<void>.value()).then((_) => WidgetsBinding.instance.addPostFrameCallback((_) => n.requestFocus()));
    }
  }

  Rect? _posterRect(int i) {
    final box = _nodes[i]?.context?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return null;
    final o = box.localToGlobal(Offset.zero);
    return Rect.fromLTWH(o.dx, o.dy, box.size.width, box.size.width * 1.5);
  }

  void _openSlate(int i, {required bool keyboard}) {
    final data = widget.slateBuilder?.call(i);
    final anchor = _posterRect(i);
    final view = _viewKey.currentContext?.findRenderObject() as RenderBox?;
    if (data == null || anchor == null || view == null) return;
    _slate?.close();
    final vo = view.localToGlobal(Offset.zero);
    final screen = MediaQuery.sizeOf(context);
    _slateIndex = i;
    _slate = showCineSlate(
      context,
      anchor: anchor,
      bounds: Rect.fromLTRB(vo.dx + 24, 0, vo.dx + view.size.width - 24, screen.height),
      data: data,
      keyboard: keyboard,
      onClosed: () {
        _slate = null;
        if (keyboard && mounted) _node(i).requestFocus();
      },
    );
  }

  void _toggleSlate(int i) {
    if (_slate != null && _slate!.isOpen && _slateIndex == i) {
      _slate!.close();
    } else {
      _openSlate(i, keyboard: true);
    }
  }

  @override
  void dispose() {
    _dwell?.cancel();
    _slate?.close();
    _scroll.dispose();
    for (final n in _nodes.values) {
      n.dispose();
    }
    super.dispose();
  }

  void _snap() {
    if (!_scroll.hasClients) return;
    final target = railSnapOffset(offset: _scroll.offset, posterWidth: _pw, gap: _gap, maxExtent: _scroll.position.maxScrollExtent);
    if ((target - _scroll.offset).abs() < 0.5) return;
    if (CineMotion.reduced(context)) {
      _scroll.jumpTo(target);
    } else {
      _scroll.animateTo(target, duration: CineDur.column, curve: CineCurves.settle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final w = widget;
    if (w.state == CineRailState.empty && w.optional) return const SizedBox.shrink();
    return Semantics(
      container: true,
      label: w.heading,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
        const CineRuleDraw(),
        SizedBox(height: c.space3),
        _header(context, c),
        SizedBox(height: c.space3),
        _body(context, c),
      ],),
    );
  }

  Widget _header(BuildContext context, CineTokens c) {
    final w = widget;
    final badges = [
      if (w.staleAgo != null) CineBadge.stale(w.staleAgo!),
      if (w.pickedAgo != null) CineBadge.pickedAgo(w.pickedAgo!),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        if (w.folio != null) ...[CineRoleText(w.folio!, c.typeFolio, color: c.colorInk45), SizedBox(width: c.space3)],
        Flexible(
          child: SetHeading(
            w.heading,
            id: 'rail-${w.headingId}',
            style: CineText.style(context, c.typeSection).copyWith(color: c.colorInk100),
            cap: c.typeSection.cap,
            level: 2,
            linked: true,
          ),
        ),
        const Spacer(),
        if (w.onSeeAll != null)
          Semantics(
            button: true,
            label: 'See all, ${w.heading}',
            excludeSemantics: true,
            onTap: w.onSeeAll,
            child: CinePressable(
              onTap: w.onSeeAll,
              builder: (_, st) => Row(mainAxisSize: MainAxisSize.min, children: [
                CineRoleText('See all', c.typeLabel, color: st.hovered ? c.colorInk100 : c.colorInk60),
                const SizedBox(width: 4),
                CineGlyphIcon(CineGlyph.arrowRight, size: 16, color: st.hovered ? c.colorInk100 : c.colorInk60),
              ],),
            ),
          ),
      ],),
      if (badges.isNotEmpty) Padding(padding: EdgeInsets.only(top: c.space2), child: Wrap(spacing: c.space2, runSpacing: c.space1, children: badges)),
    ],);
  }

  Widget _body(BuildContext context, CineTokens c) {
    final w = widget;
    switch (w.state) {
      case CineRailState.empty:
        return CineRoleText(w.emptyText, c.typeBodyItalic, color: c.colorInk45);
      case CineRailState.error:
        return Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: c.space3, children: [
          CineRoleText("This row didn't load.", c.typeCaption, color: c.colorProof),
          if (w.onRetry != null) CineButton(label: 'Retry', variant: CineButtonVariant.quiet, size: CineButtonSize.sm, onPressed: w.onRetry),
        ],);
      case CineRailState.aiUnavailable:
        final r = cineAiUnavailableCopy(w.aiReason ?? CineAiReason.failed, retryAfterSeconds: w.retryAfterSeconds);
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Semantics(
            container: true,
            child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 4, children: [
              CineRoleText(r.kicker, c.typeKicker, color: c.colorSpot),
              CineRoleText('${r.copy} Here is your shelf instead.', c.typeCaption, color: c.colorInk60),
            ],),
          ),
          if (w.fallback != null) ...[SizedBox(height: c.space3), w.fallback!],
        ],);
      case CineRailState.loading:
      case CineRailState.ready:
        return _posters(context, c, loading: w.state == CineRailState.loading);
    }
  }

  Widget _posters(BuildContext context, CineTokens c, {required bool loading}) {
    final w = widget;
    return LayoutBuilder(
      key: _viewKey,
      builder: (context, box) {
        final screenW = MediaQuery.sizeOf(context).width;
        final scale = cineScale(context);
        final visible = railVisible(width: screenW, textScale: scale);
        _gap = railGap(screenW);
        _pw = railPosterWidth(contentWidth: box.maxWidth, visible: visible, gap: _gap);
        final compact = CineReflow.of(context).railCompact;
        double lineH(CineTextRole r) {
          final s = CineText.style(context, r);
          return (s.fontSize ?? 16) * (s.height ?? 1.3) * CineText.scaler(context, r).scale(1);
        }

        final captionH = w.captions ? 8 + (compact ? 2 : 1) * lineH(c.typeTitle) + 2 + lineH(c.typeFolio) : 0.0;
        final height = 1.5 * _pw + captionH + 16 + 6;
        final count = loading ? w.loadingCount : w.itemCount;
        return SizedBox(
          height: height,
          child: NotificationListener<ScrollEndNotification>(
            onNotification: (n) {
              if (n.metrics.axis == Axis.horizontal) _snap();
              return false;
            },
            child: CinePosterGroup(
              child: FocusTraversalGroup(
                child: ListView.builder(
                  controller: _scroll,
                  scrollCacheExtent: const ScrollCacheExtent.pixels(200),
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemExtent: _pw + _gap,
                  itemCount: count,
                  itemBuilder: (context, i) {
                    final node = _node(i);
                    node.skipTraversal = i != _roving;
                    final item = loading
                        ? CinePoster(title: i < w.placeholderTitles.length ? w.placeholderTitles[i] : '', loading: true, flickerIndex: i, groupIndex: i)
                        : w.itemBuilder(context, i, _pw, node);
                    return Padding(
                      padding: EdgeInsets.only(right: _gap),
                      child: SizedBox(
                        width: _pw,
                        child: MouseRegion(
                          onEnter: (_) {
                            if (loading || w.slateBuilder == null) return;
                            _dwell?.cancel();
                            _dwell = Timer(CineDur.dwellPreview, () {
                              if (mounted) _openSlate(i, keyboard: false);
                            });
                          },
                          onExit: (_) {
                            _dwell?.cancel();
                            if (_slate != null && _slateIndex == i) _slate!.close(grace: true);
                          },
                          child: item,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
