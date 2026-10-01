import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_storage_providers.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_profile_settings.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/features/settings/utils/format_storage_bytes.dart';
import 'package:manhwamaniacs/skins/cinematic/a11y/folio.dart';
import 'package:manhwamaniacs/skins/cinematic/focus_ring.dart';
import 'package:manhwamaniacs/skins/cinematic/hit.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_dot_leader.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_registry.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/skins.dart';

/// The folio-style current value of a section in the table of contents (`CINEMATIC`, `STRIP`,
/// `4.1 GB`); null where a section has none.
final settingsSectionValueProvider = Provider.family<String?, String>((ref, slug) {
  switch (slug) {
    case 'appearance':
      return ref.watch(skinIdProvider).name.toUpperCase();
    case 'reading-manga':
      return ref.watch(readerSettingsProvider).seriesDefaults.layout.toUpperCase();
    case 'storage':
      final b = ref.watch(totalDeviceDownloadBytesProvider).valueOrNull;
      return b == null ? null : formatStorageBytes(b).toUpperCase();
    case 'feedback':
      return ref.watch(hapticFeedbackProvider) ? 'HAPTICS ON' : 'HAPTICS OFF';
    case 'server':
      final url = ref.watch(settingsApiUrlProvider).valueOrNull;
      return url == null ? null : (Uri.tryParse(url)?.host.isNotEmpty ?? false ? Uri.parse(url).host : url);
    case 'about':
      final i = ref.watch(packageInfoProvider).valueOrNull;
      return i == null ? null : '${i.version} (${i.buildNumber})';
    default:
      return null;
  }
});

/// The credits-list table of contents (one pane): folio, title, dot leaders, the current value and
/// a caret; 56 dp rows.
class SettingsContentsList extends ConsumerWidget {
  const SettingsContentsList({super.key, required this.sections, required this.onOpen});
  final List<SettingsSectionDef> sections;
  final void Function(String slug) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final s in sections)
        Builder(builder: (context) {
          final value = ref.watch(settingsSectionValueProvider(s.slug));
          final folio = folioOf(sections, s.slug);
          return Semantics(
            button: true,
            container: true,
            excludeSemantics: true,
            label: '$folio, ${s.title}${value == null ? '' : ', ${folioLabel(value)}'}',
            onTap: () => onOpen(s.slug),
            child: CinePressable(
              key: Key('settings-toc-${s.slug}'),
              onTap: () => onOpen(s.slug),
              hit: false,
              builder: (context, st) => Container(
                constraints: BoxConstraints(minHeight: cineHitMin(context) > 56 ? cineHitMin(context) : 56),
                decoration: BoxDecoration(border: Border(bottom: c.ruleHair), color: st.pressed ? c.colorPaper3 : null),
                child: Row(children: [
                  SizedBox(width: 32, child: CineRoleText(folio, c.typeFolio, color: c.colorInk60)),
                  Expanded(
                    child: CineLeaderRow(
                      label: CineRoleText(s.title, c.typeUi),
                      value: value == null ? null : CineRoleText(value, c.typeFolio, color: c.colorInk60, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  SizedBox(width: c.space2),
                  CineGlyphIcon(CineGlyph.caretRight, size: 16, color: c.colorInk60),
                ],),
              ),
            ),
          );
        },),
    ],);
  }
}

/// One row of the two-pane table of contents: folio and title, lit with a 2 px `spot` bar when it
/// is the current section.
class SettingsPaneTocRow extends StatelessWidget {
  const SettingsPaneTocRow({super.key, required this.folio, required this.title, required this.current, required this.onTap, this.focusNode});
  final String folio, title;
  final bool current;
  final VoidCallback onTap;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Semantics(
      button: true,
      selected: current,
      container: true,
      excludeSemantics: true,
      label: '$folio, $title',
      onTap: onTap,
      child: CinePressable(
        focusNode: focusNode,
        onTap: onTap,
        hit: false,
        builder: (context, st) => Container(
          constraints: BoxConstraints(minHeight: cineHitMin(context) > 48 ? cineHitMin(context) : 48),
          padding: EdgeInsets.only(left: c.space3),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: current ? c.colorSpot : const Color(0x00000000), width: 2)),
            color: st.hovered ? c.colorPaper3 : null,
          ),
          child: Row(children: [
            SizedBox(width: 32, child: CineRoleText(folio, c.typeFolio, color: current ? c.colorSpot : c.colorInk60)),
            Expanded(child: CineRoleText(title, c.typeUi, color: current ? c.colorInk100 : c.colorInk60)),
          ],),
        ),
      ),
    );
  }
}
