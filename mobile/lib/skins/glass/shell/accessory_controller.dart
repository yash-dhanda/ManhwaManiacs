import 'dart:ui' show Color, Rect;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Now narrating slot, published by the listen layer (`mobile/37`).
@immutable
class GlassNarrationAccessory {
  const GlassNarrationAccessory({
    required this.title,
    required this.playing,
    required this.progress,
    required this.onPlayPause,
    required this.openPlayer,
    this.onNextChapter,
    this.onPreviousChapter,
    this.voiceSeed,
    this.voiceHue,
    this.voiceInitial = '',
    this.onStop,
    this.phase = 0,
  });
  final String title; // "Chapter 12 · Aurora"
  final bool playing;
  final double progress; // 0..1
  final VoidCallback onPlayPause;
  final void Function(Rect fromRect) openPlayer;
  final VoidCallback? onNextChapter;
  final VoidCallback? onPreviousChapter;
  final String? voiceSeed;

  /// The narrating voice's colour and initial (the 32 px orb), and the stop-with-Undo of a downward drag.
  final Color? voiceHue;
  final String voiceInitial;
  final VoidCallback? onStop;

  /// 0 normal, 1 preparing or buffering, 2 failed (the play button's state).
  final int phase;
}

/// Continue slot, published by Home (`mobile/31`) once its hero is off-screen.
@immutable
class GlassContinueAccessory {
  const GlassContinueAccessory({required this.title, required this.subtitle, required this.coverUrl, required this.onOpen});
  final String title; // "Continue Solo Leveling"
  final String subtitle; // "Ch 143"
  final String? coverUrl;
  final void Function(Rect fromRect) onOpen;
}

/// Downloading slot, derived by the dock from the shared download queue.
@immutable
class GlassDownloadingAccessory {
  const GlassDownloadingAccessory({required this.chapters, required this.progress, required this.paused, required this.onToggle});
  final int chapters;
  final double progress; // 0..1
  final bool paused;
  final VoidCallback onToggle;
}

@immutable
class GlassAccessoryState {
  const GlassAccessoryState({
    this.narration,
    this.downloading,
    this.continueItem,
    this.hiddenForSession = false,
    this.pinned = false,
  });
  final GlassNarrationAccessory? narration;
  final GlassDownloadingAccessory? downloading;
  final GlassContinueAccessory? continueItem;
  final bool hiddenForSession;
  final bool pinned;

  /// Priority: narration, then downloading, then continue.
  bool get hasContent => narration != null || downloading != null || continueItem != null;
  bool get visible => hasContent && !hiddenForSession;

  GlassAccessoryState copyWith({
    Object? narration = _keep,
    Object? downloading = _keep,
    Object? continueItem = _keep,
    bool? hiddenForSession,
    bool? pinned,
  }) =>
      GlassAccessoryState(
        narration: identical(narration, _keep) ? this.narration : narration as GlassNarrationAccessory?,
        downloading: identical(downloading, _keep) ? this.downloading : downloading as GlassDownloadingAccessory?,
        continueItem: identical(continueItem, _keep) ? this.continueItem : continueItem as GlassContinueAccessory?,
        hiddenForSession: hiddenForSession ?? this.hiddenForSession,
        pinned: pinned ?? this.pinned,
      );
}

const Object _keep = Object();

class GlassAccessoryController extends StateNotifier<GlassAccessoryState> {
  GlassAccessoryController() : super(const GlassAccessoryState());

  void setNarration(GlassNarrationAccessory? s) => state = state.copyWith(narration: s);
  void setContinue(GlassContinueAccessory? s) => state = state.copyWith(continueItem: s);
  void setDownloading(GlassDownloadingAccessory? s) => state = state.copyWith(downloading: s);
  void hideForSession() => state = state.copyWith(hiddenForSession: true);
  void setPinned(bool v) => state = state.copyWith(pinned: v);
}

final glassAccessoryProvider = StateNotifierProvider<GlassAccessoryController, GlassAccessoryState>((ref) => GlassAccessoryController());
