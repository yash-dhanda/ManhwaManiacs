// The bulk-result toast copy (glass 7.35).

/// One toast for a whole batch: "12 marked read · 1 failed", with "Retry failed" when something failed.
({String message, String? action}) bulkToast(String verb, int ok, int failed) {
  if (failed == 0) return (message: '$ok $verb', action: null);
  if (ok == 0) return (message: '$failed failed', action: 'Retry failed');
  return (message: '$ok $verb · $failed failed', action: 'Retry failed');
}
