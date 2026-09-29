import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart';
import 'package:manhwamaniacs/features/novels/providers/novels_gate_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/gallery/fixtures.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/icon_roles.g.dart';
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_banner_strip.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_certificate.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_certificate_dialog.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_checkbox.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_confirm_dialog.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_content_mode.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_contents_tabs.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_image.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_lightbox.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_menu.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_notice.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_poster.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_pull_to_reprint.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_radio.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_select_field.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_select_mode_bar.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_slider.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_stepper.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_switch.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/commit_with_undo.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/inline_confirm.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/quick_look.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/quick_look_actions.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_contents_row.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_credits_row.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_reorderable_list.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_reorderable_wall.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_row.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_schedule_row.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_settings_row.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/rows/cine_swipe_row.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/sheet_route.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// The section ids added by mobile/05, in page order.
const List<String> kOverlayGallerySections = [
  'sheets',
  'dialogs',
  'toasts',
  'tabs',
  'rows',
  'sliders',
  'toggles',
  'menus',
  'notices',
  'certificate',
  'other',
  'lightbox',
];

/// Whether the banner offset demo is on; [CineToastHost] in the gallery reads it.
final galleryBannerProvider = StateProvider<bool>((ref) => false, name: 'galleryBanner');

void _noop() {}

/// One mobile/05 gallery section: triggers that open every overlay in each state, and the controls
/// with every variant. Fixture data only.
class OverlayGallerySection extends ConsumerStatefulWidget {
  const OverlayGallerySection({super.key, required this.id});
  final String id;

  @override
  ConsumerState<OverlayGallerySection> createState() => _OverlayGallerySectionState();
}

