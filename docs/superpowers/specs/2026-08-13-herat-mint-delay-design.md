# Herat — The Mint's Delay

**Status:** approved, pending implementation plan.

## Goal

Ninth content-expansion installment, and the first to be a deliberately flavor-only pass by explicit design, not by later discovery. Herat (Chapter 4A) is confirmed, via direct reading of all 26 nodes, to have no mechanical gap like Farah/Teginabad's — it's already the densest, most mechanically airtight chapter in the game (two full economic exchange scenes with Ardashir, zero prose/mechanics mismatches). More importantly, its central reveal-gate (`n18_the_moment_of_truth`'s `requires_reputation: {"faction_id": "trading_families", "min_score": 4}`) was calibrated earlier this project via an exhaustive enumeration of all 5,760 possible paths through the game. **Confirmed with the user directly: any addition here must carry zero coin or reputation effect**, so the calibrated gate is never touched and never needs re-validating.

## The content

Retarget `n05_the_bazaar_of_herat`'s single existing choice (`"Continue."`) from `next_id: "n06_ardashir_introduced"` to `next_id: "n05b_the_mint_of_herat"`. Its own `text` and `effects` (`{}`) stay unchanged. Two new nodes inserted between it and the existing, unchanged `n06_ardashir_introduced`:

**`n05b_the_mint_of_herat`**: past the money-changers' stalls, the actual minting house itself — the institution `n02_the_citys_pulse` already named ("Herat struck its own coin — one of six mints still answering to the Sultan") — with a line of merchants waiting longer than they'd like for their worn coin to be restruck clean. Two choices:
- `"Ask what's holding up the line."` (index 0) → `n05c_what_the_line_knows`, effects `{"flags": ["asked_about_the_mints_delay"]}` — flavor-only tracking flag, no currently-planned payoff, same shape as this initiative's other flavor flags (Teginabad's `haggled_at_teginabad`, Bost's `learned_of_two_mints_dispute`, Pushang's `asked_about_the_khutba`, Sarakhs's `learned_of_arranged_ghulam_marriages`).
- `"It's not your business today. Move on."` (index 1) → straight to `n06_ardashir_introduced`, effects `{}`.

**`n05c_what_the_line_knows`** (only reached via "Ask"): a merchant in line explains, without needing to spell it out fully — restriking used to take a season, now closer to half a year, because the muster (already established as "sooner and thinner than anyone remembered," `n02`/`n04a`) has first claim on whatever silver moves through the city. This directly connects three already-established facts (the six mints, the thinned muster, the mint's own authority) into one coherent institutional-strain beat, extending the "empire fraying" theme that already runs through Pushang's requisitions and Sarakhs's treasury fragility — to currency production specifically, a genuinely new angle for this theme. One choice, `"Continue."` → `n06_ardashir_introduced`, effects `{}`.

Both paths converge on the existing `n06_ardashir_introduced`, unchanged. No specific date or numeric figure is invented for the delay (kept impressionistic — "a season" to "half a year" — rather than a false-precision claim). No new glossary term (this chapter's existing pattern already leaves related terms like "sikka"/"muhtasib" unglossed here — they're claimed by `herat_favor_terms.json` for Chapter 4B — and this scene introduces no new technical loanword needing one).

## Testing

Verified directly against the real current test file, not assumed:

- `tests/unit/test_herat_dialogue_content.gd` has 5 tests using a fixed hop-count that passes through the `n05 -> n06` link: `test_the_first_haggles_fair_path()` / `test_the_first_haggles_push_too_far_path()` / `test_the_first_haggles_backing_off_reaches_the_same_node_as_accepting()` / `test_the_first_haggles_walk_away_path_has_no_effects()` (all `range(6)`, reaching `n07`), `test_the_second_haggles_fair_path()` and its 3 siblings (`range(9)`, reaching `n11`), and `test_the_default_path_reaches_the_partial_truth()` / `test_sufficient_reputation_reveals_the_full_truth_choice()` / `test_insufficient_reputation_still_hides_the_gated_choice()` (`range(14)`, reaching `n18`). Inserting 2 sequential nodes where a single direct link (`n05 -> n06`, 1 press) previously existed makes that leg `n05 -> n05b -> n05c -> n06` (3 presses, taking "Ask," index 0) — a net **+2**, same arithmetic shape as every prior sequential-node insertion this session. `range(6)` becomes `range(8)`, `range(9)` becomes `range(11)`, `range(14)` becomes `range(16)`.
- `test_choosing_the_bazaar_directly_skips_the_sideroad()` and `test_choosing_the_garrison_gate_visits_the_old_soldier_then_converges()` both stop exactly at `n05` and are confirmed **unaffected** — neither walks past it.
- `test_the_full_tree_is_walkable_from_start_to_end_via_first_choices()` uses an uncapped `while` loop — absorbs the extra hops with no assertion change needed.
- `test_aftermath_nodes_do_not_assume_the_gated_full_truth_was_given()`, `test_no_node_uses_the_non_standard_demonym()`, and `test_the_muster_and_rayy_dates_are_anchored_to_the_1035_present()` all check the *content* of specific existing nodes (`n04a`, `n19b`, `n20`, `n21`) unrelated to this insertion point — confirmed unaffected, and the new nodes' own text avoids both the banned demonym ("Heratigan") and any specific date claim that could contradict the anchored dates.
- Two new test functions needed for the new nodes: one walking "Ask" through to `n05c_what_the_line_knows` and confirming the flag + eventual convergence on `n06`, one walking "Move on" straight to `n06` with empty effects.
- `test_every_next_id_points_at_a_node_that_exists`, `test_exactly_one_node_has_no_choices_and_it_is_the_last_node`, and `test_every_glossed_term_id_exists_in_the_herat_glossary` all automatically cover the new nodes — no manual change needed, and no new glossed term is introduced.
- `test_glossary_terms_and_flag_names_are_unique_across_all_manifest_chapters` (in `test_chapter_view.gd`) automatically covers the new `asked_about_the_mints_delay` flag — confirmed via direct grep that it does not already exist anywhere in the project.
- `test_chapter_view.gd`'s full-playthrough tests are confirmed **unaffected** — the new choices carry zero coin or reputation effect, so no cumulative total shifts, and Herat 4A's own reputation-gate tests (`n18`'s `min_score: 4` threshold) are entirely untouched since nothing here changes `trading_families`.
- The full existing suite (310 tests as of the last merge to `master`) must grow by exactly 2 (the two new dialogue-content tests) to 312, with no failures.

## What this pass does not do

- Does not add any coin or reputation effect anywhere — the whole point of this pass.
- Does not touch `n18`'s reveal-gate, its `min_score: 4` threshold, or anything in the already-calibrated reputation-gate analysis.
- Does not touch `n02`, `n04a`, `n06`, or any other already-shipped Herat content.
- Does not add a new glossary term.
- Does not invent a specific, falsifiable numismatic fact — the mint's slowdown stays impressionistic ("a season" to "half a year"), not a precise invented figure.
