import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/orientation.dart';

// TODO(mobile/35): replace this file with mobile/35's `screens/reader/reader_system_ui.dart` (`GlassReaderSystemUi`,
// `GlassReaderInsets`) once mobile/35 is integrated; delete this stand-in and import that one in the novel reader.

/// Transparent bars with light icons for the app outside the reader (glass 8.14.11 "Reader system UI").
const SystemUiOverlayStyle kNovelReaderExitStyle = SystemUiOverlayStyle(
  statusBarColor: Color(0x00000000),
  systemNavigationBarColor: Color(0x00000000),
  systemNavigationBarContrastEnforced: false,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemNavigationBarIconBrightness: Brightness.light,
);

/// The reader's insets (glass 8.14.11): iOS the view padding; Android `display.stableInsets` (`mobile/35` adds the channel call; until
/// then the view padding stands in).
class NovelReaderInsets extends InheritedWidget {
  const NovelReaderInsets({super.key, required this.insets, required super.child});
  final EdgeInsets insets;

  static EdgeInsets of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NovelReaderInsets>()?.insets ?? MediaQuery.viewPaddingOf(context);

  @override
  bool updateShouldNotify(NovelReaderInsets old) => old.insets != insets;
}

/// Enter: `immersiveSticky` on both platforms and every orientation on phones; exit: `edgeToEdge`, light icons, portrait again.
class NovelReaderSystemUi extends StatefulWidget {
  const NovelReaderSystemUi({super.key, required this.child});
  final Widget child;

  @override
  State<NovelReaderSystemUi> createState() => _NovelReaderSystemUiState();
}

class _NovelReaderSystemUiState extends State<NovelReaderSystemUi> {
  EdgeInsets? _stable;
  Orientation? _orientation;

  @override
  void initState() {
    super.initState();
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky));
    unawaited(GlassOrientation.widenForReader());
  }

  @override
  void dispose() {
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    SystemChrome.setSystemUIOverlayStyle(kNovelReaderExitStyle);
    unawaited(GlassOrientation.restoreAfterReader());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The insets the bars take when shown, kept while they hide, so the chrome never jumps.
    final pad = MediaQuery.viewPaddingOf(context);
    final o = MediaQuery.orientationOf(context);
    if (o != _orientation) {
      _orientation = o;
      _stable = null;
    }
    final s = _stable;
    final stable = s == null ? pad : EdgeInsets.fromLTRB(pad.left > s.left ? pad.left : s.left, pad.top > s.top ? pad.top : s.top, pad.right > s.right ? pad.right : s.right, pad.bottom > s.bottom ? pad.bottom : s.bottom);
    if (stable != s) _stable = stable;
    return NovelReaderInsets(insets: stable, child: widget.child);
  }
}
