import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/sheet_route.dart';

/// Opens the Contents of the reader as a Cinematic sheet on phones (cinematic 8.14.3, 7.9): the
/// `CONTENTS` kicker and `Done` come from the sheet frame. A tap on a chapter is the caller's
/// [content] `onPick`, which closes it.
Future<void> showContentsSheet(BuildContext context, {required WidgetBuilder content}) =>
    showCineSheet<void>(
      context,
      kicker: 'CONTENTS',
      title: 'Contents',
      // The sheet body scrolls, so the list needs a height of its own (and a Material for its
      // number field).
      builder: (sheetContext) => Material(
        type: MaterialType.transparency,
        child: SizedBox(height: MediaQuery.sizeOf(sheetContext).height * 0.68, child: content(sheetContext)),
      ),
    );
