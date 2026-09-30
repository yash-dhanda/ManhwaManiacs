import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/inline_notice.dart';
import 'package:manhwamaniacs/skins/glass/shell/error_surface.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_providers.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The `warning` capsule's copy with a live countdown, replacing `{n}` seconds as it drops.
class GlassRateLimitCapsule extends ConsumerStatefulWidget {
  const GlassRateLimitCapsule({super.key, required this.limit});
  final GlassRateLimit limit;

  @override
  ConsumerState<GlassRateLimitCapsule> createState() => _GlassRateLimitCapsuleState();
}

class _GlassRateLimitCapsuleState extends ConsumerState<GlassRateLimitCapsule> {
  late int _left = widget.limit.seconds;
  late final Stream<int> _ticks = Stream.periodic(const Duration(seconds: 1), (i) => i + 1).take(widget.limit.seconds);

  @override
  Widget build(BuildContext context) => StreamBuilder<int>(
        stream: _ticks,
        builder: (context, snap) {
          _left = widget.limit.seconds - (snap.data ?? 0);
          final text = widget.limit.copy.replaceAll(RegExp(r'\d+ s'), '${_left < 0 ? 0 : _left} s');
          return Semantics(
            container: true,
            label: widget.limit.copy,
            excludeSemantics: true,
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: gt.colorFill2, borderRadius: BorderRadius.circular(16)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(GlassGlyph.warning.fill, size: 14, color: gt.colorWarning), const SizedBox(width: 6), GlassText(text, role: gt.typeFootnote, wght: 600, onGlass: true)]),
            ),
          );
        },
      );
}

/// The unreachable-server notice (glass 8.0.10): a top warning line with "Try again" while the server has not answered three times.
class GlassUnreachableNotice extends ConsumerWidget {
  const GlassUnreachableNotice({super.key, required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(glassOfflineProvider)) return const SizedBox.shrink();
    return GlassInlineNotice(message: "Can't reach the server. Your downloads still open.", variant: GlassNoticeVariant.warning, actionLabel: 'Try again', onAction: onRetry);
  }
}
