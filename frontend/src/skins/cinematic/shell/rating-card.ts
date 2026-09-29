"use client";
import type { ReactNode } from "react";
import { create } from "zustand";

/** The rating card's slot (§8.33.5). The card itself, its timing and its callers are web/07, web/11 and web/12. */
export const useRatingCard = create<{ node: ReactNode | null; show: (n: ReactNode) => void; hide: () => void }>((set) => ({ node: null, show: (node) => set({ node }), hide: () => set({ node: null }) }));
export const showRatingCard = (node: ReactNode) => useRatingCard.getState().show(node);
export const hideRatingCard = () => useRatingCard.getState().hide();
