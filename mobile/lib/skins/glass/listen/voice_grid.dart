/// The orbit's grid (glass 8.16.4, F4): every voice as a card in a searchable grid (2 columns in the phone and tablet frames, 4 on the
/// desktop frame) with filter chips All / Female / Male / In use and counts from the list.
library;

import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/features/novels/models/novel_cast.dart';
import 'package:manhwamaniacs/features/novels/services/voice_sample_player.dart';
import 'package:manhwamaniacs/skins/glass/listen/orbit_math.dart';
import 'package:manhwamaniacs/skins/glass/listen/voice_card.dart';
import 'package:manhwamaniacs/skins/glass/primitives/chip.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/search_field.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

enum VoiceFilter { all, female, male, inUse }

/// [voices] narrowed by [filter] and the [query] (name, character or licence); [inUse] holds the ids a book uses.
List<NovelVoice> filterVoices(List<NovelVoice> voices, VoiceFilter filter, String query, Set<String> inUse) {
  final q = query.trim().toLowerCase();
  return [
    for (final v in voices)
      if (switch (filter) {
            VoiceFilter.all => true,
            VoiceFilter.female => v.gender == 'female',
            VoiceFilter.male => v.gender == 'male',
            VoiceFilter.inUse => inUse.contains(v.voiceId),
          } &&
          (q.isEmpty || v.name.toLowerCase().contains(q) || v.character.toLowerCase().contains(q)))
        v,
  ];
}

class GlassVoiceGrid extends StatefulWidget {
  const GlassVoiceGrid({
    super.key,
    required this.voices,
    required this.attribution,
    required this.sample,
    required this.ranks,
    required this.total,
    required this.columns,
    required this.autoPlay,
    required this.onPlay,
    required this.onStop,
    required this.onUse,
    required this.onOrbit,
  });

  final List<NovelVoice> voices;
  final NovelAttribution? attribution;
  final SampleState sample;
  final Map<String, int> ranks;
  final int total, columns;
  final bool autoPlay;
  final void Function(NovelVoice) onPlay;
  final VoidCallback onStop, onOrbit;

  /// Null for a non-owner.
  final Future<void> Function(NovelVoice)? onUse;

  @override
  State<GlassVoiceGrid> createState() => _GlassVoiceGridState();
}

class _GlassVoiceGridState extends State<GlassVoiceGrid> {
  VoiceFilter _filter = VoiceFilter.all;
  String _query = '';

  Set<String> get _inUse {
    final a = widget.attribution;
    if (a == null) return const {};
    return {if (a.narratorVoiceId != null) a.narratorVoiceId!, for (final m in a.cast) if (m.voiceId != null) m.voiceId!};
  }

  @override
  Widget build(BuildContext context) {
    final inUse = _inUse;
    int count(VoiceFilter f) => filterVoices(widget.voices, f, '', inUse).length;
    final shown = filterVoices(widget.voices, _filter, _query, inUse);
    Widget chip(VoiceFilter f, String label) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GlassChip(label: label, kind: GlassChipKind.choice, selected: _filter == f, count: count(f), onPressed: () => setState(() => _filter = f), inChoiceGroup: true),
        );
    return Material(
      type: MaterialType.transparency,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(child: GlassSearchField(variant: GlassSearchVariant.filter, placeholder: 'Search voices', onQuery: (q) => setState(() => _query = q))),
                const SizedBox(width: 8),
                GlassButton(label: 'Orbit', size: GlassButtonSize.small, onPressed: widget.onOrbit, semanticsLabel: 'Show the voice orbit'),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [chip(VoiceFilter.all, 'All'), chip(VoiceFilter.female, 'Female'), chip(VoiceFilter.male, 'Male'), chip(VoiceFilter.inUse, 'In use')]),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: shown.isEmpty
                ? Center(child: GlassText('No voices match', role: gt.typeCallout, color: gt.colorLabel2))
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: widget.columns, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: kOrbitCardHeight + 52),
                    itemCount: shown.length,
                    itemBuilder: (context, i) {
                      final v = shown[i];
                      return Column(
                        children: [
                          Center(
                            child: GlassVoiceCard(
                              voice: v,
                              position: widget.voices.indexOf(v) + 1,
                              total: widget.total,
                              dots: expressivenessDots(widget.ranks[v.voiceId] ?? 1, widget.total),
                              sample: widget.sample,
                              autoPlay: false,
                              tag: _tagFor(v),
                              onPlay: () => widget.onPlay(v),
                              onStop: widget.onStop,
                            ),
                          ),
                          const SizedBox(height: 6),
                          GlassButton(label: 'Use this voice', size: GlassButtonSize.small, onPressed: widget.onUse == null ? null : () => widget.onUse!(v), disabledReason: widget.onUse == null ? "Voices are set by the server's owner" : null),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String? _tagFor(NovelVoice v) {
    final a = widget.attribution;
    if (a == null) return null;
    if (a.narratorVoiceId == v.voiceId) return 'Narrator';
    final names = [for (final m in a.cast) if (m.voiceId == v.voiceId) m.name];
    return names.isEmpty ? null : 'In use for ${names.first}';
  }
}
