/// The `g` chord targets of glass 8.0.6, and the pure machine that resolves them within a 1 s window.
const Map<String, String> gGlassTargets = {
  'h': '/',
  'l': '/library',
  'b': '/library/browse',
  's': '/sources',
  'u': '/updates',
  'd': '/downloads',
  'c': '/circle',
  't': '/library/statistics',
  'f': '/library/recommendations',
  'p': '/profiles',
  ',': '/settings',
};

const int kGWindowMs = 1000;

sealed class GlassGEffect {
  const GlassGEffect();
}

/// The key is not the sequence's.
class GlassGIgnored extends GlassGEffect {
  const GlassGIgnored();
}

/// The sequence armed or swallowed the key.
class GlassGConsumed extends GlassGEffect {
  const GlassGConsumed();
}

class GlassGJump extends GlassGEffect {
  const GlassGJump(this.location);
  final String location;
}

/// `g` arms for 1 s; a target key jumps; any other key or the timeout cancels. Time is passed in, so tests need no clock.
class GlassGSequence {
  int? _armedAt;

  bool get armed => _armedAt != null;

  /// Cancels an expired arm; call before [key].
  void tick(int nowMs) {
    if (_armedAt != null && nowMs - _armedAt! > kGWindowMs) _armedAt = null;
  }

  /// [character] is the typed character (lower case); [textFocus] true while a text field has focus.
  GlassGEffect key(String character, int nowMs, {bool textFocus = false}) {
    if (textFocus) {
      _armedAt = null;
      return const GlassGIgnored();
    }
    tick(nowMs);
    if (_armedAt == null) {
      if (character == 'g') {
        _armedAt = nowMs;
        return const GlassGConsumed();
      }
      return const GlassGIgnored();
    }
    _armedAt = null;
    final target = gGlassTargets[character];
    return target == null ? const GlassGConsumed() : GlassGJump(target);
  }
}
