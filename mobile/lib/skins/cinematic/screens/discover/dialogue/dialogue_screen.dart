import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/library/models/followed_series.dart';
import 'package:manhwamaniacs/features/library/providers/library_list_provider.dart';
import 'package:manhwamaniacs/features/ocr/models/ocr_search_result.dart';
import 'package:manhwamaniacs/features/ocr/providers/dialogue_jump_provider.dart';
import 'package:manhwamaniacs/features/ocr/providers/ocr_providers.dart';
import 'package:manhwamaniacs/features/sources/providers/discover_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/dialogue/transcript_block.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/discover_keys.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/index_field_header.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// `/ocr`: "What they said", subtitled stills; tapping one opens the reader
/// on the matched page with the bubble pulse.
class DialogueScreen extends ConsumerStatefulWidget {
  const DialogueScreen({super.key, this.q = ''});

  final String q;

  @override
  ConsumerState<DialogueScreen> createState() => _DialogueScreenState();
}

class _DialogueScreenState extends ConsumerState<DialogueScreen> {
  late final _text = TextEditingController(text: widget.q);
  final _field = FocusNode();
  Timer? _debounce;
  late String _q = widget.q.trim();
  final _more = <OcrSearchResult>[];
  bool _loadingMore = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _text.dispose();
    _field.dispose();
    super.dispose();
  }

  void _apply(String v) {
    _debounce?.cancel();
    setState(() {
      _q = v.trim();
      _more.clear();
    });
    context.go(Routes.dialogue({'q': _q.isEmpty ? null : _q}));
  }

  void _open(OcrSearchResult hit) {
    ref.read(dialogueJumpProvider.notifier).set(
          DialogueJump(
            sourceId: hit.sourceId,
            seriesKey: hit.seriesKey,
            chapterKey: hit.chapterKey,
            q: _q,
            page: hit.page,
            box: hit.box,
          ),
        );
    // TODO(mobile/06): enterReader(context, target, entry: ReaderEntry.dip).
    unawaited(
      context.push(
        Routes.reader(hit.sourceId, hit.seriesKey, hit.chapterKey, {
          'page': hit.page,
        }),
      ),
    );
  }

  Future<void> _showMore(int offset) async {
    setState(() => _loadingMore = true);
    final r = await ref.read(ocrRepositoryProvider).search(_q, offset: offset);
    if (!mounted) return;
    setState(() {
      _loadingMore = false;
      if (r.isOk) _more.addAll(r.value.items);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    final visible = ref.watch(ocrFeatureVisibleProvider);
    final mode = ref.watch(contentModeControllerProvider);
    final tablet = isTablet(context);
    final pad = tablet ? CineSpace.s8 : CineSpace.s4;

    Widget? body;
    List<OcrSearchResult>? hits;
    Widget? footer;
    FollowedSeries? Function(OcrSearchResult) seriesOf = (_) => null;
    if (mode == ContentMode.novel) {
      body = CineNotice(
        kicker: 'NOTE',
        headline:
            "Dialogue search is for manga. Switch to Manga, or search the novels' text.",
        actions: [
          QuietButton('Search novels',
              onPressed: () => context.go(Routes.discover()),),
        ],
      );
    } else if (!visible) {
      body = const CineNotice(
          kicker: 'NOTE',
          headline: "Dialogue search isn't available on this device.",);
    } else if (!(ref.watch(serverOcrCapabilityProvider).valueOrNull ?? true)) {
      body = const CineNotice(
          kicker: 'NOTE',
          headline: "Dialogue search isn't available on this server.",);
    } else if (_q.isEmpty) {
      body = Padding(
        padding: EdgeInsets.all(pad),
        child: Text('Type a line you remember.',
            style: cineText(context, t.typeDeck, color: t.colorInk60),),
      );
    } else {
      final res = ref.watch(ocrSearchProvider(_q));
      final followed = ref.watch(libraryListProvider).valueOrNull?.items ??
          const <FollowedSeries>[];
      seriesOf = (h) => followed
          .where((s) => s.sourceId == h.sourceId && s.seriesKey == h.seriesKey)
          .firstOrNull;
      final other = res.when(
        loading: () => Column(
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: pad, vertical: CineSpace.s3,),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FlickerPlate(aspect: 16 / 9),
                    SizedBox(height: 8),
                    FlickerPlate(height: 14),
                    SizedBox(height: 6),
                    FlickerPlate(height: 14, width: 200),
                  ],
                ),
              ),
          ],
        ),
        error: (e, _) => e is NetworkError || e is TimeoutError
            ? CineNotice(
                kicker: 'OFFLINE EDITION',
                headline: 'Dialogue search needs a connection.',
                actions: [
                  QuietButton('Go to Downloads',
                      onPressed: () => context.go(Routes.downloads()),),
                ],
              )
            : CineNotice(
                kicker: 'CORRECTION',
                kickerColor: t.colorProof,
                headline: "Dialogue search didn't finish.",
                deck: e is AppError ? e.userMessage : null,
                actions: [
                  QuietButton('Try again',
                      onPressed: () => ref.invalidate(ocrSearchProvider(_q)),),
                ],
              ),
        data: (page) {
          final items = [...page.items, ..._more];
          if (items.isEmpty) {
            return CineNotice(
              kicker: 'NOTE',
              headline:
                  'Nothing found for "$_q". Only chapters whose dialogue was scanned, in series you follow, can be searched.',
            );
          }
          final canMore = items.length < page.total;
          hits = items;
          footer = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (canMore)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: pad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Showing the first ${items.length} of ${page.total} matches. Narrow the search.',
                        style: cineText(context, t.typeCaption,
                            color: t.colorInk60,),
                      ),
                      _loadingMore
                          ? const Padding(
                              padding: EdgeInsets.all(16), child: LeaderDial(),)
                          : QuietButton('Show more',
                              onPressed: () => _showMore(items.length),),
                    ],
                  ),
                ),
              const SizedBox(height: CineSpace.s16),
            ],
          );
          return const SizedBox.shrink();
        },
      );
      if (hits == null) body = other;
    }

    final masthead = Column(children: [
      Padding(
        padding: EdgeInsets.fromLTRB(pad, CineSpace.s6, pad, CineSpace.s2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Kicker('No. 09 — Dialogue'),
            const ZeroSizeHeading('Dialogue search'),
            const SizedBox(height: CineSpace.s3),
            IndexField(
              controller: _text,
              focusNode: _field,
              hint: 'Search what a character said',
              onChanged: (v) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 300), () {
                  if (mounted) _apply(v);
                });
              },
              onSubmitted: _apply,
              onClear: () {
                _text.clear();
                _apply('');
              },
            ),
            const SizedBox(height: CineSpace.s3),
            Text(
              'Across chapters whose dialogue has been read, in series you follow.',
              style: cineText(context, t.typeDeck, color: t.colorInk60),
            ),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Scan more chapters from ',
                  style: cineText(context, t.typeCaption, color: t.colorInk60),
                ),
                QuietButton('Downloads',
                    onPressed: () => context.go(Routes.downloads()),),
              ],
            ),
          ],
        ),
      ),
    ],);

    return CineKeys(
      group: 'Dialogue',
      keys: [
        CineKey(key(LogicalKeyboardKey.slash), _field.requestFocus,
            whenTextFieldFree: true,),
        CineKey(key(LogicalKeyboardKey.keyJ),
            () => focusStep(context, forward: true),
            whenTextFieldFree: true,),
        CineKey(key(LogicalKeyboardKey.keyK),
            () => focusStep(context, forward: false),
            whenTextFieldFree: true,),
      ],
      child: Scaffold(
        backgroundColor: t.colorPaper0,
        body: SafeArea(
          child: ListView.builder(
            itemCount: 1 + (hits?.length ?? 1) + (footer == null ? 0 : 1),
            itemBuilder: (context, i) {
              if (i == 0) return masthead;
              if (hits == null) return body ?? const SizedBox.shrink();
              if (i <= hits!.length) {
                final h = hits![i - 1];
                return TranscriptBlock(
                  key: ValueKey('hit-${i - 1}-${h.chapterKey}-${h.page}'),
                  hit: h,
                  series: seriesOf(h),
                  index: i - 1,
                  onTap: () => _open(h),
                );
              }
              return footer!;
            },
          ),
        ),
      ),
    );
  }
}
