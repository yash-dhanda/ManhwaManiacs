import { expect, test } from "@playwright/test";

const G = "/dev/glass-primitives";

test.describe("phone touch targets", () => {
  test.use({ viewport: { width: 390, height: 844 }, hasTouch: true, isMobile: true });
  test("every interactive element is at least 44 x 44", async ({ page }) => {
    const bad: string[] = [];
    for (const s of ["buttons", "hold", "icon-buttons", "inputs", "search", "chips", "segmented", "cards", "posters", "rails", "progress", "badges", "avatars", "tooltips"]) {
      await page.goto(`${G}?section=${s}`, { waitUntil: "networkidle" });
      await page.waitForTimeout(400);
      const r = await page.evaluate(() => {
        const out: string[] = [];
        const sel = 'button, a[href], input, textarea, [role=button], [role=radio], [role=tab], [role=switch], [role=slider], [role=checkbox]';
        document.querySelectorAll<HTMLElement>(`main ${sel}`).forEach((el) => {
          if (el.closest(".gal-toolbar, .gal-nav") || el.tabIndex < -1 && false) return;
          const w = el.offsetWidth, h = el.offsetHeight; // the layout box: a forced pressed state scales the paint, not the hit area
          if (!w || !h) return;
          if (w < 44 || h < 44) out.push(`${el.tagName}.${el.className.toString().slice(0, 30)}:${w}x${h}`);
        });
        return out;
      });
      r.forEach((x) => bad.push(`${s} ${x}`));
    }
    expect(bad).toEqual([]);
  });
});

