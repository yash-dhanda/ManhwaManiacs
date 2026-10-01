import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/settings/models/backup_status.dart';
import 'package:manhwamaniacs/features/settings/providers/backup_provider.dart';
import 'package:manhwamaniacs/features/settings/services/backup_download.dart';
import 'package:manhwamaniacs/features/settings/utils/format_storage_bytes.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';
import 'package:manhwamaniacs/skins/glass/icons/icon_roles.g.dart' show GlassIconWeight;
import 'package:manhwamaniacs/skins/glass/primitives/alert.dart';
import 'package:manhwamaniacs/skins/glass/primitives/cards/slab.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/inline_notice.dart';
import 'package:manhwamaniacs/skins/glass/primitives/liquid_progress.dart';
import 'package:manhwamaniacs/skins/glass/primitives/progress.dart' show GlassDots;
import 'package:manhwamaniacs/skins/glass/primitives/skeleton.dart';
import 'package:manhwamaniacs/skins/glass/primitives/text_field.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/admin_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_common.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_row.dart';
import 'package:manhwamaniacs/skins/glass/screens/you/you_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/type.dart';

/// The four consequences of a restore (glass 8.25.10).
const List<String> kGlassRestoreBullets = [
  'It replaces every account on this server.',
  'Sign-ins come from the backup.',
  'It applies on the next restart.',
  'Nothing of the current state is kept.',
];

/// The nightly card's line and tone: unknown is never shown as healthy.
({String line, Glyph glyph, Color color}) nightlyCard(NightlyBackup? n) {
  if (n == null) return (line: 'Last nightly backup: Unknown', glyph: YouGlyphs.warning, color: gt.colorWarning);
  final when = n.finishedAt == null ? '' : '${glassClock(n.finishedAt!)} · ';
  if (!n.ok) return (line: 'Last nightly backup: ${when}Failed${n.phase == null ? '' : ' at ${n.phase}'}', glyph: YouGlyphs.warningCircle, color: gt.colorDanger);
  final size = n.bytes == null ? '' : '${formatStorageBytes(n.bytes!)} · ';
  return (line: 'Last nightly backup: $when${size}OK', glyph: YouGlyphs.checkCircle, color: gt.colorSuccess);
}

/// "Type RESTORE to confirm" matches case-insensitively.
bool restorePhraseMatches(String s) => s.trim().toUpperCase() == 'RESTORE';

typedef BackupFilePick = Future<({String path, String name, int size})?> Function();

/// Tests and captures: answers "Choose backup file" instead of the system picker.
final backupFilePickProvider = Provider<BackupFilePick?>((ref) => null, name: 'backupFilePick');

/// Settings -> Backup and restore (glass 8.25.10, admin).
class BackupSection extends ConsumerWidget {
  const BackupSection({super.key, this.filePicker});

  /// Test hook: resolves instead of opening the system picker.
  final BackupFilePick? filePicker;

  @override
  Widget build(BuildContext context, WidgetRef ref) => GlassAdminGate(child: BackupBody(filePicker: filePicker));
}

class BackupBody extends ConsumerStatefulWidget {
  const BackupBody({super.key, this.filePicker});
  final BackupFilePick? filePicker;
  @override
  ConsumerState<BackupBody> createState() => _BackupBodyState();
}

