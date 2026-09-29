import 'package:flutter/widgets.dart';

final Map<int, List<double>> _matrices = {};

/// The 20-number matrix that maps luminance onto black -> [duo] (cinematic 2.1.5, sRGB arithmetic).
List<double> duotoneMatrix(Color duo) => _matrices.putIfAbsent(duo.toARGB32(), () {
      List<double> row(double d) => [d * 0.2126, d * 0.7152, d * 0.0722, 0, 0];
      return List.unmodifiable([...row(duo.r), ...row(duo.g), ...row(duo.b), 0, 0, 0, 1, 0]);
    });

class CineDuotone extends StatelessWidget {
  const CineDuotone({super.key, required this.duo, required this.child});
  final Color duo;
  final Widget child;

  @override
  Widget build(BuildContext context) => ColorFiltered(colorFilter: ColorFilter.matrix(duotoneMatrix(duo)), child: child);
}
