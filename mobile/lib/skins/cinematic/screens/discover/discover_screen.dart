import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/library/providers/intelligence_providers.dart';
import 'package:manhwamaniacs/features/library/providers/library_list_provider.dart';
import 'package:manhwamaniacs/features/library/utils/recent_searches.dart';
import 'package:manhwamaniacs/features/ocr/providers/ocr_providers.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/features/sources/providers/discover_providers.dart';
import 'package:manhwamaniacs/features/sources/providers/source_pins_provider.dart';
import 'package:manhwamaniacs/features/sources/utils/discover_scope.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/navigation.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_slug_lines.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/ask_scope.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_extras.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/cine_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/discover_idle.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/discover_keys.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/discover_results.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/genre_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/discover/index_field_header.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/skin_haptics.dart';

/// `/search`: index field, scopes, idle page, tiered results, ASK.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key, this.q = '', this.scope, this.genre});

  final String q;
  final String? scope;
  final String? genre;

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  late final TextEditingController _text =
      TextEditingController(text: widget.q);
  final _field = FocusNode();
  final _scroll = ScrollController();
  final _results = GlobalKey<DiscoverResultsState>();
  Timer? _debounce;
  bool _genreOpened = false;

  @override
  void initState() {
    super.initState();
    if (widget.q.trim().isNotEmpty) {
      unawaited(
        Future<void>.microtask(() => _search(widget.q, replaceUrl: false)),
      );
    }
  }

  @override
  void didUpdateWidget(DiscoverScreen old) {
    super.didUpdateWidget(old);
    if (widget.q != old.q && widget.q != _text.text.trim()) {
      _text.text = widget.q;
      unawaited(
        Future<void>.microtask(() => _search(widget.q, replaceUrl: false)),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _text.dispose();
    _field.dispose();
    _scroll.dispose();
    super.dispose();
  }

  bool get _aiOn =>
      ref.read(suggestAvailabilityProvider).valueOrNull?.available ?? false;

  bool get _dialogueOn =>
      ref.read(ocrFeatureVisibleProvider) &&
      (ref.read(serverOcrCapabilityProvider).valueOrNull ?? true) &&
      ref.read(contentModeControllerProvider) == ContentMode.manga;

  DiscoverScope get _scopeNow => parseDiscoverScope(
        widget.scope,
        aiAvailable: _aiOn,
        dialogueAvailable: _dialogueOn,
      );

  void _go(String q, DiscoverScope scope) => context.go(
        Routes.discover({
          'q': q.isEmpty ? null : q,
          'scope': scope == DiscoverScope.all ? null : scope.name,
        }),
      );

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted && _scopeNow != DiscoverScope.ask) _search(v);
    });
    setState(() {});
  }

  void _search(String v, {bool replaceUrl = true}) {
    _debounce?.cancel();
    final q = v.trim();
    ref.read(searchQueryProvider.notifier).state = q;
    if (replaceUrl) _go(q, _scopeNow);
    if (q.length >= 2) {
      final prefs = ref.read(sharedPrefsProvider);
      final pid = ref.read(activeProfileProvider)?.id;
      unawaited(
        writeRecentSearch(prefs, q, profileId: pid).then((_) {
          if (mounted) setState(() {});
        }),
      );
    }
  }

  void _submit(String v) {
    if (_scopeNow == DiscoverScope.ask) {
      unawaited(ref.read(suggestionsProvider.notifier).submit(v));
    } else {
      _search(v);
    }
  }

  void _setScope(DiscoverScope s) {
    unawaited(ref.read(skinHapticsProvider).fire(HapticEvent.select));
    _go(_text.text.trim(), s);
  }

  void _clear() {
    _text.clear();
    _search('');
  }

  void _escape() {
    if (_text.text.isNotEmpty) {
      _clear();
    } else {
      _field.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    ref.listen(focusSearchSignalProvider, (_, __) => _field.requestFocus());
    final ai =
        ref.watch(suggestAvailabilityProvider).valueOrNull?.available ?? false;
    final dialogue = ref.watch(ocrFeatureVisibleProvider) &&
        (ref.watch(serverOcrCapabilityProvider).valueOrNull ?? true) &&
        ref.watch(contentModeControllerProvider) == ContentMode.manga;
    final scope = parseDiscoverScope(
      widget.scope,
      aiAvailable: ai,
      dialogueAvailable: dialogue,
    );
    final scopes = [
      DiscoverScope.all,
      DiscoverScope.library,
      DiscoverScope.sources,
      if (dialogue) DiscoverScope.dialogue,
      if (ai) DiscoverScope.ask,
    ];
    final labels = {
      DiscoverScope.all: 'ALL',
      DiscoverScope.library: 'LIBRARY',
      DiscoverScope.sources: 'SOURCES',
      DiscoverScope.dialogue: 'DIALOGUE',
      DiscoverScope.ask: 'ASK',
    };
    final query = _text.text.trim();
    final hint = scope == DiscoverScope.ask
        ? 'Describe what you feel like reading'
        : 'Search every source';

    // /search?genre=Romance opens that genre's sheet once.
    if (widget.genre != null && !_genreOpened) {
      final idx = ref.watch(genreIndexProvider).valueOrNull;
      final entry =
          idx?.where((g) => g.genre == widget.genre!.toLowerCase()).firstOrNull;
      if (entry != null) {
        _genreOpened = true;
        final pins = ref.read(sourcePinsProvider).valueOrNull?.pins ?? const [];
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(openGenre(context, ref, entry, pins));
        });
      }
    }

    final prefs = ref.watch(sharedPrefsProvider);
    final recent = readRecentSearches(
      prefs,
      profileId: ref.watch(activeProfileProvider)?.id,
    );

    Widget body;
    if (scope == DiscoverScope.ask) {
      body = AskScope(
        query: query,
        onSearchInstead: () => _go(query, DiscoverScope.all),
      );
    } else if (query.length < 2) {
      body = DiscoverIdle(
        recent: recent,
        aiAvailable: ai,
        dialogueAvailable: dialogue,
        onRecent: (r) {
          _text.text = r;
          _search(r);
        },
        onClearRecent: () async {
          await clearRecentSearches(
            prefs,
            profileId: ref.read(activeProfileProvider)?.id,
          );
          if (mounted) setState(() {});
        },
      );
    } else {
      body = DiscoverResults(
        key: _results,
        query: query,
        scope: scope,
        dialogueAvailable: dialogue,
        scrollController: _scroll,
        onAsk: () => _go(query, DiscoverScope.ask),
      );
    }

    final keys = <CineKey>[
      CineKey(
        key(LogicalKeyboardKey.slash),
        _field.requestFocus,
        whenTextFieldFree: true,
      ),
      CineKey(key(LogicalKeyboardKey.escape), _escape),
      CineKey(
        key(LogicalKeyboardKey.enter),
        () => _submit(_text.text),
        whenTextFieldFree: true,
      ),
      CineKey(
        key(LogicalKeyboardKey.arrowDown),
        () => focusStep(context, forward: true),
      ),
      for (var i = 0; i < 5; i++)
        CineKey(
          key(
            [
              LogicalKeyboardKey.digit1,
              LogicalKeyboardKey.digit2,
              LogicalKeyboardKey.digit3,
              LogicalKeyboardKey.digit4,
              LogicalKeyboardKey.digit5,
            ][i],
          ),
          () {
            if (i < scopes.length) _setScope(scopes[i]);
          },
          whenTextFieldFree: true,
        ),
      CineKey(
        key(LogicalKeyboardKey.bracketRight),
        () => _results.currentState?.step(1),
        whenTextFieldFree: true,
      ),
      CineKey(
        key(LogicalKeyboardKey.bracketLeft),
        () => _results.currentState?.step(-1),
        whenTextFieldFree: true,
      ),
    ];

    final tablet = isTablet(context);
    return CineKeys(
      group: 'Discover',
      keys: keys,
      child: Scaffold(
        backgroundColor: t.colorPaper0,
        body: SafeArea(
          child: CinePullToReprint(
            onRefresh: () async {
              if (query.length >= 2) {
                await ref.read(searchListProvider.notifier).refresh();
              }
            },
            child: ListView(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    tablet ? CineSpace.s8 : CineSpace.s4,
                    CineSpace.s6,
                    tablet ? CineSpace.s8 : CineSpace.s4,
                    CineSpace.s2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Kicker('No. 04 — Discover'),
                      const ZeroSizeHeading('Discover'),
                      const SizedBox(height: CineSpace.s3),
                      IndexField(
                        controller: _text,
                        focusNode: _field,
                        hint: hint,
                        onChanged: _onChanged,
                        onSubmitted: _submit,
                        onClear: _clear,
                        semanticsLabel: hint,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: CineSpace.s4),
                  child: CineSlugLines(
                    items: [
                      for (var i = 0; i < scopes.length; i++)
                        CineSlug(
                          '$i',
                          labels[scopes[i]]!,
                          // The scopes are numbered like contents (`01 ALL`); the folio is not spoken.
                          leading: CineLit(
                            (i + 1).toString().padLeft(2, '0'),
                            CineFace.archivo,
                            12,
                            16,
                            wght: 600,
                            wdth: 75,
                            color: context.cine.colorInk45,
                          ),
                        ),
                    ],
                    selected: {
                      '${scopes.indexOf(scope).clamp(0, scopes.length - 1)}',
                    },
                    onChanged: (id) => _setScope(scopes[int.parse(id)]),
                  ),
                ),
                body,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
