# 18+ checklist, mobile/30 (result box empty)

- The profile form's switch never flips on a tap: the alert opens first with "Show mature content?". Result:
- The alert has Cancel first with initial focus, the "Hold: I am 18 or older" button (1,200 ms) and the always-visible "I am 18 or older, enable". Result:
- Turning it off is immediate and fires `toggle.off`. Result:
- Saving the ACTIVE profile with the gate closed drops the mature rows from Downloads and hides gated content on the shelf at once (the shell's purge). Result:
- Picking a profile whose gate is closed runs the purge before the hand-off. Result:
- The picker marks nothing: no lock, no blur, no hidden count. Result:
- The onboarding genre field holds Murim, System, Tragedy, Revenge and Cooking with the gate closed, and Adult, Ecchi, Hentai, Mature and Smut in their place with it open. Result:
- The seeds come from the server already 18+ filtered. Result:
