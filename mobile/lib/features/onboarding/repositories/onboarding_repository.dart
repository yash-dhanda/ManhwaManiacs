import 'package:manhwamaniacs/core/utils/result.dart';
import 'package:manhwamaniacs/features/onboarding/models/onboarding_catalog.dart';
import 'package:manhwamaniacs/features/onboarding/models/taste.dart';

/// Set from the backend probe: `GET /profiles/{id}/taste` exists (backend/05).
const bool kTasteReadable = true;

abstract class OnboardingRepository {
  Future<Result<OnboardingCatalog>> catalog({List<String> formats = const [], List<String> genres = const [], List<String> styles = const []});
  Future<Result<void>> saveTaste(int profileId, TasteUpdate body);

  /// Null when the server has no read endpoint (404 or 405).
  Future<Result<Taste?>> getTaste(int profileId);
}
