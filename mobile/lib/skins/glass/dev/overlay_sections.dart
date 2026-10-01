import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/skins/glass/dev/demo_cover.dart';
import 'package:manhwamaniacs/skins/glass/dev/gallery_sections.dart';
import 'package:manhwamaniacs/skins/glass/primitives/alert.dart';
import 'package:manhwamaniacs/skins/glass/primitives/checkbox.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/confirm_alert.dart';
import 'package:manhwamaniacs/skins/glass/primitives/content_mode_switch.dart';
import 'package:manhwamaniacs/skins/glass/primitives/context_menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/fast_scroll.dart';
import 'package:manhwamaniacs/skins/glass/primitives/fill_slider.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/image_viewer.dart';
import 'package:manhwamaniacs/skins/glass/primitives/inline_notice.dart';
import 'package:manhwamaniacs/skins/glass/primitives/menu.dart';
import 'package:manhwamaniacs/skins/glass/primitives/new_chapters_capsule.dart';
import 'package:manhwamaniacs/skins/glass/primitives/pull_to_refresh.dart';
import 'package:manhwamaniacs/skins/glass/primitives/radio_list.dart';
import 'package:manhwamaniacs/skins/glass/primitives/recede.dart';
import 'package:manhwamaniacs/skins/glass/primitives/scroll_edge.dart';
import 'package:manhwamaniacs/skins/glass/primitives/scrollbar.dart';
import 'package:manhwamaniacs/skins/glass/primitives/scrub_rail.dart';
import 'package:manhwamaniacs/skins/glass/primitives/selection_check.dart';
import 'package:manhwamaniacs/skins/glass/primitives/slider.dart';
import 'package:manhwamaniacs/skins/glass/primitives/speed_dial.dart';
import 'package:manhwamaniacs/skins/glass/primitives/status_capsule.dart';
import 'package:manhwamaniacs/skins/glass/primitives/stepper.dart';
import 'package:manhwamaniacs/skins/glass/primitives/switch.dart';
import 'package:manhwamaniacs/skins/glass/primitives/tab_pager.dart';
import 'package:manhwamaniacs/skins/glass/primitives/text_field.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/primitives/unsaved_changes_bar.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_sheet_route.dart';

/// The second half of the primitives gallery (`mobile/27`): sheets, alerts, toasts, tabs, sliders, toggles,
/// menus, notices, scroll furniture, pull to refresh and the content-mode switch. `null` means "not mine".
const List<String> kGlassOverlaySections = [
  'sheets',
  'alerts',
  'toasts',
  'tabs',
  'sliders',
  'toggles',
  'menus',
  'banners',
  'image-viewer',
  'scroll-edges',
  'pull-to-refresh',
  'content-mode',
];

Widget? glassOverlaySection(BuildContext context, String name, GalleryGround g) => switch (name) {
      'sheets' => GlassRecede(child: _sheets(context)),
      'alerts' => _alerts(context),
      'toasts' => const _Toasts(),
      'tabs' => const _Tabs(),
      'sliders' => const _Sliders(),
      'toggles' => const _Toggles(),
      'menus' => _menus(context),
      'banners' => const _Notices(),
      'image-viewer' => _imageViewer(context),
      'scroll-edges' => const _ScrollDemo(),
      'pull-to-refresh' => const GlassPullDemo(),
      'content-mode' => const Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            GlassContentModeSwitch(),
            GlassContentModeSwitch(variant: GlassContentModeVariant.navRow),
            GlassContentModeSwitch(variant: GlassContentModeVariant.menu),
          ],
        ),
      _ => null,
    };

Rect _rectOf(BuildContext c) {
  final b = c.findRenderObject()! as RenderBox;
  return b.localToGlobal(Offset.zero) & b.size;
}

/// The sheet page the dev route `/dev/glass/primitives/sheet/:id` serves (`peek`, `medium`, `large`, `monolith`).
GlassSheetPage<void> glassDemoSheetPage(String id, {LocalKey? key}) => GlassSheetPage<void>(
      key: key,
      title: 'Sheet $id',
      detents: id == 'peek' ? const [GlassDetent.peek, GlassDetent.medium, GlassDetent.large] : const [GlassDetent.medium, GlassDetent.large],
      opening: switch (id) {
        'peek' => GlassDetent.peek,
        'large' => GlassDetent.large,
        _ => GlassDetent.medium,
      },
      material: id == 'monolith' ? GlassSheetMaterial.monolith : GlassSheetMaterial.standard,
      builder: (_) => ListView.builder(itemCount: 1000, itemBuilder: (_, i) => SizedBox(height: 48, child: Center(child: GlassLabel('Row $i', role: gt.typeBody)))),
    );

