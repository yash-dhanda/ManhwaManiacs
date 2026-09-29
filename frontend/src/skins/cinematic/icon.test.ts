import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it } from "vitest";
import { Icon, cinematicWeight } from "./Icon";
import { GLYPHS } from "./icons/glyphs.generated";
import { PHOSPHOR } from "./icons/phosphor";
import { ICON_ROLES, type IconRole } from "./icons/roles.generated";

const roles = Object.keys(ICON_ROLES) as IconRole[];

describe("cinematic icons", () => {
  it("resolves every role through PHOSPHOR or GLYPHS", () => {
    for (const r of Object.values(ICON_ROLES)) {
      if (r.kind === "phosphor") expect(PHOSPHOR[r.component], r.component).toBeTruthy();
      else expect(GLYPHS[r.name], r.name).toBeTruthy();
    }
  });
  it("renders one svg per role, decorative by default", () => {
    for (const name of roles) {
      const html = renderToStaticMarkup(createElement(Icon, { name }));
      expect(html.match(/<svg/g)?.length, name).toBe(1);
      expect(html).toContain('aria-hidden="true"');
    }
  });
  it("labelled icons are images", () => {
    const html = renderToStaticMarkup(createElement(Icon, { name: "search", label: "Search" }));
    expect(html).toContain('role="img"');
    expect(html).toContain('aria-label="Search"');
    expect(html).not.toContain("aria-hidden");
  });
  it("weight rule: light at 24+, regular at 20 and below, fill when filled", () => {
    expect([16, 20].map((s) => cinematicWeight(s, false))).toEqual(["regular", "regular"]);
    expect([24, 32].map((s) => cinematicWeight(s, false))).toEqual(["light", "light"]);
    expect([16, 24, 32].map((s) => cinematicWeight(s, true))).toEqual(["fill", "fill", "fill"]);
  });
});
