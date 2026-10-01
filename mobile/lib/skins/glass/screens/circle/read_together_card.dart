import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/switch.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// "This profile doesn't share" (glass 9.3.1): a `surface1` card with "Read together", the promise, and the master switch "Share
/// what I'm reading" (a partial PATCH with only `activity: true`). Others' activity still shows below it.
class ReadTogetherCard extends ConsumerStatefulWidget {
  const ReadTogetherCard({super.key, this.compact = false});

  /// The share sheet's one-line form (glass 9.3.3).
  final bool compact;

  @override
  ConsumerState<ReadTogetherCard> createState() => _ReadTogetherCardState();
}

class _ReadTogetherCardState extends ConsumerState<ReadTogetherCard> {
  bool _busy = false;
  int _err = 0;

  Future<void> _turnOn() async {
    final pid = ref.read(activeProfileProvider)?.id;
    final cur = pid == null ? null : ref.read(sharingProvider(pid)).valueOrNull;
    if (pid == null || cur == null) return;
    setState(() => _busy = true);
    final ok = await ref.read(sharingProvider(pid).notifier).patch(cur.copyWith(activity: true));
    if (!mounted) return;
    glassFire(ref, ok ? HapticEvent.toggleOn : HapticEvent.error);
    setState(() {
      _busy = false;
      if (!ok) _err++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sw = GlassSwitch(value: false, label: "Share what I'm reading", loading: _busy, errorTrigger: _err, onChanged: (v) => v ? unawaited(_turnOn()) : null);
    if (widget.compact) {
      return Row(children: [
        Expanded(child: GlassText('This profile doesn\'t share yet. Turn on sharing to share shelves.', role: gt.typeFootnote, color: gt.colorLabel2)),
        sw,
      ],);
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: gt.colorSurface1, borderRadius: BorderRadius.circular(26)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Semantics(header: true, headingLevel: 2, child: GlassText('Read together', role: gt.typeTitle3)),
        const SizedBox(height: 8),
        GlassText(
          'Share what this profile reads with the other readers on this server: what you start and finish, your reactions, and the collections you choose to share. Never your bookmarks, searches or downloads.',
          role: gt.typeBody,
          color: gt.colorLabel2,
        ),
        const SizedBox(height: 12),
        Row(children: [Expanded(child: ExcludeSemantics(child: GlassText("Share what I'm reading", role: gt.typeHeadline))), sw]),
      ],),
    );
  }
}
