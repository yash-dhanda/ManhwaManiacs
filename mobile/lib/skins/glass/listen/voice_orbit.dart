/// The voice orbit (glass 8.16.4, F2-F6): every voice the server has (31 in production, never hard-coded) as 160 x 220 cards in a
/// horizontal list on `SnapPhysics` (stride 176), each card transformed per frame from the scroll offset (rotateY, scale, opacity from
/// `orbit_math.dart`). The centred voice introduces itself after 400 ms of rest, its orb pulsing with the sample; moving stops it.
/// "Use this voice" pins it for the narrator or a character; a grid toggle switches to a searchable grid.
library;


import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/features/novels/models/novel_cast.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_cast_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_chapter_provider.dart';
import 'package:manhwamaniacs/features/novels/services/voice_sample_player.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/glass/shape.dart';
import 'package:manhwamaniacs/skins/glass/icons/phosphor.g.dart';
import 'package:manhwamaniacs/skins/glass/listen/glass_narration_host.dart';
import 'package:manhwamaniacs/skins/glass/listen/listen_prefs.dart';
import 'package:manhwamaniacs/skins/glass/listen/orbit_math.dart';
import 'package:manhwamaniacs/skins/glass/listen/voice_card.dart';
import 'package:manhwamaniacs/skins/glass/listen/voice_grid.dart';
import 'package:manhwamaniacs/skins/glass/physics/glass_physics.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// Who the picked voice is for.
class VoiceTarget {
  const VoiceTarget.narrator()
      : character = null,
        gender = null;
  const VoiceTarget.character(String this.character, {this.gender});

  /// The character's name; null for the narrator.
  final String? character;

  /// `male` or `female` narrows the orbit; null or `unknown` shows every voice.
  final String? gender;

  bool get isNarrator => character == null;
  String get label => character ?? 'the narrator';
}

/// "Narrator" when [voiceId] is the book's narrator voice, "In use for Kade" (and "+2" more) when characters have it.
String? voiceUseTag(String voiceId, NovelAttribution? a) {
  if (a == null) return null;
  if (a.narratorVoiceId == voiceId) return 'Narrator';
  final names = [for (final m in a.cast) if (m.voiceId == voiceId) m.name];
  if (names.isEmpty) return null;
  return names.length == 1 ? 'In use for ${names.first}' : 'In use for ${names.first} +${names.length - 1}';
}

/// The voices a target may pick from: all of them, or the ones whose gender matches a character's.
List<NovelVoice> voicesFor(List<NovelVoice> all, VoiceTarget t) {
  final g = t.gender;
  if (g != 'male' && g != 'female') return all;
  final f = all.where((v) => v.gender == g).toList();
  return f.isEmpty ? all : f;
}

/// Expressiveness ranks (1 = flattest) of [voices] among themselves.
Map<String, int> expressivenessRankOf(List<NovelVoice> voices) {
  final sorted = [...voices]..sort((a, b) => a.expressiveness.compareTo(b.expressiveness));
  return {for (var i = 0; i < sorted.length; i++) sorted[i].voiceId: i + 1};
}

class GlassVoiceOrbit extends ConsumerStatefulWidget {
  const GlassVoiceOrbit({super.key, required this.chapter, this.target = const VoiceTarget.narrator()});
  final NovelChapterKey chapter;
  final VoiceTarget target;

  @override
  ConsumerState<GlassVoiceOrbit> createState() => _GlassVoiceOrbitState();
}

class _GlassVoiceOrbitState extends ConsumerState<GlassVoiceOrbit> {
  ScrollController? _scroll;
  Timer? _rest;
  int _centered = -1;
  bool _keyboard = false, _grid = false, _saving = false;
  final FocusNode _focus = FocusNode(debugLabel: 'GlassVoiceOrbit');

  @override
  void dispose() {
    _rest?.cancel();
    _scroll?.dispose();
    _focus.dispose();
    final p = ref.read(voiceSamplePlayerProvider.notifier);
    unawaited(p.stop());
    super.dispose();
  }

  int _indexOf(double offset, int n) => (offset / kOrbitStride).round().clamp(0, n - 1);

  bool _autoPlayAllowed() => !MediaQuery.accessibleNavigationOf(context) && !_keyboard && ref.read(glassAutoPlayPreviewsProvider);

  void _armRest(List<NovelVoice> voices) {
    _rest?.cancel();
    if (!_autoPlayAllowed() || voices.isEmpty) return;
    _rest = Timer(const Duration(milliseconds: 400), () {
      if (!mounted || _centered < 0 || _centered >= voices.length || !_autoPlayAllowed()) return;
      unawaited(ref.read(voiceSamplePlayerProvider.notifier).play(voices[_centered].voiceId));
    });
  }

  void _moved() {
    _rest?.cancel();
    final p = ref.read(voiceSamplePlayerProvider);
    if (p.status != SampleStatus.idle) unawaited(ref.read(voiceSamplePlayerProvider.notifier).stop());
  }

