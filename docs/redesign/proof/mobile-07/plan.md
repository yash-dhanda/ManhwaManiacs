# mobile/07 plan

Order followed: (1) data layer, no pixels: profile fields, session-end reasons, server check, mature predicate and gate provider, v4 stamps on every device store, the stamper, filtered local reads, a queue that follows the gate; (2) shared auth layout and copy maps; (3) Setup, Login, Register; (4) picker with the Iris, profile form, Manage profiles; (5) the 18+ switch (settings and form mode) and the rating card; (6) gallery `auth` section, widget tests, the end-to-end gate test, the `mobile-07` screenshot group; (7) checklists and report.

Decisions: pure decision functions (`decidePickerOutcome`, `decideEditionSave`, copy maps, descriptors) are unit-tested first; screens use mobile/04-06 primitives only; per-screen states that need time or a tap are captured by scripted interaction over fixture providers.
