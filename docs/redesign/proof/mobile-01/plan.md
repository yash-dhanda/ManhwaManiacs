# mobile/01 plan

Slices, in order: (A) skin types, skeleton skins, pending screen and routes; (B) SkinBoot, AppRestart, SkinApp, switch and timing, boot check; (C) Profile.skin, repository param, skin outbox, gate flush; (D) Diagnostics "Edition (debug)" row; (E) tests and the predictive-back manifest flag.
Baseline before any change: 2046 tests passed, 0 failed.
Deviation from the prompt's file layout: `lib/skins/pending_routes.dart` holds the shared route builder and the alias map so both skin routers stay one literal `PENDING` set each; `SkinMirror` is public (a private enum in a public signature trips the lints).