/// A wide-form sheet page (panel, window, detail window, popover); on a phone it is an ordinary sheet.
GlassSheetPage<void> _formPage(GlassWideForm form, Rect origin) => GlassSheetPage<void>(
      title: switch (form) {
        GlassWideForm.panel => 'Panel',
        GlassWideForm.window => 'Window',
        GlassWideForm.detailWindow => 'Detail window',
        GlassWideForm.popover => 'Offer',
      },
      wideForm: form,
      originRect: origin,
      builder: (_) => ListView.builder(itemCount: 40, itemBuilder: (_, i) => SizedBox(height: 48, child: Center(child: GlassLabel('Row $i', role: gt.typeBody)))),
    );

GlassSheetPage<void> _stackedPage(int depth) => GlassSheetPage<void>(
      title: 'Sheet ${depth + 1}',
      detents: const [GlassDetent.large],
      opening: GlassDetent.large,
      builder: (c) => Center(
        child: GlassButton(label: 'Open another', onPressed: () => Navigator.of(c).push<void>(_stackedPage(depth + 1).createRoute(c))),
      ),
    );

GlassSheetPage<void> _keyboardPage() => GlassSheetPage<void>(
      title: 'New note',
      builder: (_) => ListView(
        padding: const EdgeInsets.all(16),
        children: const [Material(type: MaterialType.transparency, child: GlassTextField(label: 'Note', hint: 'Write something'))],
      ),
    );

Widget _sheets(BuildContext context) {
  Widget open(String label, GlassSheetPage<void> Function(Rect origin) page) => Builder(
        builder: (c) => GlassButton(label: label, onPressed: () => Navigator.of(c).push<void>(page(_rectOf(c)).createRoute(c))),
      );
  return Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final id in const ['peek', 'medium', 'large', 'monolith']) open('Open $id', (_) => glassDemoSheetPage(id)),
      open('Panel', (o) => _formPage(GlassWideForm.panel, o)),
      open('Window', (o) => _formPage(GlassWideForm.window, o)),
      open('Detail window', (o) => _formPage(GlassWideForm.detailWindow, o)),
      open('Popover', (o) => _formPage(GlassWideForm.popover, o)),
      open('Stacked', (_) => _stackedPage(0)),
      open('Keyboard field', (_) => _keyboardPage()),
      open('1,000-row list', (_) => glassDemoSheetPage('medium')),
    ],
  );
}

Widget _alerts(BuildContext context) => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Builder(
          builder: (c) => GlassButton(
            label: 'Confirm',
            onPressed: () => confirmAlert(c, title: 'Remove download?', body: 'It can be downloaded again.', confirmLabel: 'Remove', destructive: true, sourceRect: _rectOf(c)),
          ),
        ),
        Builder(
          builder: (c) => GlassButton(
            label: 'From centre',
            onPressed: () => confirmAlert(c, title: 'Sign out?', body: 'You can sign back in any time.', confirmLabel: 'Sign out'),
          ),
        ),
        Builder(
          builder: (c) => GlassButton(
            label: 'Pending',
            onPressed: () => showGlassAlert<int>(
              c,
              title: 'Clearing cache',
              body: 'This takes a moment.',
              sourceRect: _rectOf(c),
              actions: [
                const GlassAlertAction<int>('Cancel', role: GlassAlertRole.cancel, value: 0),
                GlassAlertAction<int>('Clear', value: 1, run: () => Future<void>.delayed(const Duration(days: 1))),
              ],
            ),
          ),
        ),
        Builder(
          builder: (c) => GlassButton(
            label: 'Error',
            onPressed: () => showGlassAlert<int>(
              c,
              title: 'Delete account?',
              body: 'This cannot be undone.',
              sourceRect: _rectOf(c),
              actions: [
                const GlassAlertAction<int>('Cancel', role: GlassAlertRole.cancel, value: 0),
                GlassAlertAction<int>('Delete', role: GlassAlertRole.destructive, value: 1, errorText: 'Could not reach the server', run: () async => throw StateError('offline')),
              ],
            ),
          ),
        ),
        Builder(
          builder: (c) => GlassButton(
            label: 'Three actions',
            onPressed: () => showGlassAlert<int>(
              c,
              title: 'Leave the reader?',
              body: 'Your place is saved.',
              sourceRect: _rectOf(c),
              actions: const [
                GlassAlertAction<int>('Cancel', role: GlassAlertRole.cancel, value: 0),
                GlassAlertAction<int>('Stay offline', value: 1),
                GlassAlertAction<int>('Leave', role: GlassAlertRole.destructive, value: 2),
              ],
            ),
          ),
        ),
      ],
    );

