export function engineLabel(engine: string): string {
  const e = engine.trim().toLowerCase();
  if (e === "vision" || e === "apple_vision" || e === "apple-vision") return "VISION";
  if (e === "mlkit" || e === "ml_kit" || e === "ml-kit") return "ML KIT";
  return engine.toUpperCase();
}
