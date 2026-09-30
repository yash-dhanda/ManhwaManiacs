import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Device-global list of usernames that signed in here (usernames only, never a password or token). Glass 15.5.
const String kKnownAccountsKey = 'mm.known-accounts';
const int kKnownAccountsMax = 5;

/// Most recent first, at most 5; a corrupt value reads as empty.
List<String> knownAccounts(SharedPreferences prefs) {
  final raw = prefs.getString(kKnownAccountsKey);
  if (raw == null) return const [];
  try {
    final j = jsonDecode(raw);
    if (j is! List) return const [];
    return [for (final e in j) if (e is String && e.isNotEmpty) e].take(kKnownAccountsMax).toList();
  } catch (_) {
    return const [];
  }
}

/// Puts [username] first; a case-insensitive duplicate is replaced by the newest spelling.
Future<void> rememberAccount(SharedPreferences prefs, String username) async {
  final name = username.trim();
  if (name.isEmpty) return;
  final next = [name, for (final n in knownAccounts(prefs)) if (n.toLowerCase() != name.toLowerCase()) n].take(kKnownAccountsMax).toList();
  await prefs.setString(kKnownAccountsKey, jsonEncode(next));
}

Future<void> forgetAll(SharedPreferences prefs) => prefs.remove(kKnownAccountsKey);
