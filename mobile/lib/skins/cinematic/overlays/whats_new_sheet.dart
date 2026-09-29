import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/settings/models/app_changelog.dart';
import 'package:manhwamaniacs/features/settings/providers/app_changelog_provider.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/features/settings/utils/whats_new_policy.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/a11y/folio.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_badge.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_notice.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/sheet_route.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

/// What's new (cinematic 8.29): the release notes as errata and additions in a sheet at the 0.92
/// detent (720 wide from 600 dp). Closing it stores the running build as seen.
Future<void> showWhatsNewSheet(BuildContext context, WidgetRef ref) async {
  final prefs = ref.read(preferencesProvider);
  final build = await _currentBuild(ref);
  if (!context.mounted) return;
  await showCineSheet<void>(
    context,
    kicker: "WHAT'S NEW",
    title: 'Release notes',
    builder: (_) => const WhatsNewBody(),
  );
  if (build > 0) unawaited(prefs.setLastSeenChangelogBuild(build));
}

Future<int> _currentBuild(WidgetRef ref) async {
  try {
    final info = await ref.read(packageInfoProvider.future);
    return int.tryParse(info.buildNumber) ?? 0;
  } catch (_) {
    return 0;
  }
}

/// The sheet's body: loading, unavailable, or the entries newest first.
class WhatsNewBody extends ConsumerWidget {
  const WhatsNewBody({super.key, this.preview});

  /// Test and proof hook: entries instead of `appChangelogProvider`.
  final AsyncValue<List<ChangelogRelease>>? preview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.cine;
    final AsyncValue<List<ChangelogRelease>> async = preview ?? ref.watch(appChangelogProvider);
    return async.when(
      loading: () => Padding(
        padding: EdgeInsets.all(c.space6),
        child: Row(
          children: [
            const CineLeaderDial(size: 24),
            SizedBox(width: c.space3),
            CineRoleText('LOADING', c.typeKicker, color: c.colorInk60),
          ],
        ),
      ),
      error: (_, __) => _unavailable(c),
      data: (entries) => entries.isEmpty ? _unavailable(c) : _entries(context, c, entries),
    );
  }

  Widget _unavailable(CineTokens c) => Padding(
        padding: EdgeInsets.all(c.space4),
        child: const CineNotice(tone: CineNoticeTone.caution, kicker: 'NOTE', headline: "Release notes aren't available right now."),
      );

  // The sheet's own body scrolls (and its header carries `Done`), so this is a plain column.
  Widget _entries(BuildContext context, CineTokens c, List<ChangelogRelease> entries) => Padding(
        key: const Key('whats-new-list'),
        padding: EdgeInsets.fromLTRB(c.space4, c.space4, c.space4, c.space8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < entries.length; i++) ...[
              _Entry(entry: entries[i], latest: i == 0),
              if (i < entries.length - 1) Container(margin: EdgeInsets.symmetric(vertical: c.space6), height: 1, color: c.colorRule1),
            ],
          ],
        ),
      );
}

class _Entry extends StatelessWidget {
  const _Entry({required this.entry, required this.latest});
  final ChangelogRelease entry;
  final bool latest;

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final folio = formatReleaseFolio(entry);
    return Semantics(
      container: true,
      label: '${latest ? 'Latest. ' : ''}${folioLabel(folio)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(child: CineRoleText(folio, c.typeFolioLg, color: c.colorInk80)),
              if (latest) ...[SizedBox(width: c.space2), const CineBadge('LATEST', variant: CineBadgeVariant.reading)],
            ],
          ),
          SizedBox(height: c.space3),
          for (final h in entry.highlights)
            Padding(
              padding: EdgeInsets.only(bottom: c.space2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 24, child: CineRoleText('—', c.typeBody, color: c.colorInk60)),
                  Expanded(child: CineRoleText(h, c.typeBody)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// True when the running build should open the notes by itself (a stored build, lower).
Future<bool> whatsNewDue(WidgetRef ref) async {
  final prefs = ref.read(preferencesProvider);
  final current = await _currentBuild(ref);
  if (current <= 0) return false;
  final last = prefs.lastSeenChangelogBuild;
  final due = prefs.setupCompleted && shouldAutoOpenWhatsNew(currentBuild: current, lastSeenBuild: last > 0 ? last : null);
  // A first run stores the current build without opening.
  if (last <= 0) await prefs.setLastSeenChangelogBuild(current);
  return due;
}
