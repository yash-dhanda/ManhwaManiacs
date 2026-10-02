import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/admin/providers/status_providers.dart';
import 'package:manhwamaniacs/features/admin/utils/status_summary.dart' show describeCheckSchedule;
import 'package:manhwamaniacs/features/profiles/providers/notify_enabled_provider.dart';
import 'package:manhwamaniacs/features/settings/providers/source_cache_ttl_provider.dart';
import 'package:manhwamaniacs/features/updates/models/update_settings.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/primitives/alert.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/slab.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/slider.dart';
import 'package:manhwamaniacs/skins/glass/primitives/stepper.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/primitives/unsaved_changes_bar.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/admin_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_row.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The editable fields of Notifications.
@immutable
class NotificationsDraft {
  const NotificationsDraft({required this.enabled, required this.onStartup, required this.notify, required this.interval, required this.ttl});
  final bool enabled, onStartup, notify;
  final int interval, ttl;

  NotificationsDraft copyWith({bool? enabled, bool? onStartup, bool? notify, int? interval, int? ttl}) => NotificationsDraft(
        enabled: enabled ?? this.enabled,
        onStartup: onStartup ?? this.onStartup,
        notify: notify ?? this.notify,
        interval: interval ?? this.interval,
        ttl: ttl ?? this.ttl,
      );

  @override
  bool operator ==(Object other) => other is NotificationsDraft && other.enabled == enabled && other.onStartup == onStartup && other.notify == notify && other.interval == interval && other.ttl == ttl;
  @override
  int get hashCode => Object.hash(enabled, onStartup, notify, interval, ttl);
}

/// Settings -> Notifications (glass 8.25.6): every profile's own "Notify me" master (`PATCH /profiles/{id} {notify_enabled}`, the
/// same one Cinematic writes); for an admin, also the server-wide checker: the schedule strip, three switches, the interval slider
/// with its 30 min magnet, the catalogue-cache stepper and the draft-then-save bar.
class NotificationsSection extends ConsumerWidget {
  const NotificationsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(children: [
        const _ProfileNotify(),
        if (glassIsAdmin(ref)) const _Body(),
      ],);
}

class _ProfileNotify extends ConsumerWidget {
  const _ProfileNotify();

  @override
  Widget build(BuildContext context, WidgetRef ref) => SettingsGroup(
        id: 'notify-profile',
        footer: 'Saved for this profile',
        children: [
          SettingsSwitchRow(
            id: 'notify-me',
            title: 'Notify me about new chapters',
            caption: "When this is off, new chapters don't reach your Library badge, Updates or the banner.",
            value: ref.watch(notifyEnabledProvider),
            onChanged: (v) async {
              final err = await ref.read(notifyEnabledProvider.notifier).setEnabled(v);
              if (err != null) settingsToast(ref, "Couldn't save. Try again.", kind: GlassToastKind.error);
            },
          ),
        ],
      );
}

class _Body extends ConsumerStatefulWidget {
  const _Body();
  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  NotificationsDraft? _saved, _draft;
  bool _saving = false;
  int _err = 0;
  String? _error;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // The relative times recompute every 30 s while the section is visible.
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  bool get _dirty => _draft != null && _draft != _saved;

  void _edit(NotificationsDraft Function(NotificationsDraft d) f) => setState(() => _draft = f(_draft!));

  Future<void> _save() async {
    final d = _draft!;
    setState(() {
      _saving = true;
      _error = null;
    });
    final r = await ref.read(updatesRepositoryProvider).updateSettings(enabled: d.enabled, checkIntervalMinutes: d.interval, notifyEnabled: d.notify, checkOnStartup: d.onStartup);
    final ttlErr = r.isOk && d.ttl != _saved!.ttl ? await ref.read(sourceCacheTtlProvider.notifier).save(d.ttl) : null;
    if (!mounted) return;
    if (r.isErr || ttlErr != null) {
      setState(() {
        _saving = false;
        _error = "Couldn't save. Try again.";
        _err++;
      });
      return;
    }
    setState(() {
      _saving = false;
      _saved = d;
    });
    ref.invalidate(updateSettingsProvider);
    settingsToast(ref, 'Saved', kind: GlassToastKind.success);
  }

