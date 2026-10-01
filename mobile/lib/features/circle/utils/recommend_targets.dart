import 'package:manhwamaniacs/features/circle/models/circle_models.dart';

/// Who the recommend sheet lists (glass 9.3.4).
class RecommendTargets {
  const RecommendTargets({this.selectable = const [], this.disabled = const []});

  /// Members the server marks `can_receive: true`.
  final List<CircleMember> selectable;

  /// Members with `shares.recommendations` off ("{name} isn't taking recommendations").
  final List<CircleMember> disabled;
}

/// Members who take recommendations but cannot receive this series (its 18+ gate) are omitted, never explained.
RecommendTargets recommendTargets(List<CircleMember> ms) => RecommendTargets(
      selectable: [for (final m in ms) if (m.shares.recommendations && (m.canReceive ?? false)) m],
      disabled: [for (final m in ms) if (!m.shares.recommendations) m],
    );
