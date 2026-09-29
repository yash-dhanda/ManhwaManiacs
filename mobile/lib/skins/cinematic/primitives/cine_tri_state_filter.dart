import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

enum CineTriState { neutral, include, exclude }

/// The genre filter word: tap cycles neutral -> include -> exclude -> neutral; a 450 ms long-press
/// jumps straight to exclude (cinematic 7.5).
class CineTriStateFilter extends StatelessWidget {
  const CineTriStateFilter({super.key, required this.label, required this.value, required this.onChanged});
  final String label;
  final CineTriState value;
  final ValueChanged<CineTriState> onChanged;

  String get spoken => switch (value) {
        CineTriState.include => '$label: included',
        CineTriState.exclude => '$label: excluded',
        CineTriState.neutral => '$label: not filtered',
      };

  void _set(BuildContext context, CineTriState next) {
    cineFeedback(context, HapticEvent.select, sound: SoundEvent.select);
    onChanged(next);
    final msg = switch (next) {
      CineTriState.include => '$label: included',
      CineTriState.exclude => '$label: excluded',
      CineTriState.neutral => '$label: not filtered',
    };
    try {
      SemanticsService.sendAnnouncement(View.of(context), msg, Directionality.of(context));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final next = CineTriState.values[(value.index + 1) % 3];
    return Semantics(
      button: true,
      label: label,
      value: spoken,
      excludeSemantics: true,
      onTap: () => _set(context, next),
      onLongPress: () => _set(context, CineTriState.exclude),
      child: CinePressable(
        hit: false,
        onTap: () => _set(context, next),
        onLongPress: () => _set(context, CineTriState.exclude),
        builder: (context, st) {
          final included = value == CineTriState.include;
          final excluded = value == CineTriState.exclude;
          final hit = cineHitMin(context);
          return ConstrainedBox(
            constraints: BoxConstraints(minWidth: 44, minHeight: hit),
            child: Center(
              widthFactor: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Stack(clipBehavior: Clip.none, children: [
                  CineLit(
                    label,
                    CineFace.archivo,
                    12,
                    16,
                    upper: true,
                    wght: 600,
                    wdth: 75,
                    tracking: 0.10,
                    color: included || st.hovered ? c.colorInk100 : c.colorInk45,
                  ),
                  if (excluded)
                    Positioned.fill(child: Center(child: Container(height: 1, color: c.colorProof))),
                  if (included) Positioned(left: 0, right: 0, bottom: -6, height: 2, child: ColoredBox(color: c.colorSpot)),
                ],),
              ),
            ),
          );
        },
      ),
    );
  }
}
