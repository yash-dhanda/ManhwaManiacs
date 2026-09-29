import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'gallery_host.dart';

void main() {
  testWidgets('the section 7 semantics rows for the controls of this step', (t) async {
    final h = t.ensureSemantics();
    await pumpGallery(t);
    SemanticsNode node(String label) => t.getSemantics(find.bySemanticsLabel(label).first);

    // Slug lines: single-select is a mutually exclusive group with checked; multi-select a toggle button.
    expect(node('Reading, 12'), isSemantics(isInMutuallyExclusiveGroup: true, hasCheckedState: true, isChecked: true));
    expect(node('Plan, 5'), isSemantics(isInMutuallyExclusiveGroup: true, hasCheckedState: true, isChecked: false));
    expect(node('Romance'), isSemantics(isButton: true, hasToggledState: true, isToggled: true));
    expect(node('Fantasy'), isSemantics(isButton: true, hasToggledState: true, isToggled: false));

    // Tri-state filter value strings.
    expect(t.getSemantics(find.byKey(const Key('g-tri-neutral'))), isSemantics(isButton: true, value: 'Romance: not filtered'));
    expect(t.getSemantics(find.byKey(const Key('g-tri-include'))), isSemantics(isButton: true, value: 'Action: included'));
    expect(t.getSemantics(find.byKey(const Key('g-tri-exclude'))), isSemantics(isButton: true, value: 'Horror: excluded'));

    // Download marks.
    for (final (key, label) in [
      ('saved', 'Saved'),
      ('queued', 'Queued'),
      ('downloading', 'Downloading, 30 percent'),
      ('failed', 'Failed, tap to retry'),
      ('paused', 'Paused'),
      ('stale', 'Saved copy is out of date, download again'),
      ('notDownloaded', 'Not downloaded'),
    ]) {
      expect(t.getSemantics(find.byKey(Key('g-download-$key'))), isSemantics(isButton: true, label: label), reason: key);
    }

    // Progress value, badge certificate, search field.
    expect(find.bySemanticsLabel('Mature, 18 plus'), findsWidgets);
    expect(node('Search every source'), isSemantics(isTextField: true, label: 'Search every source'));
    expect(node('Search or jump'), isSemantics(isTextField: true, label: 'Search or jump'));
    expect(node('Ember Ledger, Favourite'), isNotNull, reason: 'favourited posters say so');
    expect(find.bySemanticsLabel('Number 3, Night Ward'), findsOneWidget);
    h.dispose();
  });

  testWidgets('a rule progress reports its percentage', (t) async {
    final h = t.ensureSemantics();
    await pumpGallery(t, section: 'progress');
    expect(find.semantics.byValue('63 percent'), findsOneWidget);
    h.dispose();
  });
}
