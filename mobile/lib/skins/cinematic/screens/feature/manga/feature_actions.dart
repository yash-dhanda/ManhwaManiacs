import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/library/providers/device_online_provider.dart';
import 'package:manhwamaniacs/features/library/providers/library_series_actions.dart';
import 'package:manhwamaniacs/features/recap/models/recap_origin.dart';
import 'package:manhwamaniacs/features/updates/providers/updates_provider.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/cine_glyphs.g.dart';
import 'package:manhwamaniacs/skins/cinematic/icons/phosphor.g.dart';
import 'package:manhwamaniacs/skins/cinematic/navigation.dart';
import 'package:manhwamaniacs/skins/cinematic/recap/continue_to.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_data.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_shortcuts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/feature_states.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/feature/manga/chapters_panel.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// Where `Read` / `Continue` goes, and what the split button says.
typedef ResumePoint = ({String label, String? chapter, String? sub});

/// Follow, Favourite, Notify, Download and the split primary, phone or tablet
/// form. Owns the follow error line and registers the page's key commands.
class FeatureActions extends ConsumerStatefulWidget {
  const FeatureActions({
    super.key,
    required this.data,
    required this.resume,
    required this.wide,
    required this.onSelect,
    required this.commands,
    this.onOverflow,
  });

  final FeatureData data;
  final ResumePoint resume;
  final bool wide;
  final VoidCallback onSelect;
  final FeatureCommands commands;
  final VoidCallback? onOverflow;

  @override
  ConsumerState<FeatureActions> createState() => _FeatureActionsState();
}

class _FeatureActionsState extends ConsumerState<FeatureActions> {
  String? _error;

  FeatureData get d => widget.data;

  @override
  void initState() {
    super.initState();
    final c = widget.commands;
    c.continueReading = _continue;
    c.readAll = _readAll;
    c.favorite = _favorite;
    c.notify = _notify;
    c.toggleFollow = _toggleFollow;
    c.download = widget.onSelect;
  }

  void _continue() {
    final ch = widget.resume.chapter;
    if (ch == null) return;
    unawaited(continueTo(context, ref, sourceId: d.sourceId, seriesKey: d.seriesKey, chapterKey: ch, title: d.title, lastReadAt: d.followed?.readState?.lastReadAt, origin: RecapEntry.wipe));
  }

  void _readAll() {
    if (d.chapters.length < 2) return;
    enterReader(context, ReaderTarget.readAll(d.sourceId, d.seriesKey), entry: ReaderEntry.wipe);
  }

  Future<void> _favorite() async {
    final f = d.followed;
    if (f == null || !isOnline(ref)) return;
    feedback(ref, HapticEvent.favorite, SoundEvent.favorite);
    await ref.read(libraryRepositoryProvider).patchSeries(f.id, isFavorite: !f.isFavorite);
    ref.invalidate(updatesProvider);
  }

  Future<void> _notify() async {
    final f = d.followed;
    if (f == null || !isOnline(ref)) return;
    await ref.read(libraryRepositoryProvider).patchSeries(f.id, notify: !f.notify);
    ref.invalidate(updatesProvider);
  }

