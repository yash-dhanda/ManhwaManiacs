import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Where the reader is in its life, for the system bars (cinematic 8.0.5 "System bars").
enum ReaderUiPhase { enter, chromeShown, chromeHidden, exit }

/// One decision: a mode, its overlays for `manual`, and the overlay style on exit.
@immutable
class ReaderSystemUi {
  const ReaderSystemUi(this.mode, {this.overlays, this.style});
  final SystemUiMode mode;
  final List<SystemUiOverlay>? overlays;
  final SystemUiOverlayStyle? style;

  @override
  bool operator ==(Object other) =>
      other is ReaderSystemUi && other.mode == mode && listEquals(other.overlays, overlays) && other.style == style;

  @override
  int get hashCode => Object.hash(mode, Object.hashAll(overlays ?? const []), style);

  @override
  String toString() => 'ReaderSystemUi($mode, $overlays)';
}

/// Transparent light bars for the app outside the reader.
final SystemUiOverlayStyle kReaderExitStyle = SystemUiOverlayStyle.light.copyWith(
  statusBarColor: const Color(0x00000000),
  systemNavigationBarColor: const Color(0x00000000),
  systemNavigationBarContrastEnforced: false,
);

/// The bars for [phase] on [platform]. Enter: iOS hides the status bar (the home indicator
/// auto-hides), Android goes immersive sticky. Chrome shown: the status bar comes back. Chrome
/// hidden: the entry mode again. Exit: edge to edge with transparent light bars.
ReaderSystemUi readerSystemUi(TargetPlatform platform, ReaderUiPhase phase) {
  final entry = platform == TargetPlatform.android
      ? const ReaderSystemUi(SystemUiMode.immersiveSticky)
      : const ReaderSystemUi(SystemUiMode.manual, overlays: <SystemUiOverlay>[]);
  return switch (phase) {
    ReaderUiPhase.enter || ReaderUiPhase.chromeHidden => entry,
    ReaderUiPhase.chromeShown => const ReaderSystemUi(SystemUiMode.manual, overlays: [SystemUiOverlay.top]),
    ReaderUiPhase.exit => ReaderSystemUi(SystemUiMode.edgeToEdge, style: kReaderExitStyle),
  };
}

/// Applies [ui] through `SystemChrome`.
Future<void> applyReaderSystemUi(ReaderSystemUi ui) async {
  await SystemChrome.setEnabledSystemUIMode(ui.mode, overlays: ui.overlays);
  final style = ui.style;
  if (style != null) SystemChrome.setSystemUIOverlayStyle(style);
}
