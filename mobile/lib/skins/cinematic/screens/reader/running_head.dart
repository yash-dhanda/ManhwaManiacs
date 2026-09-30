import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/a11y/folio.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/cine_icon.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_icon_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/reader_tint.dart';
import 'package:manhwamaniacs/skins/cinematic/scrim_head.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The fade of the head scrim: 44 px on phones, 64 px from 600 px (cinematic 2.8.3).
double readerScrimFade(BuildContext context) => MediaQuery.sizeOf(context).width >= 600 ? 64 : 44;

/// The running head of the manga reader (cinematic 8.14.3): back, the series title and the
/// chapter folio as two separate targets, and an ordered list of trailing buttons, over a head
/// scrim. The scrim paints past the bar's bottom edge, so the bar keeps its own height.
class ReaderRunningHead extends StatelessWidget {
  const ReaderRunningHead({
    super.key,
    required this.seriesTitle,
    required this.folio,
    required this.onBack,
    required this.onOpenSeries,
    required this.onOpenContents,
    this.trailing = const [],
    this.loading = false,
    this.offlineEdition = false,
    this.houseSoundLabel,
    this.onOpenHouseSound,
  });

  final String seriesTitle;

  /// `CH 142`; while [loading] it reads `LOADING CH 142` and is no button.
  final String folio;
  final VoidCallback onBack, onOpenSeries, onOpenContents;
  final List<Widget> trailing;
  final bool loading, offlineEdition;

  /// `Rain on glass` while a house-sound loop plays: the `waveform` shows in the title group.
  final String? houseSoundLabel;
  final VoidCallback? onOpenHouseSound;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final hit = cineHitMin(context);
    final top = MediaQuery.viewPaddingOf(context).top;
    final fade = readerScrimFade(context);
    final gutter = MediaQuery.sizeOf(context).width >= 600 ? c.space8 : c.space4;
    final horizontal = MediaQuery.viewPaddingOf(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        scrimHeadLayer(fade: fade, tint: ReaderTintScope.of(context).tint),
        Padding(
          padding: EdgeInsets.only(top: top, left: horizontal.left + gutter - 8, right: horizontal.right + gutter - 8),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: hit),
            child: Row(
              children: [
                CineIconButton(label: 'Back to the series', role: CineIconRole.back, onPressed: onBack),
                const SizedBox(width: 8),
                Expanded(child: _Title(seriesTitle: seriesTitle, folio: folio, loading: loading, offline: offlineEdition, onOpenSeries: onOpenSeries, onOpenContents: onOpenContents, houseSoundLabel: houseSoundLabel, onOpenHouseSound: onOpenHouseSound)),
                for (final t in trailing) ...[const SizedBox(width: 8), t],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({
    required this.seriesTitle,
    required this.folio,
    required this.loading,
    required this.offline,
    required this.onOpenSeries,
    required this.onOpenContents,
    this.houseSoundLabel,
    this.onOpenHouseSound,
  });

  final String seriesTitle, folio;
  final bool loading, offline;
  final VoidCallback onOpenSeries, onOpenContents;
  final String? houseSoundLabel;
  final VoidCallback? onOpenHouseSound;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final hit = cineHitMin(context);
    final folioText = loading ? 'LOADING $folio' : folio;
    return LayoutBuilder(
      builder: (context, box) {
        // A narrow title group (four trailing buttons on a phone) drops the series name: every
        // target keeps its 44 / 48 hit area, so the folio is what stays.
        final roomForSeries = box.maxWidth >= hit * 2 + 16 + (houseSoundLabel != null ? hit : 0);
        return _row(context, c, hit, folioText, showSeries: roomForSeries);
      },
    );
  }

  Widget _row(BuildContext context, CineTokens c, double hit, String folioText, {required bool showSeries}) {
    return Row(
      children: [
        if (showSeries) Flexible(
          child: CinePressable(
            onTap: onOpenSeries,
            builder: (context, st) => ConstrainedBox(
              constraints: BoxConstraints(minHeight: hit),
              child: Semantics(
                button: true,
                label: seriesTitle,
                hint: 'Opens the series page',
                excludeSemantics: true,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: 1,
                  child: CineRoleText(seriesTitle, c.typeNav, color: st.hovered ? c.colorInk100 : c.colorInk60, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
            ),
          ),
        ),
        if (showSeries) ExcludeSemantics(child: CineRoleText(' · ', c.typeNav, color: c.colorInk45)),
        if (loading)
          Flexible(child: FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: CineRoleText(folioText, c.typeFolio, color: c.colorSpot)))
        else
          Flexible(
            flex: 3,
            child: _FolioButton(folioText: folioText, folio: folio, onOpenContents: onOpenContents),
          ),
        if (houseSoundLabel != null && onOpenHouseSound != null) HouseSoundWaveform(label: houseSoundLabel!, onTap: onOpenHouseSound!),
        if (offline) ...[
          const SizedBox(width: 8),
          // Scales down on a narrow head rather than overflowing beside the trailing buttons.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFF000000), border: Border.all(color: c.colorInk45)),
                child: CineRoleText('OFFLINE EDITION', c.typeMicro, color: c.colorInk60, maxLines: 1),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// The chapter folio (`CH 142`, or `CH 142 · 12 OF 201` in read-all) as its own target: it opens
/// Contents. On a narrow head it scales down rather than overflow.
class _FolioButton extends StatelessWidget {
  const _FolioButton({required this.folioText, required this.folio, required this.onOpenContents});
  final String folioText, folio;
  final VoidCallback onOpenContents;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final hit = cineHitMin(context);
    return CinePressable(
      onTap: onOpenContents,
      builder: (context, st) => Tooltip(
        message: 'Contents',
        excludeFromSemantics: true,
        child: Semantics(
          button: true,
          label: folioLabel(folio),
          hint: 'Contents',
          excludeSemantics: true,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: hit, minWidth: hit),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CineRoleText(folioText, c.typeFolio, color: c.colorSpot),
                  const SizedBox(width: 4),
                  CineGlyphIcon(ReaderCp.caretDown, size: 12, color: c.colorSpot),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The 16 px `waveform` after the folio's caret while a house-sound loop plays, with its own 44 / 48
/// hit: it opens Reading setup at AMBIENT.
class HouseSoundWaveform extends StatelessWidget {
  const HouseSoundWaveform({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final hit = cineHitMin(context);
    return CinePressable(
      onTap: onTap,
      builder: (context, st) => Tooltip(
        message: 'House sound: $label',
        excludeFromSemantics: true,
        child: Semantics(
          button: true,
          label: 'House sound: $label',
          hint: 'Opens Reading setup',
          excludeSemantics: true,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: hit, minWidth: hit),
            child: Center(widthFactor: 1, child: CineIcon(CineIconRole.soundscape, size: 16, color: st.hovered ? c.colorInk100 : c.colorInk60)),
          ),
        ),
      ),
    );
  }
}