class _Toasts extends ConsumerWidget {
  const _Toasts();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final k in GlassToastKind.values) GlassButton(label: k.name, onPressed: () => showGlassToast(ref, GlassToastSpec('A ${k.name} toast', kind: k))),
          GlassButton(label: 'Undo', onPressed: () => showGlassToast(ref, GlassToastSpec('Removed from library', undo: () {}))),
        ],
      );
}

class _Tabs extends StatelessWidget {
  const _Tabs();

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 260,
        child: GlassTabPager(
          tabs: const [GlassTabSpec('Chapters'), GlassTabSpec('About'), GlassTabSpec('Similar', disabled: true), GlassTabSpec('Notes', loading: true)],
          panels: [
            for (final t in const ['Chapters', 'About', 'Similar', 'Notes']) Center(child: GlassLabel(t, role: gt.typeBody)),
          ],
        ),
      );
}

class _Sliders extends StatefulWidget {
  const _Sliders();
  @override
  State<_Sliders> createState() => _SlidersState();
}

class _SlidersState extends State<_Sliders> {
  double a = 0.5, b = 0.7, dial = 1, interval = 30;
  bool unsaved = false;
  int page = 12;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 260, child: GlassSlider(value: a, onChanged: (v) => setState(() => a = v), label: 'Text size', divisions: 8)),
          const SizedBox(height: 12),
          // mobile/40: the floating "Unsaved changes" bar (glass 8.25.6) and a value magnet at 30 (detent.magnet).
          GlassButton(label: unsaved ? 'Hide the Unsaved changes bar' : 'Show the Unsaved changes bar', onPressed: () => setState(() => unsaved = !unsaved)),
          GlassUnsavedChangesBar(visible: unsaved, onDiscard: () => setState(() => unsaved = false), onSave: () => setState(() => unsaved = false)),
          SizedBox(width: 260, child: GlassSlider(value: interval, min: 5, max: 120, divisions: 23, magnet: 30, onChanged: (v) => setState(() => interval = v), label: 'Check interval', format: (v) => '${v.round()} min')),
          const SizedBox(height: 12),
          SizedBox(width: 260, child: GlassFillSlider(value: b, onChanged: (v) => setState(() => b = v), label: 'Brightness')),
          const SizedBox(height: 12),
          SizedBox(width: 260, child: GlassFillSlider(value: b, onChanged: (v) => setState(() => b = v), label: 'Volume', kind: GlassFillKind.volume)),
          const SizedBox(height: 12),
          GlassScrubRail(
            pageCount: 40,
            page: page,
            onCommit: (p) => setState(() => page = p),
            renderPreview: (p) => Center(child: GlassLabel('$p', role: gt.typeMono)),
            segments: const [10, 25],
            bookmarks: const [7],
          ),
          const SizedBox(height: 12),
          GlassSpeedDial(value: dial, onChanged: (v) => setState(() => dial = v), onCommit: (v) => setState(() => dial = v), wpmAt: (s) => (200 * s).round()),
        ],
      );
}

class _Toggles extends StatefulWidget {
  const _Toggles();
  @override
  State<_Toggles> createState() => _TogglesState();
}

class _TogglesState extends State<_Toggles> {
  bool sw = true;
  bool? cb = true;
  String radio = 'a';
  int n = 3;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassSwitch(value: sw, onChanged: (v) => setState(() => sw = v), label: 'Wi-Fi only'),
          const GlassSwitch(value: false, onChanged: null, label: 'Disabled'),
          GlassSwitch(value: true, onChanged: (_) {}, label: 'Loading', loading: true),
          GlassCheckbox(value: cb, onChanged: (v) => setState(() => cb = v), label: 'Mark read'),
          const GlassCheckbox(value: null, onChanged: null, label: 'Mixed'),
          GlassRadioList<String>(
            options: const [GlassRadioOption(value: 'a', label: 'Newest'), GlassRadioOption(value: 'b', label: 'Popular'), GlassRadioOption(value: 'c', label: 'Off', enabled: false)],
            value: radio,
            onChanged: (v) => setState(() => radio = v),
          ),
          const Row(mainAxisSize: MainAxisSize.min, children: [GlassSelectionCheck(selected: true), SizedBox(width: 12), GlassSelectionCheck(selected: false)]),
          GlassStepper(value: n, onChanged: (v) => setState(() => n = v), label: 'Parallel downloads', min: 1, max: 6),
        ],
      );
}

