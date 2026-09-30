import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';

/// Fields the profile PATCH takes that `POST /profiles` does not: the skin, the daily goal and the order.
/// A `dailyGoal` of `(minutes: null)` means Off and is sent as an explicit JSON null; a null record leaves it untouched.
class ProfileExtras {
  const ProfileExtras({this.skin, this.dailyGoal, this.sortOrder});
  final String? skin;
  final ({int? minutes})? dailyGoal;
  final int? sortOrder;

  bool get isEmpty => skin == null && dailyGoal == null && sortOrder == null;

  Map<String, Object?> toJson() => {
        if (skin != null) 'skin': skin,
        if (dailyGoal != null) 'daily_goal_minutes': dailyGoal!.minutes,
        if (sortOrder != null) 'sort_order': sortOrder,
      };
}

/// What `createWithExtras` reports: the profile exists once [created] is set, even when the second call failed.
class CreateProfileOutcome {
  const CreateProfileOutcome({this.error, this.created, this.extrasFailed = false});
  final AppError? error;
  final Profile? created;
  final bool extrasFailed;
}
