/// `?sheet=player` (glass 8.16.2, E1-E3): the full player, grown out of the listen row or the accessory. Phones and tablets: a sheet
/// with detents `medium` (52 %) and `large` (adds the sentence list), T5 glass cross-fading to `solid2` by position (`monolith`);
/// the desktop frame: a 560 px T5 window (radius 32, up to 88 % of the window) blooming from the desktop accessory.
library;

import 'package:manhwamaniacs/skins/glass/frame.dart';
import 'package:manhwamaniacs/skins/glass/listen/glass_narration_host.dart';
import 'package:manhwamaniacs/skins/glass/listen/player_column.dart';
import 'package:manhwamaniacs/skins/glass/listen/player_more.dart';
import 'package:manhwamaniacs/skins/glass/routes/glass_sheet_route.dart';
import 'package:manhwamaniacs/skins/glass/routes/sheet_registry.dart';

final GlassSheetSpec glassPlayerSheetSpec = GlassSheetSpec(
  title: 'Now narrating',
  builder: (context) => GlassPlayerColumn(form: GlassFrame.of(context) == GlassFrameKind.phone ? PlayerForm.sheet : PlayerForm.window),
  detents: const [GlassDetent.medium, GlassDetent.large],
  opening: GlassDetent.medium,
  material: GlassSheetMaterial.monolith,
  origin: () => glassPlayerOrigin,
  trailing: const GlassPlayerMore(),
);

void registerPlayerSheet() => registerGlobalSheet('player', glassPlayerSheetSpec);
