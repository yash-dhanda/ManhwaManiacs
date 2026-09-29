import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manhwamaniacs/core/error/fatal_error.dart';
import 'package:manhwamaniacs/core/error/not_available.dart';
import 'package:manhwamaniacs/core/keyboard/shortcut_registry.dart';
import 'package:manhwamaniacs/skins/cinematic/gallery/fixtures.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_banner_strip.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_not_available_notice.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/system/cine_broken_part.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/system/cine_error_screen.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/command_palette.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/keyboard_sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/running_head.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/stop_press_banner.dart';
import 'package:manhwamaniacs/skins/cinematic/shell/thumb_index.dart';
import 'package:manhwamaniacs/skins/cinematic/shutter.dart';
import 'package:manhwamaniacs/skins/cinematic/splash/cine_splash.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/cinematic/wipe_geometry.dart';

/// The section ids added by mobile/06, in page order: the pure views of the shell, and the frozen
/// frames of the splash, the Column wipe and the Iris.
const List<String> kShellGallerySections = ['shell', 'shell-frames'];

void _noop() {}

/// The mobile/06 gallery sections. Fixture props only; nothing here reads a provider except the
/// controls' own.
class ShellGallerySection extends StatelessWidget {
  const ShellGallerySection({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) => id == 'shell-frames' ? _frames(context) : _shell(context);

  Widget _sec(BuildContext context, String title, List<Widget> children) {
    final c = context.cine;
    return Padding(
      key: Key('gallery-$id'),
      padding: EdgeInsets.only(top: c.space10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        CineRoleText('GALLERY · ${title.toUpperCase()}', c.typeKicker, color: c.colorInk45),
        SizedBox(height: c.space2),
        const CineRuleDraw(kind: CineRuleKind.heavy),
        SizedBox(height: c.space4),
        ...children,
      ],),
    );
  }

  Widget _tag(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: CineRoleText(text, context.cine.typeCaption, color: context.cine.colorInk45),
      );

