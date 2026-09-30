import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/platform/media_store.dart';
import 'package:manhwamaniacs/skins/cinematic/feedback.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_button.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_notice.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_progress.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_segmented_control.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/cine_slug_lines.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/sheet_route.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/toasts.dart';
import 'package:manhwamaniacs/skins/cinematic/share/share_card_capture.dart';
import 'package:manhwamaniacs/skins/cinematic/share/share_card_model.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:share_plus/share_plus.dart';

/// The share seam (`share_plus` 12.0.2): a provider so tests answer it.
abstract interface class ShareDelegate {
  Future<ShareResult> share(ShareParams params);
}

class SharePlusDelegate implements ShareDelegate {
  const SharePlusDelegate();
  @override
  Future<ShareResult> share(ShareParams params) =>
      SharePlus.instance.share(params);
}

final shareDelegateProvider = Provider<ShareDelegate>(
    (_) => const SharePlusDelegate(),
    name: 'shareDelegate',);

/// Renders a card to PNG bytes: a provider so tests can stub the capture.
typedef CardRenderer = Future<Uint8List> Function(
    BuildContext context, ShareTemplate t, ShareFormat f,);

final cardRendererProvider =
    Provider<CardRenderer>((_) => renderShareCard, name: 'cardRenderer');

/// Opens the press-run sheet (`[0.92]` detent, 720 wide max).
Future<void> showPressRun(BuildContext context, ShareInput input) =>
    showCineSheet<void>(context,
        kicker: 'PRESS RUN',
        title: 'Press run',
        builder: (context) => PressRunBody(input: input),);

/// The press run's content (cinematic 9.2.5): a 240 px live preview of the
/// real PNG, the template slug line, the STORY | POST control and the actions.
/// The same content sits inline on Annual page 11 ([inline]).
class PressRunBody extends ConsumerStatefulWidget {
  const PressRunBody(
      {super.key,
      required this.input,
      this.inline = false,
      this.onReadNumbers,
      this.initial,});

  final ShareInput input;
  final bool inline;
  final VoidCallback? onReadNumbers;
  final ShareId? initial;

  @override
  ConsumerState<PressRunBody> createState() => _PressRunBodyState();
}

class _PressRunBodyState extends ConsumerState<PressRunBody> {
  late final List<ShareTemplate> _templates = shareTemplates(widget.input);
  int _index = 0;
  ShareFormat _format = ShareFormat.story;
  Uint8List? _bytes;
  bool _rendering = false;
  int _token = 0;
  bool? _canSave;
  final _shareKey = GlobalKey();

