import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/platform/media_store.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/common.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glass_button.dart';
import 'package:manhwamaniacs/skins/glass/primitives/segmented.dart';
import 'package:manhwamaniacs/skins/glass/primitives/sheet_scaffold.dart' show GlassCloseButton;
import 'package:manhwamaniacs/skins/glass/primitives/switch.dart';
import 'package:manhwamaniacs/skins/glass/primitives/toast.dart';
import 'package:manhwamaniacs/skins/glass/shell/shell_common.dart' show globalRectOf;
import 'package:manhwamaniacs/skins/glass/wrapped/share_card.dart';
import 'package:manhwamaniacs/skins/glass/wrapped/share_layout.dart';
import 'package:share_plus/share_plus.dart';

/// The platform a save follows (tests override it): iOS saves through the share sheet, Android 10 and later through `mm/media`.
final glassShareIsAndroidProvider = Provider<bool>((ref) => defaultTargetPlatform == TargetPlatform.android, name: 'glassShareIsAndroid');

/// The share side of a card (glass 9.2.4): the rendered PNG in the card's place and, under it, the strip with Story and Post, "Show my
/// profile name" (off) and the buttons Share and Save image. The preview is rendered exactly like the export, so what shows is what ships.
class GlassShareSide extends ConsumerStatefulWidget {
  const GlassShareSide({super.key, required this.spec, required this.onClose, this.initial = ShareFormat.story});
  final ShareSpec spec;
  final VoidCallback onClose;
  final ShareFormat initial;

  @override
  ConsumerState<GlassShareSide> createState() => GlassShareSideState();
}

class GlassShareSideState extends ConsumerState<GlassShareSide> {
  late ShareFormat format = widget.initial;
  bool showName = false;
  Uint8List? png;
  Uint8List? previous;
  bool rendering = true;
  bool sharing = false;
  bool? canSave;
  int _token = 0;
  final _shareKey = GlobalKey();
  final _saveKey = GlobalKey();

  bool get _android => ref.read(glassShareIsAndroidProvider);

  @override
  void initState() {
    super.initState();
    unawaited(ref.read(mediaStoreProvider).canSaveImage().then((v) {
      if (mounted) setState(() => canSave = v);
    }),);
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_render(preview: true)));
  }

  /// Switches the format (keys `1` and `2` on a hardware keyboard).
  void setFormat(ShareFormat f) {
    if (f == format) return;
    setState(() => format = f);
    unawaited(_render(preview: true));
  }

  String? get _name => shareProfileName(showName, ref.read(activeProfileProvider)?.name);

  Future<Uint8List?> _render({required bool preview}) async {
    final token = ++_token;
    setState(() {
      rendering = true;
      previous = png ?? previous;
    });
    try {
      final bytes = await renderShareCard(context, widget.spec, format, profileName: _name);
      if (!mounted || token != _token) return bytes;
      setState(() {
        png = bytes;
        rendering = false;
      });
      return bytes;
    } catch (_) {
      if (mounted && token == _token) {
        setState(() => rendering = false);
        showGlassToast(ref, const GlassToastSpec("Couldn't make the image. Try again.", kind: GlassToastKind.error));
      }
      return null;
    }
  }

  Rect? _origin(GlobalKey k) {
    final c = k.currentContext;
    return c == null ? null : globalRectOf(c);
  }

  Future<void> _share({required bool save}) async {
    if (sharing) return;
    setState(() => sharing = true);
    try {
      final bytes = await _render(preview: false);
      if (bytes == null || !mounted) return;
      final name = widget.spec.fileName;
      if (save && _android && (canSave ?? false)) {
        final ok = await ref.read(mediaStoreProvider).saveImage(bytes, name);
        if (!mounted) return;
        if (ok) {
          _done();
          showGlassToast(ref, const GlassToastSpec('Saved to Pictures/ManhwaManiacs', kind: GlassToastKind.success));
        } else {
          showGlassToast(ref, const GlassToastSpec("Couldn't make the image. Try again.", kind: GlassToastKind.error));
        }
        return;
      }
      final origin = _origin(save ? _saveKey : _shareKey);
      final r = await ref.read(glassShareDelegateProvider).share(
            ShareParams(
              files: [XFile.fromData(bytes, mimeType: 'image/png', name: name)],
              fileNameOverrides: [name],
              sharePositionOrigin: origin,
            ),
          );
      if (!mounted) return;
      if (r.status == ShareResultStatus.success) {
        _done();
        final toPhotos = !_android && r.raw.contains('com.apple.UIKit.activity.SaveToCameraRoll');
        showGlassToast(ref, GlassToastSpec(toPhotos ? 'Saved to Photos' : 'Shared', kind: GlassToastKind.success));
      }
    } catch (_) {
      if (mounted) showGlassToast(ref, const GlassToastSpec("Couldn't make the image. Try again.", kind: GlassToastKind.error));
    } finally {
      if (mounted) setState(() => sharing = false);
    }
  }

  void _done() {
    glassFire(ref, HapticEvent.shareExport);
    glassSound(ref, SoundEvent.downloadDone);
  }

  @override
  Widget build(BuildContext context) {
    final logical = shareLogical(format);
    final showSave = !_android || (canSave ?? false);
    final shown = png ?? previous;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.digit1): () => setFormat(ShareFormat.story),
        const SingleActivator(LogicalKeyboardKey.digit2): () => setFormat(ShareFormat.post),
        const SingleActivator(LogicalKeyboardKey.escape): widget.onClose,
      },
      child: Focus(
        autofocus: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onClose,
                child: Semantics(
                  image: true,
                  label: 'Share image preview, ${format == ShareFormat.story ? 'Story' : 'Post'}',
                  child: AspectRatio(
                    aspectRatio: logical.width / logical.height,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 120),
                      opacity: rendering && shown != null ? 0.4 : 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: shown == null ? const ColoredBox(color: Color(0xFF0B0B0F)) : Image.memory(shown, fit: BoxFit.cover, gaplessPlayback: true),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _Strip(
              format: format,
              onFormat: setFormat,
              showName: showName,
              onName: (v) {
                setState(() => showName = v);
                unawaited(_render(preview: true));
              },
              sharing: sharing,
              shareKey: _shareKey,
              saveKey: _saveKey,
              showSave: showSave,
              onShare: () => unawaited(_share(save: false)),
              onSave: () => unawaited(_share(save: true)),
              onClose: widget.onClose,
            ),
          ],
        ),
      ),
    );
  }
}