Widget _menus(BuildContext context) => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Builder(
          builder: (c) => GlassButton(
            label: 'Context lift',
            onPressed: () => showGlassContextMenu(
              c,
              sourceRect: const Rect.fromLTWH(140, 260, 110, 165),
              preview: SizedBox(width: 110, height: 165, child: Image(image: kGlassDemoCover, fit: BoxFit.cover)),
              kind: GlassPreviewKind.poster,
              title: 'Series',
              entries: [
                GlassMenuEntry(label: 'Add to library', onSelected: () {}),
                GlassMenuEntry(label: 'Share', onSelected: () {}),
                GlassMenuEntry(label: 'Remove', destructive: true, separatorBefore: true, onSelected: () {}),
              ],
            ),
          ),
        ),
        GlassContextRegion(
          title: 'Row',
          entries: [GlassMenuEntry(label: 'Mark as read', onSelected: () {}), GlassMenuEntry(label: 'Remove', destructive: true, onSelected: () {})],
          child: SizedBox(width: 160, height: 48, child: Center(child: GlassLabel('Right-click me', role: gt.typeBody))),
        ),
        Builder(
          builder: (c) => GlassButton(
            label: 'Menu',
            onPressed: () => showGlassMenu(
              c,
              anchor: _rectOf(c),
              title: 'Actions',
              entries: [
                GlassMenuEntry(label: 'Mark as read', onSelected: () {}),
                GlassMenuEntry(label: 'Sort by newest', checked: true, onSelected: () {}),
                const GlassMenuEntry(label: 'Unavailable', enabled: false),
                GlassMenuEntry(label: 'Remove', destructive: true, separatorBefore: true, onSelected: () {}),
              ],
            ),
          ),
        ),
      ],
    );

class _Notices extends StatelessWidget {
  const _Notices();

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final v in GlassNoticeVariant.values)
            Padding(padding: const EdgeInsets.only(bottom: 8), child: GlassInlineNotice(message: 'A ${v.name} notice', variant: v, actionLabel: 'Details', onAction: () {})),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final k in GlassStatusKind.values) GlassStatusCapsule(kind: k)]),
          const SizedBox(height: 8),
          GlassNewChaptersCapsule(spec: const GlassNewChaptersSpec(id: 1, chapters: 5, series: 3), onDismiss: () {}),
          const SizedBox(height: 8),
          GlassAppUpdateCapsule(spec: GlassAppUpdateSpec(onUpdate: () {})),
        ],
      );
}

class _ScrollDemo extends StatefulWidget {
  const _ScrollDemo();
  @override
  State<_ScrollDemo> createState() => _ScrollDemoState();
}

class _ScrollDemoState extends State<_ScrollDemo> {
  final c = ScrollController();

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 320,
        child: GlassScrollEdges(
          topPlateau: 24,
          bottomPlateau: 24,
          child: GlassFastScroll(
            controller: c,
            itemCount: 400,
            labelAt: (i) => String.fromCharCode(65 + i % 26),
            child: GlassScrollbar(controller: c, child: ListView.builder(controller: c, itemCount: 400, itemExtent: 56, itemBuilder: (_, i) => Center(child: GlassLabel('Row $i', role: gt.typeBody)))),
          ),
        ),
      );
}

class GlassPullDemo extends StatelessWidget {
  const GlassPullDemo({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 320,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            GlassPullToRefresh(
              onRefresh: () async {
                await Future<void>.delayed(const Duration(seconds: 1));
                return RefreshResult.changed;
              },
            ),
            SliverList.builder(itemCount: 30, itemBuilder: (_, i) => SizedBox(height: 48, child: Center(child: GlassLabel('Row $i', role: gt.typeBody)))),
          ],
        ),
      );
}

Widget _imageViewer(BuildContext context) => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Builder(
          builder: (c) => GlassButton(
            label: 'Open image',
            onPressed: () => Navigator.of(c).push<void>(GlassImageViewerRoute<void>(image: kGlassDemoCover, thumbRect: _rectOf(c), description: 'Cover art')),
          ),
        ),
        Builder(
          builder: (c) => GlassButton(
            label: 'Broken image',
            onPressed: () => Navigator.of(c).push<void>(GlassImageViewerRoute<void>(image: const _BrokenImage(), thumbRect: _rectOf(c), description: 'Missing art')),
          ),
        ),
      ],
    );

/// An image that always fails to load: the viewer's error state with Retry.
class _BrokenImage extends ImageProvider<_BrokenImage> {
  const _BrokenImage();
  @override
  Future<_BrokenImage> obtainKey(ImageConfiguration configuration) => Future.value(this);
  @override
  ImageStreamCompleter loadImage(_BrokenImage key, ImageDecoderCallback decode) => OneFrameImageStreamCompleter(Future<ImageInfo>.error(StateError('no image')));
}
