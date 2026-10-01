/// The cast sheet (glass 8.16.4, F1): "Voices in this chapter". The Narrator row is pinned at the top (its orb in the voice's hue,
/// the voice name or "Default voice", a chevron into the orbit); one row per character in cast order: a 12 px speaker swatch (dashed
/// ring from the 11th speaker), the name, a gender capsule (the owner's tap opens Male / Female / Unknown and shows the lock), the
/// assigned voice or "Automatic", the share of lines and a lock when set by hand. A tap opens the orbit narrowed to that character's
/// gender; the owner's row ⋯ holds "Same character as..." and "Reset to automatic". Everyone else sees the rows read-only.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/features/novels/models/novel_cast.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_cast_provider.dart';
import 'package:manhwamaniacs/features/novels/providers/novel_chapter_provider.dart';
import 'package:manhwamaniacs/features/novels/utils/speaker_slots.dart';
import 'package:manhwamaniacs/skins/glass/glass/shape.dart';
import 'package:manhwamaniacs/skins/glass/icons/phosphor.g.dart';
import 'package:manhwamaniacs/skins/glass/listen/glass_narration_host.dart';
import 'package:manhwamaniacs/skins/glass/listen/listen_common.dart';
import 'package:manhwamaniacs/skins/glass/listen/voice_hue.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/press.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/screens/novel/speaker_bands.dart' show speakerHue;
import 'package:manhwamaniacs/skins/glass/type.dart';

const String kCastLoading = 'Looking up who speaks here…';
const String kCastNobody = 'Nobody has been identified in this chapter, so the narrator reads it all.';
const String kCastReadOnly = "Voices are set by the server's owner";

/// The status line above the rows: loading, nobody identified, or the narrator-is-a-character explanation.
String? castStatusLine(NovelAttribution a, {required bool loading}) {
  if (loading) return kCastLoading;
  if (!a.attributed && a.cast.isEmpty) return kCastNobody;
  final n = a.narrator;
  if (n != null && n.isNotEmpty && a.cast.any((m) => m.name == n)) return "Narrated by $n: $n's own lines use the narrator's voice because they are the same person.";
  return null;
}

/// "31 %" for each character: its `line_count` (or the chapter's spans) over everyone's.
Map<String, int> castShares(NovelAttribution a) {
  final counts = <String, int>{
    for (final m in a.cast) m.name: m.lineCount ?? a.spans.where((s) => s.speaker == m.name).length,
  };
  final total = counts.values.fold<int>(0, (x, y) => x + y);
  return {for (final e in counts.entries) e.key: total == 0 ? 0 : (e.value * 100 / total).round()};
}

String genderLabel(String g) => switch (g) { 'male' => 'Male', 'female' => 'Female', _ => 'Unknown' };

