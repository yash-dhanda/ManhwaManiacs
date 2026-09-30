import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/ai/models/similar_result.dart';
import 'package:manhwamaniacs/features/ai/providers/ai_providers.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/parts/ai/not_interested.dart';
import 'package:manhwamaniacs/skins/glass/prefs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/ai/machine_badge.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/screens/home/home_actions.dart'
    show openSeries;
import 'package:manhwamaniacs/skins/glass/screens/home/home_common.dart'
    show HomeCoverImage;
import 'package:manhwamaniacs/skins/glass/screens/picks/deal_layer.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart' show GlassTwin;
import 'package:manhwamaniacs/skins/glass/type.dart';
import 'package:manhwamaniacs/skins/skins.dart';
import 'package:url_launcher/url_launcher.dart';

/// `why` types in at 12 ms per character (Quick type); reduced motion shows it whole.
class TypedWhy extends ConsumerStatefulWidget {
  const TypedWhy(this.text, {super.key, this.animate = true});
  final String text;
  final bool animate;

  @override
  ConsumerState<TypedWhy> createState() => _TypedWhyState();
}

class _TypedWhyState extends ConsumerState<TypedWhy> {
  Timer? _t;
  int _n = 0;

  @override
  void initState() {
    super.initState();
    _n = widget.animate ? 0 : widget.text.length;
    if (widget.animate) {
      _t = Timer.periodic(const Duration(milliseconds: 12), (t) {
        if (!mounted) return;
        if (ref.read(glassMotionPrefsProvider).reduced) {
          setState(() => _n = widget.text.length);
        } else {
          setState(() => _n++);
        }
        if (_n >= widget.text.length) t.cancel();
      });
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shown = widget.text.substring(0, _n.clamp(0, widget.text.length));
    return Semantics(
      label: suggestedByAi(widget.text),
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
              padding: EdgeInsets.only(top: 3, right: 6),
              child: MachineBadge(),),
          Expanded(
              child: GlassText(shown,
                  role: gt.typeCallout, color: gt.colorLabel2, maxLines: 4,),),
        ],
      ),
    );
  }
}

/// One wide answer card (glass 9.1.2): poster 96 x 144, title, meta, `why`, availability and the actions.
class AnswerCard extends ConsumerWidget {
  const AnswerCard(
      {super.key, required this.item, this.animate = true, this.onMenu,});
  final WorldItem item;
  final bool animate;
  final VoidCallback? onMenu;

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final box = context.findRenderObject() as RenderBox?;
    final from = box != null && box.attached
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    final av = item.available;
    if (av.length > 1 && from != null) {
      await showGlassMenu(context, anchor: from, title: 'Open on', entries: [
        for (final a in av)
          GlassMenuEntry(
              label: 'On ${a.sourceName}',
              onSelected: () => unawaited(
                  openSeries(ref, a.sourceId, a.seriesKey, from: from),),),
      ],);
    } else if (av.isNotEmpty) {
      await openSeries(ref, av.first.sourceId, av.first.seriesKey, from: from);
    }
  }

  Future<void> _external(WidgetRef ref, WorldPlatform p) async {
    try {
      if (!await launchUrl(Uri.parse(p.url),
          mode: LaunchMode.externalApplication,)) {
        throw StateError('launch');
      }
    } catch (_) {
      showGlassToast(
          ref,
          GlassToastSpec("Couldn't open ${p.site}",
              kind: GlassToastKind.error,),);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platform = item.platforms.firstOrNull;
    final meta = item.badgeLine;
    return DecoratedBox(
      decoration: BoxDecoration(
          color: gt.colorSurface1,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: gt.colorMachineRim, width: 0.5),),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 96,
                height: 144,
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: HomeCoverImage(url: item.coverUrl, width: 96),),),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: GlassText(item.title,
                              role: gt.typeHeadline,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,),),
                      if (onMenu != null)
                        Semantics(
                          button: true,
                          label: 'More for ${item.title}',
                          child: GestureDetector(
                              onTap: onMenu,
                              behavior: HitTestBehavior.opaque,
                              child: SizedBox(
                                  width: GlassFrame.hitMin(context),
                                  height: GlassFrame.hitMin(context),
                                  child: Center(
                                      child: GlassText('···',
                                          role: gt.typeHeadline,
                                          color: gt.colorLabel2,),),),),
                        ),
                    ],
                  ),
                  if (meta != null)
                    GlassText(meta,
                        role: gt.typeCaption1, color: gt.colorLabel2,),
                  if (item.why != null) ...[
                    const SizedBox(height: 6),
                    TypedWhy(item.why!, animate: animate),
                  ],
                  const SizedBox(height: 8),
                  GlassText(item.availabilityLabel ?? 'Not on your sources',
                      role: gt.typeCaption1,
                      color: item.available.isEmpty
                          ? gt.colorLabel3
                          : gt.colorLabel1,),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (item.available.isNotEmpty)
                        GlassButton(
                            label: 'Open',
                            size: GlassButtonSize.small,
                            twin: GlassTwin.content,
                            onPressed: () => unawaited(_open(context, ref)),),
                      if (item.available.isEmpty)
                        GlassButton(
                            label: 'Search my sources',
                            size: GlassButtonSize.small,
                            variant: GlassButtonVariant.plain,
                            twin: GlassTwin.content,
                            onPressed: () => unawaited(ref
                                .read(skinRouterProvider)
                                .push<void>(
                                    Routes.discover({'q': item.title}),),),),
                      if (item.available.isEmpty && platform != null)
                        GlassButton(
                            label: 'Read on ${platform.site}',
                            size: GlassButtonSize.small,
                            variant: GlassButtonVariant.plain,
                            twin: GlassTwin.content,
                            onPressed: () =>
                                unawaited(_external(ref, platform)),),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The answers of one ask (up to 8 local, 12 worldwide): a list or a grid, dealt out of the Ask button.
