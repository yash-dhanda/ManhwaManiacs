/// The five scopes of the Discover search field (Glass adds `text` and maps to
/// [DiscoverScope.all] until it has its own).
enum DiscoverScope { all, library, sources, dialogue, ask }

/// Parses `?scope=`. Unknown values (and Glass's `text`) mean `all`; `ask`
/// needs AI, `dialogue` needs OCR in manga mode, otherwise both mean `all`.
DiscoverScope parseDiscoverScope(
  String? value, {
  required bool aiAvailable,
  required bool dialogueAvailable,
}) =>
    switch (value) {
      'library' => DiscoverScope.library,
      'sources' => DiscoverScope.sources,
      'ask' => aiAvailable ? DiscoverScope.ask : DiscoverScope.all,
      'dialogue' =>
        dialogueAvailable ? DiscoverScope.dialogue : DiscoverScope.all,
      _ => DiscoverScope.all,
    };
