import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/platform/media_store.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/buttons.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/cine_text.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/cue.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/notice.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/sheet.dart';
import 'package:manhwamaniacs/skins/cinematic/kit/toast.dart';
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
  Future<ShareResult> share(ShareParams params) => SharePlus.instance.share(params);
}

final shareDelegateProvider = Provider<ShareDelegate>((_) => const SharePlusDelegate(), name: 'shareDelegate');

/// Renders a card to PNG bytes: a provider so tests can stub the capture.
typedef CardRenderer = Future<Uint8List> Function(BuildContext context, ShareTemplate t, ShareFormat f);

final cardRendererProvider = Provider<CardRenderer>((_) => renderShareCard, name: 'cardRenderer');

/// Opens the press-run sheet (`[0.92]` detent, 720 wide max).
Future<void> showPressRun(BuildContext context, ShareInput input) => showCineSheet<void>(context, kicker: 'PRESS RUN', builder: (context) => PressRunBody(input: input));

/// The press run's content (cinematic 9.2.5): a 240 px live preview of the
/// real PNG, the template slug line, the STORY | POST control and the actions.
/// The same content sits inline on Annual page 11 ([inline]).
class PressRunBody extends ConsumerStatefulWidget {
  const PressRunBody({super.key, required this.input, this.inline = false, this.onReadNumbers, this.initial});

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

  ShareTemplate? get _current => _templates.isEmpty ? null : _templates[_index.clamp(0, _templates.length - 1)];

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
      showCineToast(context, "Couldn't make the card. Try again.", duration: CineDur.holdToastError, error: true);
    }
  }

  Future<Uint8List?> _cardBytes() async {
    if (_bytes != null && !_rendering) return _bytes;
    final t = _current;
    if (t == null) return null;
    try {
      return await ref.read(cardRendererProvider)(context, t, _format);
    } catch (_) {
      if (mounted) showCineToast(context, "Couldn't make the card. Try again.", duration: CineDur.holdToastError, error: true);
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
      return await ref.read(shareDelegateProvider).share(ShareParams(
            files: [XFile.fromData(bytes, mimeType: 'image/png', name: name)],
            fileNameOverrides: [name],
            sharePositionOrigin: _shareOrigin(),
          ),);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveAndroid(Uint8List bytes, String name, {required bool instead}) async {
    final ok = (_canSave ?? false) && await ref.read(mediaStoreProvider).saveImage(bytes, name);
    if (!mounted) return;
    if (ok) {
      showCineToast(context, instead ? 'Saved the card instead.' : 'Card saved to Pictures › ManhwaManiacs.');
    } else {
      showCineToast(context, instead ? "Couldn't share the card." : "Couldn't save the card.", duration: CineDur.holdToastError, error: true);
    }
  }

  Future<void> _share() async {
    final t = _current;
    if (t == null) return;
    cinematicCue(ref, HapticEvent.shareExport, SoundEvent.shareExport);
    final bytes = await _cardBytes();
    if (bytes == null || !mounted) return;
    final name = shareFileName(t.id, _format);
    final r = await _openShareSheet(bytes, name);
    if (!mounted) return;
    if (r != null && r.status == ShareResultStatus.dismissed) return;
    if (r == null || r.status == ShareResultStatus.unavailable) {
      // A share that failed saves the card instead (Android); iOS has no silent save.
      if (_ios) {
        showCineToast(context, "Couldn't share the card.", duration: CineDur.holdToastError, error: true);
      } else {
        await _saveAndroid(bytes, name, instead: true);
      }
    }
  }

  Future<void> _save() async {
    final t = _current;
    if (t == null) return;
    cinematicCue(ref, HapticEvent.shareExport, SoundEvent.shareExport);
    final bytes = await _cardBytes();
    if (bytes == null || !mounted) return;
    final name = shareFileName(t.id, _format);
    if (_ios) {
      final r = await _openShareSheet(bytes, name);
      if (!mounted) return;
      if (r != null && r.status == ShareResultStatus.success && (r.raw).contains('SaveToCameraRoll')) {
        showCineToast(context, 'Card saved.');
      }
    } else {
      await _saveAndroid(bytes, name, instead: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    if (_templates.isEmpty) {
      return const CineNotice(kicker: 'PRESS RUN', headline: 'Nothing to print yet.', line: 'Read a few chapters and your cards appear here.');
    }
    final cur = _current!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          height: 240,
          child: Semantics(
            image: true,
            label: '${cur.id.label[0]}${cur.id.label.substring(1).toLowerCase()} card, ${_format.name}',
            child: DecoratedBox(
              decoration: BoxDecoration(border: Border.all(color: CineColors.rule2)),
              child: Stack(alignment: Alignment.center, children: [
                if (_bytes != null) Opacity(opacity: _rendering ? 0.4 : 1, child: Image.memory(_bytes!, fit: BoxFit.contain, gaplessPlayback: true)),
                if (_rendering) const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 1.5, color: CineColors.spot)),
              ],),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _SlugLine(
          labels: [for (final x in _templates) x.id.label],
          index: _index.clamp(0, _templates.length - 1),
          onSelect: (i) {
            if (i == _index) return;
            setState(() => _index = i);
            _preview();
          },
        ),
        const SizedBox(height: 12),
        _FormatControl(
          format: _format,
          onChanged: (f) {
            if (f == _format) return;
            setState(() => _format = f);
            _preview();
          },
        ),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: KeyedSubtree(key: _shareKey, child: CineButton('Share', loading: _rendering, onPressed: _rendering ? null : _share))),
          if (_canSave ?? false) ...[
            const SizedBox(width: 8),
            Expanded(child: CineButton('Save image', kind: CineButtonKind.secondary, onPressed: _rendering ? null : _save)),
          ],
        ],),
        if (widget.onReadNumbers != null) ...[
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerLeft, child: CineButton('Read the numbers', kind: CineButtonKind.quiet, onPressed: widget.onReadNumbers)),
        ],
        if (widget.inline) SizedBox(height: 4, child: CineText('', t.typeMicro)),
      ],),
    );
  }
}