class GlassCastBody extends ConsumerWidget {
  const GlassCastBody({super.key, required this.chapter, this.onGlass = true});
  final NovelChapterKey chapter;
  final bool onGlass;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(novelAttributionProvider(chapter));
    final voices = ref.watch(novelVoicesProvider).valueOrNull ?? const <NovelVoice>[];
    final owner = ref.watch(glassIsOwnerProvider);
    final online = ref.watch(deviceOnlineProvider).valueOrNull ?? true;
    final canEdit = owner && online;
    if (async.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            GlassText("Couldn't load who speaks here", role: gt.typeCallout, onGlass: onGlass, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            GlassButton(label: 'Try again', size: GlassButtonSize.small, onPressed: () => ref.invalidate(novelAttributionProvider(chapter))),
          ],),
        ),
      );
    }
    final loading = async.isLoading && !async.hasValue;
    final a = async.valueOrNull ?? NovelAttribution.none;
    final byId = {for (final v in voices) v.voiceId: v};
    final narratorVoice = a.narratorVoiceId == null ? null : byId[a.narratorVoiceId];
    final narrator = ref.watch(glassNarratorProvider(chapter));
    final status = castStatusLine(a, loading: loading);
    final slots = speakerSlots(a);
    final shares = castShares(a);
    final actions = ref.read(glassNarrationActionsProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        if (status != null) Padding(padding: const EdgeInsets.fromLTRB(4, 0, 4, 12), child: Semantics(liveRegion: true, child: GlassText(status, role: gt.typeFootnote, onGlass: onGlass, color: gt.colorLabel2, maxScale: 1.5, maxLines: 4))),
        _Row(
          key: const ValueKey('cast-narrator'),
          semantics: 'Narrator, ${narratorVoice?.name ?? 'Default voice'}',
          leading: ListenVoiceOrb(hue: narratorVoice == null ? narrator.hue : voiceHue(narratorVoice.pitchHz), initial: narratorVoice == null ? 'N' : narrator.initial),
          title: 'Narrator',
          subtitle: narratorVoice?.name ?? 'Default voice',
          trailing: Icon(PhosphorRegular.caretLeft, size: 16, color: gt.colorLabel3, textDirection: TextDirection.rtl),
          onGlass: onGlass,
          onTap: () => actions.openSheet('voices'),
        ),
        if (loading)
          GlassSkeletonGroup(label: kCastLoading, child: Column(children: [for (var i = 0; i < 5; i++) Padding(padding: const EdgeInsets.only(top: 8), child: GlassSkeleton(height: 56, radius: 20, index: i))]))
        else
          for (final m in a.cast)
            _Row(
              key: ValueKey('cast-${m.name}'),
              semantics: '${m.name}, ${genderLabel(m.gender)}, ${m.voiceId == null ? 'automatic voice' : byId[m.voiceId]?.name ?? 'voice'}, ${shares[m.name] ?? 0} percent of lines${m.locked ? ', set by hand' : ''}',
              leading: _Swatch(slot: slots[m.name]),
              title: m.name,
              subtitle: m.voiceId == null ? 'Automatic' : (byId[m.voiceId]?.name ?? 'Voice'),
              meta: '${shares[m.name] ?? 0} %',
              locked: m.locked,
              gender: _GenderCapsule(chapter: chapter, member: m, editable: canEdit, onGlass: onGlass),
              trailing: canEdit ? _MoreButton(chapter: chapter, member: m, others: [for (final o in a.cast) if (o.name != m.name) o.name]) : null,
              onGlass: onGlass,
              onTap: () => actions.openSheet('voices', extra: {'character': m.name, 'gender': m.gender}),
            ),
        if (!owner) Padding(padding: const EdgeInsets.only(top: 16), child: GlassText(kCastReadOnly, role: gt.typeCaption1, onGlass: onGlass, color: gt.colorLabel2, textAlign: TextAlign.center, maxLines: 2)),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.slot});
  final ({int slot, bool dotted})? slot;

  @override
  Widget build(BuildContext context) {
    final s = slot;
    return ExcludeSemantics(
      child: SizedBox(
        width: 24,
        height: 24,
        child: Center(
          child: s == null || s.dotted
              ? CustomPaint(size: const Size(12, 12), painter: _DashedRing(s == null ? gt.colorLabel3 : speakerHue(s.slot)))
              : Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: speakerHue(s.slot))),
        ),
      ),
    );
  }
}

class _DashedRing extends CustomPainter {
  const _DashedRing(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = color;
    final r = Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5);
    for (var i = 0; i < 8; i++) {
      canvas.drawArc(r, i * 0.785398, 0.45, false, p);
    }
  }

  @override
  bool shouldRepaint(_DashedRing o) => o.color != color;
}

class _Row extends StatelessWidget {
  const _Row({super.key, required this.semantics, required this.leading, required this.title, required this.subtitle, this.meta, this.locked = false, this.gender, this.trailing, required this.onGlass, required this.onTap});
  final String semantics, title, subtitle;
  final Widget leading;
  final String? meta;
  final bool locked, onGlass;
  final Widget? gender, trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: GlassPressable(
          material: GlassMaterial.content,
          sink: 0.99,
          shape: const GlassShape.superellipse(20),
          minHit: false,
          onTap: onTap,
          semanticsLabel: semantics,
          builder: (context, info) => Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: ShapeDecoration(color: gt.colorFill2, shape: const GlassShape.superellipse(20).border(const Size(340, 56))),
            child: Row(
              children: [
                leading,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GlassText(title, role: gt.typeSubhead, wght: 600, onGlass: onGlass, maxLines: 1, overflow: TextOverflow.ellipsis, maxScale: 1.5),
                      GlassText(subtitle, role: gt.typeFootnote, onGlass: onGlass, color: gt.colorLabel2, maxLines: 1, overflow: TextOverflow.ellipsis, maxScale: 1.5),
                    ],
                  ),
                ),
                if (gender != null) ...[gender!, const SizedBox(width: 8)],
                if (meta != null) GlassText(meta!, role: gt.typeMono, size: 12, onGlass: onGlass, color: gt.colorLabel2, maxLines: 1),
                if (locked) Padding(padding: const EdgeInsets.only(left: 6), child: Icon(PhosphorRegular.pushPin, size: 14, color: gt.colorLabel2, semanticLabel: 'Set by hand')),
                if (trailing != null) ...[const SizedBox(width: 4), trailing!],
              ],
            ),
          ),
        ),
      );
}