test.describe("desktop behaviour", () => {
  test.use({ viewport: { width: 1440, height: 900 } });

  test("cursor contract", async ({ page }) => {
    await page.goto(`${G}?section=cursors`, { waitUntil: "networkidle" });
    const c = (id: string) => page.getByTestId(id).first().evaluate((e) => getComputedStyle(e).cursor);
    expect(await c("cur-button")).toBe("pointer");
    expect(await c("cur-disabled")).toBe("not-allowed");
    expect(await c("cur-field")).toBe("text");
    expect(await c("cur-grab")).toBe("grab");
    expect(await c("cur-zoom-in")).toBe("zoom-in");
    expect(await c("cur-all-scroll")).toBe("all-scroll");
  });

  test("segmented thumb cursor: grab at rest, grabbing while dragged", async ({ page }) => {
    await page.goto(`${G}?section=segmented`, { waitUntil: "networkidle" });
    const thumb = page.getByTestId("seg-4").first().locator(".g-seg__thumb");
    const cur = () => thumb.evaluate((e) => getComputedStyle(e).cursor);
    expect(await cur()).toBe("grab");
    const b = (await thumb.boundingBox())!;
    await page.mouse.move(b.x + b.width / 2, b.y + b.height / 2);
    await page.mouse.down();
    await page.mouse.move(b.x + b.width / 2 + 40, b.y + b.height / 2, { steps: 5 });
    await expect(thumb).toHaveAttribute("data-dragging", "");
    expect(await cur()).toBe("grabbing");
    await page.mouse.up();
  });

  test("segmented error springs the thumb back", async ({ page }) => {
    await page.goto(`${G}?section=segmented`, { waitUntil: "networkidle" });
    const seg = page.getByTestId("seg-error").first();
    const thumb = seg.locator(".g-seg__thumb");
    const x0 = (await thumb.boundingBox())!.x;
    await seg.getByRole("radio").nth(1).click();
    await expect(seg).toHaveAttribute("data-error", "");
    await page.waitForTimeout(900);
    expect(Math.abs((await thumb.boundingBox())!.x - x0)).toBeLessThan(2);
  });

  test("hold to confirm", async ({ page }) => {
    await page.goto(`${G}?section=hold`, { waitUntil: "networkidle" });
    const btn = page.getByTestId("hold-standalone").first();
    const read = () => page.getByTestId("hold-readout").first().innerText();
    await btn.focus();
    await page.keyboard.press("Enter");
    expect(await read()).toContain("requestConfirm 1");
    // a 1,300 ms hold confirms
    let b = (await btn.boundingBox())!;
    await page.mouse.move(b.x + b.width / 2, b.y + b.height / 2);
    await page.mouse.down();
    await page.waitForTimeout(1300);
    await page.mouse.up();
    expect(await read()).toContain("confirmed 1");
    // a 600 ms hold aborts and shows the helper for 2 s
    await page.mouse.move(b.x + b.width / 2, b.y + b.height / 2);
    await page.mouse.down();
    await page.waitForTimeout(600);
    await page.mouse.up();
    await expect(page.getByTestId("hold-standalone-helper").first()).toContainText("Keep holding");
    expect(await read()).toContain("confirmed 1");
    await page.waitForTimeout(2200);
    await expect(page.getByTestId("hold-standalone-helper").first()).toHaveText("");
    // 10 px of movement before 200 ms cancels with no click
    b = (await btn.boundingBox())!;
    await page.mouse.move(b.x + 20, b.y + 20);
    await page.mouse.down();
    await page.mouse.move(b.x + 32, b.y + 20);
    await page.mouse.up();
    expect(await read()).toContain("requestConfirm 1");
    // inAlert: the fallback is visible with no interaction
    await expect(page.getByTestId("hold-inalert-fallback").first()).toBeVisible();
  });

  test("keyboard: ring, segmented arrows, rail model, tooltip", async ({ page }) => {
    await page.goto(`${G}?section=segmented`, { waitUntil: "networkidle" });
    const seg = page.getByTestId("seg-4").first();
    await seg.getByRole("radio").first().focus();
    await page.keyboard.press("ArrowRight");
    await expect(seg.getByRole("radio").nth(1)).toHaveAttribute("aria-checked", "true");
    await page.keyboard.press("End");
    await expect(seg.getByRole("radio").nth(3)).toHaveAttribute("aria-checked", "true");
    await page.keyboard.press("Home");
    await expect(seg.getByRole("radio").nth(0)).toHaveAttribute("aria-checked", "true");
    const ring = await seg.evaluate((e) => getComputedStyle(e).boxShadow);
    expect(ring).toContain("rgb(188, 176, 255)");

    await page.goto(`${G}?section=rails`, { waitUntil: "networkidle" });
    const group = page.locator(".g-railgroup").first();
    await page.waitForTimeout(500);
    expect(await group.locator(".g-rail").first().locator(".g-poster__main[tabindex='0']").count()).toBe(1);
    await group.locator(".g-rail").first().locator(".g-poster__main[tabindex='0']").focus();
    await page.keyboard.press("ArrowRight");
    await page.keyboard.press("ArrowRight");
    await page.keyboard.press("ArrowDown");
    const col = await page.evaluate(() => {
      const el = document.activeElement!;
      const rail = el.closest(".g-rail")!;
      return { idx: Array.from(rail.querySelectorAll(".g-poster__main")).indexOf(el), label: rail.getAttribute("aria-label") };
    });
    expect(col).toEqual({ idx: 2, label: "New this week" });

    await page.goto(`${G}?section=tooltips`, { waitUntil: "networkidle" });
    const t = page.getByTestId("tip-target").first();
    await t.hover();
    const tip = page.locator("[data-glass-tooltip]");
    await expect(tip).toBeVisible({ timeout: 3000 });
    const tb = (await tip.boundingBox())!;
    await page.mouse.move(tb.x + tb.width / 2, tb.y + tb.height / 2);
    await page.waitForTimeout(800);
    await expect(tip).toBeVisible();
    await page.keyboard.press("Escape");
    await expect(tip).toBeHidden();
  });

  test("aria: toggles, invalid field, error region", async ({ page }) => {
    await page.goto(`${G}?section=icon-buttons`, { waitUntil: "networkidle" });
    const fav = page.getByTestId("ib-fav").first();
    await expect(fav).toHaveAttribute("aria-label", "Favourite");
    await expect(fav).toHaveAttribute("aria-pressed", "false");
    await fav.click();
    await expect(fav).toHaveAttribute("aria-pressed", "true");
    await expect(fav).toHaveAttribute("aria-label", "Favourite");
    await page.goto(`${G}?section=inputs`, { waitUntil: "networkidle" });
    const f = page.getByTestId("tf-error").first();
    await expect(f).toHaveAttribute("aria-invalid", "true");
    const id = await f.getAttribute("aria-describedby");
    expect(await page.locator(`[id="${id}"]`).innerText()).toContain("valid email");
    await page.goto(`${G}?section=buttons`, { waitUntil: "networkidle" });
    await page.getByTestId("error-button").first().click();
    await expect(page.locator("[data-glass-announcer]")).toHaveText("Couldn't save");
  });
});
