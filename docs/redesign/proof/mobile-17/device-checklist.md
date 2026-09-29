# mobile/17 device checks (owner)

iPhone via SideStore from the CI IPA, Android flagship from the CI APK.

- [ ] A real 10-chapter queue: pause, resume, background the app and return. The Activity block reads PAUSED with the background line while away and DOWNLOADING on return.
- [ ] The meter's `spot` segment grows as each chapter lands (240 ms), and the folio line's free space matches Settings on the phone.
- [ ] Swipe a saved chapter left past half: the row springs back reading `REMOVING…`, the toast holds 8 s, Undo keeps it; leave the app before 8 s and check it is gone on return.
- [ ] Save to Files as CBZ: iPhone into Files › On My iPhone › ManhwaManiacs › Exports; Android into Download/ManhwaManiacs/Exports. Open one in another app. `Open Files` on the iPhone.
- [ ] Android 7-9 device (if any): the result dialog offers Share instead of a path.
- [ ] Kill the app during a download, relaunch: the chapter resumes on its own and Activity shows it.
- [ ] Turn on "Download new chapters of followed series automatically", let a new chapter arrive, reopen the app: the toast "Queued 1 new chapter." appears.
- [ ] Install a newer build over the old one: What's new opens by itself once, not over a reader.
- [ ] Android: the update banner and Install now steps appear on the Index and clear after installing.
- [ ] System status as admin: LIVE counts down, Check now toasts, a stopped backend turns the summary red.
- [ ] Screen reader pass (VoiceOver, TalkBack) over Downloads, the Index, the What's new sheet and System status.
