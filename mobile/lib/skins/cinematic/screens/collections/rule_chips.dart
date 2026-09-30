import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/library/utils/smart_shelf.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_badge.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_checkbox.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_select_field.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_stepper.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_switch.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The rule chips of the New shelf form (cinematic 8.11), as a value the form edits.
class RuleDraft {
  const RuleDraft({this.status, this.favourite = false, this.newCount, this.formats = const {}, this.unfinished = false});

  /// `reading_status eq`, or null.
  final String? status;
  final bool favourite;

  /// `new_count gte`, or null.
  final int? newCount;

  /// `format in`.
  final Set<String> formats;

  /// The unfinished-novels pair.
  final bool unfinished;

  static const formatWords = {'manhwa': 'Manhwa', 'manga': 'Manga', 'manhua': 'Manhua'};

  bool get isEmpty => status == null && !favourite && newCount == null && formats.isEmpty && !unfinished;

  RuleDraft copyWith({String? status, bool clearStatus = false, bool? favourite, int? newCount, bool clearNewCount = false, Set<String>? formats, bool? unfinished}) => RuleDraft(
        status: clearStatus ? null : (status ?? this.status),
        favourite: favourite ?? this.favourite,
        newCount: clearNewCount ? null : (newCount ?? this.newCount),
        formats: formats ?? this.formats,
        unfinished: unfinished ?? this.unfinished,
      );

  /// The rules this draft stands for (AND); null when nothing is chosen.
  ShelfRules? toRules() {
    if (isEmpty) return null;
    return ShelfRules(all: [
      if (status != null) ShelfRule(field: 'reading_status', op: 'eq', value: status!),
      if (favourite) const ShelfRule(field: 'is_favorite', op: 'eq', value: true),
      if (newCount != null) ShelfRule(field: 'new_count', op: 'gte', value: newCount!),
      if (formats.isNotEmpty) ShelfRule(field: 'format', op: 'in', value: [for (final f in formatWords.keys) if (formats.contains(f)) f]),
      if (unfinished) ...unfinishedNovels,
    ],);
  }

  /// The draft for stored [rules]; rules the form has no chip for are dropped.
  static RuleDraft from(ShelfRules? rules) {
    if (rules == null) return const RuleDraft();
    var d = const RuleDraft();
    var novel = false, notDone = false;
    for (final r in rules.all) {
      switch ((r.field, r.op)) {
        case ('reading_status', 'eq'):
          d = d.copyWith(status: '${r.value}');
        case ('reading_status', 'ne') when r.value == 'completed':
          notDone = true;
        case ('content_kind', 'eq') when r.value == 'novel':
          novel = true;
        case ('is_favorite', 'eq'):
          d = d.copyWith(favourite: r.value == true);
        case ('new_count', 'gte'):
          d = d.copyWith(newCount: r.value is num ? (r.value as num).toInt() : int.tryParse('${r.value}'));
        case ('format', 'in'):
          d = d.copyWith(formats: {for (final f in r.value as List) '$f'});
      }
    }
    return d.copyWith(unfinished: novel && notDone);
  }
}

/// The chips: *status is*, *favourite*, *new chapters at least*, *format*, *unfinished novels*.
class RuleChips extends StatelessWidget {
  const RuleChips({super.key, required this.draft, required this.onChanged});
  final RuleDraft draft;
  final ValueChanged<RuleDraft> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    Widget row(String label, Widget control) => ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(children: [
            Expanded(child: CineRoleText(label, c.typeUi)),
            control,
          ],),
        );
    return Column(key: const Key('rule-chips'), crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      CineSelectField<String>(
        label: 'Status is',
        value: draft.status ?? '',
        options: [
          const CineOption('', 'Any status'),
          for (final s in const ['reading', 'unread', 'completed', 'on_hold', 'plan_to_read', 'dropped']) CineOption(s, readingStatusLabel(s)),
        ],
        onChanged: (v) => onChanged(v.isEmpty ? draft.copyWith(clearStatus: true) : draft.copyWith(status: v)),
      ),
      row('Favourites only', CineSwitch(label: 'Favourites only', value: draft.favourite, onChanged: (v) => onChanged(draft.copyWith(favourite: v)))),
      row(
        'New chapters at least',
        Row(mainAxisSize: MainAxisSize.min, children: [
          if (draft.newCount != null) CineStepper(label: 'New chapters at least', value: draft.newCount!, min: 1, onChanged: (v) => onChanged(draft.copyWith(newCount: v))),
          SizedBox(width: c.space3),
          CineSwitch(label: 'Filter by new chapters', value: draft.newCount != null, onChanged: (v) => onChanged(v ? draft.copyWith(newCount: 3) : draft.copyWith(clearNewCount: true))),
        ],),
      ),
      Padding(
        padding: EdgeInsets.only(top: c.space2),
        child: Wrap(spacing: c.space4, children: [
          for (final e in RuleDraft.formatWords.entries)
            CineCheckbox(
              value: draft.formats.contains(e.key),
              label: e.value,
              onChanged: (v) => onChanged(draft.copyWith(formats: v ? {...draft.formats, e.key} : ({...draft.formats}..remove(e.key)))),
            ),
        ],),
      ),
      row('Unfinished novels', CineSwitch(label: 'Unfinished novels', value: draft.unfinished, onChanged: (v) => onChanged(draft.copyWith(unfinished: v)))),
    ],);
  }
}
