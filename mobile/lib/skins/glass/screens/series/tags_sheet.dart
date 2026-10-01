import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/ai/providers/suggested_tags_provider.dart';
import 'package:manhwamaniacs/features/library/models/tag.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/features/library/providers/tags_controller.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/glass/primitives/ai/machine_badge.dart';
import 'package:manhwamaniacs/skins/glass/primitives/chip.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/primitives/text_field.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_sheet_route.dart';
import 'package:manhwamaniacs/skins/glass/screens/series/series_data.dart';

/// Pushes an inner sheet over the series page (the two-sheet rule, glass 7.10 stacking).
Future<void> pushSeriesSheet(BuildContext context, {required String title, required WidgetBuilder builder, List<GlassDetent> detents = const [GlassDetent.medium, GlassDetent.large], GlassDetent opening = GlassDetent.medium}) {
  final page = GlassSheetPage<void>(key: ValueKey('series-sheet:$title'), title: title, builder: builder, detents: detents, opening: opening, wideForm: GlassWideForm.window);
  return Navigator.of(context, rootNavigator: true).push<void>(page.createRoute(context));
}

/// The ten speaker hues (glass 2.1.5) a new tag takes its colour from.
List<Color> get tagHues => [gt.colorSpk1, gt.colorSpk2, gt.colorSpk3, gt.colorSpk4, gt.colorSpk5, gt.colorSpk6, gt.colorSpk7, gt.colorSpk8, gt.colorSpk9, gt.colorSpk10];

String _hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// Tags… (`?sheet=tags`, glass 8.12): the profile's tags to toggle on this series, New tag, and the AI suggestions.
class SeriesTagsSheet extends ConsumerStatefulWidget {
  const SeriesTagsSheet({super.key, required this.data});
  final GlassSeriesData data;

  @override
  ConsumerState<SeriesTagsSheet> createState() => _SeriesTagsSheetState();
}

class _SeriesTagsSheetState extends ConsumerState<SeriesTagsSheet> {
  final _name = TextEditingController();
  final _nameFocus = FocusNode(debugLabel: 'new tag');
  int _hue = 0;
  String? _inline;
  final Set<String> _dismissed = {};
  final Map<int, bool> _pending = {};

  TagSeriesKey get _k => (sourceId: widget.data.sourceId, seriesKey: widget.data.seriesKey);

