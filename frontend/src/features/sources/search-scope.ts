export type DiscoverScope = "all" | "library" | "sources" | "dialogue" | "ask";

export function parseDiscoverScope(
  value: string | null | undefined,
  caps: { aiAvailable: boolean; dialogueAvailable: boolean },
): DiscoverScope {
  switch (value) {
    case "library":
    case "sources":
      return value;
    case "ask":
      return caps.aiAvailable ? "ask" : "all";
    case "dialogue":
      return caps.dialogueAvailable ? "dialogue" : "all";
    default:
      return "all";
  }
}
