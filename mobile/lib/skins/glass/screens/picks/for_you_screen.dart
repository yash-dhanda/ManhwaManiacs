import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' hide ShortcutRegistry;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/library/providers/intelligence_providers.dart';
import 'package:manhwamaniacs/features/library/providers/pending_ask_provider.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/copy/ai.dart' show glassAiPartialLine;
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/ai/ai_notice.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/letter_reveal.dart';
import 'package:manhwamaniacs/skins/glass/primitives/pull_to_refresh.dart';
import 'package:manhwamaniacs/skins/glass/screens/picks/answer_list.dart';
import 'package:manhwamaniacs/skins/glass/screens/picks/ask_box.dart';
import 'package:manhwamaniacs/skins/glass/screens/picks/ask_controller.dart';
import 'package:manhwamaniacs/skins/glass/screens/picks/ask_controls.dart';
import 'package:manhwamaniacs/skins/glass/screens/picks/for_you_sections.dart';
import 'package:manhwamaniacs/skins/glass/screens/picks/for_you_states.dart';
import 'package:manhwamaniacs/skins/glass/screens/picks/genre_filter_chip.dart';
import 'package:manhwamaniacs/skins/glass/shell/glass_scaffold.dart';
import 'package:manhwamaniacs/skins/glass/shell/global_keys.dart'
    show registerSearchFocus, useGlassRefresh;
import 'package:manhwamaniacs/skins/skins.dart';

/// For you and Ask (glass 9.1.2, ScreenId `picks`).
class ForYouScreen extends ConsumerStatefulWidget {
  const ForYouScreen({super.key, this.genre});
  final String? genre;

  @override
  ConsumerState<ForYouScreen> createState() => _ForYouScreenState();
}

class _ForYouScreenState extends ConsumerState<ForYouScreen> {
  final TextEditingController _text = TextEditingController();
  final FocusNode _focus = FocusNode(debugLabel: 'AskBox');
  final GlobalKey _askKey = GlobalKey();
  final GlassPullToRefreshController _refresh = GlassPullToRefreshController();
  final Object _token = Object();
  bool _onlyMine = false, _useTaste = true, _grid = false;
  VoidCallback? _offSearch, _offRefresh;
  late final ShortcutRegistry _shortcuts =
      ref.read(shortcutRegistryProvider.notifier);

  bool get _novels =>
      ref.read(contentModeControllerProvider) == ContentMode.novel;

  @override
  void initState() {
    super.initState();
    _offSearch = registerSearchFocus(_focus);
    _offRefresh = useGlassRefresh(() => unawaited(_refresh.refresh()));
    _text.addListener(() => mounted ? setState(() {}) : null);
    Future.microtask(() {
      if (!mounted) return;
      _shortcuts.register(_token, [
        for (final (d, k, s) in [
          ('Focus the Ask box', ['/'], true),
          ('Ask', ['Enter'], false),
          ('Cancel the ask', ['Esc'], false),
          ('Fill an example and ask', ['Alt', '1 to 3'], false),
          ('Next and previous answer', ['J', 'K'], true),
          ("Open an answer's menu", ['.'], true),
          ('Not interested', ['Delete'], false),
        ])
          ShortcutEntry(
              group: 'For you',
              activator: const SingleActivator(LogicalKeyboardKey.abort),
              description: d,
              onInvoke: () {},
              keys: k,
              singleKey: s,),
      ]);
      final draft = ref.read(pendingAskProvider.notifier).take();
      if (draft != null && draft.trim().isNotEmpty) {
        _text.text = draft;
        _ask();
      }
    });
  }

  @override
  void dispose() {
    _offSearch?.call();
    _offRefresh?.call();
    final s = _shortcuts, t = _token;
    Future.microtask(() => s.unregister(t));
    _text.dispose();
    _focus.dispose();
    _refresh.dispose();
    super.dispose();
  }

  bool get _canAsk {
    final n = _text.text.trim().characters.length;
    return n >= kAskMin && n <= kAskMax;
  }

  void _ask([String? _]) {
    if (!_canAsk) return;
    unawaited(ref.read(askControllerProvider.notifier).ask((
      prompt: _text.text.trim(),
      onlyMine: _onlyMine,
      useTaste: _useTaste,
      novels: _novels
    ),),);
  }

  void _example(int i) {
    _text.text = kAskExamples[i];
    _ask();
  }

  Future<RefreshResult> _onRefresh() async {
    ref.invalidate(worldRecommendationsProvider);
    ref.invalidate(suggestAvailabilityProvider);
    try {
      await ref.read(worldRecommendationsProvider(widget.genre).future);
    } catch (_) {}
    return RefreshResult.changed;
  }

  void _clearGenre() => context.replace(Routes.picks());

