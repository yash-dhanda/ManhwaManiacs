import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/collections/providers/collection_detail_provider.dart';
import 'package:manhwamaniacs/features/collections/providers/collections_provider.dart';
import 'package:manhwamaniacs/features/library/models/collection.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_dialog.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_switch.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_text_field.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_textarea.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/dialog_route.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/sheet_route.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/collections/rule_chips.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// The New shelf / Edit form (cinematic 8.11, 7.10): a sheet on phones, a dialog from 600 px.
/// [edit] prefills it and turns `Create` into `Save` (disabled while unchanged). Resolves with the
/// saved collection's id, or null when cancelled.
Future<int?> showShelfForm(BuildContext context, {Collection? edit}) {
  if (MediaQuery.sizeOf(context).width >= 600) {
    return showCineDialog<int>(context, builder: (ctx) => CineDialog(title: edit == null ? 'New shelf' : 'Edit shelf', content: _ShelfForm(edit: edit, dialog: true), actions: const []));
  }
  return showCineSheet<int>(context, kicker: edit == null ? 'NEW SHELF' : 'EDIT SHELF', title: edit == null ? 'New shelf' : 'Edit shelf', builder: (ctx) => _ShelfForm(edit: edit, dialog: false));
}

class _ShelfForm extends ConsumerStatefulWidget {
  const _ShelfForm({required this.edit, required this.dialog});
  final Collection? edit;
  final bool dialog;

  @override
  ConsumerState<_ShelfForm> createState() => _ShelfFormState();
}

class _ShelfFormState extends ConsumerState<_ShelfForm> {
  late final _name = TextEditingController(text: widget.edit?.name ?? '');
  late final _desc = TextEditingController(text: widget.edit?.description ?? '');
  late bool _smart = widget.edit?.smart ?? false;
  late RuleDraft _draft = RuleDraft.from(widget.edit?.rules);
  late final RuleDraft _draft0 = _draft;
  late final bool _smart0 = _smart;
  bool _saving = false;
  String? _error, _rulesError;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() => _error = null));
    _desc.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  bool get _changed {
    final e = widget.edit;
    if (e == null) return true;
    return _name.text.trim() != e.name || _desc.text.trim() != (e.description ?? '') || _smart != _smart0 || _draft.toRules() != _draft0.toRules();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty || name.length > 255) {
      setState(() => _error = name.isEmpty ? 'Give the shelf a name.' : 'Keep the name under 255 characters.');
      return;
    }
    final rules = _smart ? _draft.toRules() : null;
    if (_smart && rules == null) {
      setState(() => _rulesError = 'Choose at least one rule.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _rulesError = null;
    });
    cineFeedback(context, HapticEvent.tapPrimary);
    final edit = widget.edit;
    int? id;
    AppError? err;
    if (edit == null) {
      err = await ref.read(collectionsProvider.notifier).createCollection(name: name, description: _desc.text.trim(), rules: rules);
    } else {
      err = await ref.read(collectionDetailProvider(edit.id).notifier).updateCollection(
            name: name,
            description: _desc.text.trim(),
            rules: rules,
            clearRules: !_smart && edit.smart,
          );
      id = edit.id;
    }
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _saving = false;
        _error = err is ApiError && err.statusCode == 409 ? 'A shelf with that name already exists.' : err!.userMessage;
      });
      return;
    }
    Navigator.of(context).pop(id ?? -1);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final form = Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      CineTextField(
        key: const Key('shelf-name'),
        label: 'Name',
        controller: _name,
        size: CineFieldSize.field,
        errorText: _error,
        enabled: !_saving,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (_) => unawaited(_save()),
      ),
      SizedBox(height: c.space3),
      CineTextarea(key: const Key('shelf-description'), label: 'Description', controller: _desc, enabled: !_saving),
      SizedBox(height: c.space3),
      ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(children: [
          Expanded(child: CineRoleText('Smart shelf', c.typeUi)),
          CineSwitch(label: 'Smart shelf', value: _smart, onChanged: _saving ? null : (v) => setState(() => _smart = v)),
        ],),
      ),
      if (_smart) ...[
        RuleChips(draft: _draft, onChanged: (d) => setState(() {
              _draft = d;
              _rulesError = null;
            }),),
        if (_rulesError != null) Padding(padding: EdgeInsets.only(top: c.space2), child: CineRoleText(_rulesError!, c.typeCaption, color: c.colorProof)),
      ],
      SizedBox(height: c.space6),
      CineButton(
        key: const Key('shelf-save'),
        label: widget.edit == null ? 'Create' : 'Save',
        loading: _saving,
        fullWidth: true,
        onPressed: _changed ? () => unawaited(_save()) : null,
        disabledReason: 'Nothing has changed.',
      ),
      SizedBox(height: c.space2),
      CineButton(label: 'Cancel', variant: CineButtonVariant.quiet, fullWidth: true, onPressed: _saving ? null : () => Navigator.of(context).pop()),
    ],);
    return Padding(padding: widget.dialog ? EdgeInsets.zero : EdgeInsets.fromLTRB(c.space4, 0, c.space4, c.space4), child: form);
  }
}
