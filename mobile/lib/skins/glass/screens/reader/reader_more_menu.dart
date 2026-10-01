import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_state.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/reader_host.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_common.dart';

/// The landscape phone's ... menu (glass 8.14.11 "Landscape phone"): Download, Cruise, Guided view, Previous chapter, Next chapter.
Future<void> presentReaderMore(BuildContext context, GlassReaderHost host, ReaderEngineState state, {VoidCallback? onDownload}) => showGlassMenu(
      context,
      anchor: globalRectOf(context),
      title: 'More',
      entries: [
        if (onDownload != null) GlassMenuEntry(label: 'Download', onSelected: onDownload),
        GlassMenuEntry(label: state.autoScrolling ? 'Pause cruise' : 'Cruise', onSelected: host.toggleCruise),
        if (host.cruiseAvailable) GlassMenuEntry(label: host.guidedOn ? 'Close guided view' : 'Guided view', onSelected: host.toggleGuided),
        GlassMenuEntry(label: 'Previous chapter', enabled: state.hasPrevious, onSelected: host.previousChapter),
        GlassMenuEntry(label: 'Next chapter', enabled: state.hasNext, onSelected: host.nextChapter),
      ],
    );
