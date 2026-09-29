import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it } from "vitest";
import { Icon, glassWeight } from "./Icon";
import { GLYPHS } from "./icons/glyphs.generated";
import { PHOSPHOR } from "./icons/phosphor";
import { ICON_ROLES, type IconRole } from "./icons/roles.generated";

const roles = Object.keys(ICON_ROLES) as IconRole[];

describe("glass icons", () => {
  it("resolves every role through PHOSPHOR or GLYPHS", () => {
    for (const r of Object.values(ICON_ROLES)) {
      if (r.kind === "phosphor") expect(PHOSPHOR[r.component], r.component).toBeTruthy();
      else expect(GLYPHS[r.name], r.name).toBeTruthy();
    }
  });
  it("renders one svg per role in every state and tier", () => {
    for (const name of roles) {
      for (const p of [{}, { state: "active" }, { state: "pressed" }, { tier: "ornamental" }, { tier: "dense" }] as const) {
        const html = renderToStaticMarkup(createElement(Icon, { name, ...p }));
        expect(html.match(/<svg/g)?.length, `${name} ${JSON.stringify(p)}`).toBe(1);
        expect(html).toContain('aria-hidden="true"');
      }
    }
  });
  it("labelled icons are images", () => {
    const html = renderToStaticMarkup(createElement(Icon, { name: "search", label: "Search" }));
    expect(html).toContain('role="img"');
    expect(html).toContain('aria-label="Search"');
  });
  it("weight rule", () => {
    expect(glassWeight("rest", "default")).toBe("regular");
    expect(glassWeight("active", "default")).toBe("duotone");
    expect(glassWeight("pressed", "default")).toBe("fill");
    expect(glassWeight("rest", "ornamental")).toBe("light");
    expect(glassWeight("rest", "dense")).toBe("bold");
  });
});