  void _settled(List<NovelVoice> voices) {
    final c = _scroll;
    if (c == null || !c.hasClients) return;
    final i = _indexOf(c.offset, voices.length);
    if (i != _centered) {
      _centered = i;
      glassFire(ref, HapticEvent.voiceCenter);
      setState(() {});
    }
    _armRest(voices);
  }

  void _step(int d, List<NovelVoice> voices) {
    final c = _scroll;
    if (c == null || !c.hasClients) return;
    _moved();
    final to = (_indexOf(c.offset, voices.length) + d).clamp(0, voices.length - 1);
    unawaited(c.animateTo(to * kOrbitStride, duration: Duration(milliseconds: gt.springSettle.ms), curve: SpringCurve(gt.springSettle)));
  }

  Future<void> _use(NovelVoice v) async {
    if (_saving) return;
    setState(() => _saving = true);
    final t = widget.target;
    final err = t.isNarrator ? await ref.read(novelVoiceWriterProvider).setNarrator(widget.chapter, v.voiceId) : await ref.read(novelVoiceWriterProvider).setCharacter(widget.chapter, t.character!, v.voiceId);
    if (!mounted) return;
    setState(() => _saving = false);
    if (err == null) {
      glassFire(ref, HapticEvent.voiceAssign);
      glassSound(ref, SoundEvent.voiceAssign);
    } else {
      glassFire(ref, HapticEvent.error);
      ref.read(glassToastProvider.notifier).show(GlassToastSpec(listenErrorText(err), kind: GlassToastKind.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final voicesAsync = ref.watch(novelVoicesProvider);
    final online = ref.watch(deviceOnlineProvider).valueOrNull ?? true;
    final attribution = ref.watch(novelAttributionProvider(widget.chapter)).valueOrNull;
    final owner = ref.watch(glassIsOwnerProvider);
    final sample = ref.watch(voiceSamplePlayerProvider);
    final auto = ref.watch(glassAutoPlayPreviewsProvider);
    if (!online && !voicesAsync.hasValue) return const _Note('Voices need a connection');
    return voicesAsync.when(
      loading: () => const _OrbitSkeleton(),
      error: (_, __) => _Retry(message: "Couldn't load the voices", onRetry: () => ref.invalidate(novelVoicesProvider)),
      data: (all) {
        if (all.isEmpty) return const _Note("No voices are installed on the server, so characters can't be cast here yet.");
        final voices = voicesFor(all, widget.target);
        final ranks = expressivenessRankOf(all);
        if (_grid) {
          return GlassVoiceGrid(
            voices: voices,
            attribution: attribution,
            sample: sample,
            ranks: ranks,
            total: all.length,
            columns: GlassFrame.of(context) == GlassFrameKind.phone || GlassFrame.of(context) == GlassFrameKind.tablet ? 2 : 4,
            autoPlay: auto,
            onPlay: (v) => unawaited(ref.read(voiceSamplePlayerProvider.notifier).play(v.voiceId)),
            onStop: () => unawaited(ref.read(voiceSamplePlayerProvider.notifier).stop()),
            onUse: owner ? _use : null,
            onOrbit: () => setState(() => _grid = false),
          );
        }
        final assigned = widget.target.isNarrator ? attribution?.narratorVoiceId : attribution?.cast.where((m) => m.name == widget.target.character).firstOrNull?.voiceId;
        final start = assigned == null ? 0 : voices.indexWhere((v) => v.voiceId == assigned).clamp(0, voices.length - 1);
        if (_scroll == null) {
          _scroll = ScrollController(initialScrollOffset: start * kOrbitStride);
          _centered = start;
          WidgetsBinding.instance.addPostFrameCallback((_) => _armRest(voices));
        }
        final c = _scroll!;
        final centered = _centered.clamp(0, voices.length - 1);
        return LayoutBuilder(
          builder: (context, box) {
            final side = (box.maxWidth - kOrbitCardWidth) / 2;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 12, 4),
                  child: Row(
                    children: [
                      Expanded(child: GlassText('A voice for ${widget.target.label}', role: gt.typeSubhead, color: gt.colorLabel2, maxLines: 1, overflow: TextOverflow.ellipsis, maxScale: 1.5)),
                      GlassButton(label: 'Grid', size: GlassButtonSize.small, onPressed: () => setState(() => _grid = true), semanticsLabel: 'Show all voices as a grid'),
                    ],
                  ),
                ),
                Semantics(
                  label: 'Voices',
                  onIncrease: () => _step(1, voices),
                  onDecrease: () => _step(-1, voices),
                  child: Focus(
                    focusNode: _focus,
                    onKeyEvent: (n, e) {
                      if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
                      if (e.logicalKey == LogicalKeyboardKey.arrowRight) {
                        _keyboard = true;
                        _step(1, voices);
                        return KeyEventResult.handled;
                      }
                      if (e.logicalKey == LogicalKeyboardKey.arrowLeft) {
                        _keyboard = true;
                        _step(-1, voices);
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: Listener(
                      onPointerDown: (_) => _keyboard = false,
                      child: SizedBox(
                        height: kOrbitCardHeight + 16,
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (n) {
                            if (n is ScrollStartNotification || (n is ScrollUpdateNotification && n.dragDetails != null)) _moved();
                            if (n is ScrollEndNotification) _settled(voices);
                            return false;
                          },
                          child: ListView.builder(
                            controller: c,
                            scrollDirection: Axis.horizontal,
                            physics: const SnapPhysics(stride: kOrbitStride),
                            padding: EdgeInsets.symmetric(horizontal: side - 8 < 0 ? 0 : side - 8),
                            itemExtent: kOrbitStride,
                            itemCount: voices.length,
                            itemBuilder: (context, i) => AnimatedBuilder(
                              animation: c,
                              builder: (context, child) {
                                final o = c.hasClients ? (i * kOrbitStride - c.offset) / kOrbitStride : (i - start).toDouble();
                                return Opacity(
                                  opacity: orbitOpacity(o).clamp(0.0, 1.0),
                                  child: Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.identity()
                                      ..setEntry(3, 2, 0.001)
                                      ..rotateY(orbitRotateY(o))
                                      ..scaleByDouble(orbitScale(o), orbitScale(o), 1, 1),
                                    child: child,
                                  ),
                                );
                              },
                              child: Center(
                                child: GlassVoiceCard(
                                  voice: voices[i],
                                  position: all.indexOf(voices[i]) + 1,
                                  total: all.length,
                                  dots: expressivenessDots(ranks[voices[i].voiceId] ?? 1, all.length),
                                  sample: sample,
                                  autoPlay: auto && _autoPlayAllowed(),
                                  tag: voiceUseTag(voices[i].voiceId, attribution),
                                  selected: i == centered,
                                  onPlay: () => unawaited(ref.read(voiceSamplePlayerProvider.notifier).play(voices[i].voiceId)),
                                  onStop: () => unawaited(ref.read(voiceSamplePlayerProvider.notifier).stop()),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: sample.status == SampleStatus.playing && sample.voiceId == voices[centered].voiceId && voices[centered].transcript.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Semantics(liveRegion: true, child: GlassText(voices[centered].transcript, role: gt.typeFootnote, color: gt.colorLabel2, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, maxScale: 1.5)),
                        )
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Column(
                    children: [
                      GlassButton(
                        label: 'Use this voice',
                        variant: GlassButtonVariant.primary,
                        fullWidth: true,
                        loading: _saving,
                        onPressed: owner ? () => unawaited(_use(voices[centered])) : null,
                        disabledReason: owner ? null : "Voices are set by the server's owner",
                      ),
                      if (!owner) Padding(padding: const EdgeInsets.only(top: 6), child: GlassText("Voices are set by the server's owner", role: gt.typeCaption1, color: gt.colorLabel2, maxLines: 2)),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _OrbitSkeleton extends StatelessWidget {
  const _OrbitSkeleton();

  @override
  Widget build(BuildContext context) => GlassSkeletonGroup(
        label: 'Loading voices',
        child: SizedBox(
          height: kOrbitCardHeight + 16,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [for (var i = 0; i < 5; i++) Padding(padding: const EdgeInsets.only(right: 16), child: Center(child: GlassSkeleton(width: kOrbitCardWidth, height: kOrbitCardHeight, radius: 26, index: i)))],
          ),
        ),
      );
}

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(24), child: Center(child: GlassText(text, role: gt.typeCallout, color: gt.colorLabel2, textAlign: TextAlign.center)));
}

class _Retry extends StatelessWidget {
  const _Retry({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlassText(message, role: gt.typeCallout, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            GlassButton(label: 'Try again', onPressed: onRetry, size: GlassButtonSize.small),
          ],
        ),
      );
}

/// The orbit's ⋯: a menu with the "Auto-play previews" switch.
class GlassVoicesMore extends ConsumerWidget {
  const GlassVoicesMore({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => SizedBox(
        width: 44,
        height: 44,
        child: Builder(
          builder: (c) => GlassPressable(
            material: GlassMaterial.content,
            sink: 0.92,
            shape: const GlassShape.circle(),
            minHit: false,
            semanticsLabel: 'More',
            onTap: () {
              final box = c.findRenderObject();
              final anchor = box is RenderBox && box.hasSize ? box.localToGlobal(Offset.zero) & box.size : Rect.zero;
              final on = ref.read(glassAutoPlayPreviewsProvider);
              unawaited(
                showGlassMenu(
                  context,
                  anchor: anchor,
                  title: 'Voice options',
                  entries: [GlassMenuEntry(label: 'Auto-play previews', checked: on, onSelected: () => unawaited(ref.read(glassPrefsRecordProvider.notifier).put({'autoPlayPreviews': !on})))],
                ),
              );
            },
            builder: (context, info) => Center(
              child: Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, color: gt.colorFill2), child: Icon(PhosphorRegular.dotsThree, size: 20, color: gt.colorOnGlass)),
            ),
          ),
        ),
      );
}
