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

/// The six scopes of Glass Search (`?scope=`). `text` searches downloaded novel chapters on the device; `ask` hands the query to
/// For you once that screen is built.
enum GlassDiscoverScope { all, library, sources, dialogue, text, ask }

extension GlassDiscoverScopeWire on GlassDiscoverScope {
  /// The `?scope=` value.
  String get wire => name;
}

/// Parses `?scope=` for Glass. Unknown means `all`; `dialogue` needs manga mode, OCR and the server capability; `text` needs novels on;
/// `ask` needs AI and a built `picks` screen ([picksReady]).
GlassDiscoverScope parseGlassDiscoverScope(
  String? value, {
  required bool aiAvailable,
  required bool dialogueAvailable,
  required bool novelsEnabled,
  required bool picksReady,
}) =>
    switch (value) {
      'library' => GlassDiscoverScope.library,
      'sources' => GlassDiscoverScope.sources,
      'dialogue' => dialogueAvailable ? GlassDiscoverScope.dialogue : GlassDiscoverScope.all,
      'text' => novelsEnabled ? GlassDiscoverScope.text : GlassDiscoverScope.all,
      'ask' => aiAvailable && picksReady ? GlassDiscoverScope.ask : GlassDiscoverScope.all,
      _ => GlassDiscoverScope.all,
    };
