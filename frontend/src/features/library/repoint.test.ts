import { expect, it } from "vitest";
import { mappingSentence } from "./repoint";

it("maps by number when in range", () => {
  expect(mappingSentence({ currentNumber: 142, candidateRange: [1, 150], sourceName: "Asura" })).toBe(
    "Your place moves by chapter number. You're on chapter 142; Asura has chapters 1–150, so chapter 142 there becomes your place.",
  );
});
it("starts at chapter 1 when out of range, unknown or no candidate range", () => {
  const s = "Chapter numbers don't line up, so you'll start at chapter 1 on Asura.";
  expect(mappingSentence({ currentNumber: 200, candidateRange: [1, 150], sourceName: "Asura" })).toBe(s);
  expect(mappingSentence({ currentNumber: null, candidateRange: [1, 150], sourceName: "Asura" })).toBe(s);
  expect(mappingSentence({ currentNumber: 5, candidateRange: null, sourceName: "Asura" })).toBe(s);
});
