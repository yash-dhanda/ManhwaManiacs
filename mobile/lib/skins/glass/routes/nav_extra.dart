import 'package:flutter/widgets.dart';

enum GlassPresentation { sheet, page }

/// `context.push(location, extra: GlassNavExtra(...))` opens a sheet route as a sheet; a location reached with no extra (a deep link,
/// a cold start, the return route) renders the screen as a full page (glass 8.0.3).
@immutable
class GlassNavExtra {
  const GlassNavExtra({this.presentation = GlassPresentation.sheet, this.originRect, this.velocity});
  final GlassPresentation presentation;

  /// The trigger's global rect: the sheet or window grows out of it.
  final Rect? originRect;

  /// The throw's release velocity in px/s (a poster thrown into the sheet), if any.
  final Offset? velocity;
}
