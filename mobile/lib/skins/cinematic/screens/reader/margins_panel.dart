import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/circle/providers/circle_providers.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_contents_tabs.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_icon_button.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/circle_tab.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/dialogue_tab.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/notes_tab.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/ocr_overlay.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The right "Margins" column panel of the tablet reader (cinematic 8.14.12): tabs `NOTES ·
/// DIALOGUE · CIRCLE` over the chapter being read. The CIRCLE tab is absent while the Circle
/// answers 404. Phones have no Margins panel; their paths are the page actions.
class MarginsPanel extends ConsumerStatefulWidget {
  const MarginsPanel({
    super.key,
    required this.engine,
    required this.overlay,
    required this.sourceId,
    required this.seriesKey,
    required this.chapterKey,
    required this.chapterNumber,
    required this.chapterSaved,
    required this.completedOpen,
    required this.onClose,
    this.seriesTitle,
  });

  final ReaderEngine engine;
  final OcrOverlayController overlay;
  final String sourceId, seriesKey, chapterKey;
  final double? chapterNumber;
  final bool chapterSaved, completedOpen;
  final VoidCallback onClose;
  final String? seriesTitle;

  @override
  ConsumerState<MarginsPanel> createState() => _MarginsPanelState();
}

class _MarginsPanelState extends ConsumerState<MarginsPanel> with TickerProviderStateMixin {
  late TabController _tc = TabController(length: 3, vsync: this)..addListener(_changed);
  int _length = 3;

  void _changed() {
    if (mounted) setState(() {});
  }

  void _resize(int length) {
    if (length == _length) return;
    final old = _tc;
    _length = length;
    _tc = TabController(length: length, vsync: this, initialIndex: old.index.clamp(0, length - 1))..addListener(_changed);
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final circle = ref.watch(circleSeriesProvider((sourceId: widget.sourceId, seriesKey: widget.seriesKey)));
    // Circle not deployed (404): the answer is data-less, and the tab goes.
    final hasCircle = !(circle.hasValue && circle.valueOrNull == null);
    _resize(hasCircle ? 3 : 2);
    final tabs = [
      const CineTab(folio: '01', label: 'NOTES'),
      const CineTab(folio: '02', label: 'DIALOGUE'),
      if (hasCircle) const CineTab(folio: '03', label: 'CIRCLE'),
    ];
    final body = switch (_tc.index) {
      0 => NotesTab(
          engine: widget.engine,
          sourceId: widget.sourceId,
          seriesKey: widget.seriesKey,
          chapterKey: widget.chapterKey,
          seriesTitle: widget.seriesTitle,
          chapterNumber: widget.chapterNumber,
        ),
      1 => DialogueTab(
          engine: widget.engine,
          overlay: widget.overlay,
          sourceId: widget.sourceId,
          seriesKey: widget.seriesKey,
          chapterKey: widget.chapterKey,
          saved: widget.chapterSaved,
          chapterNumber: widget.chapterNumber,
        ),
      _ => CircleTab(
          sourceId: widget.sourceId,
          seriesKey: widget.seriesKey,
          chapterKey: widget.chapterKey,
          chapterNumber: widget.chapterNumber,
          completedOpen: widget.completedOpen,
        ),
    };
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(c.space4, c.space2, c.space2, 0),
            child: Row(children: [
              Expanded(child: CineRoleText('MARGINS', c.typeKicker, color: c.colorInk60)),
              SizedBox(height: cineHitMin(context)),
              CineIconButton(label: 'Close Margins', role: CineIconRole.close, onPressed: widget.onClose),
            ],),
          ),
          CineContentsTabs(controller: _tc, tabs: tabs),
          Expanded(child: body),
        ],
      ),
    );
  }
}