class _OverlayGallerySectionState extends ConsumerState<OverlayGallerySection> with TickerProviderStateMixin {
  late final TabController _tabs, _nested, _stateTabs;
  final CineCertificateController _stamp = CineCertificateController();
  double _size = 5, _vol = 0.4;
  int _page = 18, _step = 3;
  bool? _check = false;
  bool _sw = false, _sw2 = true;
  String _radio = 'a', _select = 'warm';
  final List<String> _order = ['Salt and Iron', 'Ember Ledger', 'Moonlit Bakery', 'Night Ward'];
  final List<String> _wall = [for (var i = 0; i < 6; i++) galleryTitle(i)];
  final Set<int> _picked = {1};
  bool _selectRows = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _nested = TabController(length: 2, vsync: this);
    _stateTabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _nested.dispose();
    _stateTabs.dispose();
    _stamp.dispose();
    super.dispose();
  }

  Widget _sec(String title, List<Widget> children) {
    final c = context.cine;
    return Padding(
      key: Key('gallery-${widget.id}'),
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

  Widget _tag(String text) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: CineRoleText(text, context.cine.typeCaption, color: context.cine.colorInk45),
      );

  Widget _wrap(List<Widget> children) => Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: children);

  Widget _btn(String key, String label, VoidCallback onPressed) => CineButton(key: Key(key), label: label, variant: CineButtonVariant.secondary, size: CineButtonSize.sm, onPressed: onPressed);

  @override
  Widget build(BuildContext context) => switch (widget.id) {
        'sheets' => _sheets(),
        'dialogs' => _dialogs(),
        'toasts' => _toasts(),
        'tabs' => _tabsSection(),
        'rows' => _rows(),
        'sliders' => _sliders(),
        'toggles' => _toggles(),
        'menus' => _menus(),
        'notices' => _notices(),
        'certificate' => _certificate(),
        'other' => _other(),
        'lightbox' => _lightbox(),
        _ => const SizedBox.shrink(),
      };

  // ---- sheets ----

  Widget _sheets() => _sec('Sheets', [
        _wrap([
          _btn('g-sheet-basic', 'Sheet', () => showCineSheet<void>(context, kicker: 'SETTINGS', title: 'Reading', builder: (_) => const _SheetBody())),
          _btn('g-sheet-live', 'Live preview', () => showCineSheet<void>(context, kicker: 'READER', title: 'Type', livePreview: true, builder: (_) => const _SheetBody(slider: true))),
          _btn('g-sheet-loading', 'Loading', () => showCineSheet<void>(context, kicker: 'SETTINGS', title: 'Voices', state: CineSheetState.loading, builder: (_) => const SizedBox(height: 120))),
          _btn('g-sheet-error', 'Error', () => showCineSheet<void>(context, kicker: 'SETTINGS', title: 'Voices', state: CineSheetState.error, onRetry: () {}, builder: (_) => const SizedBox(height: 120))),
        ]),
        _tag('select field opens a sheet of radio rows'),
        CineSelectField<String>(
          key: const Key('g-select-field'),
          label: 'Page tone',
          value: _select,
          options: const [CineOption('warm', 'Warm'), CineOption('cool', 'Cool'), CineOption('paper', 'Paper')],
          onChanged: (v) => setState(() => _select = v),
        ),
      ]);

  // ---- dialogs ----

  Future<void> _fail() async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    throw const ApiError(message: 'The server didn’t answer.', statusCode: 500, code: 'server_error');
  }

  Widget _dialogs() => _sec('Dialogs', [
        _tag('destructive: arming for 1,000 ms, then armed'),
        _wrap([
          _btn('g-dialog-destructive', 'Delete profile', () => showCineConfirm(context, title: 'Delete Reader?', body: 'Its library, progress, bookmarks and collections go with it. This can’t be undone.', confirmLabel: 'Delete', destructive: true)),
          _btn('g-dialog-signout', 'Sign out', () => showCineConfirm(context, title: 'Sign out on this device?', confirmLabel: 'Sign out', destructive: true)),
          _btn('g-dialog-plain', 'Plain', () => showCineConfirm(context, title: 'Add to your library?', body: 'It will appear on your shelf.', confirmLabel: 'Add')),
        ]),
        _tag('heavy confirmations'),
        _wrap([
          _btn('g-dialog-heavy-phrase', 'Type RESTORE', () => showCineConfirm(context, title: 'Restore from backup?', body: 'This replaces everything on this device.', confirmLabel: 'Restore', destructive: true, typedPhrase: 'RESTORE')),
          _btn('g-dialog-heavy-ack', 'Acknowledge', () => showCineConfirm(context, title: 'Reset all sessions?', confirmLabel: 'Reset', destructive: true, acknowledge: 'I understand this signs me out on this device too')),
          _btn('g-dialog-heavy-username', 'Type username', () => showCineConfirm(context, title: 'Delete this account?', confirmLabel: 'Delete account', destructive: true, typedUsername: 'reader')),
        ]),
        _tag('pending and error'),
        _wrap([
          _btn('g-dialog-pending', 'Pending', () => showCineConfirm(context, title: 'Remove downloads?', confirmLabel: 'Remove', destructive: true, onConfirm: () => Future<void>.delayed(const Duration(seconds: 3)))),
          _btn('g-dialog-error', 'Error', () => showCineConfirm(context, title: 'Remove downloads?', confirmLabel: 'Remove', destructive: true, onConfirm: _fail)),
        ]),
        _tag('inline confirm and commit with undo'),
        _wrap([
          const CineInlineConfirm(key: Key('g-inline-confirm'), label: 'Remove downloads', verb: 'removal', onConfirm: _noop),
          _btn('g-undo-remove', 'Unfollow', () => commitWithUndo(context, run: () async {}, undo: () async {}, message: 'Removed Salt and Iron.')),
        ]),
      ]);

  // ---- toasts ----

  Widget _toasts() {
    final n = ref.read(cineToastsProvider.notifier);
    final banner = ref.watch(galleryBannerProvider);
    return _sec('Toasts', [
      _wrap([
        _btn('g-toast-info', 'Info', () => n.info('Saved for offline reading.')),
        _btn('g-toast-success', 'Success', () => n.success('Added to Slow burns.')),
        _btn('g-toast-error', 'Error', () => n.error('Couldn’t reach the server. Try again.')),
        _btn('g-toast-action', 'Action', () => n.action('Chapter 143 is out.', label: 'View', onAction: () {})),
        _btn('g-toast-undo', 'Undo', () => n.undo('Removed Salt and Iron.', onUndo: () {})),
        _btn('g-toast-two', 'Two', () {
          n.info('First subtitle.');
          n.success('Second subtitle, pushing the first one up.');
        }),
      ]),
      _tag('the stop-press banner lifts the stack and shows one toast'),
      CineButton(key: const Key('g-toast-banner'), label: banner ? 'Banner on' : 'Banner off', variant: CineButtonVariant.secondary, size: CineButtonSize.sm, toggle: true, selected: banner, onPressed: () => ref.read(galleryBannerProvider.notifier).state = !banner),
    ]);
  }

  // ---- tabs ----

  Widget _tabsSection() => _sec('Contents tabs', [
        CineContentsTabs(key: const Key('g-tabs-default'), controller: _tabs, tabs: const [CineTab(folio: '01', label: 'CHAPTERS', count: 201), CineTab(folio: '02', label: 'DETAILS'), CineTab(folio: '03', label: 'MORE LIKE THIS')]),
        SizedBox(
          height: 96,
          child: CineTabPanels(controller: _tabs, children: [for (final t in const ['Chapters', 'Details', 'More like this']) Center(child: CineRoleText(t, context.cine.typeCaption, color: context.cine.colorInk60))]),
        ),
        _tag('nested tabs switch by tap only (pager: false)'),
        CineContentsTabs(key: const Key('g-tabs-nested'), controller: _nested, tabs: const [CineTab(folio: '01', label: 'NEW · FOLLOWING'), CineTab(folio: '02', label: 'ALL')]),
        SizedBox(height: 56, child: CineTabPanels(controller: _nested, pager: false, children: const [Center(child: Text('New')), Center(child: Text('All'))])),
        _tag('states: default, loading count, error count, disabled'),
        CineContentsTabs(
          key: const Key('g-tabs-states'),
          controller: _stateTabs,
          tabs: const [
            CineTab(folio: '01', label: 'CHAPTERS', count: 12),
            CineTab(folio: '02', label: 'HISTORY', loading: true),
            CineTab(folio: '03', label: 'UPDATES', error: true),
            CineTab(folio: '04', label: 'CIRCLE', disabled: true, disabledReason: 'Sharing is off'),
          ],
        ),
      ]);

  // ---- rows ----

  Widget _rows() {
    final now = DateTime(2026, 9, 29);
    return _sec('Rows', [
      CineButton(key: const Key('g-row-select-toggle'), label: _selectRows ? 'Done' : 'Select', variant: CineButtonVariant.secondary, size: CineButtonSize.sm, onPressed: () => setState(() => _selectRows = !_selectRows)),
      _tag('standard: cover, icon, avatar, chevron, current, selected, error, loading, disabled'),
      CineRow(key: const Key('g-row-standard'), title: 'Ember Ledger', caption: 'CH 142 · 3 NEW', trailingFolio: '63%', selectMode: _selectRows, selected: _picked.contains(0), onSelectedChanged: (v) => setState(() => v ? _picked.add(0) : _picked.remove(0)), onTap: _noop, leading: const SizedBox(width: 40, height: 60, child: CineImage(url: 'assets/gallery/covers/02-ember-ledger.webp')), menu: const [CineMenuEntry(label: 'Open', value: 'open'), CineMenuEntry(label: 'Remove', destructive: true, separatorBefore: true)]),
      CineRow(key: const Key('g-row-icon'), title: 'Downloads', leading: cineRowIcon(context, 0xe1ac), chevron: true, onTap: _noop),
      const CineRow(key: Key('g-row-selected'), title: 'Selected row', caption: 'raised, with a spot bar', selected: true, onTap: _noop),
      const CineRow(key: Key('g-row-current'), title: 'Current chapter', caption: 'the go-to target', current: true, onTap: _noop),
      const CineRow(key: Key('g-row-error'), title: 'Night Ward', errorText: 'The source didn’t answer.', onRetry: _noop),
      const CineRow(key: Key('g-row-loading'), title: '', loading: true),
      const CineRow(key: Key('g-row-disabled'), title: 'Petal Almanac', caption: 'Not on your sources', disabled: true),
      _tag('settings row'),
      CineSettingsRow(key: const Key('g-row-settings-switch'), label: 'Notify me', description: 'When a followed series updates.', control: CineSwitch(value: _sw, label: 'Notify me', onChanged: (v) => setState(() => _sw = v))),
      const CineSettingsRow(key: Key('g-row-settings-value'), label: 'Reading direction', value: 'Vertical', chevron: true, onTap: _noop),
      _tag('schedule row'),
      CineScheduleRow(key: const Key('g-row-schedule-unread'), number: '143', title: 'Chapter 143: The lamp', released: DateTime(2026, 9, 29), pages: 27, now: now, onTap: _noop, menu: const [CineMenuEntry(label: 'Mark read')]),
      CineScheduleRow(key: const Key('g-row-schedule-progress'), number: '142.5', title: 'Interlude', released: DateTime(2026, 9, 26), pages: 27, progressPage: 14, state: CineReadState.inProgress, now: now, downloadMark: const CineDownloadMark(state: CineDownloadState.saved), onTap: _noop),
      CineScheduleRow(key: const Key('g-row-schedule-read'), title: 'Extra', released: DateTime(2026, 9, 12), pages: 12, state: CineReadState.read, now: now, onTap: _noop),
      _tag('contents row (novel TOC)'),
      const CineContentsRow(key: Key('g-row-contents'), ordinal: 12, title: 'The road keeps moving', minutes: 12, percent: 42, narrated: true, onTap: _noop),
      const CineContentsRow(key: Key('g-row-contents-current'), ordinal: 13, title: 'A lantern at the border', minutes: 9, current: true, onTap: _noop),
      const CineContentsRow(key: Key('g-row-contents-read'), ordinal: 11, title: 'Salt', minutes: 7, read: true, onTap: _noop),
      _tag('credits row'),
      const CineCreditsRow(key: Key('g-static-credits-row'), label: 'Story', value: 'M. Verrill'),
      const CineCreditsRow(key: Key('g-row-credits-tap'), label: 'Source', value: 'Harbour', onTap: _noop),
      _tag('swipe: Mark read springs back, Remove leaves'),
      CineSwipeRow(id: 'read', kind: CineSwipeKind.markRead, onCommit: () {}, child: const CineRow(key: Key('g-row-swipe-read'), title: 'Swipe to mark read', caption: 'release past halfway')),
      CineSwipeRow(id: 'remove', kind: CineSwipeKind.remove, onCommit: () {}, child: const CineRow(key: Key('g-row-swipe-remove'), title: 'Swipe to remove', caption: 'the siblings close up')),
      _tag('reorder list: drag the handle, Alt+Up / Alt+Down, or the row menu'),
      CineReorderableList<String>(
        key: const Key('g-reorder-list'),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        items: _order,
        idOf: (s) => s,
        titleOf: (s) => s,
        onMove: (f, t) => setState(() => _order.insert(t, _order.removeAt(f))),
        itemBuilder: (context, s, i, handle, entries, sem) => CineRow(key: Key('g-reorder-row-$i'), title: s, caption: 'Position ${i + 1}', handle: handle, menu: entries, semanticActions: sem, onTap: _noop),
      ),
      _tag('reorder wall'),
      SizedBox(
        height: 260,
        child: CineReorderableWall<String>(
          key: const Key('g-reorder-wall'),
          items: _wall,
          idOf: (s) => s,
          titleOf: (s) => s,
          onMove: (f, t) => setState(() => _wall.insert(t, _wall.removeAt(f))),
          itemBuilder: (context, s, i, handle, entries, sem) => CinePoster(title: s, url: galleryCover(kGalleryTitles.indexOf(s)), dragHandle: handle, caption: CinePosterCaption.wall),
        ),
      ),
    ]);
  }

  // ---- sliders ----

  Widget _sliders() => _sec('Sliders', [
        CineSlider(key: const Key('g-slider-steps'), label: 'Font size', value: _size, max: 20, divisions: 20, minCaption: '12 px', maxCaption: '32 px', flagText: (v) => '${(12 + v).round()} px', valueText: (v) => '${(12 + v).round()} pixels', onChanged: (v) => setState(() => _size = v)),
        const SizedBox(height: 16),
        CineSlider(key: const Key('g-slider-continuous'), label: 'Volume', value: _vol, flagText: (v) => '${(v * 100).round()}', valueText: (v) => '${(v * 100).round()} percent', onChanged: (v) => setState(() => _vol = v)),
        const SizedBox(height: 16),
        const CineSlider(key: Key('g-slider-disabled'), label: 'Locked', value: 0.5, onChanged: null),
        _tag('scrubber base'),
        CineScrubber(key: const Key('g-scrubber'), page: _page, pages: 40, chapterStarts: const {20: 2}, onPage: (p) => setState(() => _page = p), valueText: (p) => 'Page $p of 40'),
      ]);

  // ---- toggles ----

  Widget _toggles() => _sec('Switches, checkboxes, radios, stepper', [
        _tag('switch: off, on, disabled, loading, error'),
        _wrap([
          CineSwitch(key: const Key('g-switch-off'), value: _sw, label: 'Off', onChanged: (v) => setState(() => _sw = v)),
          CineSwitch(key: const Key('g-switch-on'), value: _sw2, label: 'On', onChanged: (v) => setState(() => _sw2 = v)),
          const CineSwitch(key: Key('g-switch-disabled'), value: false, label: 'Disabled', onChanged: null),
          CineSwitch(key: const Key('g-switch-loading'), value: false, label: '18+', onChanged: (_) => Future<void>.delayed(const Duration(seconds: 4))),
          CineSwitch(key: const Key('g-switch-error'), value: false, label: 'Notify', onChanged: (_) => Future<void>.delayed(const Duration(milliseconds: 600), () => throw const ApiError(message: 'no', statusCode: 500, code: 'server_error'))),
        ]),
        _tag('checkbox: unchecked, checked, indeterminate, disabled'),
        _wrap([
          CineCheckbox(key: const Key('g-check'), value: _check, label: 'Select all', onChanged: (v) => setState(() => _check = v)),
          const CineCheckbox(key: Key('g-check-mixed'), value: null, label: 'Some', onChanged: _ignoreBool),
          const CineCheckbox(key: Key('g-check-disabled'), value: true, label: 'Locked', onChanged: null),
        ]),
        _tag('radio'),
        _wrap([
          for (final v in const ['a', 'b', 'c']) CineRadio<String>(key: Key('g-radio-$v'), value: v, groupValue: _radio, label: 'Option $v', onChanged: (x) => setState(() => _radio = x)),
        ]),
        _tag('stepper'),
        CineStepper(key: const Key('g-stepper'), label: 'Daily goal', value: _step, max: 12, onChanged: (v) => setState(() => _step = v)),
      ]);

  static void _ignoreBool(bool _) {}

  // ---- menus ----

  Widget _menus() => _sec('Menus and Quick look', [
        Builder(
          builder: (btn) => _btn('g-menu-open', 'Open menu', () => showCineMenu<String>(btn, anchor: cineAnchorRect(btn), entries: const [
                CineMenuEntry(label: 'Open', value: 'open', shortcut: [LogicalKeyboardKey.enter]),
                CineMenuEntry(label: 'Sort by', value: 'sort', submenu: [CineMenuEntry(label: 'Title', value: 'title', checked: true), CineMenuEntry(label: 'Last read', value: 'read')]),
                CineMenuEntry(label: 'Download', value: 'dl', disabled: true),
                CineMenuEntry(label: 'Remove', value: 'rm', destructive: true, separatorBefore: true),
              ],),),
        ),
        _tag('Quick look: long-press the poster'),
        SizedBox(
          width: 96,
          child: CinePoster(
            key: const Key('g-quicklook-poster'),
            title: galleryTitle(0),
            url: galleryCover(0),
            folio: 'CH 142',
            heroTag: ('gallery', 'quick-look'),
            onQuickLook: () => openQuickLook(
              context,
              title: galleryTitle(0),
              credits: 'M. VERRILL · HARBOUR SOURCE',
              heroTag: ('gallery', 'quick-look'),
              cover: const CineImage(url: 'assets/gallery/covers/01-salt-and-iron.webp'),
              actions: quickLookActions({for (final id in const [QuickLookId.open, QuickLookId.continueReading, QuickLookId.addToCollection, QuickLookId.markRead, QuickLookId.unfollow]) id: () {}}),
            ),
          ),
        ),
      ]);

  // ---- notices ----

  Widget _notices() => _sec('Notices', [
        const CineNotice(key: Key('g-notice-empty'), tone: CineNoticeTone.empty, headline: 'Nothing followed yet.', deck: 'Follow a series and it appears here.'),
        const SizedBox(height: 32),
        const CineNotice(key: Key('g-notice-error'), tone: CineNoticeTone.error, headline: 'That didn’t load.', deck: 'The source didn’t answer.', primary: CineNoticeAction('Try again', _noop)),
        const SizedBox(height: 32),
        CineNotice.offline(key: const Key('g-notice-offline'), onGoToDownloads: _noop),
        const SizedBox(height: 32),
        const CineNotice(key: Key('g-notice-caution'), tone: CineNoticeTone.caution, headline: 'This source is slow today.', deck: 'Chapters may take a moment.'),
        const SizedBox(height: 32),
        const CineNotice(key: Key('g-notice-rate'), tone: CineNoticeTone.rateLimit, headline: 'You’re going fast.', deck: 'The server asked us to wait.', retryAfter: Duration(seconds: 12)),
      ]);

  // ---- certificate ----

  Widget _certificate() => _sec('Certificate', [
        Center(child: CineCertificate(key: const Key('g-certificate'), controller: _stamp)),
        const SizedBox(height: 16),
        _wrap([
          _btn('g-certificate-stamp', 'Stamp', _stamp.stamp),
          _btn('g-certificate-dialog', 'Open dialog', () => openCineCertificateDialog(context, profileName: 'Reader', onConfirm: () async {
                await Future<void>.delayed(const Duration(milliseconds: 600));
                return true;
              },),),
          _btn('g-certificate-dialog-fail', 'Dialog, fails', () => openCineCertificateDialog(context, onConfirm: () async => false)),
        ]),
      ]);

  // ---- other ----

  Widget _other() => _sec('Content mode, pull to reprint, select bar, banners', [
        ProviderScope(
          overrides: [novelsEnabledProvider.overrideWithValue(true), contentModeControllerProvider.overrideWith(_DemoMode.new)],
          child: const Row(children: [CineContentModeToggle(key: Key('g-content-toggle')), SizedBox(width: 24), CineContentModeChip(key: Key('g-content-chip'))]),
        ),
        _tag('pull to reprint'),
        SizedBox(
          height: 220,
          child: CinePullToReprint(
            key: const Key('g-pull'),
            onRefresh: () => Future<void>.delayed(const Duration(seconds: 2)),
            child: ListView(physics: const AlwaysScrollableScrollPhysics(), children: [for (var i = 0; i < 6; i++) CineRow(title: galleryTitle(i), caption: 'pull down')]),
          ),
        ),
        _tag('select-mode bar: selecting, running, result'),
        const CineSelectModeBar(
          key: Key('g-selectbar'),
          selected: 12,
          total: 40,
          onSelectAll: _noop,
          onDone: _noop,
          actions: [CineSelectAction('Favourite', CineIconRole.favourite, _noop), CineSelectAction('Mark read', CineIconRole.select, _noop), CineSelectAction('Download', CineIconRole.download, _noop), CineSelectAction('Unfollow', CineIconRole.following, _noop, destructive: true)],
        ),
        const SizedBox(height: 8),
        const CineSelectModeBar(key: Key('g-selectbar-running'), selected: 12, total: 40, actions: [], onDone: _noop, run: (done: 4, total: 12, failed: 1), onStop: _noop),
        const SizedBox(height: 8),
        const CineSelectModeBar(key: Key('g-selectbar-result'), selected: 0, total: 40, actions: [], onDone: _noop, result: 'Unfollowed 12 series.', onUndo: _noop, onDismissResult: _noop),
        _tag('banner strips'),
        const CineBannerStrip(key: Key('g-banner-note'), line: 'Nothing followed yet.', actions: [CineBannerAction('Browse', _noop)]),
        const SizedBox(height: 16),
        const CineBannerStrip(key: Key('g-banner-correction'), tone: CineBannerTone.correction, line: 'Your last restore is staged.', actions: [CineBannerAction('Apply', _noop), CineBannerAction('Discard', _noop)]),
        const SizedBox(height: 16),
        const CineBannerStrip(key: Key('g-banner-plain'), tone: CineBannerTone.plain, line: 'The checker is overdue.'),
      ]);

  // ---- lightbox ----

  Widget _lightbox() => _sec('Lightbox', [
        Builder(
          builder: (ctx) => GestureDetector(
            key: const Key('g-lightbox-open'),
            onTap: () => openCineLightbox(ctx, heroTag: 'gallery-lightbox', image: AssetImage(galleryCover(0)), fullImage: AssetImage(galleryCover(0)), title: galleryTitle(0), folio: 'COVER · 720 × 1080'),
            child: SizedBox(width: 120, height: 180, child: Hero(tag: 'gallery-lightbox', child: Image.asset(galleryCover(0), fit: BoxFit.cover))),
          ),
        ),
        _tag('tap the cover; pinch, double tap, drag down at 1x'),
      ]);
}

/// The gallery's own content-mode state, so the toggle works without a session or the novels gate.
class _DemoMode extends ContentModeController {
  @override
  ContentMode build() => ContentMode.manga;

  @override
  Future<void> setMode(ContentMode mode) async => state = mode;
}

class _SheetBody extends StatefulWidget {
  const _SheetBody({this.slider = false});
  final bool slider;

  @override
  State<_SheetBody> createState() => _SheetBodyState();
}

class _SheetBodyState extends State<_SheetBody> {
  bool _on = true;
  double _v = 8;

  @override
  Widget build(BuildContext context) => Column(children: [
        CineSettingsRow(label: 'Keep screen awake', description: 'While a chapter is open.', control: CineSwitch(value: _on, label: 'Keep screen awake', onChanged: (v) => setState(() => _on = v))),
        if (widget.slider)
          Padding(
            padding: const EdgeInsets.all(16),
            child: CineSlider(label: 'Font size', value: _v, max: 20, divisions: 20, flagText: (v) => '${(12 + v).round()} px', valueText: (v) => '${(12 + v).round()} pixels', onChanged: (v) => setState(() => _v = v)),
          ),
        const SizedBox(height: 120),
      ],);
}
