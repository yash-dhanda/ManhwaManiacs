# mobile/07 18+ on-device checklist (cinematic 15.7)

Run on the owner's own server with a throwaway profile whose gate is open; undo afterwards.

1. Follow a series from a healthy non-18+ source and mark it mature (legacy series page Undo path, or `PATCH /library/series/{followed_id} {"mature_override": true}`).
2. Save two chapters (and its narration audio if it is a novel), queue a third, add a bookmark.
3. Close the gate from the Cinematic profile form.
4. Check row by row that each of these shows none of it and says nothing about it: thumb-index Downloads badge, legacy Downloads screen (debug row on LEGACY), Bookmarks, the offline follow cache (airplane mode, Library), search over downloads, every badge. Result:
5. The queued chapter did not download and shows nowhere. Result:
6. Opening the saved chapter from a notification or history offline shows "This series isn't available here any more." Result:
7. The storage meter total is unchanged. Result:
8. Reopen the gate: everything returns and the queued chapter downloads. Result:
9. Set the override back.

Rows whose Cinematic screen does not exist yet (Library offline, Tonight's offline edition, Bookmarks, Downloads): arrives in mobile/09 / mobile/08 / mobile/10 / mobile/17; re-run in mobile/24.
