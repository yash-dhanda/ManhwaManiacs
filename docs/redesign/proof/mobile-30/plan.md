# mobile/30 plan: Glass setup, login, register, profiles, onboarding

Lane M30, worktree `wt/M30`, branch `redesign/M30`. The order the work landed in (each step one commit with its tests):

1. Shared additions (skin-neutral, `features/` and `core/`): known accounts, register validation, profile extras (`createWithExtras`, `edit` extras, `reorder`, `kDailyGoalOptions`), one reference-counted gravity source (the light angle rides it), the mature-gate side-effect helper.
2. Glass plumbing: the redirect hold, the Setup splash target, additive options on the text field (IME action, autofocus, capitalisation, formatters, keyboard, counter), the button (`mono`), the chips (a colour dot) and the flight layer (a meniscus tail).
3. Setup, Login, Register: frame and lens, the Address drain, the Slab condense and the droplet, the lens split hand-off.
4. The picker: orb physics, Step into the light (a pure timeline), the flight, the melt and restart, manage mode, the context menu, every state.
5. The profile form, the delete alert and Manage profiles.
6. Onboarding: the pure step rules, the flow (draft first, debounced save, `done` with retries), the dots, the seven steps, the genre field (pure physics and a painter).
7. Fixtures (`/dev/glass/auth`), tests (pure, widget, gate end to end, accessibility, budget, reduced, solid), captures and the owner checklists.

Skin neutrality: nothing under `features/` or `core/` imports a widget or `lib/skins/**`; Glass screens import only the allowed folders; `mature_filter.dart` and `mature_gate_provider.dart` are untouched; Cinematic changed by one import (the moved gate-effects helper).
