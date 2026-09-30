import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/glass/icons/glass_glyphs.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs_more.dart';

/// The situations that get an object lens (glass 7.24), so no screen invents a glyph.
enum LensSituation {
  library,
  shelf,
  collection,
  bookmarks,
  history,
  nothingFound,
  dialogueIdle,
  noRecapSource,
  noUpdates,
  caughtUp,
  nothingDownloaded,
  offline,
  loadError,
  serverUnreachable,
  unavailable,
  circleQuiet,
  adminOnly,
  notFound,
  aiUnavailable,
  readerLanding,
  noProfile,
}

/// The Phosphor Light glyph of each situation (the custom ones are drawn from `GlassGlyphs`).
IconData lensGlyph(LensSituation s) => switch (s) {
      LensSituation.library || LensSituation.shelf => GlassGlyph28.books.light,
      LensSituation.collection => GlassGlyph28.stack.light,
      LensSituation.bookmarks => GlassGlyph28.bookmarkSimple.light,
      LensSituation.history => GlassGlyph28.clockCounterClockwise.light,
      LensSituation.nothingFound => GlassGlyph28.magnifyingGlass.light,
      LensSituation.dialogueIdle || LensSituation.noRecapSource => GlassGlyphs.bubbleSearchRegular,
      LensSituation.noUpdates => GlassGlyph28.bellSimple.light,
      LensSituation.caughtUp => GlassGlyph28.checkCircle.light,
      LensSituation.nothingDownloaded => GlassGlyph28.cloudArrowDown.light,
      LensSituation.offline => GlassGlyph28.wifiSlash.light,
      LensSituation.loadError => GlassGlyph28.warningCircle.light,
      LensSituation.serverUnreachable => GlassGlyph28.cloudSlash.light,
      LensSituation.unavailable => GlassGlyph28.eyeSlash.light,
      LensSituation.circleQuiet => GlassGlyph28.usersThree.light,
      LensSituation.adminOnly => GlassGlyph28.shield.light,
      LensSituation.notFound => GlassGlyph28.question.light,
      LensSituation.aiUnavailable => GlassGlyphs.sparkleSlashRegular,
      LensSituation.readerLanding => GlassGlyphs.stripScrollRegular,
      LensSituation.noProfile => GlassGlyph28.userCircle.light,
    };

/// `aiUnavailable` draws in `label2`, not the tone colour (a missing AI answer is not an error).
bool lensGlyphIsNeutral(LensSituation s) => s == LensSituation.aiUnavailable;
