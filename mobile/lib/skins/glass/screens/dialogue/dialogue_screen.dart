import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/features/library/providers/library_list_provider.dart';
import 'package:manhwamaniacs/features/ocr/models/ocr_search_result.dart';
import 'package:manhwamaniacs/features/ocr/providers/dialogue_jump_provider.dart';
import 'package:manhwamaniacs/features/ocr/providers/ocr_providers.dart';
import 'package:manhwamaniacs/features/sources/providers/discover_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/search_field.dart';
import 'package:manhwamaniacs/skins/glass/screens/dialogue/dialogue_card.dart';
import 'package:manhwamaniacs/skins/glass/screens/dialogue/dialogue_keys.dart';
import 'package:manhwamaniacs/skins/glass/screens/dialogue/dialogue_states.dart';
import 'package:manhwamaniacs/skins/glass/shell/glass_scaffold.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// Opens a dialogue hit: the jump is handed over (`dialogueJumpProvider`) and the manga reader is entered. The reader glides to the
/// page and settles the hit lens (mobile/35's reader takes the jump); with no match it opens at the chapter start.
void openDialogueHit(WidgetRef ref, OcrSearchResult hit, String q) {
  ref.read(dialogueJumpProvider.notifier).set(DialogueJump(sourceId: hit.sourceId, seriesKey: hit.seriesKey, chapterKey: hit.chapterKey, q: q, page: hit.page, box: hit.box));
  unawaited(ref.read(skinRouterProvider).push<void>(Routes.reader(hit.sourceId, hit.seriesKey, hit.chapterKey, {if (hit.page != null) 'page': hit.page})));
}

/// `/ocr` (glass 8.23): Dialogue search.
class GlassDialogueScreen extends ConsumerStatefulWidget {
  const GlassDialogueScreen({super.key, this.q});
  final String? q;

  @override
  ConsumerState<GlassDialogueScreen> createState() => _GlassDialogueScreenState();
}

class _GlassDialogueScreenState extends ConsumerState<GlassDialogueScreen> {
  late final TextEditingController _c = TextEditingController(text: widget.q ?? '');
  final FocusNode _focus = FocusNode(debugLabel: 'dialogue field');
  final Object _token = Object();
  late final ShortcutRegistry _shortcuts;
  Timer? _debounce;
  late String _q = (widget.q ?? '').trim();
  List<OcrSearchResult> _more = [];
  int _offset = 0;
  bool _loadingMore = false;
  bool? _moreHasMore;
  int? _moreTotal;

  @override
  void initState() {
    super.initState();
    _shortcuts = ref.read(shortcutRegistryProvider.notifier);
    Future.microtask(() => _shortcuts.register(_token, dialogueShortcutEntries()));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _c.dispose();
    _focus.dispose();
    final s = _shortcuts;
    final t = _token;
    Future.microtask(() => s.unregister(t));
    super.dispose();
  }

  void _set(String v) {
    _debounce?.cancel();
    final q = v.trim();
    if (q == _q) return;
    setState(() {
      _q = q;
      _more = [];
      _offset = 0;
      _moreHasMore = null;
    });
    try {
      GoRouter.of(context).replace<void>(Routes.dialogue({if (q.isNotEmpty) 'q': q}));
    } catch (_) {}
  }

  Future<void> _loadMore(int at) async {
    setState(() => _loadingMore = true);
    final r = await ref.read(ocrRepositoryProvider).search(_q, offset: at);
    if (!mounted) return;
    setState(() {
      _loadingMore = false;
      if (!r.isErr) {
        _more = [..._more, ...r.value.items];
        _offset = at + r.value.items.length;
        _moreHasMore = r.value.hasMore;
        _moreTotal = r.value.total;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(contentModeControllerProvider);
    final capable = ref.watch(serverOcrCapabilityProvider).valueOrNull ?? true;
    final online = ref.watch(deviceOnlineProvider).valueOrNull ?? true;
    final engine = ref.watch(ocrFeatureVisibleProvider);
    final margin = GlassFrame.screenMargin(context);
    final wide = GlassFrame.of(context) != GlassFrameKind.phone;

    Widget body;
    if (!capable) {
      body = const DialogueUnavailableLens();
    } else if (mode == ContentMode.novel) {
      body = DialogueNovelsLens(q: _q);
    } else if (!online) {
      body = const DialogueOfflineLens();
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassSearchField(
            variant: GlassSearchVariant.page,
            controller: _c,
            focusNode: _focus,
            placeholder: 'Search dialogue',
            onQuery: (v) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 350), () {
                if (mounted) _set(v);
              });
            },
            onSubmitted: _set,
          ),
          DialogueHint(engineAvailable: engine),
          _results(),
        ],
      );
    }
    if (wide) body = Align(alignment: Alignment.topCenter, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 880), child: body));
    return Focus(
      canRequestFocus: false,
      onKeyEvent: (n, e) {
        if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.slash && FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<EditableText>() == null) {
          _focus.requestFocus();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GlassScaffold(
        title: 'Dialogue search',
        leading: GlassLeading.back,
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(margin, 0, margin, 120),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlassLabel('Search what characters said across the series you follow, and jump to the page.', role: gt.typeCallout, color: gt.colorLabel2, maxLines: 3),
                  const SizedBox(height: 12),
                  body,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _results() {
    if (_q.isEmpty) return const DialogueIdleLens();
    final res = ref.watch(ocrSearchProvider(_q));
    final followed = ref.watch(libraryListProvider).valueOrNull?.items ?? const <FollowedSeries>[];
    return res.when(
      loading: () => const DialogueSkeleton(),
      error: (e, _) => DialogueErrorLens(onRetry: () => ref.invalidate(ocrSearchProvider(_q))),
      data: (page) {
        final items = [...page.items, ..._more];
        if (items.isEmpty) return DialogueEmptyLens(q: _q);
        final total = _moreTotal ?? page.total;
        final hasMore = _moreHasMore ?? page.hasMore;
        final next = _offset == 0 ? page.offset + page.items.length : _offset;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final h in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Builder(builder: (context) {
                  final s = followed.where((f) => f.sourceId == h.sourceId && f.seriesKey == h.seriesKey).firstOrNull;
                  return GlassDialogueCard(hit: h, title: s?.title, coverUrl: s?.coverUrl, onOpen: () => openDialogueHit(ref, h, _q));
                }),
              ),
            GlassLabel('Showing the first ${items.length} of $total matches', role: gt.typeFootnote, color: gt.colorLabel2),
            if (hasMore) GlassButton(label: 'Load more', variant: GlassButtonVariant.plain, loading: _loadingMore, onPressed: () => _loadMore(next)),
          ],
        );
      },
    );
  }
}
