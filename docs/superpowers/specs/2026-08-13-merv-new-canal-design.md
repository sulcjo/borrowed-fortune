# Merv — The New Canal

**Status:** approved, pending implementation plan.

## Goal

Twelfth and final content-expansion installment of this session — the last chapter this initiative had never touched. Merv (9 nodes) is deliberately the smallest, most self-contained chapter in the game: an optional detour whose entire identity is quiet dramatic irony — real, calibrated 1035-era prosperity shown with no visible cracks, because only the player knows the city falls to the Seljuks in 1037 (a fact already established in this project's own prior work on this chapter, never stated in the text itself). Direct reading of all 9 nodes confirms no mechanical gap (the one coin choice, `n05_the_sarrafs_price`, already matches its own prose exactly) and no NPC/dialogue depth missing in a way that would need fixing.

**Confirmed with the user directly:** the substantial addition is a new scene deepening that same dramatic-irony theme, not a mechanical fix or a reuse of the Nishapur debt-repayment mechanic (considered and explicitly declined, to avoid complicating or double-dipping that already-shipped beat).

## The content

Retarget `n02_the_citadel_that_was`'s single existing choice (`"Continue."`) from `next_id: "n03_the_bazaar_at_the_crossing"` to `next_id: "n02b_the_new_canal"`. Its own `text` and `effects` (`{}`) stay unchanged. One new node inserted between it and the existing, unchanged `n03_the_bazaar_at_the_crossing`:

**`n02b_the_new_canal`**: past the old quarter's empty lanes, work of a different kind — a new channel being cut from the river, widening desert into land that will be worth taxing in a season or two. Farrukh's guide points it out with real pride, certain Merv "had been doing this since before anyone could remember, and would keep doing it long after everyone currently digging was dust." The irony is left entirely for the player to feel — the guide's confidence about long-term continuity is, in one narrow sense, about to be interrupted by something neither of them can imagine. Deliberately generic (a new irrigation channel extending existing canal infrastructure, matching `n01_merv_arrival`'s own established "canals that had been running the same patient water" detail) rather than a specific named structure — avoiding the same overclaiming risk already flagged and avoided when this chapter first shipped (Merv's "great city" reputation is properly 12th-century, a full century later; this stays firmly grounded in what's plausible for 1035). One choice, `"Continue."` → `n03_the_bazaar_at_the_crossing`, effects `{}` — matching this chapter's own established rhythm, where every node before the one real economic fork (`n05`) is pure narration with no branching at all.

No new glossary term (no technical loanword is introduced — "channel"/"canal" stay in plain English rather than reaching for a specific irrigation-technology term this hasn't been verified). No new flag (a single pure-narration node has nothing to track). No coin or reputation effect.

## Testing

Verified directly against the real current test file, not assumed:

- `tests/unit/test_merv_dialogue_content.gd` has 3 tests using a fixed hop-count that passes through the `n02 -> n03` link: `test_the_pay_in_full_choice_reaches_its_outcome_and_effects()`, `test_the_haggle_choice_reaches_its_outcome_and_effects()`, and `test_the_decline_choice_reaches_its_outcome_and_effects()` (all `for i in range(4): engine.choose(0)`, comment confirms `n01 -> n02 -> n03 -> n04 -> n05`). Inserting **one** new node where a single direct link (`n02 -> n03`, 1 press) previously existed makes that leg 2 presses — a net **+1**, not the familiar +2 from every other installment this session (which all inserted *two* sequential nodes; this one inserts only one). `range(4)` becomes `range(5)` in all three tests.
- `test_the_full_tree_is_walkable_from_start_to_end_via_first_choices()` uses an uncapped `while` loop — absorbs the extra hop with no assertion change needed.
- `test_every_next_id_points_at_a_node_that_exists`, `test_exactly_one_node_has_no_choices_and_it_is_the_last_node`, `test_the_terminal_node_points_at_chapter_8`, and `test_every_glossed_term_id_exists_in_the_merv_glossary` all automatically cover the new node — no manual change needed, and no new glossed term is introduced.
- **Confirmed via direct grep: zero references to Merv anywhere in `tests/unit/test_chapter_view.gd`.** No full-playthrough test ever takes the Merv detour — the "always press 0" convention at Sarakhs's `n10b_the_road_forks` takes the straight-to-Nishapur option (index 0), not Merv (index 1) — so this is the only installment this session with **no cross-file cumulative-total impact at all**.
- The full existing suite (316 tests as of the last merge to `master`) does not grow — no new test function is added (a single pure-narration node needs no new test beyond the existing structural/wiring tests, which already cover it automatically). Confirm it stays at 316 tests, 315 passing + the 1 pre-existing risky test, with no failures.

## What this pass does not do

- Does not add any coin, reputation, or flag effect anywhere.
- Does not touch `n01`, `n03`, or any other already-shipped Merv content.
- Does not add a new glossary term.
- Does not reference Merv's later, 12th-century "great city" reputation, its real 1037 fall, or anything the characters couldn't plausibly know in 1035.
- Does not reuse the Nishapur debt-repayment mechanic here — considered and explicitly declined by the user.
