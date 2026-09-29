import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/app/theme/app_colors.dart';
import 'package:manhwamaniacs/features/settings/providers/settings_provider.dart';
import 'package:manhwamaniacs/skins/cinematic/tokens.g.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';
import 'package:manhwamaniacs/skins/skin.dart';
import 'package:manhwamaniacs/skins/skin_audio.dart';
import 'package:manhwamaniacs/skins/skin_haptics.dart';
import 'package:manhwamaniacs/skins/token_types.g.dart';

/// Debug: feel and hear both skins' haptic and sound vocabularies on this
/// device, independent of the running skin. Legacy UI folder; goes with legacy.
class FeedbackLabScreen extends ConsumerStatefulWidget {
  const FeedbackLabScreen({super.key, this.driver, this.audio});

  /// Tests inject a recording driver / audio.
  final HapticsDriver? driver;
  final SkinAudio? audio;

  @override
  ConsumerState<FeedbackLabScreen> createState() => _FeedbackLabScreenState();
}

class _FeedbackLabScreenState extends ConsumerState<FeedbackLabScreen> {
  SkinId _skin = SkinId.cinematic;
  bool _sounds = false;
  String? _category;

  Map<HapticEvent, List<HapticStep>> get _map =>
      _skin == SkinId.glass ? glassHaptics : cinematicHaptics;

  Future<void> _play(HapticEvent e) async {
    await SkinHaptics(
            skin: _skin, map: _map, enabled: true, driver: widget.driver,)
        .fire(e, velocity: 2000, depth: 3);
    if (_sounds) {
      for (final s in SoundEvent.values) {
        if (s.id == e.id) {
          await (widget.audio ?? SkinAudio.instance)
              .preview(_skin, s, depth: 3);
        }
      }
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        final c = await const MethodChannel('mm/platform')
            .invokeMethod<String>('audio.category');
        if (mounted) setState(() => _category = c);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = [
      for (final e in HapticEvent.values)
        if ((_map[e] ?? const []).any((s) => s.pattern != 'none')) e,
    ];
    final on = ref.watch(hapticFeedbackProvider);
    const mono = TextStyle(fontFamily: 'monospace', fontSize: 13);
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback lab')),
      body: FocusTraversalGroup(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Semantics(
              label: 'Skin',
              container: true,
              child: SegmentedButton<SkinId>(
                showSelectedIcon: false,
                style: const ButtonStyle(
                  tapTargetSize: MaterialTapTargetSize.padded,
                  minimumSize: WidgetStatePropertyAll(Size(120, 44)),
                ),
                segments: const [
                  ButtonSegment(
                      value: SkinId.cinematic, label: Text('CINEMATIC'),),
                  ButtonSegment(value: SkinId.glass, label: Text('GLASS')),
                ],
                selected: {_skin},
                onSelectionChanged: (s) => setState(() => _skin = s.first),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Play sounds'),
              subtitle: const Text('This screen only'),
              value: _sounds,
              onChanged: (v) => setState(() => _sounds = v),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Haptics switch: ${on ? 'on' : 'off'}',
                style: TextStyle(color: context.colors.muted),
              ),
            ),
            if (_category != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Audio session category: $_category',
                  style: TextStyle(color: context.colors.muted),
                ),
              ),
            const SizedBox(height: 8),
            for (final e in events)
              MergeSemantics(
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.id),
                            Text(_map[e]!.map((s) => s.pattern).join(' → '),
                                style: mono,),
                          ],
                        ),
                      ),
                    ),
                    SizedBox.square(
                      dimension: 48,
                      child: IconButton(
                        tooltip: 'Play ${e.id}',
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () => _play(e),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
