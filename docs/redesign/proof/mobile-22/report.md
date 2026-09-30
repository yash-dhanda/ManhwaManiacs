# mobile/22 report: Cinematic Circle

Done: A data layer (repository extended, collections calls live in CircleRepository rather than LibraryRepository to keep its fakes valid), B Circle screen, C stamps and guard, D Pass it on and letters, E shared shelves, F member page, G Settings section 09, H Tonight/Index/Quick look, I a11y tests. J untouched.

Screenshots (all in this folder, harness `test/screenshots/mobile_22_shots.dart`): circle-* prove B states and tabs; circle-ring-tooltip presence; letter-unfold letters; stamps-credits-open/guarded, reader-circle-tab-guarded/unsealed, schedule-row-reactions, feature-circle-tab the guard; react-sheet, pass-it-on(-nobody) D; collections-shared, shelf-member-view, leave-shelf-arming, shelf-share-sheet E; member, member-not-sharing F; settings-circle G; tonight-circle-sections H; reduced-motion-circle, text-scale-2-circle accessibility. No web-twin captures existed to compare.

Choices: headline copy over 60 graphemes is split into headline and deck (CineNotice cap); Settings 18+ row is gated by a new RowGate.mature; the Circle poll invalidates members, letters and member pages; `now` and the ring appear only when the member's show_presence is on (Glass-only switch); the feature page 04 CIRCLE tab is disabled for a non-sharing profile while the Circle screen follows reciprocity; NOW badge follows section 7.19 (ink.100 fill, black text).

Names for later steps: circleMembersProvider, CirclePollScope, chapterReactionsProvider, ReactionStamps, completedThisSessionProvider, isGuarded, showPassItOnSheet.
