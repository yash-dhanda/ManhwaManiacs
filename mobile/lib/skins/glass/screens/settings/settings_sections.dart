import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:manhwamaniacs/skins/contract.g.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs.dart';
import 'package:manhwamaniacs/skins/glass/primitives/glyphs_more.dart';
import 'package:manhwamaniacs/skins/glass/screens/settings/settings_glyphs.dart';
import 'package:manhwamaniacs/skins/glass/tokens.g.dart';

/// Sections `mobile/40` builds: their rows and index entries exist, opening one renders the skin's pending body until `mobile/40`
/// empties this set (glass 8.25).
const Set<SettingsSection> sectionsBuiltLater = {
  SettingsSection.notifications,
  SettingsSection.security,
  SettingsSection.members,
  SettingsSection.backup,
  SettingsSection.server,
  SettingsSection.diagnostics,
  SettingsSection.admin,
};

/// One row of the Settings root (glass 8.24 order).
class SettingsSectionSpec {
  const SettingsSectionSpec(this.section, this.label, this.glyph, this.tile, {this.admin = false, this.appsOnly = false, this.needsKeyboard = false});
  final SettingsSection section;
  final String label;
  final Glyph glyph;
  final Color tile;
  final bool admin, appsOnly, needsKeyboard;
}

/// Tile colours are this step's choice (glass 8.25 says only "the section's colour"): brand iris for the three main groups,
/// `surface3` for the rest and `danger` for Notifications. White on each is at least 3:1 (icon_tile_test).
const List<SettingsSectionSpec> kSettingsSections = [
  SettingsSectionSpec(SettingsSection.appearance, 'Appearance and skin', SettingsGlyphs.paintBrush, GlassColors.iris600),
  SettingsSectionSpec(SettingsSection.readingManga, 'Reader', SettingsGlyphs.bookOpen, GlassColors.iris700),
  SettingsSectionSpec(SettingsSection.content, 'Content (18+)', SettingsGlyphs.shieldWarning, GlassColors.surface3),
  SettingsSectionSpec(SettingsSection.circle, 'Circle and privacy', GlassGlyph28.usersThree, GlassColors.surface3),
  SettingsSectionSpec(SettingsSection.ai, 'AI and recaps', GlassGlyph28.sparkle, GlassColors.surface3),
  SettingsSectionSpec(SettingsSection.feedback, 'Sound and haptics', SettingsGlyphs.speakerHigh, GlassColors.iris800),
  SettingsSectionSpec(SettingsSection.notifications, 'Notifications', GlassGlyph28.bellSimple, GlassColors.danger, admin: true),
  SettingsSectionSpec(SettingsSection.security, 'Security', SettingsGlyphs.lockSimple, GlassColors.surface3),
  SettingsSectionSpec(SettingsSection.storage, 'Storage', SettingsGlyphs.hardDrives, GlassColors.surface3),
  SettingsSectionSpec(SettingsSection.backup, 'Backup', SettingsGlyphs.cloudArrowUp, GlassColors.surface3, admin: true),
  SettingsSectionSpec(SettingsSection.server, 'Server', SettingsGlyphs.plugsConnected, GlassColors.surface3, appsOnly: true),
  SettingsSectionSpec(SettingsSection.diagnostics, 'Diagnostics', SettingsGlyphs.pulse, GlassColors.surface3),
  SettingsSectionSpec(SettingsSection.keyboard, 'Shortcuts', SettingsGlyphs.keyboard, GlassColors.surface3, needsKeyboard: true),
];

const SettingsSectionSpec kAboutSection = SettingsSectionSpec(SettingsSection.about, 'About', SettingsGlyphs.info, GlassColors.surface3);

/// The sections that show in the root for this platform, role and input state.
List<SettingsSectionSpec> visibleSettingsSections({required TargetPlatform platform, required bool admin, required bool keyboardSeen, required bool wide}) => [
      for (final s in kSettingsSections)
        if ((!s.admin || admin) && (!s.appsOnly || platform == TargetPlatform.android || platform == TargetPlatform.iOS) && (!s.needsKeyboard || (wide && keyboardSeen))) s,
    ];

/// Reader groups share one page: these slugs open Reader defaults scrolled to that group.
const Set<SettingsSection> readerGroupSections = {SettingsSection.readingManga, SettingsSection.readingNovels, SettingsSection.listen, SettingsSection.ambient};

/// The composite contrast ratio of [a] over [b] (WCAG), for the tile contrast test.
double contrastRatio(Color a, Color b) {
  double lum(Color c) {
    double ch(double v) => v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
  }

  final l1 = lum(a), l2 = lum(b);
  final hi = l1 > l2 ? l1 : l2, lo = l1 > l2 ? l2 : l1;
  return (hi + 0.05) / (lo + 0.05);
}

