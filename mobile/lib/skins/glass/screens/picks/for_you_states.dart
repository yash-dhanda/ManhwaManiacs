import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/time/clock.dart';
import 'package:manhwamaniacs/skins/glass/copy/ai.dart';
import 'package:manhwamaniacs/skins/glass/primitives/ai/ai_notice.dart';
import 'package:manhwamaniacs/skins/glass/primitives/ai/thinking_orbit.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/thinking_phases.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// Seconds until the next 00:00 UTC (the AI budget resets then).
Duration untilUtcMidnight(DateTime now) {
  final u = now.toUtc();
  return DateTime.utc(u.year, u.month, u.day + 1).difference(u);
}

String clockOf(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
}

/// "You've used today's AI asks..." with a live countdown to 00:00 UTC.
class BudgetNotice extends ConsumerStatefulWidget {
  const BudgetNotice({super.key});

  @override
  ConsumerState<BudgetNotice> createState() => _BudgetNoticeState();
}

class _BudgetNoticeState extends ConsumerState<BudgetNotice> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(
        const Duration(seconds: 1), (_) => mounted ? setState(() {}) : null,);
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = untilUtcMidnight(ref.read(clockProvider)());
    return AiNotice(
        reason: 'budget_exhausted',
        long: true,
        alternative: GlassText('Resets in ${clockOf(left)}',
            role: gt.typeMono, size: 13, height: 16, color: gt.colorLabel2,),);
  }
}

/// The 64 px orbit with the honest phase line (announced politely), Cancel, and the abandon copy after 40 s.
class AskingPanel extends StatefulWidget {
  const AskingPanel({super.key, required this.elapsed, required this.onCancel});
  final Duration elapsed;
  final VoidCallback onCancel;

  @override
  State<AskingPanel> createState() => _AskingPanelState();
}

class _AskingPanelState extends State<AskingPanel> {
  String? _said;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final line = phaseLineAt(widget.elapsed);
    if (line != null && line != _said) {
      _said = line;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(SemanticsService.sendAnnouncement(
              View.of(context), line, Directionality.of(context),),);
        }
      });
    }
  }

  @override
  void didUpdateWidget(AskingPanel old) {
    super.didUpdateWidget(old);
    didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ThinkingOrbit(size: 64),
            const SizedBox(height: 12),
            GlassText(phaseLineAt(widget.elapsed) ?? '',
                role: gt.typeCallout,
                color: gt.colorLabel2,
                textAlign: TextAlign.center,),
            GlassButton(
                label: 'Cancel',
                variant: GlassButtonVariant.plain,
                onPressed: widget.onCancel,),
          ],
        ),
      );
}

/// One quiet line for an ask that ended without answers, with its one action.
class AskFailureNote extends StatelessWidget {
  const AskFailureNote(
      {super.key, required this.text, this.action, this.onAction,});
  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
                liveRegion: true,
                child: GlassText(text,
                    role: gt.typeCallout, color: gt.colorLabel2,),),
            if (action != null)
              GlassButton(
                  label: action!,
                  onPressed: onAction,),
          ],
        ),
      );
}

const String kNoMatches =
    'Nothing matched that. Try describing it differently.';
const String kShelfEmpty =
    'Read or follow a few series first. Picks here start from what you read.';
const String kCatalogueSaved =
    "The worldwide catalogue isn't reachable, so these picks come from a saved copy.";
const String kNovelsNote = 'Worldwide picks cover manga, manhwa and manhua.';
String noPicksIn(String genre) => 'No picks in $genre yet';
String get timeoutLine => glassAiTimeoutLine;
