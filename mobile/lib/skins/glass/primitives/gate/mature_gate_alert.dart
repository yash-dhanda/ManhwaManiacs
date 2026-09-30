import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/icons/glass_glyphs.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/alert.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/hold_to_confirm.dart';

/// The 18+ gate alert (glass 7.25, 14.11): the `age-gate` glyph 32 in `mature` on a 40 px backing disc, the exact title and body,
/// a hold button ("Hold: I am 18 or older", 1,200 ms) and, always visible to everyone, "I am 18 or older, enable"; Cancel is the
/// least destructive action and has initial focus. It blooms from [sourceRect] (the switch). Resolves true only on the hold
/// completing or the enable button.
Future<bool> showMatureGateAlert(BuildContext context, {Rect? sourceRect}) async {
  final r = await showGlassAlert<bool>(
    context,
    title: 'Show mature content?',
    body: 'Adult (18+) sources, search results and recommendations will appear for this profile. Only continue if you are of legal age where you live. You can turn this off at any time.',
    sourceRect: sourceRect,
    leading: GlassBacking(size: 40, child: Icon(GlassGlyphs.ageGateRegular, size: 32, color: gt.colorMature)),
    extra: Builder(
      builder: (c) => HoldToConfirm(
        label: 'Hold: I am 18 or older',
        mode: HoldMode.inAlert,
        fallbackLabel: 'I am 18 or older, enable',
        onConfirm: () => Navigator.of(c).pop(true),
      ),
    ),
    actions: const [GlassAlertAction<bool>('Cancel', role: GlassAlertRole.cancel, value: false)],
  );
  return r ?? false;
}
