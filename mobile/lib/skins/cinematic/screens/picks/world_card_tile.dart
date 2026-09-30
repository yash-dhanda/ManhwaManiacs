import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/network/api_image.dart';
import 'package:manhwamaniacs/features/ai/providers/ai_providers.dart';
import 'package:manhwamaniacs/features/library/models/world_item.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/parts/quick_look_builders.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cards/cine_world_card.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:url_launcher/url_launcher.dart';

/// `MANHWA · ONGOING · ★ 8.4`; a shelf row is its source's name.
String worldKicker(WorldItem i) {
  if (i.shelf) return (i.available.firstOrNull?.sourceName ?? 'YOUR SOURCES').toUpperCase();
  return [i.format, i.status, i.ratingLabel].whereType<String>().join(' · ').toUpperCase();
}

/// `ON ASURA +1`; null for a title that is not on the reader's sources.
String? worldCredit(WorldItem i) {
  if (i.shelf) return i.author == null ? null : 'BY ${i.author!.toUpperCase()}';
  if (i.available.isEmpty) return 'NOT ON YOUR SOURCES';
  final more = i.available.length - 1;
  return 'ON ${i.available.first.sourceName.toUpperCase()}${more > 0 ? ' +$more' : ''}';
}

/// The one World card of every AI surface with its behaviour: opens the series (or the source
/// picker), Not for me (fade, then the item joins `dismissedPicksProvider` and the server is told)
/// and More like this (`liked_pick`, a toast, cleared locally by a second press). [index] staggers
/// the fade-in 30 ms per card when [animateIn].
class WorldCardTile extends ConsumerStatefulWidget {
  const WorldCardTile({super.key, required this.item, this.index = 0, this.animateIn = false, this.focusNode});
  final WorldItem item;
  final int index;
  final bool animateIn;
  final FocusNode? focusNode;

  @override
  ConsumerState<WorldCardTile> createState() => _WorldCardTileState();
}

class _WorldCardTileState extends ConsumerState<WorldCardTile> {
  bool _liked = false, _fading = false;

  Future<void> _notForMe() async {
    if (_fading) return;
    setState(() => _fading = true);
    final reduced = CineMotion.reduced(context);
    unawaited(ref.read(aiFeedbackProvider).notInterested(widget.item, hide: false));
    await Future<void>.delayed(reduced ? const Duration(milliseconds: 150) : const Duration(milliseconds: 240));
    if (!mounted) return;
    ref.read(dismissedPicksProvider.notifier).add(pickId(widget.item));
  }

  void _moreLikeThis() {
    cineFeedback(context, HapticEvent.select, sound: SoundEvent.select);
    if (_liked) {
      setState(() => _liked = false);
      return;
    }
    setState(() => _liked = true);
    unawaited(ref.read(aiFeedbackProvider).likedPick(widget.item));
    ref.read(cineToastsProvider.notifier).info('Noted. Picks will lean this way.');
  }

  Future<void> _readOn() async {
    final site = widget.item.readElsewhere;
    if (site == null) return;
    final ok = await launchUrl(Uri.parse(site.url), mode: LaunchMode.externalApplication).catchError((Object _) => false);
    if (!ok && mounted) ref.read(cineToastsProvider.notifier).error("Couldn't open ${site.url}");
  }

  @override
  Widget build(BuildContext context) {
    final i = widget.item;
    final gate = ref.watch(matureContentProvider).valueOrNull ?? false;
    final reduced = CineMotion.reduced(context);
    final kind = i.shelf ? CineWorldKind.shelf : (i.available.isEmpty ? CineWorldKind.infoOnly : CineWorldKind.available);
    final base = ref.read(apiBaseUrlProvider);
    final cover = i.coverUrl == null ? null : resolveApiResourceUrl(base, i.coverUrl!);
    final card = CineWorldCard(
      kind: kind,
      title: i.title,
      kicker: worldKicker(i),
      imageUrl: cover,
      why: i.why,
      credit: worldCredit(i),
      duo: i.ambient?.duo,
      adult: i.isAdult,
      gateOpen: gate,
      readOnLabel: i.readElsewhere?.site,
      withCredentials: i.shelf,
      focusNode: widget.focusNode,
      liked: _liked,
      onOpen: () => openWorldItem(context, i),
      onSearchMySources: () => context.go(Uri.parse(Routes.discover()).replace(queryParameters: {'q': i.title}).toString()),
      onReadOn: i.readElsewhere == null ? null : () => unawaited(_readOn()),
      onDismiss: _notForMe,
      onMoreLikeThis: _moreLikeThis,
    );
    final faded = AnimatedOpacity(opacity: _fading ? 0 : 1, duration: reduced ? const Duration(milliseconds: 150) : const Duration(milliseconds: 240), curve: Curves.easeInCubic, child: card);
    if (!widget.animateIn) return faded;
    // Each card fades in over 160 ms, 30 ms after the previous (one 160 ms fade when reduced).
    final delay = reduced ? 0 : 30 * widget.index;
    final total = 160 + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delay / total, 1),
      builder: (_, v, child) => Opacity(opacity: v, child: child),
      child: faded,
    );
  }
}