class AnswerList extends ConsumerStatefulWidget {
  const AnswerList(
      {super.key,
      required this.answers,
      required this.askButtonKey,
      required this.asGrid,
      required this.animateDeal,
      required this.onAskAgain,
      required this.onToggleGrid,});
  final List<WorldItem> answers;
  final GlobalKey askButtonKey;
  final bool asGrid;
  final bool animateDeal;
  final VoidCallback onAskAgain;
  final VoidCallback onToggleGrid;

  @override
  ConsumerState<AnswerList> createState() => _AnswerListState();
}

class _AnswerListState extends ConsumerState<AnswerList> {
  late final List<GlobalKey> _slots = [
    for (final _ in widget.answers) GlobalKey(),
  ];
  bool _dealt = false;
  OverlayEntry? _entry;
  final List<WorldItem> _extra = [];

  List<WorldItem> get _items => widget.answers;

  @override
  void initState() {
    super.initState();
    final reduced = ref.read(glassMotionPrefsProvider).reduced;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(SemanticsService.sendAnnouncement(
            View.of(context),
            '${widget.answers.length} picks ready',
            Directionality.of(context),),);
      }
    });
    if (widget.animateDeal && !reduced && widget.answers.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _deal());
    } else {
      _dealt = true;
    }
  }

  Rect? _rectOf(GlobalKey k) {
    final ro = k.currentContext?.findRenderObject();
    return ro is RenderBox && ro.attached
        ? ro.localToGlobal(Offset.zero) & ro.size
        : null;
  }

  void _deal() {
    if (!mounted) return;
    final origin = _rectOf(widget.askButtonKey)?.center;
    final slots = [for (final k in _slots) _rectOf(k)];
    if (origin == null || slots.any((r) => r == null)) {
      setState(() => _dealt = true);
      return;
    }
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      setState(() => _dealt = true);
      return;
    }
    _entry = OverlayEntry(
      builder: (_) => DealLayer(
        origin: origin,
        flights: [
          for (var i = 0; i < _items.length; i++)
            DealFlight(slot: slots[i]!, child: _flightCopy(_items[i])),
        ],
        onDone: () {
          _entry?.remove();
          _entry = null;
          if (mounted) setState(() => _dealt = true);
        },
      ),
    );
    overlay.insert(_entry!);
  }

  Widget _flightCopy(WorldItem i) => DecoratedBox(
        decoration: BoxDecoration(
            color: gt.colorSurface1,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: gt.colorMachineRim, width: 0.5),),
        child: Padding(
            padding: const EdgeInsets.all(12),
            child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                    width: 96,
                    height: 144,
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: HomeCoverImage(url: i.coverUrl, width: 96),),),),),
      );

  @override
  void dispose() {
    _entry?.remove();
    super.dispose();
  }

  Future<void> _moreLike(WorldItem w) async {
    if (w.available.isNotEmpty) {
      final a = w.available.first;
      await openSeries(ref, a.sourceId, a.seriesKey,
          query: 'focus=more-like-this',);
      return;
    }
    if (w.anilistId <= 0) return;
    final r = await ref
        .read(similarProvider(SimilarQuery.anilist(w.anilistId)).future);
    if (!mounted || r.items.isEmpty) return;
    setState(() => _extra.addAll(r.items.take(3)));
  }

  @override
  Widget build(BuildContext context) {
    final dismissed = ref.watch(dismissedPicksProvider);
    final phone = GlassFrame.of(context) == GlassFrameKind.phone;
    final wide = !phone;
    final reduced =
        ref.watch(glassMotionPrefsProvider.select((m) => m.reduced));
    final items = [
      for (final w in _items)
        if (!dismissed.contains(pickId(w))) w,
    ];
    final more = [
      for (final w in _extra)
        if (!dismissed.contains(pickId(w))) w,
    ];
    Widget card(int i, WorldItem w, {bool extra = false}) {
      final key = i < _slots.length && !extra ? _slots[i] : null;
      final content = AiCardActions(
        item: w,
        swipeRow: phone && !widget.asGrid,
        onMoreLikeThis: _moreLike,
        child: AnswerCard(item: w, animate: widget.animateDeal && _dealt),
      );
      return KeyedSubtree(key: key, child: content);
    }

    final all = [...items, ...more];
    Widget body;
    if (widget.asGrid || wide) {
      body = LayoutBuilder(
        builder: (context, c) {
          final cols =
              widget.asGrid ? (c.maxWidth / 160).floor().clamp(2, 6) : 2;
          return Wrap(spacing: 20, runSpacing: 12, children: [
            for (var i = 0; i < all.length; i++)
              SizedBox(
                  width: (c.maxWidth - 20 * (cols - 1)) / cols,
                  child: card(i, all[i], extra: i >= items.length),),
          ],);
        },
      );
    } else {
      body = Column(children: [
        for (var i = 0; i < all.length; i++)
          Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: card(i, all[i], extra: i >= items.length),),
      ],);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
            alignment: Alignment.centerRight,
            child: GlassButton(
                label: widget.asGrid ? 'Show as list' : 'Show as grid',
                variant: GlassButtonVariant.plain,
                size: GlassButtonSize.small,
                onPressed: widget.onToggleGrid,),),
        AnimatedOpacity(
            opacity: _dealt ? 1 : 0,
            duration:
                reduced ? const Duration(milliseconds: 150) : Duration.zero,
            child: body,),
        const SizedBox(height: 12),
        Center(
            child: GlassButton(
                label: 'Ask again',
                onPressed: widget.onAskAgain,),),
      ],
    );
  }
}
