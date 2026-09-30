
import 'package:flutter/material.dart';
import 'package:manhwamaniacs/features/settings/utils/settings_search.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_search_field.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_registry.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

String _titleOf(List<SettingsSectionDef> sections, String slug) => sections.where((s) => s.slug == slug).firstOrNull?.title ?? slug;

/// The result list: the label in `type.ui`, its section in `type.caption`. Empty text when the
/// query matches nothing.
class SettingsSearchResults extends StatelessWidget {
  const SettingsSearchResults({super.key, required this.query, required this.results, required this.sections, required this.onPick, this.selected = -1});
  final String query;
  final List<SettingsRowRef> results;
  final List<SettingsSectionDef> sections;
  final ValueChanged<SettingsRowRef> onPick;
  final int selected;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    if (query.trim().isEmpty) return const SizedBox.shrink();
    if (results.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(c.space4),
        child: CineRoleText('No setting matches "${query.trim()}".', c.typeCaption, color: c.colorInk60),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (var i = 0; i < results.length; i++)
        Semantics(
          button: true,
          container: true,
          excludeSemantics: true,
          selected: i == selected,
          label: '${results[i].label}, ${_titleOf(sections, results[i].section)}',
          onTap: () => onPick(results[i]),
          child: CinePressable(
            key: Key('settings-result-${results[i].id}'),
            onTap: () => onPick(results[i]),
            hit: false,
            builder: (context, st) => Container(
              constraints: BoxConstraints(minHeight: cineHitMin(context) > 56 ? cineHitMin(context) : 56),
              padding: EdgeInsets.symmetric(vertical: c.space2, horizontal: c.space3),
              decoration: BoxDecoration(
                border: Border(bottom: c.ruleHair, left: BorderSide(color: i == selected ? c.colorSpot : const Color(0x00000000), width: 2)),
                color: st.pressed || i == selected ? c.colorPaper3 : null,
              ),
              alignment: Alignment.centerLeft,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                CineRoleText(results[i].label, c.typeUi),
                CineRoleText(_titleOf(sections, results[i].section), c.typeCaption, color: c.colorInk60),
              ],),
            ),
          ),
        ),
    ],);
  }
}

/// The full-screen search of the one-pane layout. Resolves with the picked row. Android back
/// closes it first; on iOS the route cannot be swiped away and shows a visible `Close`.
class SettingsSearchPage extends StatefulWidget {
  const SettingsSearchPage({super.key, required this.rows, required this.sections});
  final List<SettingsRowRef> rows;
  final List<SettingsSectionDef> sections;

  @override
  State<SettingsSearchPage> createState() => _SettingsSearchPageState();
}

class _SettingsSearchPageState extends State<SettingsSearchPage> {
  final _q = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final ios = Theme.of(context).platform == TargetPlatform.iOS;
    final results = matchSettings(_query, widget.rows);
    final body = Scaffold(
      backgroundColor: c.colorPaper0,
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: EdgeInsets.fromLTRB(c.space4, c.space3, c.space4, c.space2),
            child: Row(children: [
              Expanded(
                child: CineSearchField(
                  semanticLabel: 'Search settings',
                  placeholder: 'Search settings',
                  variant: CineSearchVariant.compact,
                  controller: _q,
                  autofocus: true,
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              if (ios) Padding(padding: EdgeInsets.only(left: c.space2), child: CineButton(label: 'Close', variant: CineButtonVariant.quiet, size: CineButtonSize.sm, onPressed: () => Navigator.of(context).pop())),
            ],),
          ),
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: SettingsSearchResults(
                query: _query,
                results: results,
                sections: widget.sections,
                onPick: (r) => Navigator.of(context).pop(r),
              ),
            ),
          ),
        ],),
      ),
    );
    return ios ? PopScope(canPop: false, child: body) : body;
  }
}

/// Pushes the search and resolves with the row the reader picked, if any.
Future<SettingsRowRef?> openSettingsSearch(BuildContext context, List<SettingsRowRef> rows, List<SettingsSectionDef> sections) {
  return Navigator.of(context).push<SettingsRowRef>(
    PageRouteBuilder<SettingsRowRef>(
      transitionDuration: MediaQuery.disableAnimationsOf(context) ? const Duration(milliseconds: 150) : context.cine.durLine,
      reverseTransitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (_, __, ___) => SettingsSearchPage(rows: rows, sections: sections),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    ),
  );
}