  Future<void> _confirmLeave() async {
    final discard = await showGlassAlert<bool>(
      context,
      title: 'Discard your changes?',
      actions: const [
        GlassAlertAction<bool>('Keep editing', role: GlassAlertRole.cancel, value: false),
        GlassAlertAction<bool>('Discard', role: GlassAlertRole.destructive, value: true),
      ],
    );
    if ((discard ?? false) && mounted) {
      setState(() => _draft = _saved);
      final r = GoRouter.of(context);
      r.canPop() ? r.pop() : r.go('/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(updateSettingsProvider);
    final ttl = ref.watch(sourceCacheTtlProvider);
    final offline = settingsOffline(ref);
    if (settings.hasError || ttl.hasError) {
      if (offline) return const OfflineSettingsNotice();
      return GlassInlineError(onRetry: () {
        ref
          ..invalidate(updateSettingsProvider)
          ..invalidate(sourceCacheTtlProvider);
      },);
    }
    final s = settings.valueOrNull, t = ttl.valueOrNull;
    if (s == null || t == null) return const GlassRowSkeletons(5, label: 'Loading notifications');
    final loaded = NotificationsDraft(enabled: s.enabled, onStartup: s.checkOnStartup, notify: s.notifyEnabled, interval: s.checkIntervalMinutes, ttl: t);
    if (_saved == null || (!_dirty && _saved != loaded)) {
      _saved = loaded;
      _draft = loaded;
    }
    final d = _draft!;
    final enabled = !offline && !_saving;
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_confirmLeave());
      },
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (offline) const OfflineSettingsNotice(),
        _ScheduleStrip(settings: s),
        SettingsGroup(children: [
          SettingsSwitchRow(id: 'updates-auto', title: 'Check for new chapters automatically', caption: 'Nothing is checked and nothing notifies while this is off.', value: d.enabled, enabled: enabled, onChanged: (v) => _edit((x) => x.copyWith(enabled: v))),
          SettingsSwitchRow(id: 'updates-startup', title: 'Check when the server starts', value: d.onStartup, enabled: enabled, onChanged: (v) => _edit((x) => x.copyWith(onStartup: v))),
          SettingsSwitchRow(id: 'updates-notify', title: 'Send new-chapter notifications', caption: 'For every account on this server. Turn one series off from its own page.', value: d.notify, enabled: enabled, onChanged: (v) => _edit((x) => x.copyWith(notify: v))),
        ],),
        SettingsGroup(children: [
          SettingsAnchor(
            id: 'updates-interval',
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // The slider prints the value in `mono` on its trailing edge.
                GlassText('Check interval', role: gt.typeBody),
                GlassSlider(
                  key: const ValueKey('interval-slider'),
                  value: d.interval.toDouble(),
                  min: 5,
                  max: 120,
                  divisions: 23,
                  magnet: 30,
                  label: 'Check interval',
                  format: (v) => '${v.round()} min',
                  onChanged: enabled ? (v) => _edit((x) => x.copyWith(interval: v.round())) : null,
                ),
              ],),
            ),
          ),
          SettingsAnchor(
            id: 'catalogue-cache',
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: GlassText('Source catalogue cache', role: gt.typeBody)),
                  if (enabled)
                    GlassStepper(value: d.ttl, min: 5, max: 1440, step: 5, label: 'Source catalogue cache', format: (v) => '$v min', onChanged: (v) => _edit((x) => x.copyWith(ttl: v)))
                  else
                    GlassText('${d.ttl} min', role: gt.typeMono, color: gt.colorLabel2),
                ],),
                const SizedBox(height: 4),
                GlassText('How long a browsed catalogue is reused before asking the source again.', role: gt.typeFootnote, color: gt.colorLabel2),
              ],),
            ),
          ),
        ],),
        if (_error != null)
          Padding(
            padding: GlassFrame.gutter(context, bottom: 8, inner: 16),
            child: Semantics(liveRegion: true, child: GlassText(_error!, role: gt.typeFootnote, color: gt.colorDanger)),
          ),
        // Keeps the last rows clear of the floating bar.
        SizedBox(height: _dirty ? 72 : 0),
        GlassUnsavedChangesBar(
          visible: _dirty,
          saving: _saving,
          errorTrigger: _err,
          onDiscard: () => setState(() {
            _draft = _saved;
            _error = null;
          }),
          onSave: () => unawaited(_save()),
        ),
      ],),
    );
  }
}

/// The three cells: last check, next check (or overdue with "See System status"), interval (glass 8.25.6).
class _ScheduleStrip extends StatelessWidget {
  const _ScheduleStrip({required this.settings});
  final UpdateSettings settings;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final sch = describeCheckSchedule(settings, now)!;
    final last = sch.lastRunAt == null ? 'No check yet' : 'Last check ${glassAgo(sch.lastRunAt!, now)}';
    final overdue = settings.enabled && sch.overdueByMinutes != null;
    final next = !settings.enabled
        ? 'Checks are off'
        : sch.estimatedNextRunAt == null
            ? 'Next check soon'
            : overdue
                ? 'Overdue by ${sch.overdueByMinutes} min'
                : 'Next check ${glassIn(sch.estimatedNextRunAt!, now)}';
    // Three columns while they fit; from text scale 1.3 they stack as rows (one phrase a line, never one word a line).
    final stack = MediaQuery.textScalerOf(context).scale(1) >= 1.3;
    Widget cell(Widget child) => stack ? Padding(padding: const EdgeInsets.fromLTRB(12, 10, 12, 0), child: child) : Expanded(child: Padding(padding: const EdgeInsets.all(12), child: child));
    return SettingsAnchor(
      id: 'updates-schedule',
      child: Padding(
        padding: GlassFrame.gutter(context, bottom: 16),
        child: GlassSlab(
          radius: 20,
          padding: EdgeInsets.zero,
          child: Flex(direction: stack ? Axis.vertical : Axis.horizontal, crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              cell(GlassText(last, role: gt.typeFootnote, color: gt.colorLabel1)),
              cell(Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                GlassText(next, role: gt.typeFootnote, color: overdue ? gt.colorWarning : gt.colorLabel1),
                if (overdue)
                  GlassButton(label: 'See System status', variant: GlassButtonVariant.plain, size: GlassButtonSize.small, onPressed: () => GoRouter.of(context).go(Routes.status())),
              ],),),
              cell(GlassText('Every ${glassInterval(settings.checkIntervalMinutes)}', role: gt.typeFootnote, color: gt.colorLabel1)),
              if (stack) const SizedBox(height: 10),
            ],),
        ),
      ),
    );
  }
}
