import 'package:flutter/material.dart' show Material;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/copy/settings_index.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/grouped_list.dart';
import 'package:manhwamaniacs/skins/glass/primitives/list/list_row.dart';
import 'package:manhwamaniacs/skins/glass/primitives/search_field.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_index_filter.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The matches of [query], grouped by section as rows (label, the section name in `footnote` `label2`), or "No settings match “q”".
class SettingsResults extends StatelessWidget {
  const SettingsResults({super.key, required this.query, required this.matches, required this.onOpen});
  final String query;
  final List<SettingsIndexEntry> matches;
  final ValueChanged<SettingsIndexEntry> onOpen;

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return Padding(padding: const EdgeInsets.all(24), child: Center(child: GlassText('No settings match “$query”', role: gt.typeBody, color: gt.colorLabel2)));
    }
    final grouped = groupBySection(matches);
    return Column(children: [
      for (final e in grouped.entries)
        GlassGroupedList(header: settingsSectionTitle(e.key), children: [
          for (final m in e.value) GlassListRow(title: m.label, subtitle: settingsSectionTitle(m.section), caret: true, onTap: () => onOpen(m)),
        ],),
    ],);
  }
}

/// Phone search overlay (glass 8.25, B4): the page's black ground, the field at the top with "Cancel", the results. Esc and Android
/// back close it first (the screen wraps it in a `PopScope`).
class GlassSettingsSearchOverlay extends StatefulWidget {
  const GlassSettingsSearchOverlay({super.key, required this.filter, required this.onOpen, required this.onClose});

  /// Matches for a query (the screen closes over platform, role, capabilities, gate and flag).
  final List<SettingsIndexEntry> Function(String query) filter;
  final ValueChanged<SettingsIndexEntry> onOpen;
  final VoidCallback onClose;

  @override
  State<GlassSettingsSearchOverlay> createState() => _GlassSettingsSearchOverlayState();
}

class _GlassSettingsSearchOverlayState extends State<GlassSettingsSearchOverlay> {
  final TextEditingController _c = TextEditingController();
  final FocusNode _node = FocusNode(debugLabel: 'settings search');
  String _q = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _node.requestFocus();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Focus(
        onKeyEvent: (_, e) {
          if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
            widget.onClose();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Material(
          color: const Color(0xFF000000),
          child: SafeArea(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: GlassSearchField(
                  controller: _c,
                  focusNode: _node,
                  placeholder: 'Search settings',
                  onQuery: (q) => setState(() => _q = q),
                  onCancel: widget.onClose,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: _q.trim().isEmpty ? const SizedBox.shrink() : SettingsResults(query: _q.trim(), matches: widget.filter(_q), onOpen: widget.onOpen),
                ),
              ),
            ],),
          ),
        ),
      );
}
