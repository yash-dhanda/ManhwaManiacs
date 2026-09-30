import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/core/error/app_error.dart';
import 'package:manhwamaniacs/features/profiles/models/profile.dart';
import 'package:manhwamaniacs/features/profiles/providers/profiles_providers.dart';
import 'package:manhwamaniacs/shared/providers/core_providers.dart';

/// The active profile's `notify_enabled` master. Optimistic: the switch flips at once and is put
/// back when the `PATCH /profiles/{id}` fails (the error is returned for the row to show).
class NotifyEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    final id = ref.watch(activeProfileProvider.select((p) => p?.id));
    final profiles = ref.watch(profilesProvider).valueOrNull;
    return profiles?.where((p) => p.id == id).firstOrNull?.notifyEnabled ?? true;
  }

  /// Null on success, the error otherwise.
  Future<AppError?> setEnabled(bool value) async {
    final id = ref.read(activeProfileProvider)?.id;
    if (id == null) return null;
    final before = state;
    state = value;
    try {
      final r = await ref.read(dioProvider).patch<Map<String, dynamic>>('/profiles/$id', data: {'notify_enabled': value});
      final data = r.data;
      if (data != null) await ref.read(activeProfileProvider.notifier).sync(Profile.fromJson(data));
      ref.invalidate(profilesProvider);
      return null;
    } on DioException catch (e) {
      state = before;
      return e.error is AppError ? e.error! as AppError : UnknownError(message: e.message ?? 'Could not save.', cause: e);
    } catch (e) {
      state = before;
      return UnknownError(message: e.toString(), cause: e);
    }
  }
}

final notifyEnabledProvider = NotifierProvider<NotifyEnabledNotifier, bool>(NotifyEnabledNotifier.new, name: 'notifyEnabled');
