/** §9.1.8 vocabulary for AI states. web/19 extends this. Branch on the error `code`, never the HTTP status. */
const COPY: Record<string, string> = {
  budget_exhausted: "The picks desk is closed tonight. Asks reset at midnight UTC.",
  ai_budget_exhausted: "The picks desk is closed tonight. Asks reset at midnight UTC.",
  not_configured: "The editors' desk isn't set up on this server.",
  ai_not_configured: "The editors' desk isn't set up on this server.",
  ai_failed: "The editors couldn't answer that one. Try describing it differently.",
};

export const aiCopy = {
  forCode: (code: string | null | undefined): string => (code && COPY[code]) || COPY.ai_failed,
  rate_limited: (seconds: number): string => `Too many asks at once. Try again in ${seconds} s.`,
};
