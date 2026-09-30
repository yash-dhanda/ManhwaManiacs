import 'package:flutter/material.dart';
import 'package:manhwamaniacs/skins/cinematic/primitives/ambient_scope.dart';
import 'package:manhwamaniacs/skins/cinematic/tint.dart';

/// The series' ambient roles on the shared [CineAmbient] scope (800 ms dissolve).
/// The series payload carries no `ambient` yet, so a stable hue is derived from the series key.
AmbientRoles seriesAmbient(String key) {
  var h = 0;
  for (final u in key.codeUnits) {
    h = (h * 31 + u) & 0x7fffffff;
  }
  final hue = (h % 360).toDouble();
  Color hsl(double s, double l) => HSLColor.fromAHSL(1, hue, s, l).toColor();
  return AmbientRoles(duo: hsl(0.35, 0.16), tint: hsl(0.30, 0.09), ink: hsl(0.45, 0.78));
}

/// [CineAmbient] plus a builder that reads the running (dissolving) colours. It mounts on the
/// neutral fallback and takes the series colours one frame later, so the page opens with the
/// 800 ms wash (the shared scope only animates changes).
class SeriesAmbient extends StatefulWidget {
  const SeriesAmbient({super.key, required this.seriesKey, required this.builder});
  final String seriesKey;
  final Widget Function(BuildContext context, ({Color duo, Color tint, Color ink}) colors) builder;

  @override
  State<SeriesAmbient> createState() => _SeriesAmbientState();
}

class _SeriesAmbientState extends State<SeriesAmbient> {
  bool _on = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _on = true);
    });
  }

  @override
  Widget build(BuildContext context) => CineAmbient(
        ambient: _on ? seriesAmbient(widget.seriesKey) : null,
        child: Builder(builder: (c) => widget.builder(c, CineAmbient.of(c))),
      );
}
