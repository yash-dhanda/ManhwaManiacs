import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_sheet_route.dart';

/// A sheet that opens from `?sheet={id}` on any route (glass 8.0.3): its title, body and forms.
class GlassSheetSpec {
  const GlassSheetSpec({required this.title, required this.builder, this.detents = const [GlassDetent.large], this.opening, this.wideForm = GlassWideForm.window});
  final String title;
  final WidgetBuilder builder;
  final List<GlassDetent> detents;
  final GlassDetent? opening;
  final GlassWideForm wideForm;
}

final Map<String, GlassSheetSpec> _specs = {};
final Map<String, int> _claims = {};

/// Registers the global sheet [id]. `mobile/29` registers `shortcuts`, `whats-new` and `app-update`; later steps register theirs.
void registerGlobalSheet(String id, GlassSheetSpec spec) => _specs[id] = spec;

GlassSheetSpec? glassSheetSpec(String id) => _specs[id];

bool glassSheetRegistered(String id) => _specs.containsKey(id);

/// A screen that renders sheet [id] itself claims it so the host does not also push it. Returns the release.
VoidCallback glassClaimSheet(String id) {
  _claims[id] = (_claims[id] ?? 0) + 1;
  return () {
    final n = (_claims[id] ?? 1) - 1;
    if (n <= 0) {
      _claims.remove(id);
    } else {
      _claims[id] = n;
    }
  };
}

bool glassSheetClaimed(String id) => (_claims[id] ?? 0) > 0;
