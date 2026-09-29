import { notFound } from "next/navigation";
import { getSkin } from "@/skins/server";
import NotFound from "../not-found";

export { metadata } from "../not-found";

/**
 * Legacy's 404, rendered as a page rather than thrown: `src/proxy.ts` rewrites
 * every URL legacy has no screen for to here, with the 404 status, as Next's own
 * not-found route did before the skins. Deleted with legacy at the flip.
 */
export default async function LegacyNotFound() {
  if ((await getSkin()) !== "legacy") notFound();
  return <NotFound />;
}
