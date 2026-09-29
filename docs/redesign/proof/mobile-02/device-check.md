# mobile/02 owner device checklist

Feedback lab: Settings > Diagnostics > Feedback lab (debug).

- CINEMATIC: tap.primary (impress), follow.add (stamp), reader.enter (wipe), streak.milestone (ignite, then stamp 520 ms later), chapter.complete (medium, then light) feel distinct.
- GLASS: nav.push (rise3), threshold.cross (rigid 0.6), motion.catch (soft, capped), profile.select (droplet) feel crisp and light.
- Android with system haptics off: nothing vibrates.
- "Play sounds" on: Cinematic tap.primary plays set; Glass nav.push plays push-3.
- iOS: "Audio session category" reads AVAudioSessionCategoryAmbient after the first sound; the ring/silent switch mutes cues.
- Start a narration in a novel, lock the phone: it keeps playing (State B); music apps pause as before.
- Android: back out from the Library root and reopen: it opens normally (AudioServiceActivity caches the engine; note whether it resumes or cold-starts).
- Proof shot note: the monospace pattern text renders as boxes in the test harness only (no monospace font loaded in tests).
