import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/novels/controllers/narration_controller.dart';
import 'package:manhwamaniacs/features/novels/models/novel_audio.dart';

/// The legacy skin's bar over the app's [NarrationController], the clock the highlight follows.
///
/// Playback itself (streaming with the bearer token, the saved copy, speed, the audio session, the
/// lock screen) lives in the controller, which both skins share. This widget only draws it and
/// reports the playhead: [onPosition] fires on every tick as a raw millisecond count and the
/// reader does its own lookup, so nothing here decides how a chapter is drawn.
///
/// A narration saved on the phone plays from [NarrationTarget.file] with no network and no token:
/// that is what makes a chapter listenable on a plane.
class NovelAudioPlayerBar extends ConsumerStatefulWidget {
  const NovelAudioPlayerBar({
    required this.target,
    required this.onPosition,
    required this.muted,
    required this.rule,
    super.key,
  });

  /// The chapter to read aloud.
  final NarrationTarget target;

  NovelAudio get audio => target.audio;

  /// Playhead position, or null when nothing is playing.
  final ValueChanged<int?> onPosition;

  final Color muted;
  final Color rule;

  @override
  ConsumerState<NovelAudioPlayerBar> createState() => _NovelAudioPlayerBarState();
}

class _NovelAudioPlayerBarState extends ConsumerState<NovelAudioPlayerBar> {
  late final NarrationController _ctl = ref.read(narrationControllerProvider.notifier);
  bool _reported = false;

  static const _speeds = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  @override
  void initState() {
    super.initState();
    _ctl.position.addListener(_onPosition);
    ref.listenManual<NarrationState>(narrationControllerProvider, (prev, next) {
      _onPosition();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ctl.position.removeListener(_onPosition);
    final mine = _isMine(ref.read(narrationControllerProvider));
    // Releases the platform player. Left playing, the audio would outlive the reader, and on iOS
    // keep the audio session active and silence everything else on the phone.
    if (mine) {
      Future<void>.microtask(() async {
        try {
          await _ctl.stop();
        } catch (_) {}
      });
    }
    widget.onPosition(null);
    super.dispose();
  }

  bool _isMine(NarrationState s) => s.key == widget.target.key && s.target != null;

  /// The finish is reported as a position too, and it can land after the null the state listener
  /// sends for it. A finished player is not reading, whatever its playhead says.
  void _onPosition() {
    final s = ref.read(narrationControllerProvider);
    if (!_isMine(s) || s.status == NarrationStatus.completed || s.status == NarrationStatus.idle || s.status == NarrationStatus.failed) {
      if (_reported) {
        _reported = false;
        widget.onPosition(null);
      }
      return;
    }
    _reported = true;
    widget.onPosition(_ctl.position.value);
  }

  Future<void> _toggle() async {
    final s = ref.read(narrationControllerProvider);
    if (_isMine(s) && s.status != NarrationStatus.failed) {
      await _ctl.toggle();
    } else {
      await _ctl.start(widget.target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(narrationControllerProvider);
    final mine = _isMine(s);
    final total = Duration(milliseconds: widget.audio.totalMs);
    final playing = mine && s.isPlaying;
    final loading = mine && (s.status == NarrationStatus.loading || s.status == NarrationStatus.preparing);
    final failed = mine && s.status == NarrationStatus.failed;
    final speed = mine ? s.speed : ref.watch(narrationControllerProvider.select((x) => x.speed));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: widget.rule),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: loading ? null : _toggle,
            tooltip: failed
                ? 'Audio could not be loaded'
                : playing
                    ? 'Pause'
                    : 'Listen to this chapter',
            icon: Icon(
              failed
                  ? Icons.error_outline
                  : playing
                      ? Icons.pause
                      : Icons.play_arrow,
              color: widget.muted,
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<int>(
              valueListenable: _ctl.position,
              builder: (context, ms, _) {
                final at = mine ? ms : 0;
                return Slider(
                  value: at.clamp(0, widget.audio.totalMs).toDouble(),
                  max: (widget.audio.totalMs <= 0 ? 1 : widget.audio.totalMs).toDouble(),
                  onChanged: (value) {
                    final target = Duration(milliseconds: value.round());
                    if (mine) unawaited(_ctl.seek(target));
                    widget.onPosition(target.inMilliseconds);
                  },
                );
              },
            ),
          ),
          ValueListenableBuilder<int>(
            valueListenable: _ctl.position,
            builder: (context, ms, _) => Text(
              '${_clock(Duration(milliseconds: mine ? ms : 0))} / ${_clock(total)}',
              style: TextStyle(
                color: widget.muted,
                fontSize: 11,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<double>(
            value: _speeds.contains(speed) ? speed : 1.0,
            underline: const SizedBox.shrink(),
            isDense: true,
            style: TextStyle(color: widget.muted, fontSize: 12),
            items: _speeds
                .map(
                  (v) => DropdownMenuItem(
                    value: v,
                    child: Text('${v.toString().replaceAll('.0', '')}x'),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value == null) return;
              unawaited(_ctl.setSpeed(value));
            },
          ),
        ],
      ),
    );
  }
}

/// m:ss, and h:mm:ss only when there is an hour to show.
///
/// Truncates rather than rounds: rounding would read a second ahead of the
/// voice.
String _clock(Duration d) {
  final total = d.inSeconds < 0 ? 0 : d.inSeconds;
  final seconds = (total % 60).toString().padLeft(2, '0');
  final minutes = (total ~/ 60) % 60;
  final hours = total ~/ 3600;
  return hours > 0
      ? '$hours:${minutes.toString().padLeft(2, '0')}:$seconds'
      : '$minutes:$seconds';
}
