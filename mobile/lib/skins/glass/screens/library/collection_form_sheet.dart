import 'dart:async';

import 'package:flutter/services.dart' show TextCapitalization;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/collections/providers/collection_detail_provider.dart';
import 'package:manhwamaniacs/features/collections/providers/collections_provider.dart';
import 'package:manhwamaniacs/features/collections/utils/rule_draft.dart';
import 'package:manhwamaniacs/skins/glass/primitives/alert.dart';
import 'package:manhwamaniacs/skins/glass/primitives/chip.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/stepper.dart';
import 'package:manhwamaniacs/skins/glass/primitives/switch.dart';
import 'package:manhwamaniacs/skins/glass/primitives/text_area.dart';
import 'package:manhwamaniacs/skins/glass/primitives/text_field.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_sheet_route.dart';
import 'package:manhwamaniacs/skins/glass/routes/sheet_registry.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/library_common.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// `?sheet=collection-new` (medium, large once a field takes focus) and `?sheet=collection-edit&collection={id}` (glass 8.18).
final GlassSheetSpec glassCollectionNewSheetSpec = GlassSheetSpec(
  title: 'New collection',
  builder: (_) => const GlassCollectionFormBody(),
  detents: const [GlassDetent.medium, GlassDetent.large],
  opening: GlassDetent.medium,
);

final GlassSheetSpec glassCollectionEditSheetSpec = GlassSheetSpec(
  title: 'Edit collection',
  builder: (context) => GlassCollectionFormBody(editId: int.tryParse(sheetParams(context)['collection'] ?? '')),
  detents: const [GlassDetent.medium, GlassDetent.large],
  opening: GlassDetent.medium,
);

const _statuses = [('reading', 'Reading'), ('unread', 'Not started'), ('completed', 'Completed'), ('on_hold', 'On hold'), ('plan_to_read', 'Plan to read'), ('dropped', 'Dropped')];

/// The form: Name, Description, the Smart switch revealing the rule chips (combined with AND), the error line and the tinted action.
class GlassCollectionFormBody extends ConsumerStatefulWidget {
  const GlassCollectionFormBody({super.key, this.editId});
  final int? editId;

  @override
  ConsumerState<GlassCollectionFormBody> createState() => _GlassCollectionFormBodyState();
}

