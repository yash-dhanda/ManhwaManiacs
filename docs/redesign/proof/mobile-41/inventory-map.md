# mobile-41 inventory map: S11 items 1 to 20 and G5 to their Glass counterparts

Files are under `mobile/lib/skins/glass/` unless noted. ScreenId `picks` is `screens/picks/for_you_screen.dart`.

| S11 item | Cinematic element | Glass counterpart |
|---|---|---|
| 1 | AppBar back and title | `GlassScaffold` back leading with the title "For you" (nav row or toolbar) |
| 2 | HeroHeading "What do you feel like?" | `LetterReveal` large title, placement `picks:title` |
| 3 | Intro copy, three variants | Replaced by state: Ask box (available), `BudgetNotice` with live countdown (exhausted), `AiNotice` long line (off) |
| 4 | Prompt text field, 600 chars | `AskBox` (`GlassTextArea`, always-visible `n / 600`, `machineRim` while focused or thinking) |
| 5 | Example chips | `AskExamples` (`GlassChip` assist) and `alt+1` to `alt+3` |
| 6 | "Suggest something" / "Thinking" | `AskControls` Ask button (three-dot loading), `AskingPanel` (64 px `ThinkingOrbit`, phase lines, Cancel) |
| 7 | Remaining budget caption | `QuotaMeter` (72 x 8 liquid capsule, `warning` at 3 or fewer) |
| 8 | Suggestion results | `AnswerList` / `AnswerCard` dealt out of the Ask button (`deal_layer.dart`, `deal_path.dart`) |
| 9 | Suggestion error | `AskFailureNote` (no matches, timeout with Try again), `AiNotice` (upstream, offline), rate-limit countdown on the button |
| 10 | Skeleton | `GlassSkeletonGroup` (`ai: true`, 2,800 ms sheen) in `ForYouSections` |
| 11 | Quiet notice (`unavailableReason`) | `kCatalogueSaved` footnote |
| 12 | Rail "For you" | `ForYouSections` "For you" section (list on phones, grid on wider frames) |
| 13 | Rails "Because you read X" | `ForYouSections` "Because you read {title}" sections |
| 14 | WorldTitleCard | `worldCardFor` (`GlassWorldCard`) wrapped in `AiCardActions` |
| 15 | "Not on your sources" branch | `GlassWorldCard.infoOnly`: Search my sources and Read on {site} |
| 16 | Snackbar "Could not open" | Toast "Couldn't open {site}" (`error`) |
| 17 | Empty state | `suggest_shelf_empty` note with Browse sources |
| 18 | Offline state | `AiNotice` offline; sections keep their saved copy |
| 19 | Error state | "Couldn't load picks." with Try again |
| 20 | Pull to refresh | `GlassPullToRefresh` (refetches recommendations and availability, never asks the AI) and `r` |

| G5 element | Glass counterpart |
|---|---|
| Mode switch | `GlassScaffold(contentModeSwitch: true)`; Novels mode hides "Only my sources" (every ask is local with `content_kind: "novel"`) and replaces the worldwide sections with the note "Worldwide picks cover manga, manhwa and manhua." |
| Recap entries | Recaps are manga and novel both; the deck reads the same in either mode |

New in Glass (no Cinematic twin): Not interested (throw, swipe, menu, `Delete`, semantics action), More like this one, genre filter chip, "Show as grid", recap offer sheet, chapter pill, recap deck, How it works, More like this rail.
