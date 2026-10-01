import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/platform/mm_platform.dart';
import 'package:manhwamaniacs/skins/glass/orientation.dart';

/// Transparent bars with light icons for the app outside the reader (glass 8.14.11 "Reader system UI").
const SystemUiOverlayStyle kGlassReaderExitStyle = SystemUiOverlayStyle(
  statusBarColor: Color(0x00000000),
  systemNavigationBarColor: Color(0x00000000),
  systemNavigationBarContrastEnforced: false,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemNavigationBarIconBrightness: Brightness.light,
);

/// Enter: `immersiveSticky` on both platforms (iOS maps the hidden bottom overlay to `prefersHomeIndicatorAutoHidden`), every
/// orientation. Exit: `edgeToEdge` with light icons over transparent bars, portrait again on phones.
Future<void> enterGlassReaderUi() async {
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await GlassOrientation.widenForReader();
}

Future<void> exitGlassReaderUi() async {
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(kGlassReaderExitStyle);
  await GlassOrientation.restoreAfterReader();
}

/// The reader's insets (glass 8.14.11): iOS the view padding; Android the stable insets of `display.stableInsets` (what the bars
/// take when shown, so the chrome never jumps while they hide), refreshed on every metrics change.
class GlassReaderInsets extends InheritedWidget {
  const GlassReaderInsets({super.key, required this.insets, required super.child});
  final EdgeInsets insets;

  static EdgeInsets of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GlassReaderInsets>()?.insets ?? MediaQuery.viewPaddingOf(context);

  @override
  bool updateShouldNotify(GlassReaderInsets old) => old.insets != insets;
}

/// Installs the reader's system UI for as long as it is mounted (also on an exit by a skin restart or a pop from the stack
/// overview: dispose runs either way) and publishes [GlassReaderInsets].
class GlassReaderSystemUi extends ConsumerStatefulWidget {
  const GlassReaderSystemUi({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<GlassReaderSystemUi> createState() => _GlassReaderSystemUiState();
}

class _GlassReaderSystemUiState extends ConsumerState<GlassReaderSystemUi> with WidgetsBindingObserver {
  EdgeInsets? _stable;
  late final MmPlatform _platform = ref.read(mmPlatformProvider);

  bool get _android => defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    _platform;
    WidgetsBinding.instance.addObserver(this);
    unawaited(enterGlassReaderUi());
    _refresh();
  }

  @override
  void didChangeMetrics() => _refresh();

  void _refresh() {
    if (!_android) return;
    unawaited(_platform.stableInsets().then((v) {
      if (mounted && v != _stable) setState(() => _stable = v);
    }),);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(exitGlassReaderUi());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.viewPaddingOf(context);
    return GlassReaderInsets(insets: _android ? (_stable ?? pad) : pad, child: widget.child);
  }
}
