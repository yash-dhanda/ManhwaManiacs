import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/app/router/routes.dart';
import 'package:manhwamaniacs/app/theme/app_colors.dart';
import 'package:manhwamaniacs/app/theme/app_presets.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/features/library/providers/intelligence_providers.dart';
import 'package:manhwamaniacs/features/library/widgets/recommendations/world_title_card.dart';
import 'package:manhwamaniacs/shared/widgets/empty_state.dart';
import 'package:manhwamaniacs/shared/widgets/premium/hero_heading.dart';
import 'package:manhwamaniacs/shared/widgets/premium/primary_pill_button.dart';
import 'package:manhwamaniacs/shared/widgets/skeleton_box.dart';

/// "Find something to read" — titles from the whole world, not only from the
/// series this server happens to have cached.
///
/// Three parts, top to bottom: the AI prompt box and its answers (when the
/// server can run it), "For you", and one "Because you read …" row per book
/// the reader has been deepest into. Every card says whether one of the
/// reader's own sources carries the title; see [WorldTitleCard].
///
/// The genre chips that used to close the page are gone: they searched titles
/// for a genre word and came back with noise.
class RecommendationsScreen extends ConsumerStatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  ConsumerState<RecommendationsScreen> createState() =>
      _RecommendationsScreenState();
}

class _RecommendationsScreenState extends ConsumerState<RecommendationsScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    ref.read(suggestionsProvider.notifier).submit(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final availability = ref.watch(suggestAvailabilityProvider);
    final suggestions = ref.watch(suggestionsProvider);
    final recommendations = ref.watch(recommendationsProvider);

    // An unconfigured server is a deployment state, not an error to put in
    // front of a reader: the box is simply absent and the rows remain.
    final state = availability.asData?.value;
    final canAsk = state?.available ?? false;
    // "not_configured" and "budget_exhausted" both hide the box, but only one
    // of them is worth a sentence: a server with no key was never going to
    // offer this, while a reader who just spent the 60th request of the day
    // watched the box vanish out from under them and deserves to be told it
    // comes back rather than silently reading as broken or removed.
    final budgetExhausted = state?.isBudgetExhausted ?? false;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.library),
        ),
        title: const Text('Find something to read'),
      ),
      // Pull-to-refresh re-asks for the rows and for whether the box can
      // run — the two things a flaky connection leaves stale. Never the
      // suggestions: a pull is not a request to spend another AI call.
      body: RefreshIndicator(
        color: context.colors.primary,
        onRefresh: () async {
          ref
            ..invalidate(recommendationsProvider)
            ..invalidate(suggestAvailabilityProvider);
          // Held until the rows answer, so the spinner means something. A
          // failure is not rethrown: the section below draws it with Retry.
          try {
            await ref.read(recommendationsProvider.future);
          } catch (_) {}
        },
        child: ListView(
          // Short content still has to be pullable, or an error screen that
          // fits on one page could never be refreshed.
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(context.space.xl2),
          children: [
            const HeroHeading(text: 'What do you feel like?'),
            SizedBox(height: context.space.xs),
            Text(
              canAsk
                  ? 'Describe it in your own words. Answers come from '
                      "everything out there, weighed against what you've read."
                  : budgetExhausted
                      ? "You've used today's AI suggestions. They reset at "
                          'midnight UTC — the picks below are still yours.'
                      : 'Picks from everything out there, based on what you '
                          'read.',
              style: context.text.body.copyWith(color: context.colors.muted),
            ),
            if (canAsk) ...[
              SizedBox(height: context.space.xl),
              _PromptBox(
                controller: _controller,
                onSubmit: _submit,
                busy: suggestions.isLoading,
                remainingToday: state?.remainingToday,
              ),
            ],
            SizedBox(height: context.space.xl2),
            _SuggestionsSection(suggestions: suggestions, onRetry: _submit),
            _WorldSection(recommendations: recommendations),
          ],
        ),
      ),
    );
  }
}

class _PromptBox extends StatefulWidget {
  const _PromptBox({
    required this.controller,
    required this.onSubmit,
    required this.busy,
    this.remainingToday,
  });

  final TextEditingController controller;
  final VoidCallback onSubmit;
  final bool busy;

  /// Requests left in today's allowance. Null while availability is still
  /// loading — nothing renders for that, rather than a flash of "0 left".
  final int? remainingToday;

  /// Concrete enough to show the box takes a sentence, not a keyword. A reader
  /// shown "action, fantasy" types "action, fantasy" and gets a search.
  static const _examples = <String>[
    'A murim regressor who comes back stronger',
    'Magic academy, but the lead is already strong',
    'Something slow and political, not a power fantasy',
  ];

  @override
  State<_PromptBox> createState() => _PromptBoxState();
}

