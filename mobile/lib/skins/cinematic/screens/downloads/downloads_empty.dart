import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/library/models/continue_reading_item.dart';
import 'package:manhwamaniacs/features/library/providers/dashboard_providers.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_notice.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/downloads/downloads_actions.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// Nothing saved yet: the notice, then a rail of Continue reading with `Download next 5`.
class DownloadsEmpty extends ConsumerWidget {
  const DownloadsEmpty({super.key, this.preview});

  /// Test and proof hook: the rail's items instead of `continueReadingProvider`.
  final List<ContinueReadingItem>? preview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    final items = preview ?? ref.watch(continueReadingProvider).valueOrNull ?? const <ContinueReadingItem>[];
    return Column(
      key: const Key('downloads-empty'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CineNotice(
          tone: CineNoticeTone.empty,
          kicker: 'NOTHING SAVED YET',
          headline: 'Chapters you save open with no connection.',
        ),
        if (items.isNotEmpty) ...[
          SizedBox(height: c.space8),
          CineRoleText('CONTINUE READING', c.typeKicker, color: c.colorInk60),
          SizedBox(height: c.space3),
          SizedBox(
            height: 250,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => SizedBox(width: c.space3),
              itemBuilder: (context, i) => _Card(item: items[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _Card extends ConsumerStatefulWidget {
  const _Card({required this.item});
  final ContinueReadingItem item;

  @override
  ConsumerState<_Card> createState() => _CardState();
}

class _CardState extends ConsumerState<_Card> {
  bool _busy = false;

  Future<void> _download() async {
    if (_busy) return;
    setState(() => _busy = true);
    final toasts = ref.read(cineToastsProvider.notifier);
    try {
      final n = await downloadNextFive(ref, widget.item);
      toasts.info(n == 0 ? 'Nothing left to queue.' : 'Queued $n ${n == 1 ? 'chapter' : 'chapters'}.');
    } catch (_) {
      toasts.error("Couldn't reach the source. Try again.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final item = widget.item;
    final base = ref.watch(apiBaseUrlProvider);
    final cover = item.coverUrl == null
        ? '$base/sources/${Uri.encodeComponent(item.sourceId)}/series/${Uri.encodeComponent(item.seriesKey)}/cover'
        : (item.coverUrl!.startsWith('/') ? '$base${item.coverUrl}' : item.coverUrl);
    final title = item.title ?? item.seriesKey;
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: () => unawaited(context.push<void>(Routes.feature(item.sourceId, item.seriesKey), extra: const <String, String>{'transition': 'match'})),
            child: AspectRatio(
              aspectRatio: 2 / 3,
              child: DecoratedBox(
                decoration: BoxDecoration(color: c.colorPaper1),
                child: CineImage(url: cover, width: 120),
              ),
            ),
          ),
          SizedBox(height: c.space2),
          CineRoleText(title, c.typeTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: c.space2),
          if (_busy)
            const CineIndeterminateRule()
          else
            CineButton(label: 'Download next 5', variant: CineButtonVariant.secondary, size: CineButtonSize.sm, onPressed: _download),
        ],
      ),
    );
  }
}
