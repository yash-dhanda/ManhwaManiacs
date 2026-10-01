import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:manhwamaniacs/features/admin/providers/status_providers.dart';
import 'package:manhwamaniacs/features/admin/utils/status_format.dart';
import 'package:manhwamaniacs/features/auth/models/auth_state.dart';
import 'package:manhwamaniacs/features/auth/providers/auth_controller.dart';
import 'package:manhwamaniacs/features/profiles/providers/notify_enabled_provider.dart';
import 'package:manhwamaniacs/features/settings/providers/source_cache_ttl_provider.dart';
import 'package:manhwamaniacs/features/updates/models/update_settings.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_number_field.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/admin/recent_checks.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';

/// Notifications (cinematic 8.30.2 row 10): the per-profile master, then the admin block.
class NotificationsSection extends ConsumerWidget {
  const NotificationsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notify = ref.watch(notifyEnabledProvider);
    final auth = ref.watch(authControllerProvider);
    final admin = auth is AuthAuthenticated && auth.user.isAdmin;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      switchRow(
        'notify',
        'Notify me about new chapters',
        notify,
        (v) async {
          final err = await ref.read(notifyEnabledProvider.notifier).setEnabled(v);
          if (err != null) throw err;
        },
        description:
            "When this is off, new chapters don't reach your Library badge, Updates or the stop-press banner. Each series keeps its own bell for when you turn it back on. Saved for this profile.",
      ),
      if (admin) const AdminNotifications() else const SizedBox.shrink(),
    ],);
  }
}

/// The instance-wide checker settings (mobile K40): a draft saved by `Save`, the recent checks,
/// and the source cache lifetime.
class AdminNotifications extends ConsumerStatefulWidget {
  const AdminNotifications({super.key});

  @override
  ConsumerState<AdminNotifications> createState() => _AdminNotificationsState();
}

class _AdminNotificationsState extends ConsumerState<AdminNotifications> {
  UpdateSettings? _server;
  bool? _enabled, _startup, _notify;
  int? _interval;
  bool _saving = false;
  String? _saveLine;
  final _ttl = TextEditingController();
  bool _ttlSeeded = false, _ttlSaving = false;
  String? _ttlError;

  @override
  void dispose() {
    _ttl.dispose();
    super.dispose();
  }

  void _seed(UpdateSettings s) {
    if (identical(_server, s)) return;
    _server = s;
    _enabled = s.enabled;
    _startup = s.checkOnStartup;
    _notify = s.notifyEnabled;
    // Null until the slider moves, so Save never rewrites an interval the slider cannot show (the server takes any value >= 5).
    _interval = null;
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _saveLine = null;
    });
    final r = await ref.read(updatesRepositoryProvider).updateSettings(
          enabled: _enabled,
          checkIntervalMinutes: _interval,
          notifyEnabled: _notify,
          checkOnStartup: _startup,
        );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _saveLine = r.isErr ? r.error.userMessage : 'Saved.';
    });
    if (!r.isErr) ref.invalidate(updateSettingsProvider);
  }

  Future<void> _saveTtl() async {
    final err = sourceCacheTtlError(_ttl.text);
    if (err != null) {
      setState(() => _ttlError = err);
      return;
    }
    setState(() {
      _ttlSaving = true;
      _ttlError = null;
    });
    final e = await ref.read(sourceCacheTtlProvider.notifier).save(int.parse(_ttl.text.trim()));
    if (!mounted) return;
    setState(() {
      _ttlSaving = false;
      _ttlError = e?.userMessage;
    });
    if (e == null) ref.read(cineToastsProvider.notifier).success('Saved.');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final settings = ref.watch(updateSettingsProvider);
    final runs = ref.watch(updateRunsProvider);
    final ttl = ref.watch(sourceCacheTtlProvider);
    final now = DateTime.now();
    if (!_ttlSeeded && ttl.hasValue) {
      _ttlSeeded = true;
      _ttl.text = '${ttl.value}';
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SettingsKicker('THE CHECKER · INSTANCE-WIDE'),
      SettingsAsync<UpdateSettings>(
        value: settings,
        onRetry: () => ref.invalidate(updateSettingsProvider),
        rows: 4,
        builder: (context, s, offline) {
          _seed(s);
          final last = s.lastRunAt;
          final next = last?.add(Duration(minutes: s.checkIntervalMinutes));
          final overdue = next != null && next.isBefore(now) && s.enabled;
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
              padding: EdgeInsets.only(top: c.space2),
              child: CineRoleText(
                'LAST CHECK ${last == null ? '–' : clockLabel(last)} · NEXT ${next == null ? '–' : '≈ ${clockLabel(next)}'} · EVERY ${intervalLabel(s.checkIntervalMinutes)}',
                c.typeFolio,
                color: c.colorInk60,
              ),
            ),
            if (overdue)
              Padding(
                padding: EdgeInsets.only(top: c.space2),
                child: Row(children: [
                  Flexible(child: CineRoleText('Expected ${now.difference(next).inMinutes} min ago. ', c.typeCaption, color: c.colorSpot)),
                  CineButton(label: 'See System status', variant: CineButtonVariant.link, onPressed: () => unawaited(context.push<void>(Routes.status()))),
                ],),
              ),
            switchRow('check-auto', 'Check automatically', _enabled ?? s.enabled, (v) => setState(() => _enabled = v), disabled: offline),
            switchRow('check-startup', 'Check on startup', _startup ?? s.checkOnStartup, (v) => setState(() => _startup = v), disabled: offline),
            sliderRow('check-interval', 'Check interval', (_interval ?? s.checkIntervalMinutes).clamp(5, 120).toDouble(), (v) => setState(() => _interval = v.round()),
                min: 5, max: 120, divisions: 23, flag: (v) => '${v.round()} MIN', description: 'The server enforces a 5-minute floor.', disabled: offline,),
            switchRow('notify-master', 'Notify about new chapters', _notify ?? s.notifyEnabled, (v) => setState(() => _notify = v),
                description: 'The master switch for every profile.', disabled: offline,),
            Padding(
              padding: EdgeInsets.only(top: c.space2),
              child: Row(children: [
                CineButton(label: 'Save', size: CineButtonSize.sm, loading: _saving, onPressed: offline ? null : _save),
                if (_saveLine != null) Padding(padding: EdgeInsets.only(left: c.space3), child: CineRoleText(_saveLine!, c.typeCaption, color: _saveLine == 'Saved.' ? c.colorSet : c.colorProof)),
              ],),
            ),
          ],);
        },
      ),
      SizedBox(height: c.space4),
      RecentChecks(
        runs: (runs.valueOrNull ?? const <UpdateRun>[]).take(5).toList(),
        now: now,
        loading: runs.isLoading && !runs.hasValue,
        error: runs.hasError ? "This didn't load." : null,
        onRetry: () => ref.invalidate(updateRunsProvider),
      ),
      const SettingsKicker('SOURCE CACHE'),
      JumpRow(
        id: 'cache-ttl',
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          CineNumberField(label: 'Source cache lifetime', controller: _ttl, unit: 'MIN', errorText: _ttlError, enabled: ttl.hasValue, onChanged: (_) => setState(() => _ttlError = null)),
          SizedBox(height: c.space2),
          Align(alignment: Alignment.centerLeft, child: CineButton(label: 'Save', size: CineButtonSize.sm, loading: _ttlSaving, onPressed: ttl.hasValue ? _saveTtl : null)),
        ],),
      ),
    ],);
  }
}

