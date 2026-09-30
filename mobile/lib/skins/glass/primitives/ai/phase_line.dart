import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/primitives/ai/ai_phase.dart';
import 'package:manhwamaniacs/skins/glass/primitives/ai/thinking_orbit.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// Announces an AI phase or arrival politely ("8 picks ready", "Some picks didn't come through").
void announceAiPolite(BuildContext context, String message) {
  try {
    unawaited(SemanticsService.sendAnnouncement(View.of(context), message, Directionality.of(context)));
  } catch (_) {}
}

/// The 64 px orbit beside its honest phase line (glass 7.38, 9.1.5): the server's `phase` or the timers, then after 40 s
/// "That took too long. Try again." with a Try again button (recaps add Continue). Each line is announced politely.
class PhaseLine extends StatefulWidget {
  const PhaseLine({super.key, required this.clock, this.onRetry, this.onContinue, this.size = 64});
  final AiPhaseClock clock;
  final VoidCallback? onRetry;

  /// Recaps only: keep going in the background.
  final VoidCallback? onContinue;
  final double size;

  @override
  State<PhaseLine> createState() => _PhaseLineState();
}

class _PhaseLineState extends State<PhaseLine> {
  String _announced = '';

  @override
  void initState() {
    super.initState();
    widget.clock.addListener(_changed);
    WidgetsBinding.instance.addPostFrameCallback((_) => _announce());
  }

  @override
  void didUpdateWidget(PhaseLine old) {
    super.didUpdateWidget(old);
    if (old.clock != widget.clock) {
      old.clock.removeListener(_changed);
      widget.clock.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.clock.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;
    setState(() {});
    _announce();
  }

  void _announce() {
    if (!mounted) return;
    final line = widget.clock.line;
    if (line.isEmpty || line == _announced) return;
    _announced = line;
    announceAiPolite(context, line);
  }

  @override
  Widget build(BuildContext context) {
    final abandoned = widget.clock.abandoned;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!abandoned) ThinkingOrbit(size: widget.size),
        if (!abandoned) const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(liveRegion: true, child: GlassText(widget.clock.line, role: gt.typeCallout, color: gt.colorLabel2)),
              if (abandoned)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(spacing: 8, children: [
                    GlassButton(label: 'Try again', size: GlassButtonSize.small, onPressed: widget.onRetry),
                    if (widget.onContinue != null) GlassButton(label: 'Continue', size: GlassButtonSize.small, variant: GlassButtonVariant.plain, onPressed: widget.onContinue),
                  ],),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