  KeyEventResult _key(FocusNode n, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    if (e.logicalKey == LogicalKeyboardKey.escape &&
        ref.read(askControllerProvider).phase == AskPhase.asking) {
      ref.read(askControllerProvider.notifier).cancel();
      return KeyEventResult.handled;
    }
    final typing = FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<EditableText>() !=
        null;
    if (typing) return KeyEventResult.ignored;
    if (e.logicalKey == LogicalKeyboardKey.keyJ) {
      FocusScope.of(context).nextFocus();
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.keyK) {
      FocusScope.of(context).previousFocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final ask = ref.watch(askControllerProvider);
    final avail = ref.watch(suggestAvailabilityProvider);
    final novels =
        ref.watch(contentModeControllerProvider) == ContentMode.novel;
    final recs = ref.watch(worldRecommendationsProvider(widget.genre));
    final admin = ref.watch(authControllerProvider
        .select((a) => a is AuthAuthenticated && a.user.isAdmin),);
    final phone = GlassFrame.of(context) == GlassFrameKind.phone;

    // Why the Ask box is replaced by a notice, if it is.
    String? closed;
    if (avail.hasError) {
      closed = 'offline';
    } else if (avail.valueOrNull != null && !avail.value!.available) {
      closed = avail.value!.reason;
    }
    final f = ask.failure;
    if (f != null) {
      closed ??= switch (f.code) {
        'ai_budget_exhausted' => 'budget_exhausted',
        'ai_not_configured' => 'not_configured',
        'offline' => 'offline',
        'ai_failed' => 'upstream_error',
        _ => null,
      };
    }
    final asking = ask.phase == AskPhase.asking;
    final remaining = ask.remaining ?? avail.valueOrNull?.remainingToday;

    Widget? failure;
    if (f != null && closed == null) {
      failure = switch (f.code) {
        'ai_no_matches' => const AskFailureNote(text: kNoMatches),
        'suggest_shelf_empty' => AskFailureNote(
            text: kShelfEmpty,
            action: 'Browse sources',
            onAction: () => unawaited(
                ref.read(skinRouterProvider).push<void>(Routes.sources()),),),
        'timeout' => AskFailureNote(
            text: timeoutLine, action: 'Try again', onAction: _ask,),
        _ => null,
      };
    }

    // GlassScaffold insets the slivers and the large title by the screen margin.
    final body = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: phone ? double.infinity : 1200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.genre != null)
            Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GenreFilterChip(
                    genre: widget.genre!, onClear: _clearGenre,),),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (closed != null)
                  closed == 'budget_exhausted'
                      ? const BudgetNotice()
                      : AiNotice(
                          reason: closed,
                          long: true,
                          admin: admin,
                          retrySeconds: ask.retryIn,)
                else ...[
                  AskBox(
                      controller: _text,
                      focusNode: _focus,
                      thinking: asking,
                      onSubmit: _ask,),
                  AskExamples(onPick: (t) {
                    _text.text = t;
                    _ask();
                  },),
                  AskControls(
                    buttonKey: _askKey,
                    canAsk: _canAsk,
                    asking: asking,
                    onAsk: _ask,
                    onlyMine: _onlyMine,
                    onOnlyMine: (v) => setState(() => _onlyMine = v),
                    useTaste: _useTaste,
                    onUseTaste: (v) => setState(() => _useTaste = v),
                    novels: novels,
                    remaining: remaining,
                    retryIn: f?.code == 'rate_limited' ? ask.retryIn : null,
                  ),
                  if (asking)
                    AskingPanel(
                        elapsed: ask.elapsed,
                        onCancel:
                            ref.read(askControllerProvider.notifier).cancel,),
                  if (failure != null) failure,
                  if (f?.code == 'rate_limited')
                    AiNotice(
                        reason: 'rate_limited',
                        long: true,
                        retrySeconds: ask.retryIn ?? 0,),
                  if (ask.phase == AskPhase.results)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: AnswerList(
                        key: ValueKey('answers-${ask.serial}'),
                        answers: ask.items,
                        askButtonKey: _askKey,
                        asGrid: _grid,
                        animateDeal: true,
                        onAskAgain: _ask,
                        onToggleGrid: () => setState(() => _grid = !_grid),
                      ),
                    ),
                  if (ask.phase == AskPhase.results && ask.partial)
                    const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: AskFailureNote(
                            text: glassAiPartialLine,),),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          ForYouSections(
              recs: recs,
              genre: widget.genre,
              novels: novels,
              onClearGenre: _clearGenre,
              onRetry: () =>
                  ref.invalidate(worldRecommendationsProvider(widget.genre)),),
          const SizedBox(height: 40),
        ],
      ),
    );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.digit1, alt: true): () =>
            _example(0),
        const SingleActivator(LogicalKeyboardKey.digit2, alt: true): () =>
            _example(1),
        const SingleActivator(LogicalKeyboardKey.digit3, alt: true): () =>
            _example(2),
      },
      child: Focus(
        autofocus: true,
        skipTraversal: true,
        onKeyEvent: _key,
        child: GlassScaffold(
          title: 'For you',
          leading: GlassLeading.back,
          contentModeSwitch: true,
          refreshSliver:
              GlassPullToRefresh(controller: _refresh, onRefresh: _onRefresh),
          largeTitleOverride: Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
            child: LetterReveal('What do you feel like?',
                role: gt.typeLargeTitle,
                revealKey: 'picks:title',
                screenId: kPicksScreenId,
                headingLevel: 1,),
          ),
          slivers: [SliverToBoxAdapter(child: body)],
        ),
      ),
    );
  }
}
