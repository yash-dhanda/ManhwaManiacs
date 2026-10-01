import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_audio_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_chapter_provider.dart' show NovelChapterKey;

/// What the novel reader asks of listen mode (F5): `{available, playing, playFrom(int para), toggle()}`. `mobile/37` replaces the
/// default ([NarrationListenBridge]) with the full Glass narration host by overriding [glassListenBridgeFactoryProvider].
abstract class GlassListenBridge {
  /// The chapter's audio exists ("Play from here" is shown only then).
  bool get available;
  bool get playing;

  /// Starts at the first segment of paragraph [para] (0-based) and plays.
  Future<void> playFrom(int para);

  /// `p`: play or pause.
  Future<void> toggle();
}

/// What a bridge is made for: one chapter on screen.
class GlassListenContext {
  const GlassListenContext({required this.key, required this.paragraphs, required this.bookTitle, this.chapterNumber, this.chapterTitle = ''});
  final NovelChapterKey key;
  final List<String> paragraphs;
  final String bookTitle;
  final double? chapterNumber;
  final String chapterTitle;

  @override
  bool operator ==(Object other) => other is GlassListenContext && other.key == key && identical(other.paragraphs, paragraphs) && other.bookTitle == bookTitle;

  @override
  int get hashCode => Object.hash(key, identityHashCode(paragraphs), bookTitle);
}

/// The default bridge: `mobile/15`'s [NarrationController], seeked to the paragraph's first segment.
class NarrationListenBridge implements GlassListenBridge {
  NarrationListenBridge(this._ref, this._ctx);
  final Ref _ref;
  final GlassListenContext _ctx;

  NarrationController get _narr => _ref.read(narrationControllerProvider.notifier);

  @override
  bool get available => _ref.read(playableNovelAudioProvider(_ctx.key)).valueOrNull != null;

  @override
  bool get playing {
    final n = _ref.read(narrationControllerProvider);
    return n.key == _ctx.key && n.isPlaying;
  }

  @override
  Future<void> playFrom(int para) async {
    final playable = await _ref.read(playableNovelAudioProvider(_ctx.key).future);
    if (playable == null) return;
    final seg = playable.audio.segments.where((s) => s.paragraph >= para).firstOrNull;
    await _narr.start(
      NarrationTarget(
        key: _ctx.key,
        audio: playable.audio,
        file: playable.file?.path,
        paragraphs: _ctx.paragraphs,
        bookTitle: _ctx.bookTitle,
        chapterNumber: _ctx.chapterNumber,
        chapterTitle: _ctx.chapterTitle,
      ),
      startMs: seg?.startMs ?? 0,
    );
  }

  @override
  Future<void> toggle() async {
    final n = _ref.read(narrationControllerProvider);
    if (n.key == _ctx.key && n.target != null && n.status != NarrationStatus.failed) {
      await _narr.toggle();
    } else {
      await playFrom(0);
    }
  }
}

/// The factory the reader builds its bridge with. `mobile/37` overrides it.
final glassListenBridgeFactoryProvider = Provider<GlassListenBridge Function(Ref ref, GlassListenContext ctx)>(
  (ref) => NarrationListenBridge.new,
  name: 'glassListenBridgeFactory',
);

/// The bridge for one chapter on screen. It watches nothing but the factory, so its ref is never stale when a gesture calls it;
/// the reader watches the audio and narration providers itself to rebuild.
final glassListenBridgeProvider = Provider.autoDispose.family<GlassListenBridge, GlassListenContext>(
  (ref, ctx) => ref.watch(glassListenBridgeFactoryProvider)(ref, ctx),
  name: 'glassListenBridge',
);

/// The reader's bridge, for widgets below it (the selection menu, the keys, `mobile/37`'s rows).
class GlassListenBridgeScope extends InheritedWidget {
  const GlassListenBridgeScope({super.key, required this.bridge, required super.child});

  /// Null until the chapter has loaded.
  final GlassListenBridge? bridge;

  static GlassListenBridge? of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<GlassListenBridgeScope>()?.bridge;

  @override
  bool updateShouldNotify(GlassListenBridgeScope old) => old.bridge != bridge;
}

/// Fire and forget, never throwing into a gesture.
void runBridge(Future<void> Function() f) => unawaited(f().catchError((Object _) {}));
