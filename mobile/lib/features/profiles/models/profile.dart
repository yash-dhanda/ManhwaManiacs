import 'package:manhwamaniacs/core/time/server_instant.dart';
import 'package:manhwamaniacs/features/onboarding/models/taste.dart';
import 'package:manhwamaniacs/features/profiles/models/mood.dart';

/// A per-user reading persona (Netflix-style). Mirrors the backend
/// `/profiles` serialisation 1-to-1. Immutable.
class Profile {
  const Profile({
    required this.id,
    required this.name,
    required this.avatarKey,
    required this.mood,
    required this.sortOrder,
    required this.matureContentEnabled,
    required this.createdAt,
    this.skin,
    this.onboardingStep,
    this.notifyEnabled = true,
    this.dailyGoalMinutes,
  });

  final int id;
  final String name;

  /// The profile's edition, `cinematic` or `glass`; null means the default.
  final String? skin;

  /// The onboarding step the profile stopped at; `"done"` once finished, null before it began.
  final String? onboardingStep;

  /// [onboardingStep] parsed (1 to 7, done, or null).
  OnboardingStep? get onboarding => OnboardingStep.parse(onboardingStep);
  final bool notifyEnabled;
  final int? dailyGoalMinutes;

  /// References an avatar in [kAvatarPresets]; may be null for legacy rows.
  final String? avatarKey;
  final Mood mood;
  final int sortOrder;

  /// Per-profile 18+ gate. Settable at create/edit since 1a.
  final bool matureContentEnabled;
  final DateTime createdAt;

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as int,
        name: json['name'] as String,
        avatarKey: json['avatar_key'] as String?,
        mood: Mood.fromWire(json['mood'] as String?),
        sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
        matureContentEnabled: json['mature_content_enabled'] as bool? ?? false,
        // Epoch rather than a throw (see `AuthUser.fromJson`): a profile the
        // device cannot date is still a profile it can switch to.
        createdAt: serverInstant(json['created_at']) ?? _epoch,
        skin: switch (json['skin']) {
          final String s when s == 'cinematic' || s == 'glass' => s,
          _ => null,
        },
        // The server sends 3, or "done", or null.
        onboardingStep: json['onboarding_step']?.toString(),
        notifyEnabled: json['notify_enabled'] as bool? ?? true,
        dailyGoalMinutes: (json['daily_goal_minutes'] as num?)?.toInt(),
      );

  /// Reduce to the lightweight snapshot persisted as the active selection.
  ActiveProfile toSnapshot() => ActiveProfile(
        id: id,
        name: name,
        avatarKey: avatarKey,
        mood: mood,
      );
}

/// Hard cap on profiles per account, enforced in the UI (matches the backend).
const int kMaxProfiles = 5;

/// The minimal snapshot of the active profile kept on-device (persisted to
/// shared preferences). Enough to tint the shell and label the switcher without
/// re-fetching the list on every screen.
class ActiveProfile {
  const ActiveProfile({
    required this.id,
    required this.name,
    required this.avatarKey,
    required this.mood,
  });

  final int id;
  final String name;
  final String? avatarKey;
  final Mood mood;

  factory ActiveProfile.fromJson(Map<String, dynamic> json) => ActiveProfile(
        id: json['id'] as int,
        name: json['name'] as String,
        avatarKey: json['avatar_key'] as String?,
        mood: Mood.fromWire(json['mood'] as String?),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatar_key': avatarKey,
        'mood': mood.wire,
      };
}

final DateTime _epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
