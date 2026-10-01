import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/content_mode/content_mode_controller.dart' show contentModeScopeProvider;
import 'package:manhwamaniacs/features/downloads/models/downloaded_series_group.dart';
import 'package:manhwamaniacs/features/downloads/providers/active_download_queue_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloaded_series_provider.dart';
import 'package:manhwamaniacs/features/downloads/providers/downloads_scope.dart' show downloadsStoreProvider;
import 'package:manhwamaniacs/features/downloads/queue/download_queue_controller.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/segmented.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/lens_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/states/object_lens.dart';
import 'package:manhwamaniacs/skins/glass/screens/downloads/chapters_tab.dart';
import 'package:manhwamaniacs/skins/glass/screens/downloads/queue_tab.dart';
import 'package:manhwamaniacs/skins/glass/screens/downloads/storage_tab.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/library_keys.dart';
import 'package:manhwamaniacs/skins/glass/screens/library/library_section.dart';
import 'package:manhwamaniacs/skins/skins.dart';

enum DownloadsTab { chapters, queue, storage }

/// Downloads (glass 8.22): "On this device", the tabs Chapters, Queue and Storage, and every state. No pull to refresh (local data).
class GlassDownloadsPage extends ConsumerStatefulWidget {
  const GlassDownloadsPage({super.key, this.initialTab});
  final String? initialTab;

  @override
  ConsumerState<GlassDownloadsPage> createState() => _GlassDownloadsPageState();
}

class _GlassDownloadsPageState extends ConsumerState<GlassDownloadsPage> {
  late DownloadsTab _tab = DownloadsTab.values.firstWhere((t) => t.name == widget.initialTab, orElse: () => DownloadsTab.chapters);
  String? _focusKey;
  List<DownloadedSeriesGroup> _groups = const [];

  @override
  void didUpdateWidget(GlassDownloadsPage old) {
    super.didUpdateWidget(old);
    final want = DownloadsTab.values.firstWhere((t) => t.name == widget.initialTab, orElse: () => _tab);
    if (widget.initialTab != old.initialTab && want != _tab) setState(() => _tab = want);
  }

  void _setTab(DownloadsTab t) {
    setState(() => _tab = t);
    // `?tab=` is written with replace so Back does not walk the tabs.
    final uri = Uri.parse(GoRouterState.of(context).uri.toString());
    GoRouter.of(context).replace<void>(uri.replace(queryParameters: {...uri.queryParameters, 'tab': t.name}).toString());
  }

  void _toStorage() => _setTab(DownloadsTab.storage);

  void _toggleQueue() {
    final q = ref.read(downloadQueueControllerProvider);
    final c = ref.read(downloadQueueControllerProvider.notifier);
    if (q.pauseReason == DownloadQueuePauseReason.userPaused) {
      c.resume();
    } else {
      c.pause();
    }
  }

  DownloadedSeriesGroup? get _focused => _groups.where((g) => '${g.sourceId}|${g.seriesKey}' == _focusKey).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(activeProfileProvider);
    final shelf = ref.watch(downloadedShelfProvider);
    final queue = ref.watch(activeDownloadQueueProvider).valueOrNull ?? const [];
    final scope = ref.watch(contentModeScopeProvider);
    _groups = shelf.valueOrNull ?? const [];
    final wide = GlassFrame.of(context) != GlassFrameKind.phone;

    Widget body;
    if (profile == null) {
      body = Padding(padding: const EdgeInsets.symmetric(vertical: 32), child: GlassObjectLens(situation: LensSituation.noProfile, title: 'Downloads belong to a profile', primary: LensAction('Choose a profile', () => unawaited(ref.read(skinRouterProvider).push<void>(Routes.profiles())))));
    } else if (shelf.isLoading && shelf.valueOrNull == null) {
      body = Padding(padding: const EdgeInsets.symmetric(vertical: 32), child: Center(child: GlassLabel("Checking what's stored…", role: gt.typeSubhead, color: gt.colorLabel2)));
    } else if (shelf.hasError && shelf.valueOrNull == null) {
      body = Padding(padding: const EdgeInsets.symmetric(vertical: 32), child: GlassObjectLens(situation: LensSituation.loadError, tone: GlassLensTone.error, title: "Couldn't read downloads", primary: LensAction('Try again', () => ref.invalidate(downloadedSeriesProvider))));
    } else {
      body = switch (_tab) {
        DownloadsTab.chapters => _groups.isEmpty && queue.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: GlassObjectLens(
                  situation: LensSituation.nothingDownloaded,
                  title: 'Nothing downloaded yet',
                  description: scope.isNovel ? 'No books downloaded yet' : 'No series downloaded yet',
                  primary: LensAction('Go to library', () => GoRouter.of(context).go(Routes.library())),
                ),
              )
            : GlassChaptersTab(groups: _groups, onFocus: (g) => _focusKey = '${g.sourceId}|${g.seriesKey}'),
        DownloadsTab.queue => GlassQueueTab(onStorageSettings: _toStorage),
        DownloadsTab.storage => const GlassStorageTab(),
      };
    }

    return LibraryKeys(
      group: 'Downloads',
      section: LibrarySection.downloads,
      bindings: [
        LibraryKey(description: _tab == DownloadsTab.queue ? 'Pause or resume the queue' : 'Pin the focused series', keys: const ['p'], single: true, match: kChar('p'), action: () {
          if (_tab == DownloadsTab.queue) {
            _toggleQueue();
          } else if (_tab == DownloadsTab.chapters) {
            final g = _focused;
            if (g != null) unawaited(_pin(g));
          }
        },),
        LibraryKey(description: 'Remove the focused series', keys: const ['Delete'], match: kKey(LogicalKeyboardKey.delete), action: () {}),
        LibraryKey(description: 'Move through the list', keys: const ['↑', '↓'], match: kKey(LogicalKeyboardKey.arrowDown), action: () => FocusManager.instance.primaryFocus?.nextFocus()),
        LibraryKey(description: '', keys: const [], match: kKey(LogicalKeyboardKey.arrowUp), action: () => FocusManager.instance.primaryFocus?.previousFocus()),
      ],
      child: LibrarySectionFrame(
        section: LibrarySection.downloads,
        countLine: 'On this device',
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: wide ? 880 : double.infinity),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassSegmented<DownloadsTab>(
                      asTabs: true,
                      segments: const [GlassSegment(value: DownloadsTab.chapters, label: 'Chapters'), GlassSegment(value: DownloadsTab.queue, label: 'Queue'), GlassSegment(value: DownloadsTab.storage, label: 'Storage')],
                      selected: _tab,
                      onSelected: _setTab,
                    ),
                  ),
                  body,
                  const SizedBox(height: 24),
                ],),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pin(DownloadedSeriesGroup g) async {
    await ref.read(downloadsStoreProvider)?.setSeriesPinned(series: (sourceId: g.sourceId, seriesKey: g.seriesKey), pinned: !g.pinned);
    ref.invalidate(downloadedSeriesProvider);
  }
}
