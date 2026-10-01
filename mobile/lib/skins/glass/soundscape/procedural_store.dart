import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:manhwamaniacs/skins/glass/soundscape/generator.dart';
import 'package:manhwamaniacs/skins/glass/soundscape/mixer.dart';
import 'package:manhwamaniacs/skins/glass/soundscape/recipes.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// The built-in layers on disk (glass 9.4.2 Playback engines): the first render of a loop writes its WAV to
/// `soundscapes/glass/procedural/{scene}-{layer}-v1.wav` (and its envelope beside it); later starts read the bytes. The render runs
/// in a background isolate and only when the file is missing.
class ProceduralStore {
  ProceduralStore({Future<Directory> Function()? root}) : _root = root ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _root;
  final Map<SoundScene, Future<SceneAssets>> _memo = {};

  Future<File> _wav(SoundScene s, SoundLayer l) async => File(p.join((await _root()).path, 'soundscapes', 'glass', 'procedural', '${s.name}-${l.name}-v1.wav'));

  /// The scene's loops, event banks and envelopes, ready for `loadMem`.
  Future<SceneAssets> assets(SoundScene s) => _memo[s] ??= _load(s);

  Future<SceneAssets> _load(SoundScene s) async {
    final loops = <SoundLayer, Uint8List>{};
    final envelopes = <SoundLayer, Float32List>{};
    final banks = <SoundLayer, List<Uint8List>>{};
    for (final l in SoundLayer.values) {
      final kind = kRecipes[s]![l]!;
      if (kind == LayerKind.loop) {
        final f = await _wav(s, l);
        final env = File('${f.path}.env');
        if (f.existsSync() && f.lengthSync() == 44 + kLoopSamples * 2 && env.existsSync() && env.lengthSync() == kEnvelopeLength * 4) {
          loops[l] = await f.readAsBytes();
          final b = await env.readAsBytes();
          envelopes[l] = Float32List.sublistView(Uint8List.fromList(b));
        } else {
          final r = await renderLoopInIsolate(s, l);
          loops[l] = r.wav;
          envelopes[l] = r.envelope;
          try {
            await f.parent.create(recursive: true);
            final tmp = File('${f.path}.part');
            await tmp.writeAsBytes(r.wav, flush: true);
            await env.writeAsBytes(r.envelope.buffer.asUint8List(), flush: true);
            await tmp.rename(f.path);
          } catch (_) {
            // A read-only or full disk only costs the next start a render.
          }
        }
      } else if (kind == LayerKind.events) {
        banks[l] = [for (final b in renderEventBank(s)) wavBytes(b)];
      }
    }
    return SceneAssets(loops: loops, banks: banks, envelopes: envelopes);
  }

  /// Renders the remaining scenes one at a time (when the soundscape sheet opens).
  Future<void> prewarmAll() async {
    for (final s in SoundScene.values) {
      await assets(s);
    }
  }
}