class _GlassCollectionFormBodyState extends ConsumerState<GlassCollectionFormBody> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _desc = TextEditingController();
  RuleDraft _rules = const RuleDraft();
  bool _smart = false;
  bool _busy = false;
  bool _loaded = false;
  String? _error;
  String _n0 = '', _d0 = '';
  bool _smart0 = false;
  RuleDraft _rules0 = const RuleDraft();

  bool get _edit => widget.editId != null;

  @override
  void initState() {
    super.initState();
    if (_edit) WidgetsBinding.instance.addPostFrameCallback((_) => _prefill());
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _prefill() async {
    try {
      final d = await ref.read(collectionDetailProvider(widget.editId!).future);
      if (!mounted) return;
      setState(() {
        _name.text = _n0 = d.name;
        _desc.text = _d0 = d.description ?? '';
        _smart = _smart0 = d.rules != null;
        _rules = _rules0 = RuleDraft.from(d.rules);
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _error = "Couldn't load the collection");
    }
  }

  bool get _changed => !_edit ? (_name.text.isNotEmpty || _desc.text.isNotEmpty) : (_name.text != _n0 || _desc.text != _d0 || _smart != _smart0 || _rules.toRules()?.toJson().toString() != _rules0.toRules()?.toJson().toString());
  bool get _canSave => !_busy && _name.text.trim().isNotEmpty && (!_edit || (_loaded && _changed));

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final rules = _smart ? _rules.toRules() : null;
    final name = _name.text.trim();
    final desc = _desc.text.trim().isEmpty ? null : _desc.text.trim();
    final err = _edit
        ? await ref.read(collectionDetailProvider(widget.editId!).notifier).updateCollection(name: name, description: desc ?? '', rules: rules, clearRules: !_smart)
        : await ref.read(collectionsProvider.notifier).createCollection(name: name, description: desc, rules: rules);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _busy = false;
        _error = _edit ? "Couldn't save the collection" : "Couldn't create the collection";
      });
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _close(bool didPop) async {
    if (didPop) return;
    final discard = await showGlassAlert<bool>(context, title: 'Discard your changes?', actions: const [
      GlassAlertAction<bool>('Keep editing', role: GlassAlertRole.cancel, value: false),
      GlassAlertAction<bool>('Discard', role: GlassAlertRole.destructive, value: true),
    ],);
    if ((discard ?? false) && mounted) Navigator.of(context).pop();
  }

  Widget _row(String label, Widget control, bool on) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(children: [Expanded(child: GlassText(label, role: gt.typeBody, onGlass: on)), control]),
      );

  @override
  Widget build(BuildContext context) {
    final on = sheetOnGlass(context);
    final r = _rules;
    return PopScope(
      canPop: !(_edit && _changed),
      onPopInvokedWithResult: (didPop, _) => unawaited(_close(didPop)),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        shrinkWrap: true,
        children: [
          GlassTextField(controller: _name, label: 'Name', hint: 'My reading list', onSheet: true, enabled: !_busy, onChanged: (_) => setState(() {}), textCapitalization: TextCapitalization.sentences),
          const SizedBox(height: 12),
          GlassTextArea(controller: _desc, label: 'Description (optional)', maxLength: 240, onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          _row('Smart', GlassSwitch(label: 'Smart', value: _smart, onChanged: (v) => setState(() => _smart = v)), on),
          if (_smart) ...[
            const SizedBox(height: 8),
            GlassText('Every rule must hold.', role: gt.typeFootnote, onGlass: on, color: gt.colorLabel2),
            const SizedBox(height: 8),
            GlassText('Status is', role: gt.typeHeadline, onGlass: on),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final s in _statuses) GlassChip(label: s.$2, selected: r.status == s.$1, onPressed: () => setState(() => _rules = r.status == s.$1 ? r.copyWith(clearStatus: true) : r.copyWith(status: s.$1))),
            ],),
            _row('Favourites only', GlassSwitch(label: 'Favourites only', value: r.favourite, onChanged: (v) => setState(() => _rules = r.copyWith(favourite: v))), on),
            _row(
              'New chapters at least',
              Row(mainAxisSize: MainAxisSize.min, children: [
                if (r.newCount != null) GlassStepper(label: 'New chapters at least', value: r.newCount!, min: 1, onChanged: (v) => setState(() => _rules = r.copyWith(newCount: v))),
                const SizedBox(width: 12),
                GlassSwitch(label: 'Filter by new chapters', value: r.newCount != null, onChanged: (v) => setState(() => _rules = v ? r.copyWith(newCount: 3) : r.copyWith(clearNewCount: true))),
              ],),
              on,
            ),
            GlassText('Format', role: gt.typeHeadline, onGlass: on),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final e in RuleDraft.formatWords.entries)
                GlassChip(label: e.value, selected: r.formats.contains(e.key), onPressed: () => setState(() => _rules = r.copyWith(formats: r.formats.contains(e.key) ? ({...r.formats}..remove(e.key)) : {...r.formats, e.key}))),
            ],),
            _row('Unfinished novels', GlassSwitch(label: 'Unfinished novels', value: r.unfinished, onChanged: (v) => setState(() => _rules = r.copyWith(unfinished: v))), on),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Semantics(liveRegion: true, child: GlassText(_error!, role: gt.typeFootnote, onGlass: on, color: gt.colorDanger)),
          ],
          const SizedBox(height: 16),
          GlassButton(label: _edit ? 'Save' : 'Create', variant: GlassButtonVariant.primary, size: GlassButtonSize.large, fullWidth: true, loading: _busy, onPressed: _canSave ? () => unawaited(_save()) : null),
        ],
      ),
    );
  }
}
