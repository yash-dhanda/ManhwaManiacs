import 'dart:async';

import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/circle/utils/letters.dart' show noteLength, noteLimit;
import 'package:manhwamaniacs/features/circle/utils/letters_deferred.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/parts/recommend/letter_schedule.dart';
import 'package:manhwamaniacs/skins/glass/parts/recommend/recommend_sheet.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/text_area.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_sheet_route.dart';
import 'package:manhwamaniacs/skins/glass/routes/sheet_registry.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// Registers `?sheet=letter-note` (glass 9.3.4): `medium`, the 560 px window on the desktop frame.
void registerLetterNoteSheet() => registerGlobalSheet(
      'letter-note',
      const GlassSheetSpec(title: 'Add a note', builder: _note, detents: [GlassDetent.medium], opening: GlassDetent.medium),
    );

Widget _note(BuildContext context) => const LetterNoteBody();

/// "Why they'll like it" (140 characters, a `mono` counter) and "Send": sends the held letter at once with the note. A cold link
/// (`&to=&series=`) sends a new letter. Closing the sheet without Send lets the held letter go out without a note.
class LetterNoteBody extends ConsumerStatefulWidget {
  const LetterNoteBody({super.key});

  @override
  ConsumerState<LetterNoteBody> createState() => _LetterNoteBodyState();
}

class _LetterNoteBodyState extends ConsumerState<LetterNoteBody> {
  final TextEditingController _c = TextEditingController();
  late final PendingLetter? _held;
  late final ProviderContainer _container;
  bool _sent = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _held = ref.read(heldLetterProvider);
    _container = ProviderScope.containerOf(context, listen: false);
  }

  @override
  void dispose() {
    _c.dispose();
    final held = _held;
    if (held != null) {
      if (!_sent) unawaited(held.flush());
      try {
        _container.read(heldLetterProvider.notifier).state = null;
      } catch (_) {}
    }
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _busy = true);
    final held = _held;
    if (held != null) {
      _sent = true;
      await held.sendWithNote(_c.text);
    } else {
      final q = currentQuery(ref);
      final s = parseSeries(q['series']);
      final to = int.tryParse(q['to'] ?? '');
      if (s != null && to != null) {
        final err = await ref.read(circleActionsProvider).sendLetter(toProfileIds: [to], sourceId: s.sourceId, seriesKey: s.seriesKey, note: _c.text);
        if (err != null) {
          if (mounted) setState(() => _busy = false);
          ref.read(glassToastProvider.notifier).show(const GlassToastSpec("Couldn't send that", kind: GlassToastKind.error));
          return;
        }
      }
      _sent = true;
    }
    glassFire(ref, HapticEvent.recommendSend);
    if (mounted) unawaited(Navigator.of(context).maybePop());
  }

  @override
  Widget build(BuildContext context) {
    final m = GlassFrame.screenMargin(context);
    return Material(type: MaterialType.transparency, child: ListView(
      padding: EdgeInsets.fromLTRB(m, 4, m, 24),
      children: [
        GlassTextArea(controller: _c, label: "Why they'll like it", maxLength: kNoteMax, inputFormatters: [noteLimit], showCounter: false, onChanged: (_) => setState(() {})),
        Align(alignment: Alignment.centerRight, child: Padding(padding: const EdgeInsets.only(top: 4), child: GlassText('${noteLength(_c.text)}/$kNoteMax', role: gt.typeMono, color: gt.colorLabel2))),
        const SizedBox(height: 16),
        GlassButton(label: 'Send', variant: GlassButtonVariant.primary, fullWidth: true, loading: _busy, onPressed: _busy ? null : () => unawaited(_send())),
      ],
    ),);
  }
}
