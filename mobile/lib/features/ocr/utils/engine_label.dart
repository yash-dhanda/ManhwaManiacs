/// `VISION`, `ML KIT`, else the engine upper-cased, `—` for null.
String engineLabel(String? engine) {
  if (engine == null || engine.isEmpty) return '—';
  final e = engine.toLowerCase();
  if (e == 'vision' || e == 'apple_vision' || e == 'apple-vision') {
    return 'VISION';
  }
  if (e == 'mlkit' || e == 'ml_kit' || e == 'ml-kit') return 'ML KIT';
  return engine.toUpperCase();
}
