import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/reader/engine/reader_engine.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_prefs_provider.dart';
import 'package:manhwamaniacs/features/reader/providers/reader_profile_settings.dart';
import 'package:manhwamaniacs/features/reader/utils/reader_prefs_migration.dart';
import 'package:manhwamaniacs/features/settings/models/reader_defaults.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_confirm_dialog.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_contents_tabs.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/sheet_route.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/reader/setup_rows.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_kit.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// Opens Reading setup (cinematic 8.14.8): a `[0.5, 0.92]` live-preview sheet with the kicker
/// `READING SETUP`, the series title, tabs `LAYOUT · IMAGE · CONTROLS · AMBIENT` and every control
/// the app offers. Every change applies live under the sheet; the returned future completes when
/// it closes, and the caller hides the chrome then.
Future<void> showReadingSetup(
  BuildContext context, {
  required String seriesRef,
  required String seriesTitle,
  required ReaderEngine engine,
  required bool readAll,
  required VoidCallback onShowZones,
  String? pageActionsLabel,
  VoidCallback? onPageActions,
  int initialTab = 0,
  Color? topRule,
}) =>
    showCineSheet<void>(
      context,
      topRule: topRule,
      kicker: 'READING SETUP',
      title: seriesTitle,
      livePreview: true,
      builder: (sheetContext) => Material(
        type: MaterialType.transparency,
        child: ReadingSetupBody(
          initialTab: initialTab,
          seriesRef: seriesRef,
          engine: engine,
          readAll: readAll,
          onShowZones: () {
            Navigator.of(sheetContext).maybePop();
            onShowZones();
          },
          pageActionsLabel: pageActionsLabel,
          onPageActions: onPageActions == null
              ? null
              : () {
                  Navigator.of(sheetContext).maybePop();
                  onPageActions();
                },
        ),
      ),
    );

/// The body of the sheet: the tabs and the footer.
class ReadingSetupBody extends ConsumerStatefulWidget {
  const ReadingSetupBody({
    super.key,
    required this.seriesRef,
    required this.engine,
    required this.readAll,
    required this.onShowZones,
    this.pageActionsLabel,
    this.onPageActions,
    this.tabs,
    this.initialTab = 0,
  });

  final String seriesRef;
  final ReaderEngine engine;
  final bool readAll;
  final VoidCallback onShowZones;

  /// `Page actions for p. 18`, phones only.
  final String? pageActionsLabel;
  final VoidCallback? onPageActions;
  final List<SetupTab>? tabs;
  final int initialTab;

  @override
  ConsumerState<ReadingSetupBody> createState() => _ReadingSetupBodyState();
}

class _ReadingSetupBodyState extends ConsumerState<ReadingSetupBody> with SingleTickerProviderStateMixin {
  late final List<SetupTab> _tabs = widget.tabs ?? kSetupTabs;
  late final TabController _tc = TabController(length: _tabs.length, vsync: this, initialIndex: widget.initialTab)..addListener(_changed);

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    final ok = await showCineConfirm(context, title: 'Restore every reader setting to its default?', confirmLabel: 'Restore defaults', destructive: true);
    if (!ok || !mounted) return;
    cineFeedback(context, HapticEvent.deleteConfirm);
    final prefs = ref.read(sharedPrefsProvider);
    final device = ref.read(readerDefaultsProvider.notifier);
    await ref.read(readerSeriesPrefsProvider.notifier).reset();
    await ref.read(readerSettingsProvider.notifier).reset();
    // The device seed the migration left would otherwise bring the old profile defaults back.
    await prefs.setString(kReaderPrefsSeedKey, '{}');
    await device.setKeepScreenAwake(false);
    await device.setLockControls(false);
    await device.setVolumeKeyNavigation(false);
    await device.setRefreshRate(ReaderRefreshRate.auto);
    await device.setAutoNextChapter(true);
    await prefs.remove('mm.reader.device.stripWidthPx');
    ref.invalidate(stripWidthProvider);
    ref.invalidate(readerSettingsProvider);
    if (mounted) ref.read(cineToastsProvider.notifier).info('Reader settings reset.');
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(readerPrefsProvider(widget.seriesRef));
    final c = SetupCtx(
      context: context,
      ref: ref,
      seriesRef: widget.seriesRef,
      prefs: prefs,
      engine: widget.engine,
      readAll: widget.readAll,
      onShowZones: widget.onShowZones,
    );
    final tab = _tabs[_tc.index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CineContentsTabs(controller: _tc, tabs: [for (final t in _tabs) CineTab(folio: t.folio, label: t.label)]),
        for (final row in tab.rows) row(c),
        const SizedBox(height: 16),
        quietAction('Reset reader settings', () => unawaited(_reset())),
        if (widget.onPageActions != null && MediaQuery.sizeOf(context).width < 600)
          quietAction(widget.pageActionsLabel ?? 'Page actions', widget.onPageActions),
        const SizedBox(height: 24),
      ],
    );
  }
}