/// The template slug line (7.5): a single-select of the available templates, the
/// underline sliding 320 ms on `settle`; every entry is 44 / 48 tall.
class _SlugLine extends StatelessWidget {
  const _SlugLine({required this.labels, required this.index, required this.onSelect});
  final List<String> labels;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) CineText(' · ', t.typeKicker, color: CineColors.ink30),
          Semantics(
            button: true,
            selected: i == index,
            label: labels[i],
            excludeSemantics: true,
            onTap: () => onSelect(i),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelect(i),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minHit(context), minWidth: minHit(context)),
                child: Center(
                  widthFactor: 1,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    CineText(labels[i], t.typeKicker, color: i == index ? CineColors.ink100 : CineColors.ink60, excludeSemantics: true),
                    const SizedBox(height: 4),
                    AnimatedContainer(duration: CineDur.column, curve: CineCurves.settle, height: 2, width: i == index ? 24 : 0, color: CineColors.spot),
                  ],),
                ),
              ),
            ),
          ),
        ],
      ],),
    );
  }
}

/// `STORY | POST`, 40 px (7.5).
class _FormatControl extends StatelessWidget {
  const _FormatControl({required this.format, required this.onChanged});
  final ShareFormat format;
  final ValueChanged<ShareFormat> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.cine;
    Widget seg(ShareFormat f, String label) => Expanded(
          child: Semantics(
            button: true,
            selected: format == f,
            label: label,
            excludeSemantics: true,
            onTap: () => onChanged(f),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(f),
              child: Container(
                constraints: BoxConstraints(minHeight: minHit(context)),
                alignment: Alignment.center,
                color: format == f ? CineColors.paper4 : Colors.transparent,
                child: CineText(label, t.typeKicker, color: format == f ? CineColors.ink100 : CineColors.ink60, excludeSemantics: true),
              ),
            ),
          ),
        );
    return Container(
      decoration: BoxDecoration(border: Border.all(color: CineColors.rule2)),
      child: Row(children: [seg(ShareFormat.story, 'STORY'), Container(width: 1, height: 40, color: CineColors.rule2), seg(ShareFormat.post, 'POST')]),
    );
  }
}
