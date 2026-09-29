import { expect, it } from "vitest";
import { timeHere } from "./series-time";

it("formats hours and minutes", () => {
  expect(timeHere([{ time_spent_seconds: 40800 }])).toBe("11 H 20 M");
  expect(timeHere([{ time_spent_seconds: 1000 }, { time_spent_seconds: 1700 }])).toBe("45 M");
  expect(timeHere([])).toBe("—");
  expect(timeHere([{ time_spent_seconds: 20 }, {}])).toBe("—");
});
