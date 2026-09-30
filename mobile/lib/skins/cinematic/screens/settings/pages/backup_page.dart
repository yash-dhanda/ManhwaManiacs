import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/admin/utils/status_format.dart';
import 'package:manhwamaniacs/features/settings/models/backup_status.dart';
import 'package:manhwamaniacs/features/settings/providers/backup_provider.dart';
import 'package:manhwamaniacs/features/settings/services/backup_download.dart';
import 'package:manhwamaniacs/features/settings/utils/format_storage_bytes.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_banner_strip.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_confirm_dialog.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_dialog.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/dialog_route.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/screens/settings/settings_kit.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

const List<String> kRestoreBullets = [
  'It replaces every account on this server.',
  'Sign-ins come from the backup.',
  'It applies when the server restarts.',
  'Nothing of the current state is kept.',
];

String _stamp(DateTime t) {
  const m = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
  final l = t.toLocal();
  return '${l.day} ${m[l.month - 1]} ${clockLabel(l)}';
}

/// The nightly card's line: `UNKNOWN` is never shown as healthy.
String nightlyLine(NightlyBackup? n) {
  if (n == null) return 'LAST NIGHTLY · UNKNOWN';
  final when = n.finishedAt == null ? '' : ' · ${_stamp(n.finishedAt!)}';
  if (!n.ok) return 'LAST NIGHTLY · FAILED AT ${(n.phase ?? 'UNKNOWN').toUpperCase()}$when';
  return 'LAST NIGHTLY · OK$when${n.bytes == null ? '' : ' · ${formatStorageBytes(n.bytes!).toUpperCase()}'}';
}

/// Backup & restore (`/settings/backup`, admin, cinematic 8.30.6).
class BackupPage extends ConsumerStatefulWidget {
  const BackupPage({super.key, this.filePicker});

  /// Test hook: resolves with (path, name, size) instead of opening the picker.
  final Future<({String path, String name, int size})?> Function()? filePicker;

  @override
  ConsumerState<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends ConsumerState<BackupPage> {
  bool _caches = false, _exporting = false;
  int _received = 0, _total = -1;
  ({String path, String name, int size})? _file;
  String? _fileError;
  bool _restoring = false;

  Future<void> _export() async {
    setState(() {
      _exporting = true;
      _received = 0;
      _total = -1;
    });
    final dl = ref.read(backupDownloaderProvider);
    try {
      final path = await dl.download(includeCaches: _caches, onProgress: (r, t) {
        if (mounted) {
          setState(() {
            _received = r;
            _total = t;
          });
        }
      },);
      if (!mounted) return;
      await dl.share(path);
    } catch (_) {
      if (mounted) ref.read(cineToastsProvider.notifier).error("Couldn't download the backup.");
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _choose() async {
    final picked = widget.filePicker != null
        ? await widget.filePicker!()
        : await _pick();
    if (picked == null || !mounted) return;
    setState(() {
      _file = picked;
      _fileError = validateRestoreFile(name: picked.name, size: picked.size);
    });
  }

  Future<({String path, String name, int size})?> _pick() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: const ['db']);
    final f = r?.files.single;
    if (f == null || f.path == null) return null;
    return (path: f.path!, name: f.name, size: f.size);
  }

  Future<void> _restore() async {
    final f = _file!;
    final ok = await showCineConfirm(
      context,
      title: 'Restore from ${f.name}?',
      body: kRestoreBullets.join(' '),
      confirmLabel: 'Restore',
      destructive: true,
      typedPhrase: 'RESTORE',
      onConfirm: () async {
        setState(() => _restoring = true);
        final r = await ref.read(backupRepositoryProvider).importBackup(f.path);
        if (mounted) setState(() => _restoring = false);
        if (r.isErr) throw r.error;
      },
    );
    if (!ok || !mounted) return;
    ref.invalidate(backupStatusProvider);
    await showCineDialog<void>(
      context,
      builder: (ctx) => CineDialog(
        title: 'Restore staged.',
        body: 'Restart the server to finish.',
        onCancel: () => Navigator.of(ctx).pop(),
        actions: [CineButton(label: 'Done', onPressed: () => Navigator.of(ctx).pop())],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    final status = ref.watch(backupStatusProvider);
    final s = status.valueOrNull;
    final nightly = s?.nightly;
    final failed = nightly != null && !nightly.ok;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (s?.restorePending ?? false)
        CineBannerStrip(
          line: 'A restore is staged. It applies the next time the server starts; the current database is kept.',
          actions: [
            CineBannerAction('Cancel staged restore', () async {
              await ref.read(backupRepositoryProvider).cancelPendingRestore();
              ref.invalidate(backupStatusProvider);
            }),
          ],
        ),
      SettingsAsync<BackupStatus>(
        value: status,
        rows: 1,
        onRetry: () => ref.invalidate(backupStatusProvider),
        builder: (context, _, offline) => Padding(
          padding: EdgeInsets.only(top: c.space3),
          child: Container(
            padding: EdgeInsets.all(c.space3),
            decoration: BoxDecoration(color: c.colorPaper1, border: Border(left: BorderSide(color: failed ? c.colorProof : c.colorInk30, width: 2))),
            child: CineRoleText(nightlyLine(nightly), c.typeFolio, color: failed ? c.colorProof : c.colorInk60),
          ),
        ),
      ),
      const SettingsKicker('EXPORT'),
      CineRoleText('The whole database, every account. Keep it private.', c.typeCaption, color: c.colorInk60),
      switchRow('include-caches', 'Include caches (larger, warmer restore)', _caches, (v) => setState(() => _caches = v), disabled: _exporting),
      SizedBox(height: c.space3),
      Align(alignment: Alignment.centerLeft, child: CineButton(label: 'Export backup', loading: _exporting, onPressed: () => unawaited(_export()))),
      if (_exporting) ...[
        SizedBox(height: c.space3),
        CineRuleProgress(value: _total > 0 ? _received / _total : 0, semanticLabel: backupProgressLabel(_received, _total)),
        SizedBox(height: c.space1),
        CineRoleText(backupProgressLabel(_received, _total), c.typeFolio, color: c.colorInk60),
      ],
      const SettingsKicker('RESTORE'),
      Container(
        padding: EdgeInsets.all(c.space4),
        decoration: BoxDecoration(color: c.colorProofWash, border: Border(left: BorderSide(color: c.colorProof, width: 2))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CineRoleText('Restoring replaces the whole database with a backup file. It takes effect the next time the server starts.', c.typeCaption, color: c.colorInk100),
          SizedBox(height: c.space3),
          CineButton(label: 'Choose backup file', variant: CineButtonVariant.secondary, onPressed: () => unawaited(_choose())),
          SizedBox(height: c.space2),
          CineRoleText(
            _file == null ? 'No file chosen. Nothing is uploaded until you confirm.' : '${_file!.name} · ${formatStorageBytes(_file!.size).toUpperCase()}',
            c.typeFolio,
            color: c.colorInk60,
          ),
          if (_fileError != null) Padding(padding: EdgeInsets.only(top: c.space1), child: CineRoleText(_fileError!, c.typeCaption, color: c.colorProof)),
          SizedBox(height: c.space3),
          CineButton(
            label: 'Restore from this file…',
            variant: CineButtonVariant.destructive,
            loading: _restoring,
            onPressed: _file != null && _fileError == null ? () => unawaited(_restore()) : null,
          ),
        ],),
      ),
    ],);
  }
}
