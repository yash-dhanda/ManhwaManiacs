import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine_state.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/screens/reader/reader_host.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_common.dart';

/// The landscape phone's ... menu (glass 8.14.11 "Landscape phone"): Download, Cruise, Previous chapter, Next chapter. Guided view
/// joins in mobile/44.
Future<void> presentReaderMore(BuildContext context, GlassReaderHost host, ReaderEngineState state, {VoidCallback? onDownload}) => showGlassMenu(
      context,
      anchor: globalRectOf(context),
      title: 'More',
      entries: [
        if (onDownload != null) GlassMenuEntry(label: 'Download', onSelected: onDownload),
        GlassMenuEntry(label: state.autoScrolling ? 'Pause cruise' : 'Cruise', onSelected: host.toggleCruise),
        GlassMenuEntry(label: 'Previous chapter', enabled: state.hasPrevious, onSelected: host.previousChapter),
        GlassMenuEntry(label: 'Next chapter', enabled: state.hasNext, onSelected: host.nextChapter),
      ],
    );
