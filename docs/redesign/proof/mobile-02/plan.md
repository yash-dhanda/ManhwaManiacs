# mobile/02 plan (lane L01)

Order: A dependency commit (pubspec, lock, tests.yml, pub-deps) alone -> B audio_service wiring -> C mm/platform + skin_haptics -> D skin_audio + assets -> E feedback lab + tests -> proof.

CI gate: between A and every commit that imports a new package, and after B and C, the owner's integrator pushes and reads `android-apk` and `build-ios`. This lane may not push (lane override), so the gate is recorded in dependency-gate.md as PENDING at the integrator; commit order guarantees A precedes every consumer.