  Widget _box(Widget child, {double? height}) => Container(
        height: height,
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFF2B2A27))),
        child: child,
      );

  Widget _shell(BuildContext context) {
    final c = context.cine;
    final registry = [
      const ShortcutGroup('General', [
        ShortcutEntry(group: 'General', activator: SingleActivator(LogicalKeyboardKey.keyK, control: true), description: 'Open the command palette', onInvoke: _noop),
        ShortcutEntry(group: 'General', activator: SingleActivator(LogicalKeyboardKey.slash, shift: true), description: 'Show keyboard shortcuts', keys: ['?'], onInvoke: _noop),
        ShortcutEntry(group: 'General', activator: SingleActivator(LogicalKeyboardKey.keyT, alt: true), description: 'Go to notifications', onInvoke: _noop),
      ]),
      const ShortcutGroup('Navigation', [
        ShortcutEntry(group: 'Navigation', activator: SingleActivator(LogicalKeyboardKey.keyG), description: 'Go to a numbered section', keys: ['G', '1…12'], onInvoke: _noop),
      ]),
    ];
    final items = [
      PaletteItem(group: 'LIBRARY', title: 'Salt and Iron', subtitle: 'shelf', leading: SizedBox(width: 40, height: 60, child: CineImage(url: galleryCover(0), title: galleryTitle(0))), onSelect: _noop),
      const PaletteItem(group: 'GO TO', title: '02 Library', onSelect: _noop),
      const PaletteItem(group: 'GO TO', title: '04 Discover', onSelect: _noop),
      const PaletteItem(group: 'ACTIONS', title: 'Check for updates', onSelect: _noop),
      const PaletteItem(group: 'SETTINGS', title: 'Appearance', onSelect: _noop),
    ];
    final ranked = rankPalette('li', items);
    return _sec(context, 'The frame: running head, thumb index, banners', [
      _tag(context, 'RUNNING HEAD · DEFAULT, WITH BACK AND TITLE, TWO TRAILING ICONS'),
      _box(const CineRunningHead(title: 'LIBRARY · HISTORY')),
      _box(const CineRunningHead(
        title: 'DISCOVER · SOURCES',
        back: CineBack(_noop),
        trailing: [
          CineHeadAction(role: CineIconRole.search, label: 'Search', onPressed: _noop),
          CineHeadAction(role: CineIconRole.overflow, label: 'More', onPressed: _noop),
        ],
        solid: true,
      ),),
      _tag(context, 'OVER ART, WITH SCRIM.HEAD'),
      _box(
        height: 160,
        Stack(children: [
          Positioned.fill(child: CineImage(url: galleryCover(2), title: galleryTitle(2))),
          const CineRunningHead(title: 'TONIGHT', back: CineBack(_noop), overArt: true),
        ],),
      ),
      _tag(context, 'OFFLINE EDITION · GLYPH · BACK ONLINE'),
      _box(const CineRunningHead(title: 'DOWNLOADS', edition: CineEditionPhase.badge)),
      _box(const CineRunningHead(title: 'DOWNLOADS', edition: CineEditionPhase.glyph, onEditionGlyph: _noop)),
      _box(const CineRunningHead(title: 'DOWNLOADS', edition: CineEditionPhase.backOnline)),
      _tag(context, 'THUMB INDEX · EACH TAB ACTIVE, WITH BADGES'),
      for (var i = 0; i < 5; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: CineThumbIndex(active: i, badges: const [0, 3, 0, 120, 0], onSelect: _noopInt, onLongPress: _noopInt),
        ),
      _tag(context, 'STOP PRESS · PLURAL AND SINGULAR'),
      const CineStopPressBanner(chapters: 5, series: 3, onRead: _noop, onDismiss: _noop),
      const SizedBox(height: 8),
      const CineStopPressBanner(chapters: 1, series: 1, onRead: _noop, onDismiss: _noop),
      _tag(context, 'FIRST-RUN NOTE'),
      const CineBannerStrip(
        kicker: 'NOTHING FOLLOWED YET',
        line: 'Follow a series from Discover to start your shelf.',
        tone: CineBannerTone.plain,
        actions: [CineBannerAction('Discover', _noop)],
      ),
      _tag(context, 'THE G CHIP'),
      Row(children: [for (final t in const ['G _', 'G 1_']) Padding(padding: const EdgeInsets.only(right: 8), child: _Chip(t))]),
      _tag(context, 'KEYBOARD SHEET · FIXTURE REGISTRY'),
      _box(Padding(padding: EdgeInsets.all(c.space3), child: CineKeyboardSheetBody(groups: registry, platform: Theme.of(context).platform))),
      _tag(context, 'COMMAND PALETTE · RESULTS AND THE EMPTY STATE'),
      SizedBox(height: 560, child: CinePalette(fixture: items)),
      _tag(context, 'RANKED FOR "li"'),
      CineRoleText([for (final r in ranked) r.$1.title].join(' · '), c.typeCaption, color: c.colorInk60),
      const SizedBox(height: 300, child: CinePalette(fixture: [PaletteItem(group: 'GO TO', title: 'x', onSelect: _noop)], initialQuery: 'zzz')),
      _tag(context, 'STATUS SCREENS · 404, ROUTE ERROR, BROKEN PART'),
      _box(height: 520, const CineErrorScreen.notFound(location: '/nowhere')),
      _box(height: 420, CineErrorScreen.routeError(report: FatalErrorReport(StateError('fixture')), onRetry: _noop, onRestart: _noop)),
      const SizedBox(height: 8),
      const SizedBox(height: 64, child: CineBrokenPart()),
      _tag(context, 'NOT IN THIS ISSUE · SERIES, SOURCE, NOT BROWSABLE'),
      const CineNotAvailableNotice(kind: NotAvailableKind.series, title: 'Salt and Iron'),
      const CineNotAvailableNotice(kind: NotAvailableKind.source),
      const CineNotAvailableNotice(kind: NotAvailableKind.notBrowsable, sourceId: 'shelf'),
    ]);
  }

  Widget _frames(BuildContext context) {
    final c = context.cine;
    const w = 180.0, h = 390.0;
    Widget frame(String label, Widget child, {double width = w, double height = h}) => Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CineRoleText(label, c.typeCaption, color: c.colorInk45),
            const SizedBox(height: 4),
            Container(
              width: width,
              height: height,
              decoration: BoxDecoration(border: Border.all(color: const Color(0xFF2B2A27))),
              child: ClipRect(child: child),
            ),
          ],),
        );
    Widget wipe(int blades, double ms) => LayoutBuilder(builder: (context, box) {
          final painter = ColumnWipePainter(progress: ms / wipeTotalMs(blades), blades: blades);
          return Stack(fit: StackFit.expand, children: [
            CineImage(url: galleryCover(1), title: galleryTitle(1)),
            CustomPaint(painter: painter),
          ],);
        },);
    return _sec(context, 'Frozen frames: splash, Column wipe, Iris', [
      _tag(context, 'PRESS START · 0, 300, 560, 900, 1180 AND 1400 MS'),
      Wrap(children: [
        for (final ms in const [0.0, 300.0, 560.0, 900.0, 1180.0, 1400.0])
          frame('${ms.round()} MS', FittedBox(child: SizedBox(width: 390, height: 844, child: CineSplash(freezeAtMs: ms, tablet: false)))),
      ],),
      _tag(context, 'COLUMN WIPE · 4 BLADES: CLOSE END AND MID-OPEN'),
      Wrap(children: [
        frame('CLOSED · 4', wipe(4, wipeCloseMs(4).toDouble())),
        frame('MID-OPEN · 4', wipe(4, wipeCloseMs(4) + kWipeHoldMs + wipeOpenMs(4) / 2)),
      ],),
      _tag(context, 'COLUMN WIPE · 8 BLADES'),
      Wrap(children: [
        frame('CLOSED · 8', wipe(8, wipeCloseMs(8).toDouble()), width: 360, height: 300),
        frame('MID-OPEN · 8', wipe(8, wipeCloseMs(8) + kWipeHoldMs + wipeOpenMs(8) / 2), width: 360, height: 300),
      ],),
      _tag(context, 'IRIS · MID-CLOSE'),
      frame(
        'IRIS',
        CineShutterLayer(child: Builder(builder: (context) => _IrisPreview(c: context))),
      ),
    ]);
  }
}

void _noopInt(int _) {}

class _Chip extends StatelessWidget {
  const _Chip(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      constraints: const BoxConstraints(minWidth: 20, minHeight: 24),
      decoration: BoxDecoration(color: c.colorPaper2, border: Border.all(color: c.colorInk30)),
      alignment: Alignment.center,
      child: CineLit(text, CineFace.plexMono, 12, 16, color: c.colorInk100),
    );
  }
}

/// Paints an iris mid-close over a cover, once after the first frame.
class _IrisPreview extends StatefulWidget {
  const _IrisPreview({required this.c});
  final BuildContext c;

  @override
  State<_IrisPreview> createState() => _IrisPreviewState();
}

class _IrisPreviewState extends State<_IrisPreview> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) CineShutter.maybeOf(context)?.irisPreview(const Offset(90, 190), 60);
    });
  }

  @override
  Widget build(BuildContext context) => CineImage(url: galleryCover(3), title: galleryTitle(3));
}