  @override
  void dispose() {
    _name.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  List<Tag> _current() => ref.read(seriesTagOverlayProvider)[_k] ?? widget.data.followed?.tags ?? const [];

  Future<void> _toggle(Tag t, bool on) async {
    setState(() => _pending[t.id] = on);
    final c = ref.read(tagsControllerProvider);
    final err = on ? await c.tagSeries(_k, t, current: _current()) : await c.untagSeries(_k, t, current: _current());
    if (!mounted) return;
    setState(() => _pending.remove(t.id));
    if (err != null) showGlassToast(ref, const GlassToastSpec("Couldn't update tags", kind: GlassToastKind.error));
  }

  Future<void> _create([String? preset]) async {
    final name = (preset ?? _name.text).trim();
    if (name.isEmpty) return;
    final tags = ref.read(profileTagsProvider).valueOrNull ?? const <Tag>[];
    final existing = tags.where((t) => t.name.toLowerCase() == name.toLowerCase()).firstOrNull;
    if (existing != null) {
      if (preset != null) return _toggle(existing, true);
      setState(() => _inline = 'You already have a tag called $name');
      return;
    }
    final created = await ref.read(libraryRepositoryProvider).createTag(name: name, color: _hex(tagHues[_hue]));
    ref.invalidate(profileTagsProvider);
    final err = created.isErr ? created.error : await ref.read(tagsControllerProvider).tagSeries(_k, created.value, current: _current());
    if (!mounted) return;
    if (err != null) {
      setState(() => _inline = "Couldn't create that tag");
      return;
    }
    setState(() => _inline = null);
    _name.clear();
  }

  @override
  Widget build(BuildContext context) {
    final online = isOnline(ref);
    final tags = ref.watch(profileTagsProvider);
    final on = {for (final t in ref.watch(seriesTagOverlayProvider)[_k] ?? widget.data.followed?.tags ?? const <Tag>[]) t.id};
    final ai = ref.watch(suggestedTagsProvider((sourceId: widget.data.sourceId, seriesKey: widget.data.seriesKey))).valueOrNull;
    final names = {for (final t in tags.valueOrNull ?? const <Tag>[]) t.name.toLowerCase()};

    Widget body;
    if (!online) {
      body = GlassLabel('Tags need a connection', key: const ValueKey('tags-offline'), role: gt.typeBody, color: gt.colorLabel2);
    } else if (tags.isLoading && !tags.hasValue) {
      body = GlassSkeletonGroup(child: Wrap(spacing: 8, children: [for (var i = 0; i < 4; i++) GlassSkeleton(width: 72.0 + 12 * i, height: 34, radius: 17, index: i)]));
    } else if (tags.hasError && !tags.hasValue) {
      body = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GlassLabel("Couldn't load your tags", role: gt.typeBody),
        GlassButton(label: 'Try again', variant: GlassButtonVariant.plain, size: GlassButtonSize.small, onPressed: () => ref.invalidate(profileTagsProvider)),
      ],);
    } else if ((tags.valueOrNull ?? const []).isEmpty) {
      body = GlassLabel('No tags yet', key: const ValueKey('tags-empty'), role: gt.typeBody, color: gt.colorLabel2);
      if (!_nameFocus.hasFocus) WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _nameFocus.requestFocus() : null);
    } else {
      body = Wrap(spacing: 8, runSpacing: 8, children: [
        for (final t in tags.value!)
          GlassChip(
            key: ValueKey('tag-${t.id}'),
            label: t.name,
            selected: _pending[t.id] ?? on.contains(t.id),
            dot: t.color,
            onPressed: () => unawaited(_toggle(t, !(on.contains(t.id)))),
          ),
      ],);
    }

    final suggestions = [
      for (final s in ai?.tags ?? const <String>[])
        if (!names.contains(s.toLowerCase()) && !_dismissed.contains(s)) s,
    ].take(5).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          body,
          const SizedBox(height: 20),
          GlassLabel('New tag', role: gt.typeHeadline),
          const SizedBox(height: 8),
          GlassTextField(
            key: const ValueKey('new-tag-field'),
            controller: _name,
            focusNode: _nameFocus,
            hint: 'Tag name',
            enabled: online,
            error: _inline,
            onSheet: true,
            inputFormatters: [LengthLimitingTextInputFormatter(24)],
            onChanged: (_) => setState(() => _inline = null),
            onSubmitted: (_) => unawaited(_create()),
          ),
          if (_name.text.length >= 20) GlassLabel('${_name.text.length}/24', role: gt.typeCaption1, color: gt.colorLabel3),
          const SizedBox(height: 8),
          Wrap(spacing: 4, children: [
            for (var i = 0; i < 10; i++)
              Semantics(
                selected: _hue == i,
                button: true,
                label: 'Colour ${i + 1}',
                child: GestureDetector(
                  onTap: () => setState(() => _hue = i),
                  child: SizedBox.square(
                    dimension: 32,
                    child: Center(child: Container(width: _hue == i ? 22 : 16, height: _hue == i ? 22 : 16, decoration: BoxDecoration(color: tagHues[i], shape: BoxShape.circle))),
                  ),
                ),
              ),
          ],),
          GlassButton(label: 'Create tag', size: GlassButtonSize.small, onPressed: online ? () => unawaited(_create()) : null),
          if (ai != null && ai.available && suggestions.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(children: [const MachineBadge(), const SizedBox(width: 6), GlassLabel('Suggested', role: gt.typeHeadline)]),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final s in suggestions)
                Row(mainAxisSize: MainAxisSize.min, key: ValueKey('suggest-$s'), children: [
                  GlassChip(label: s, kind: GlassChipKind.assist),
                  GlassButton(label: '✓', semanticsLabel: 'Add $s', variant: GlassButtonVariant.plain, size: GlassButtonSize.small, onPressed: online ? () => unawaited(_create(s)) : null),
                  GlassButton(
                    label: '×',
                    semanticsLabel: 'Dismiss $s',
                    variant: GlassButtonVariant.plain,
                    size: GlassButtonSize.small,
                    onPressed: () {
                      setState(() => _dismissed.add(s));
                      fire(ref.read(aiRepositoryProvider).rejectSuggestedTag(widget.data.sourceId, widget.data.seriesKey, s));
                    },
                  ),
                ],),
            ],),
          ],
        ],
      ),
    );
  }
}