class _GenderCapsule extends ConsumerWidget {
  const _GenderCapsule({required this.chapter, required this.member, required this.editable, required this.onGlass});
  final NovelChapterKey chapter;
  final NovelCastMember member;
  final bool editable;
  final bool onGlass;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = genderLabel(member.gender);
    final capsule = DecoratedBox(
      decoration: ShapeDecoration(color: gt.colorFill3, shape: const GlassShape.capsule().border(const Size(64, 24))),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), child: GlassText(text, role: gt.typeCaption1, onGlass: onGlass, maxLines: 1)),
    );
    if (!editable) return Semantics(label: 'Gender, $text', excludeSemantics: true, child: capsule);
    return Builder(
      builder: (c) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          final box = c.findRenderObject();
          final anchor = box is RenderBox && box.hasSize ? box.localToGlobal(Offset.zero) & box.size : Rect.zero;
          Future<void> set(String g) async {
            final err = await ref.read(novelCastingWriterProvider).setGender(chapter, member.name, g);
            if (err != null) ref.read(glassToastProvider.notifier).show(GlassToastSpec(listenErrorText(err), kind: GlassToastKind.error));
          }

          unawaited(
            showGlassMenu(context, anchor: anchor, title: 'Gender of ${member.name}', entries: [
              for (final g in const ['male', 'female', 'unknown']) GlassMenuEntry(label: genderLabel(g), checked: member.gender == g, onSelected: () => unawaited(set(g))),
            ],),
          );
        },
        child: Semantics(button: true, label: 'Gender of ${member.name}, $text. Change', excludeSemantics: true, child: ConstrainedBox(constraints: const BoxConstraints(minHeight: 44), child: Center(child: capsule))),
      ),
    );
  }
}

class _MoreButton extends ConsumerWidget {
  const _MoreButton({required this.chapter, required this.member, required this.others});
  final NovelChapterKey chapter;
  final NovelCastMember member;
  final List<String> others;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Builder(
        builder: (c) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            final box = c.findRenderObject();
            final anchor = box is RenderBox && box.hasSize ? box.localToGlobal(Offset.zero) & box.size : Rect.zero;
            void toastErr(String text) => ref.read(glassToastProvider.notifier).show(GlassToastSpec(text, kind: GlassToastKind.error));

            Future<void> alias(String canonical) async {
              final err = await ref.read(novelCastingWriterProvider).mergeAlias(chapter, member.name, canonical);
              if (err != null) toastErr(listenErrorText(err));
            }

            Future<void> reset() async {
              final err = await ref.read(novelVoiceWriterProvider).setCharacter(chapter, member.name, null);
              if (err != null) toastErr(listenErrorText(err));
            }

            unawaited(
              showGlassMenu(context, anchor: anchor, title: member.name, entries: [
                GlassMenuEntry(
                  label: 'Same character as…',
                  enabled: others.isNotEmpty,
                  onSelected: () => unawaited(showGlassMenu(context, anchor: anchor, title: 'Same character as', entries: [for (final o in others) GlassMenuEntry(label: o, onSelected: () => unawaited(alias(o)))])),
                ),
                GlassMenuEntry(label: 'Reset to automatic', enabled: member.voiceId != null || member.locked, onSelected: () => unawaited(reset())),
              ],),
            );
          },
          child: Semantics(button: true, label: 'More for ${member.name}', excludeSemantics: true, child: SizedBox(width: 44, height: 44, child: Center(child: Icon(PhosphorRegular.dotsThree, size: 20, color: gt.colorOnGlass)))),
        ),
      );
}
