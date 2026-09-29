import { expect, type Page } from "@playwright/test";

export const GALLERY = "/skin-preview/cinematic/primitives?eager=1";
export async function open(page: Page) {
  await page.goto(GALLERY);
  await expect(page.getByTestId("gallery")).toBeVisible();
  await page.waitForLoadState("networkidle");
}
/** Replay the reveals section and return once the new nodes are mounted. */
export async function replay(page: Page) {
  await page.locator("#reveals").scrollIntoViewIfNeeded();
  await page.locator('[data-gallery="reveals-replay"]').click();
}
