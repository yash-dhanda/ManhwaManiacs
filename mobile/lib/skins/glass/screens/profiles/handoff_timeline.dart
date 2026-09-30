/// Step into the light (glass 4.10, 8.5): the timeline of a profile pick, pure so it is a unit test. Times are ms from the tap.
enum HandoffEventKind { inflate, repel, titleFade, pour, flight, melt, landHaptic, dematerialiseOrb, restart, commit }

class HandoffEvent {
  const HandoffEvent(this.atMs, this.kind, {this.durationMs = 0});
  final int atMs;
  final HandoffEventKind kind;
  final int durationMs;

  @override
  String toString() => '$kind@$atMs+$durationMs';
}

abstract final class Handoff {
  /// The whole pick: the arrival or the restart lands here.
  static const int totalMs = 1100;

  /// The chosen orb leaves for the dock or sidebar (or the melt starts), unless the choice changed before.
  static const int flightAtMs = 450;

  /// The colour pour: the three blobs slide to the profile's colours.
  static const int pourMs = 600;
  static const int meltMs = 615;
  static const int flightMs = 558;
  static const int titleFadeMs = 120;
  static const int othersFadeMs = 350;
  static const int tailFadeMs = 300;
  static const int orbDematerialiseMs = 350;
  static const double inflateScale = 1.35;
  static const double repelSpeedPxPerS = 900;

  /// A tap on another orb changes the choice until the flight or the melt starts.
  static bool canInterrupt(int tMs) => tMs < flightAtMs;

  /// Home, or the onboarding step while the profile needs it.
  static String destination({required bool onboardingPending, required String tonight, required String onboarding}) => onboardingPending ? onboarding : tonight;

  /// The ordered events of a pick. A skin mismatch melts at 450 ms and restarts (no flight, no landing); otherwise the orb flies
  /// on `springZoom`, lands (`profile.select`) and the destination commits at 1,100 ms. Onboarding dematerialises the orb instead of
  /// the dock forming.
  static List<HandoffEvent> plan({required bool mismatch, bool onboarding = false}) => [
        const HandoffEvent(0, HandoffEventKind.inflate),
        const HandoffEvent(0, HandoffEventKind.repel, durationMs: othersFadeMs),
        const HandoffEvent(0, HandoffEventKind.titleFade, durationMs: titleFadeMs),
        const HandoffEvent(0, HandoffEventKind.pour, durationMs: pourMs),
        if (mismatch) ...[
          const HandoffEvent(flightAtMs, HandoffEventKind.melt, durationMs: meltMs),
          const HandoffEvent(flightAtMs + meltMs, HandoffEventKind.restart),
        ] else ...[
          const HandoffEvent(flightAtMs, HandoffEventKind.flight, durationMs: flightMs),
          const HandoffEvent(flightAtMs + flightMs, HandoffEventKind.landHaptic),
          if (onboarding) const HandoffEvent(totalMs, HandoffEventKind.dematerialiseOrb, durationMs: orbDematerialiseMs),
          const HandoffEvent(totalMs, HandoffEventKind.commit),
        ],
      ];

  /// The moment each kind first happens, or null.
  static int? at(List<HandoffEvent> plan, HandoffEventKind k) {
    for (final e in plan) {
      if (e.kind == k) return e.atMs;
    }
    return null;
  }
}

/// The events of [plan] that became due between [prevMs] (exclusive; -1 before the start) and [nowMs] (inclusive).
List<HandoffEvent> dueEvents(List<HandoffEvent> plan, int prevMs, int nowMs) => [
      for (final e in plan)
        if (e.atMs > prevMs && e.atMs <= nowMs) e,
    ];
