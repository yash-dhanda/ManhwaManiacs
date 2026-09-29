import { http } from "@/services/http";

/**
 * The slice of the unified `/settings` payload this feature reads/writes.
 * The endpoint returns more (downloads, updates, ocr, …); we only touch the
 * mature-content gate here.
 */
/** What the server offers (`GET /settings`). */
export interface ServerCapabilities {
  online_sources?: boolean;
  client_downloads?: boolean;
  ocr?: boolean;
  collections?: boolean;
  bookmarks?: boolean;
  continue_reading?: boolean;
  reading_progress?: boolean;
}

export interface ContentPreferences {
  mature_content_enabled: boolean;
  /** What this server offers (`GET /settings`); absent on older servers. */
  capabilities?: ServerCapabilities;
}

export const preferencesApi = {
  get: () => http.get<ContentPreferences>("/settings"),

  setMatureContent: (enabled: boolean) =>
    http.put<ContentPreferences>("/settings", { mature_content_enabled: enabled }),
};