class _Strip extends StatelessWidget {
  const _Strip(
      {required this.format,
      required this.onFormat,
      required this.showName,
      required this.onName,
      required this.sharing,
      required this.shareKey,
      required this.saveKey,
      required this.showSave,
      required this.onShare,
      required this.onSave,
      required this.onClose,});
  final ShareFormat format;
  final ValueChanged<ShareFormat> onFormat;
  final bool showName;
  final ValueChanged<bool> onName;
  final bool sharing;
  final GlobalKey shareKey;
  final GlobalKey saveKey;
  final bool showSave;
  final VoidCallback onShare;
  final VoidCallback onSave;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: gt.colorSurface2, borderRadius: BorderRadius.circular(26)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: GlassSegmented<ShareFormat>(
                    segments: const [GlassSegment(value: ShareFormat.story, label: 'Story'), GlassSegment(value: ShareFormat.post, label: 'Post')],
                    selected: format,
                    onSelected: onFormat,
                  ),
                ),
                const SizedBox(width: 8),
                GlassCloseButton(onTap: onClose),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: GlassLabel('Show my profile name', role: gt.typeBody, color: gt.colorLabel1)),
                GlassSwitch(value: showName, onChanged: onName, label: 'Show my profile name'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: KeyedSubtree(key: shareKey, child: GlassButton(label: 'Share', variant: GlassButtonVariant.primary, loading: sharing, onPressed: onShare, fullWidth: true))),
                if (showSave) ...[
                  const SizedBox(width: 8),
                  Expanded(child: KeyedSubtree(key: saveKey, child: GlassButton(label: 'Save image', onPressed: sharing ? null : onSave, fullWidth: true))),
                ],
              ],
            ),
          ],
        ),
      );
}

/// Opens the share side of [spec] over everything (Statistics' nav Share, a stat card, the streak): a dark scrim and the side, closed
/// by its glyph, a tap on the image, Esc and Android back.
Future<void> openShare(BuildContext context, WidgetRef ref, ShareSpec spec) {
  final nav = Navigator.of(context, rootNavigator: true);
  return nav.push<void>(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: const Color(0xCC000000),
      pageBuilder: (ctx, a, b) => SafeArea(
          child: Center(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: GlassShareSide(spec: spec, onClose: () => Navigator.of(ctx).maybePop())),),),),
      transitionsBuilder: (ctx, a, b, child) => FadeTransition(opacity: a, child: child),
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 200),
    ),
  );
}
