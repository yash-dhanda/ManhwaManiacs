import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manhwamaniacs/features/admin/models/account.dart';
import 'package:manhwamaniacs/shared/providers/repository_providers.dart';

/// `GET /auth/users` (admin): every account on this instance. `autoDispose`: a list of who can
/// sign in is read fresh each time the page opens.
final membersProvider = FutureProvider.autoDispose<List<Account>>((ref) async {
  final r = await ref.read(adminRepositoryProvider).listAccounts();
  if (r.isErr) throw r.error;
  return r.value;
}, name: 'members',);
