import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart' show GlassIconWeight;
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/progress.dart';
import 'package:manhwamaniacs/skins/glass/skin_glass.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

enum GlassStatusKind { offline, savedCopy, syncing, rateLimit }

/// The status capsules (glass 7.30): `glassThin` 32 tall, glyph and `footnote` 600 `onGlass`. "Offline" and "Saved copy
/// · 2 h" carry a `warning` `wifi-slash` on the backing disc, "Syncing" a spinner, and the rate-limit capsule "Sources
/// are busy. Retrying in 12 s" a live countdown. "Offline" and the rate-limit capsule are announced once (polite) when
/// they first appear; the countdown is not re-announced. It materialises in and dematerialises out. With [inGroup] (a
/// toolbar group, `mobile/29`) it draws as a shape of its host group and adds no layer.
class GlassStatusCapsule extends StatefulWidget {
  const GlassStatusCapsule({super.key, required this.kind, this.savedAgo = '2 h', this.retryInSeconds = 12, this.inGroup = false, this.visible = true, this.onRetryTick});
  final GlassStatusKind kind;
  final String savedAgo;
  final int retryInSeconds;
  final bool inGroup;
  final bool visible;
  final ValueChanged<int>? onRetryTick;

  @override
  State<GlassStatusCapsule> createState() => _GlassStatusCapsuleState();
}

class _GlassStatusCapsuleState extends State<GlassStatusCapsule> {
  final GlobalKey<SkinGlassState> _glass = GlobalKey();
  late int _left = widget.retryInSeconds;
  Timer? _timer;
  bool _shown = true;

  @override
  void initState() {
    super.initState();
    _shown = widget.visible;
    if (widget.kind == GlassStatusKind.rateLimit) _startTimer();
    if (widget.kind == GlassStatusKind.offline || widget.kind == GlassStatusKind.rateLimit) _announce();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_left > 0) setState(() => _left--);
      widget.onRetryTick?.call(_left);
      if (_left <= 0) t.cancel();
    });
  }

  void _announce() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        unawaited(SemanticsService.sendAnnouncement(View.of(context), _text(counting: false), Directionality.of(context)));
      } catch (_) {}
    });
  }

  @override
  void didUpdateWidget(GlassStatusCapsule old) {
    super.didUpdateWidget(old);
    if (old.visible && !widget.visible) {
      final f = _glass.currentState?.dematerialize();
      if (f != null) {
        unawaited(f.then((_) {
          if (mounted) setState(() => _shown = false);
        }),);
      } else {
        setState(() => _shown = false);
      }
    } else if (!old.visible && widget.visible) {
      setState(() => _shown = true);
    }
    if (old.retryInSeconds != widget.retryInSeconds) _left = widget.retryInSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _text({bool counting = true}) => switch (widget.kind) {
        GlassStatusKind.offline => 'Offline',
        GlassStatusKind.savedCopy => 'Saved copy · ${widget.savedAgo}',
        GlassStatusKind.syncing => 'Syncing',
        GlassStatusKind.rateLimit => 'Sources are busy. Retrying in ${counting ? _left : widget.retryInSeconds} s',
      };

  @override
  Widget build(BuildContext context) {
    if (!_shown) return const SizedBox.shrink();
    final warn = widget.kind == GlassStatusKind.offline || widget.kind == GlassStatusKind.savedCopy || widget.kind == GlassStatusKind.rateLimit;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.kind == GlassStatusKind.syncing) const GlassSpinner(size: 14) else if (warn) GlassBacking(size: 20, child: GlyphIcon(GlassGlyph.wifiSlash, size: 14, color: gt.colorWarning, weight: GlassIconWeight.bold)),
          const SizedBox(width: 6),
          Flexible(child: GlassText(_text(), role: gt.typeFootnote, wght: 600, onGlass: true, maxScale: 1.5)),
        ],
      ),
    );
    return Semantics(
      container: true,
      label: _text(counting: false),
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 32),
        child: widget.inGroup
            ? Center(widthFactor: 1, heightFactor: 1, child: content)
            : GlassHost(
                child: Stack(
                  children: [
                    Positioned.fill(child: SkinGlass(key: _glass, tier: GlassTierId.t2, layer: GlassLayerKind.hud, debugLabel: 'GlassStatusCapsule', child: const SizedBox.shrink())),
                    Center(widthFactor: 1, heightFactor: 1, child: content),
                  ],
                ),
              ),
      ),
    );
  }
}