class _BackupBodyState extends ConsumerState<BackupBody> {
  Timer? _poll;
  bool _caches = false, _preparing = false, _exporting = false, _cancelling = false, _restoring = false;
  int _received = 0, _total = -1;
  String? _saved, _exportError, _fileError;
  ({String path, String name, int size})? _file;
  final GlobalKey _exportKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Re-read every 30 s, only while the page is up.
    _poll = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) ref.invalidate(backupStatusProvider);
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Rect? _rectOf(GlobalKey k) {
    final box = k.currentContext?.findRenderObject() as RenderBox?;
    return box == null || !box.hasSize ? null : box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> _export() async {
    setState(() {
      _preparing = true;
      _exporting = true;
      _received = 0;
      _total = -1;
      _saved = null;
      _exportError = null;
    });
    final dl = ref.read(backupDownloaderProvider);
    try {
      final path = await dl.download(
        includeCaches: _caches,
        onProgress: (r, t) {
          if (mounted) {
            setState(() {
              _preparing = false;
              _received = r;
              _total = t;
            });
          }
        },
      );
      if (!mounted) return;
      await dl.share(path, origin: _rectOf(_exportKey));
      if (mounted) setState(() => _saved = 'Saved ${path.split('/').last}');
    } catch (_) {
      if (mounted) setState(() => _exportError = "Couldn't export the backup. Try again.");
    } finally {
      if (mounted) {
        setState(() {
          _exporting = false;
          _preparing = false;
        });
      }
    }
  }

  Future<void> _choose() async {
    final picked = await (widget.filePicker ?? ref.read(backupFilePickProvider) ?? _pick)();
    if (picked == null || !mounted) return;
    final err = validateRestoreFile(name: picked.name, size: picked.size);
    setState(() {
      _file = err == null ? picked : null;
      _fileError = err?.replaceAll(RegExp(r'\.$'), '');
    });
  }

  static Future<({String path, String name, int size})?> _pick() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: const ['db']);
    final f = r?.files.single;
    if (f == null || f.path == null) return null;
    return (path: f.path!, name: f.name, size: f.size);
  }

  Future<void> _restore() async {
    final f = _file!;
    final ok = await showGlassAlert<bool>(
      context,
      title: 'Restore from “${f.name}”?',
      notes: kGlassRestoreBullets,
      actions: const [GlassAlertAction<bool>('Cancel', role: GlassAlertRole.cancel, value: false)],
      extra: const TypedPhraseConfirm(),
    );
    if (!(ok ?? false) || !mounted) return;
    setState(() => _restoring = true);
    final r = await ref.read(backupRepositoryProvider).importBackup(f.path);
    if (!mounted) return;
    setState(() => _restoring = false);
    if (r.isErr) {
      setState(() => _fileError = r.error.userMessage);
      return;
    }
    ref.invalidate(backupStatusProvider);
    await showGlassAlert<void>(context, title: 'Restore staged. Restart the server to finish.', actions: const [GlassAlertAction<void>('OK', role: GlassAlertRole.cancel)]);
  }

  Future<void> _cancelStaged() async {
    setState(() => _cancelling = true);
    final r = await ref.read(backupRepositoryProvider).cancelPendingRestore();
    if (!mounted) return;
    setState(() => _cancelling = false);
    ref.invalidate(backupStatusProvider);
    if (r.isErr) {
      // Still staged: a restart would apply it, so say so.
      settingsToast(ref, "Couldn't cancel. The restore is still staged. ${r.error.userMessage}", kind: GlassToastKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(backupStatusProvider);
    final offline = settingsOffline(ref);
    final on = !offline;
    final s = status.valueOrNull;
    Widget card;
    if (status.hasError && !status.isLoading) {
      card = GlassInlineError(message: "Couldn't read the backup status", onRetry: () => ref.invalidate(backupStatusProvider));
    } else if (s == null) {
      card = const Padding(padding: EdgeInsets.all(16), child: GlassSkeletonGroup(label: 'Loading the backup status', child: GlassSkeleton(height: 64)));
    } else {
      final n = nightlyCard(s.nightly);
      card = SettingsAnchor(
        id: 'backup-nightly',
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: GlassSlab(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              GlyphIcon(n.glyph, weight: GlassIconWeight.fill, color: n.color),
              const SizedBox(width: 12),
              Expanded(child: GlassText(n.line, role: gt.typeCallout)),
            ],),
          ),
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (offline) const OfflineSettingsNotice(),
      card,
      if (s?.restorePending ?? false)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            GlassInlineNotice(message: 'A restore is staged and applies when the server restarts.', variant: GlassNoticeVariant.warning, actionLabel: _cancelling ? null : 'Cancel staged restore', onAction: on ? () => unawaited(_cancelStaged()) : null),
            if (_cancelling) const Padding(padding: EdgeInsets.only(top: 8), child: GlassDots()),
          ],),
        ),
      SettingsGroup(id: 'backup-export', header: 'Export', children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 0), child: GlassText('The whole database, every account. Keep it private.', role: gt.typeFootnote, color: gt.colorLabel2)),
        SettingsSwitchRow(id: 'include-caches', title: 'Include caches (larger, restores faster)', value: _caches, enabled: on && !_exporting, onChanged: (v) => setState(() => _caches = v)),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            KeyedSubtree(
              key: _exportKey,
              child: GlassButton(label: _preparing ? 'Preparing…' : 'Export backup', variant: GlassButtonVariant.primary, loading: _preparing, onPressed: on && !_exporting ? () => unawaited(_export()) : null),
            ),
            if (_exporting && !_preparing) ...[
              const SizedBox(height: 12),
              ClipRRect(borderRadius: BorderRadius.circular(12), child: LiquidProgress(value: _total > 0 ? _received / _total : 0)),
              const SizedBox(height: 4),
              GlassText(_total > 0 ? '${formatStorageBytes(_received)} of ${formatStorageBytes(_total)}' : formatStorageBytes(_received), role: gt.typeMono, color: gt.colorLabel2),
            ],
            if (_saved != null) Padding(padding: const EdgeInsets.only(top: 8), child: GlassText(_saved!, role: gt.typeFootnote, color: gt.colorLabel2)),
            if (_exportError != null) Padding(padding: const EdgeInsets.only(top: 8), child: Semantics(liveRegion: true, child: GlassText(_exportError!, role: gt.typeFootnote, color: gt.colorDanger))),
          ],),
        ),
      ],),
      SettingsAnchor(
        id: 'backup-restore',
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(color: gt.colorSurface1, border: Border(left: BorderSide(color: gt.colorDanger, width: 3))),
              child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      GlassText('RESTORE', role: gt.typeFootnote, wght: 600, color: gt.colorLabel2),
                      const SizedBox(height: 4),
                      GlassText('Restoring replaces everything on this server with the backup. It applies on the next restart, and nothing of the current state is kept.', role: gt.typeFootnote, color: gt.colorLabel2),
                      const SizedBox(height: 12),
                      GlassButton(label: 'Choose backup file', onPressed: on ? () => unawaited(_choose()) : null),
                      const SizedBox(height: 8),
                      GlassText(_file == null ? 'No file chosen. Nothing is uploaded until you confirm.' : '${_file!.name} · ${formatStorageBytes(_file!.size)}', role: gt.typeFootnote, color: gt.colorLabel2),
                      if (_fileError != null) Padding(padding: const EdgeInsets.only(top: 4), child: Semantics(liveRegion: true, child: GlassText(_fileError!, role: gt.typeFootnote, color: gt.colorDanger))),
                      const SizedBox(height: 12),
                      GlassButton(
                        label: _restoring ? 'Uploading…' : 'Restore from this file…',
                        variant: GlassButtonVariant.destructive,
                        loading: _restoring,
                        onPressed: on && _file != null && !_restoring ? () => unawaited(_restore()) : null,
                      ),
                    ],),
              ),
            ),
          ),
        ),
      ),
    ],);
  }
}

/// The alert's "Type RESTORE to confirm" field and its destructive "Restore", enabled once the phrase matches.
class TypedPhraseConfirm extends StatefulWidget {
  const TypedPhraseConfirm({super.key});
  @override
  State<TypedPhraseConfirm> createState() => _TypedPhraseConfirmState();
}

class _TypedPhraseConfirmState extends State<TypedPhraseConfirm> {
  final _c = TextEditingController();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  // The alert has no Material ancestor; the field needs one.
  Widget build(BuildContext context) => Material(
        type: MaterialType.transparency,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        GlassTextField(controller: _c, label: 'Type RESTORE to confirm', onSheet: true, autofocus: true, onChanged: (_) => setState(() {})),
        const SizedBox(height: 12),
        GlassButton(label: 'Restore', variant: GlassButtonVariant.destructive, fullWidth: true, onPressed: restorePhraseMatches(_c.text) ? () => Navigator.of(context).pop(true) : null),
      ],),
      );
}
