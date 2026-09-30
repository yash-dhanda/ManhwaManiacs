import 'dart:ui' show Rect;
import 'package:manhwamaniacs/features/reader/engine/reader_ambient.dart';

/// The panel boxes (page fractions) of a page's [PanelsState]: null while it is being analysed,
/// absent, or has no result; empty never (a page without panels is [PanelsNone] -> null).
List<Rect>? panelBoxesOf(PanelsState? s) => switch (s) {
      PanelsFound(:final fractions) when fractions.isNotEmpty => fractions,
      _ => null,
    };
