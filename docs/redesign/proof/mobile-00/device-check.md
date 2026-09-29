# mobile/00 device check: pixel-free reader engine extraction

Commit under test: `e8be5bf` (`refactor(reader): extract the pixel-free reader engine`)
on `redesign/mobile1`, plus the no-pixel section E moves after it. Use the first
iPhone build `ios-build.yml` publishes once this is integrated into
`feat/vps-slim-source-native` (update through SideStore), and the next signed APK
built from a commit that contains it.

Nothing should look or behave differently. The reader's logic moved out of
`ReaderContent` into `features/reader/engine/` and the old screen became a thin
frame that draws today's bars over it; both the library reader and the Sources
reader run on the new engine. The 14 parity goldens in this folder were captured
before the change and still match byte for byte. Any difference you can see or
feel on a device is a bug in this step.

- [ ] **Scroll performance.** Open a 120-page webtoon chapter whose pages decode
      at the 2,880 px cap (a long-strip source; series used: ________). Settings →
      Diagnostics, with "Use the highest refresh rate everywhere" on (Android).
      Scroll the whole chapter top to bottom by fling. Pass: Diagnostics shows
      FPS ≥ 115 at 120 Hz, JANK < 5 %, WORST < 16.7 ms.
- [ ] **Resume.** Leave mid-chapter, reopen from History. Pass: it opens on the
      same page, within one page height.
- [ ] **Bookmark.** Bookmark at about 62 % of a page, reopen the bookmark. Pass:
      same spot; the "Bookmarked page N — X% of the chapter" message shows as before.
- [ ] **Read-all.** Read across three chapters in one continuous feed. Pass:
      seams appear, no jump backwards at a seam, progress lands in each chapter.
- [ ] **Auto-scroll** at Slow, Medium and Fast. Pass: speeds unchanged, it stops
      at the end.
- [ ] **Lock mode.** Turn it on, then five taps in the centre. Pass: "Reader
      unlocked".
- [ ] **Zoom and keys.** Double-tap zoom; keyboard H / L / B / + / − / 0 (iPad or
      Android with a keyboard); volume keys (Android, when enabled). Pass: all
      act as before.
- [ ] **Offline.** A downloaded chapter with flight mode on. Pass: it opens from
      disk.
- [ ] **Source reader auto-queue.** Sources tab, open a chapter while on Wi-Fi.
      Pass: the next chapter appears queued in Downloads.
