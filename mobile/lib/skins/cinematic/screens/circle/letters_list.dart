import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/circle/models/circle_models.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/circle/utils/letters.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/features/library/utils/cover_url.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/circle_follow.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cards/cine_letter_card.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/layout/cine_grid.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/circle/circle_states.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// Letters that have already unfolded this session (a letter unfolds once).
final unfoldedLettersProvider = StateProvider<Set<int>>((ref) => <int>{}, name: 'unfoldedLetters');

/// Letter actions shared by the Circle's tab and aside and Tonight's `Sent to you`.
class LetterActions {
  LetterActions(this.context, this.ref);
  final BuildContext context;
  final WidgetRef ref;

  Future<bool> _patch(Letter l, LetterState to) async {
    final ok = await ref.read(lettersProvider.notifier).patch(l.id, to);
    if (!ok) ref.read(cineToastsProvider.notifier).error("Couldn't update the letter.");
    return ok;
  }

  /// Opens the series and marks the letter read.
  Future<void> read(Letter l) async {
    unawaited(context.push(Routes.feature(l.sourceId, l.seriesKey)));
    if (l.state == LetterState.newLetter) await _patch(l, LetterState.read);
  }

  Future<void> add(Letter l) async {
    final ok = await circleFollow(context, ref, sourceId: l.sourceId, seriesKey: l.seriesKey, title: l.title);
    if (ok && l.state == LetterState.newLetter) await _patch(l, LetterState.read);
  }

  Future<void> keep(Letter l) async {
    if (await _patch(l, LetterState.kept)) ref.read(cineToastsProvider.notifier).info('Kept. It stays in Sent to you.');
  }

  Future<void> dismiss(Letter l) => _patch(l, LetterState.dismissed);

  Future<void> markRead(Letter l) => _patch(l, LetterState.read);
}

/// The letters (cinematic 9.3.4): `new` and kept ones, newest first, as Letter cards. A `new` letter
/// unfolds the first time it renders and turns `read` after 2000 ms at 50 % visibility.
class LettersList extends ConsumerStatefulWidget {
  const LettersList({super.key, required this.letters, this.duplicateNames = const {}, this.scrollable = true, this.focusFirst, this.leadingSlivers = const []});
  final List<Letter> letters;
  final Set<String> duplicateNames;

  /// False in the tablet aside: a column that does not scroll on its own.
  final bool scrollable;
  final FocusNode? focusFirst;
  final List<Widget> leadingSlivers;

  @override
  ConsumerState<LettersList> createState() => _LettersListState();
}

class _LettersListState extends ConsumerState<LettersList> {
  final _viewport = GlobalKey();
  final Map<int, GlobalKey> _keys = {};
  final Set<int> _shown = {};
  final Set<int> _ready = {}; // unfolded, eligible for the read rule
  final Map<int, Timer> _timers = {};

  @override
  void dispose() {
    for (final t in _timers.values) {
      t.cancel();
    }
    super.dispose();
  }

  double _fraction(int id) {
    final v = _viewport.currentContext?.findRenderObject() as RenderBox?;
    final b = _keys[id]?.currentContext?.findRenderObject() as RenderBox?;
    if (v == null || b == null || !v.hasSize || !b.hasSize || !b.attached) return 0;
    return visibleFraction(b.localToGlobal(Offset.zero) & b.size, v.localToGlobal(Offset.zero) & v.size);
  }

  void _check() {
    if (!mounted) return;
    for (final l in widget.letters) {
      if (l.state != LetterState.newLetter || !_ready.contains(l.id)) continue;
      final vis = _fraction(l.id) >= letterReadFraction;
      if (vis && !_timers.containsKey(l.id)) {
        _timers[l.id] = Timer(letterReadAfter, () {
          _timers.remove(l.id);
          if (mounted && _fraction(l.id) >= letterReadFraction) unawaited(LetterActions(context, ref).markRead(l));
        });
      } else if (!vis) {
        _timers.remove(l.id)?.cancel();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final grid = CineGrid.of(context);
    final base = ref.watch(apiBaseUrlProvider);
    final online = ref.watch(deviceOnlineProvider).valueOrNull ?? true;
    final unfolded = ref.watch(unfoldedLettersProvider);
    for (final l in widget.letters) {
      if (l.state == LetterState.newLetter || l.state == LetterState.kept) _shown.add(l.id);
    }
    final shown = [for (final l in widget.letters) if (_shown.contains(l.id) && l.state != LetterState.dismissed) l];
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
    final actions = LetterActions(context, ref);
    final cards = <Widget>[
      for (var i = 0; i < shown.length; i++)
        Padding(
          key: _keys.putIfAbsent(shown[i].id, GlobalKey.new),
          padding: EdgeInsets.only(bottom: c.space4),
          child: Builder(builder: (context) {
            final l = shown[i];
            final firstTime = l.state == LetterState.newLetter && !unfolded.contains(l.id);
            return CineLetterCard(
              key: ValueKey('letter-${l.id}'),
              from: l.from.name,
              kicker: 'FROM ${l.from.name.toUpperCase()}${widget.duplicateNames.contains(l.from.name) && l.from.username != null ? ' (@${l.from.username})' : ''}',
              title: l.title,
              note: l.note,
              imageUrl: historyCoverUrl(base, l.coverUrl),
              duo: l.ambient?.duo,
              isNew: l.state == LetterState.newLetter,
              unfold: firstTime,
              focusNode: i == 0 ? widget.focusFirst : null,
              actionsEnabled: online,
              disabledHint: CircleCopy.needsConnection,
              onUnfolded: () {
                if (!mounted) return;
                _ready.add(l.id);
                WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(unfoldedLettersProvider.notifier).update((s) => {...s, l.id}));
                _check();
              },
              onOpen: () => unawaited(actions.read(l)),
              onRead: () => unawaited(actions.read(l)),
              onAdd: () => unawaited(actions.add(l)),
              onKeep: l.state == LetterState.kept ? null : () => unawaited(actions.keep(l)),
              onDismiss: () => unawaited(actions.dismiss(l)),
            );
          },),
        ),
    ];
    // A letter that has already unfolded is ready at once.
    for (final l in shown) {
      if (unfolded.contains(l.id)) _ready.add(l.id);
    }
    if (shown.isEmpty) {
      return widget.scrollable
          ? CustomScrollView(slivers: [...widget.leadingSlivers, const SliverToBoxAdapter(child: CircleTabEmpty(text: CircleCopy.emptyLetters))])
          : const CircleTabEmpty(text: CircleCopy.emptyLetters);
    }
    final pad = EdgeInsets.fromLTRB(grid.left, c.space4, grid.right, 96);
    if (!widget.scrollable) return Padding(padding: EdgeInsets.only(top: c.space4), child: Column(key: _viewport, crossAxisAlignment: CrossAxisAlignment.stretch, children: cards));
    return NotificationListener<ScrollNotification>(
      onNotification: (_) {
        _check();
        return false;
      },
      child: CustomScrollView(
        key: _viewport,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          ...widget.leadingSlivers,
          SliverPadding(padding: pad, sliver: SliverList(delegate: SliverChildListDelegate(cards))),
        ],
      ),
    );
  }
}
