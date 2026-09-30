import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:manhwamaniacs/skins/cinematic/motion.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/cinematic/type.dart';

const int kPreviewFrames = 36;
const int kPreviewFps = 6;

/// `assets/skin_previews/{skin}/007.png`.
String previewFramePath(String skin, int i) => 'assets/skin_previews/$skin/${i.toString().padLeft(3, '0')}.png';

/// The edition preview: a bundled 36-frame PNG loop at 6 fps (6 s). All frames are pre-cached on
/// first build; the ticker runs only while its route is on screen (a `TickerMode` gate), and
/// reduced motion shows frame 000 only. Frames the bundle does not have yet show [missing].
class PreviewLoop extends StatefulWidget {
  const PreviewLoop({super.key, required this.skin, this.missing = ''});

  /// The folder under `assets/skin_previews/`.
  final String skin;

  /// The caption on the empty plate when the frames are not bundled.
  final String missing;

  @override
  State<PreviewLoop> createState() => _PreviewLoopState();
}

class _PreviewLoopState extends State<PreviewLoop> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  int _frame = 0;
  bool _cached = false, _reduced = false;

  void _tick(Duration elapsed) {
    final f = (elapsed.inMilliseconds * kPreviewFps ~/ 1000) % kPreviewFrames;
    if (f != _frame) setState(() => _frame = f);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = CineMotion.reduced(context);
    if (!_cached) {
      _cached = true;
      for (var i = 0; i < kPreviewFrames; i++) {
        precacheImage(AssetImage(previewFramePath(widget.skin, i)), context, onError: (_, __) {});
      }
    }
    if (_reduced) {
      _ticker.stop();
      _frame = 0;
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cine;
    return Image.asset(
      previewFramePath(widget.skin, _frame),
      key: Key('preview-frame-${widget.skin}'),
      fit: BoxFit.cover,
      gaplessPlayback: true,
      excludeFromSemantics: true,
      errorBuilder: (_, __, ___) => ColoredBox(
        color: c.colorPaper1,
        child: widget.missing.isEmpty
            ? null
            : Center(child: Padding(padding: EdgeInsets.all(c.space3), child: CineRoleText(widget.missing, c.typeCaption, color: c.colorInk60, textAlign: TextAlign.center))),
      ),
    );
  }

  @visibleForTesting
  int get frame => _frame;
}
