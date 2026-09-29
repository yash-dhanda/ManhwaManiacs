import { subtitle } from "./subtitles";

/** Single unfollow / remove never opens a dialog: commit at once, then a toast "Removed {title}." with Undo held 8000 ms (§7.10). */
export async function commitWithUndo({ run, undo, message }: { run: () => Promise<void> | void; undo: () => Promise<void> | void; message: string }): Promise<void> {
  await run();
  subtitle.undo(message, () => { void undo(); });
}