  bool get _ios => defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      final i = _templates.indexWhere((t) => t.id == widget.initial);
      if (i >= 0) _index = i;
    }
    if (_ios) {
      _canSave = true;
    } else {
      ref.read(mediaStoreProvider).canSaveImage().then((v) {
        if (mounted) setState(() => _canSave = v);
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _preview());
  }

  ShareTemplate? get _current => _templates.isEmpty
      ? null
      : _templates[_index.clamp(0, _templates.length - 1)];

  Future<void> _preview() async {
    final t = _current;
    if (t == null || !mounted) return;
    final token = ++_token;
    setState(() => _rendering = true);
    try {
      final bytes = await ref.read(cardRendererProvider)(context, t, _format);
      if (!mounted || token != _token) return;
      setState(() {
        _bytes = bytes;
        _rendering = false;
      });
    } catch (_) {
      if (!mounted || token != _token) return;
      setState(() => _rendering = false);
      ref
          .read(cineToastsProvider.notifier)
          .error("Couldn't make the card. Try again.");
    }
  }

  Future<Uint8List?> _cardBytes() async {
    if (_bytes != null && !_rendering) return _bytes;
    final t = _current;
    if (t == null) return null;
    try {
      return await ref.read(cardRendererProvider)(context, t, _format);
    } catch (_) {
      if (mounted) {
        ref
            .read(cineToastsProvider.notifier)
            .error("Couldn't make the card. Try again.");
      }
      return null;
    }
  }

  Rect? _shareOrigin() {
    final box = _shareKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Future<ShareResult?> _openShareSheet(Uint8List bytes, String name) async {
    try {
      return await ref.read(shareDelegateProvider).share(
            ShareParams(
              files: [XFile.fromData(bytes, mimeType: 'image/png', name: name)],
              fileNameOverrides: [name],
              sharePositionOrigin: _shareOrigin(),
            ),
          );
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveAndroid(Uint8List bytes, String name,
      {required bool instead,}) async {
    final ok = (_canSave ?? false) &&
        await ref.read(mediaStoreProvider).saveImage(bytes, name);
    if (!mounted) return;
    if (ok) {
      ref.read(cineToastsProvider.notifier).success(instead
          ? 'Saved the card instead.'
          : 'Card saved to Pictures › ManhwaManiacs.',);
    } else {
      ref.read(cineToastsProvider.notifier).error(
          instead ? "Couldn't share the card." : "Couldn't save the card.",);
    }
  }

  Future<void> _share() async {
    final t = _current;
    if (t == null) return;
    cineFeedback(context, HapticEvent.shareExport,
        sound: SoundEvent.shareExport,);
    final bytes = await _cardBytes();
    if (bytes == null || !mounted) return;
    final name = shareFileName(t.id, _format);
    final r = await _openShareSheet(bytes, name);
    if (!mounted) return;
    if (r != null && r.status == ShareResultStatus.dismissed) return;
    if (r == null || r.status == ShareResultStatus.unavailable) {
      // A share that failed saves the card instead (Android); iOS has no silent save.
      if (_ios) {
        ref.read(cineToastsProvider.notifier).error("Couldn't share the card.");
      } else {
        await _saveAndroid(bytes, name, instead: true);
      }
    }
  }

  Future<void> _save() async {
    final t = _current;
    if (t == null) return;
    cineFeedback(context, HapticEvent.shareExport,
        sound: SoundEvent.shareExport,);
    final bytes = await _cardBytes();
    if (bytes == null || !mounted) return;
    final name = shareFileName(t.id, _format);
    if (_ios) {
      final r = await _openShareSheet(bytes, name);
      if (!mounted) return;
      if (r != null &&
          r.status == ShareResultStatus.success &&
          (r.raw).contains('SaveToCameraRoll')) {
        ref.read(cineToastsProvider.notifier).success('Card saved.');
      }
    } else {
      await _saveAndroid(bytes, name, instead: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_templates.isEmpty) {
      return const CineNotice(
          tone: CineNoticeTone.empty,
          kicker: 'PRESS RUN',
          headline: 'Nothing to print yet.',
          deck: 'Read a few chapters and your cards appear here.',);
    }
    final cur = _current!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 240,
            child: Semantics(
              image: true,
              label:
                  '${cur.id.label[0]}${cur.id.label.substring(1).toLowerCase()} card, ${_format.name}',
              child: DecoratedBox(
                decoration:
                    BoxDecoration(border: Border.all(color: CineColors.rule2)),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_bytes != null)
                      Opacity(
                          opacity: _rendering ? 0.4 : 1,
                          child: Image.memory(_bytes!,
                              fit: BoxFit.contain, gaplessPlayback: true,),),
                    if (_rendering)
                      const CineLeaderDial(size: 24, showAfter: Duration.zero),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          CineSlugLines(
            items: [
              for (final x in _templates) CineSlug(x.id.name, x.id.label),
            ],
            selected: {
              _templates[_index.clamp(0, _templates.length - 1)].id.name,
            },
            onChanged: (id) {
              final i = _templates.indexWhere((x) => x.id.name == id);
              if (i < 0 || i == _index) return;
              setState(() => _index = i);
              _preview();
            },
          ),
          const SizedBox(height: 12),
          CineSegmentedControl(
            labels: const ['STORY', 'POST'],
            index: _format.index,
            onChanged: (i) {
              final f = ShareFormat.values[i];
              if (f == _format) return;
              setState(() => _format = f);
              _preview();
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: KeyedSubtree(
                      key: _shareKey,
                      child: CineButton(
                          label: 'Share',
                          loading: _rendering,
                          onPressed: _rendering ? null : _share,),),),
              if (_canSave ?? false) ...[
                const SizedBox(width: 8),
                Expanded(
                    child: CineButton(
                        label: 'Save image',
                        variant: CineButtonVariant.secondary,
                        onPressed: _rendering ? null : _save,),),
              ],
            ],
          ),
          if (widget.onReadNumbers != null) ...[
            const SizedBox(height: 8),
            Align(
                alignment: Alignment.centerLeft,
                child: CineButton(
                    label: 'Read the numbers',
                    variant: CineButtonVariant.quiet,
                    onPressed: widget.onReadNumbers,),),
          ],
        ],
      ),
    );
  }
}
