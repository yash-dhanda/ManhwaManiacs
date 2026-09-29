import { http } from "@/services/http";

// TODO(web/08): stand-in for web/08's `sendAiFeedback`; replace with that file.
export interface AiFeedback {
  signal: string;
  source_id?: string;
  series_key?: string;
  tag?: string;
}

export function sendAiFeedback(body: AiFeedback): Promise<unknown> {
  return http.post("/ai/feedback", body).catch(() => null);
}