  Future<void> _toggleFollow() async {
    if (!isOnline(ref)) return;
    final f = d.followed;
    setState(() => _error = null);
    if (f == null) {
      final err = await ref
          .read(updatesProvider.notifier)
          .followSeries(sourceId: d.sourceId, seriesKey: d.seriesKey);
      if (!mounted) return;
      if (err != null) {
        if (err is ApiError && err.code == 'follow_limit_reached') {
          setState(() => _error = "You're following 1,000 series, the limit for a profile.");
        } else {
          featureToast(context, err.userMessage);
        }
        return;
      }
      feedback(ref, HapticEvent.followAdd, SoundEvent.followAdd);
      featureToast(context, 'Following ${d.title}. New chapters will notify you.');
    } else {
      final actions = ref.read(librarySeriesActionsProvider);
      final r = await actions.remove(f);
      if (!mounted) return;
      if (r.error != null) {
        featureToast(context, r.error!.userMessage);
        return;
      }
      featureToast(
        context,
        'Removed ${d.title}.',
        onUndo: () => unawaited(actions.restore(f, slots: r.slots)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = cineOf(context);
    final wide = widget.wide;
    final f = d.followed;
    final online = isOnline(ref);
    final resume = widget.resume;

    final caughtUp = resume.label == 'All caught up';
    final primary = SizedBox(
      width: wide ? null : double.infinity,
      child: FilledButton(
        key: const Key('primary-action'),
        style: FilledButton.styleFrom(
          minimumSize: Size(wide ? 200 : 0, wide ? 56 : 48),
          disabledBackgroundColor: t.colorPaper3,
          disabledForegroundColor: t.colorInk30,
        ),
        onPressed: resume.chapter == null ? null : _continue,
        child: caughtUp
            ? const Row(
                mainAxisSize: MainAxisSize.min,
                children: [Icon(PhosphorRegular.check, size: 18), SizedBox(width: 8), Text('All caught up')],
              )
            : Text(resume.sub == null ? resume.label : '${resume.label}  │  ${resume.sub}'),
      ),
    );

    final readAll = d.chapters.length > 1
        ? SizedBox(
            width: wide ? null : double.infinity,
            child: OutlinedButton.icon(
              key: const Key('read-all'),
              style: OutlinedButton.styleFrom(minimumSize: Size(48, wide ? 56 : 48)),
              icon: const Icon(CineGlyphs.stripScrollRegular, size: 20),
              label: const Text('Read all'),
              onPressed: _readAll,
            ),
          )
        : null;

    Widget cell(
      IconData icon,
      String label,
      VoidCallback? onTap, {
      bool on = false,
      String? tooltip,
    }) {
      final scale = MediaQuery.textScalerOf(context).scale(10) / 10;
      final child = Semantics(
        button: true,
        selected: on,
        enabled: onTap != null,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64, minWidth: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: onTap == null ? t.colorInk30 : (on ? t.colorSpot : t.colorInk100)),
                if (on)
                  Container(margin: const EdgeInsets.only(top: 2), height: 2, width: 20, color: t.colorSpot),
                if (!wide)
                  MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: TextScaler.linear(scale.clamp(1.0, 1.3))),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label.toUpperCase(),
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: scale >= 1.3 ? 0.6 : 0.4,
                            color: onTap == null ? t.colorInk30 : t.colorInk100,
                            fontVariations: const [FontVariation('wdth', 62)],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
      final tip = onTap == null && !online && f != null ? kNeedsConnection : (tooltip ?? '');
      final withTip = Tooltip(message: tip.isEmpty ? label : tip, child: child);
      return wide ? SizedBox(width: 52, child: withTip) : Expanded(child: withTip);
    }

    final row = Row(
      mainAxisSize: wide ? MainAxisSize.min : MainAxisSize.max,
      children: [
        cell(f == null ? PhosphorRegular.plus : PhosphorRegular.check, 'Follow', online ? _toggleFollow : null,
            on: f != null, tooltip: f == null ? 'Follow' : 'Following',),
        cell(f?.isFavorite ?? false ? PhosphorFill.star : PhosphorRegular.star, 'Favourite',
            f == null || !online ? null : _favorite, on: f?.isFavorite ?? false,),
        cell(f?.notify ?? false ? PhosphorRegular.bellRinging : PhosphorRegular.bellSimple, 'Notify',
            f == null || !online ? null : _notify, on: f?.notify ?? false,),
        cell(PhosphorRegular.cloudArrowDown, 'Download', widget.onSelect),
        if (wide && widget.onOverflow != null) cell(PhosphorRegular.dotsThree, 'More', widget.onOverflow),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (wide)
          Wrap(spacing: 8, runSpacing: 8, children: [primary, if (readAll != null) readAll])
        else ...[
          primary,
          if (readAll != null) ...[const SizedBox(height: 8), readAll],
        ],
        const SizedBox(height: 8),
        row,
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(_error!, key: const Key('follow-error'), style: TextStyle(fontSize: 12, color: t.colorProof)),
          ),
      ],
    );
  }
}

/// Keeps the `context.canPop` back behaviour in one place.
void featureBack(BuildContext context) => context.canPop() ? context.pop() : context.go('/');