class _PromptBoxState extends State<_PromptBox> {
  @override
  void initState() {
    super.initState();
    // The button's enabled state depends on the text, so it has to rebuild on
    // every keystroke. Without this listener the CTA stays permanently live —
    // pressable, unresponsive to an empty box, and silent about why: the
    // notifier refuses anything under 3 characters with no state change at
    // all, so a tap on a dead button looked identical to a tap on a working
    // one. The web client gets this for free from `disabled={...}` re-running
    // on every render; a StatelessWidget here cannot.
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  bool get _canSubmit =>
      !widget.busy && widget.controller.text.trim().length >= 3;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          minLines: 2,
          maxLines: 4,
          maxLength: 600,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            hintText: 'e.g. a revenge story with a competent lead, no harem',
            filled: true,
            fillColor: context.colors.panel,
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.radii.lg),
              borderSide: BorderSide(color: context.colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.radii.lg),
              borderSide: BorderSide(color: context.colors.border),
            ),
          ),
        ),
        SizedBox(height: context.space.md),
        Wrap(
          spacing: context.space.sm,
          runSpacing: context.space.sm,
          children: [
            for (final example in _PromptBox._examples)
              ActionChip(
                label: Text(example, style: context.text.caption),
                backgroundColor: context.colors.panel,
                onPressed: widget.busy
                    ? null
                    : () {
                        widget.controller.text = example;
                        widget.onSubmit();
                      },
              ),
          ],
        ),
        SizedBox(height: context.space.lg),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryPillButton(
              label: widget.busy ? 'Thinking' : 'Suggest something',
              onPressed: _canSubmit ? widget.onSubmit : null,
            ),
            // Matches the web client's threshold: silent above 10 remaining,
            // shown once the day's allowance is close enough to matter.
            if (widget.remainingToday != null && widget.remainingToday! <= 10) ...[
              SizedBox(width: context.space.md),
              Text(
                '${widget.remainingToday} left today',
                style: context.text.caption.copyWith(color: context.colors.muted),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _SuggestionsSection extends StatelessWidget {
  const _SuggestionsSection({
    required this.suggestions,
    required this.onRetry,
  });

  final AsyncValue<WorldSuggestResponse?> suggestions;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return suggestions.when(
      loading: () => const _CardSkeletons(),
      error: (error, _) => Padding(
        padding: EdgeInsets.only(bottom: context.space.xl2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              error is AppError
                  ? error.userMessage
                  : "That didn't work. Try describing it differently.",
              style: context.text.body.copyWith(color: context.colors.danger),
            ),
            SizedBox(height: context.space.md),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
      // `dropped` is deliberately not mentioned: those are titles the model
      // named that the catalog could not verify, i.e. possibly invented.
      data: (result) {
        if (result == null || result.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: EdgeInsets.only(bottom: context.space.xl2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final item in result.items) ...[
                WorldTitleCard(item: item),
                SizedBox(height: context.space.md),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// "For you" and the "Because you read …" rows, with every state the request
/// can be in: a blank space for loading, failure and "nothing yet" alike is
/// how the page used to read as broken offline.
class _WorldSection extends ConsumerWidget {
  const _WorldSection({required this.recommendations});

  final AsyncValue<WorldRecommendations> recommendations;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void retry() => ref.invalidate(recommendationsProvider);

    return recommendations.when(
      loading: () => const _CardSkeletons(key: Key('world-loading')),
      error: (error, _) {
        if (error is NetworkError) {
          return EmptyState(
            icon: Icons.cloud_off_outlined,
            message: "You're offline",
            subtitle: error.userMessage,
            action: FilledButton(onPressed: retry, child: const Text('Retry')),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              error is AppError
                  ? error.userMessage
                  : "Couldn't load recommendations.",
              style: context.text.body.copyWith(color: context.colors.danger),
            ),
            SizedBox(height: context.space.md),
            FilledButton(onPressed: retry, child: const Text('Retry')),
          ],
        );
      },
      data: (recs) {
        final notice = recs.unavailableReason;
        // Nothing AND no reason: this profile has no reading to seed from.
        if (recs.isEmpty && notice == null) {
          return EmptyState(
            icon: Icons.auto_awesome_outlined,
            message: 'Read or follow a few series first',
            subtitle: 'Recommendations are built from what you read.',
            action: PrimaryPillButton(
              label: 'Browse Sources',
              onPressed: () => context.go(Routes.sources),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notice != null) _QuietNotice(text: notice),
            if (recs.forYou.isNotEmpty)
              _TitleRow(title: 'For you', items: recs.forYou),
            for (final section in recs.sections)
              if (section.items.isNotEmpty)
                _TitleRow(
                  title: 'Because you read ${section.becauseTitle}',
                  items: section.items,
                ),
          ],
        );
      },
    );
  }
}

/// A titled, horizontally scrolling row of cards.
///
/// Not a lazy `ListView`: that needs a fixed height, and a card's height
/// depends on its title, its actions and the reader's text size — a guess
/// clips or overflows. A row holds at most ~24 cards, so building them all is
/// cheap next to getting that wrong.
class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.title, required this.items});

  final String title;
  final List<WorldItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.space.xl2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.text.labelLg),
          SizedBox(height: context.space.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in items)
                  Padding(
                    padding: EdgeInsets.only(right: context.space.md),
                    child: SizedBox(
                      width: 300,
                      child: WorldTitleCard(item: item),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Why the rows are thin or missing when the worldwide catalog could not be
/// reached. Deliberately not an error: whatever did load is still usable.
class _QuietNotice extends StatelessWidget {
  const _QuietNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final muted = context.colors.muted;
    return Padding(
      padding: EdgeInsets.only(bottom: context.space.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: muted),
          SizedBox(width: context.space.sm),
          Expanded(
            child: Text(
              text,
              style: context.text.caption.copyWith(color: muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardSkeletons extends StatelessWidget {
  const _CardSkeletons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 3; i++) ...[
          const SkeletonBox(width: double.infinity, height: 124),
          SizedBox(height: context.space.md),
        ],
      ],
    );
  }
}
