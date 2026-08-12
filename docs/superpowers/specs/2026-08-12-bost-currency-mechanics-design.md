# Bost — Currency Mechanics (The Light Coin)

**Status:** approved, pending implementation plan.

## Goal

Fifth installment of the content-expansion initiative. Deepens Mihran's shop further with real currency mechanics — coin debasement/clipping and regional mint-distrust — extending the existing coin-check scene (`n02b_the_ordinary_business`) directly, per the user's own pick. Plants the frontier's political fragility early (Bost is Chapter 2, common to every playthrough) as a quiet foreshadow of what Pushang and Sarakhs dramatize explicitly much later.

## The content

Two new nodes inserted between the existing `n02b_the_ordinary_business` and `n02c_mihran_on_letters_of_credit` (both left completely unchanged in content — only their choices' `next_id` values are retargeted).

**`n02d_the_light_coin`** (reached from either of `n02b`'s existing choices, "Thorough" or "Quick," regardless of which — Mihran catches this either way, consistent with his established competence): mid-weighing, he stops on one coin — clipped/shaved silver — and separately notes a mint-mark he no longer trusts, since "the man whose name is on it stopped being anyone's idea of an authority worth trusting." Two choices:
- `"Ask what happened to the mint's authority."` (index 0) → `n02e_the_mint_in_question`, effects `{"flags": ["learned_of_two_mints_dispute"]}` — flavor-only tracking flag, no payoff currently planned, matching the precedent of Teginabad's `haggled_at_teginabad` flag.
- `"Let it go. It's his problem now."` (index 1) → straight to `n02c_mihran_on_letters_of_credit`, effects `{}`.

**`n02e_the_mint_in_question`** (only reached via "Ask"): Mihran explains, in grounded but deliberately unnamed terms — two rival amirs each striking coin with his own name, merchants deciding for themselves whose promise to trust rather than waiting for anyone to settle it properly. One choice, `"Continue."` → `n02c_mihran_on_letters_of_credit`, effects `{}`.

Both paths converge on the existing `n02c_mihran_on_letters_of_credit`, unchanged.

**No new glossary term.** The natural term for this idea — sikka, the political-legitimacy weight of whose name is struck on a coin — is already glossed in `content/glossary/herat_favor_terms.json` (Chapter 4B, reached only on the plunder branch). Per this project's project-wide glossary-uniqueness rule (already hit twice this session, with suftaja), re-defining it in `bost_terms.json` is not an option, and gating the concept behind a term most playthroughs never see it glossed for would be worse than not naming it. The idea (whoever's name is on the coin is making a political claim) is expressed in Mihran's own plain prose instead, without using the loanword.

**Zero coin/reputation effects on either new choice** — deliberately flavor-only, matching Chapter 5's own precedent that not every choice needs mechanical stakes. This scene's value is the worldbuilding beat itself, not another economic lever; it also means no full-playthrough cumulative wealth/reputation total in `test_chapter_view.gd` needs touching.

## Testing

Verified directly against the real current test files, not assumed:

- `tests/unit/test_bost_dialogue_content.gd`'s `test_the_ordinary_business_choices_have_the_right_effects()` and `test_taking_the_quick_option_spends_less_and_gains_reputation()` both currently assert `engine.current_node()["id"] == "n02c_mihran_on_letters_of_credit"` immediately after choosing Thorough/Quick — both need that literal changed to `"n02d_the_light_coin"` (the immediate landing node now), everything else in those two tests (the effects assertions on the Thorough/Quick choices themselves) is unchanged.
- Two new test functions needed for the new nodes: one walking the "Ask" choice through to `n02e_the_mint_in_question` and confirming the flag + eventual convergence on `n02c`, one walking "Let it go" straight to `n02c` with empty effects.
- **Hop-count arithmetic, traced precisely, not assumed to be a simple +1:** `test_the_pressed_path_is_walkable_and_sets_its_flag_and_reputation()` and `test_the_patient_path_is_walkable_and_converges_on_the_same_node()` both currently use `for i in range(8): engine.choose(0)` to reach `n07_the_offer` via "always press 0." Before this change, `n02b`'s index-0 choice ("Thorough") reached `n02c` in exactly 1 press. After this change, the same index-0 path goes `n02b → n02d → n02e → n02c` — 3 presses instead of 1, a net **+2**, not +1 (confirmed by hand-walking the full chain: n01→n02→n02b→n02d→n02e→n02c→n03→n04→n05→n06→n07, which is 10 presses, not 9 — n03 through n06 are each single-choice, unforked nodes, confirmed directly). Both `range(8)` calls become `range(10)`.
- `test_glossary_terms_and_flag_names_are_unique_across_all_manifest_chapters` (in `test_chapter_view.gd`) automatically covers the new `learned_of_two_mints_dispute` flag — confirmed via direct grep that this flag name does not already exist anywhere in the project.
- `test_every_next_id_points_at_a_node_that_exists` and `test_exactly_one_node_has_no_choices_and_it_is_the_last_node` (both in `test_bost_dialogue_content.gd`) automatically cover the new nodes' wiring, no manual change needed.
- `test_every_glossed_term_id_exists_in_the_bost_glossary` needs no change — the new nodes introduce no glossed term at all.
- `test_chapter_view.gd`'s full-playthrough wealth/reputation totals (`-83.0`, `-16.0`, and the `trading_families == 9` reputation assertion) are all confirmed **unaffected** — the new choices carry zero coin or reputation effects, so nothing numeric downstream shifts. Their internal `while ... presses < 200` loops (uncapped by a fixed count) absorb the extra hops with no assertion changes needed.
- The full existing suite (296 tests as of the last merge to `master`) must grow by exactly 2 (the two new dialogue-content tests) to 298, with no failures.

## What this pass does not do

- Does not add any new NPC or portrait — Mihran is already fully portrayed.
- Does not touch `n02b`'s or `n02c`'s own text, or any other already-shipped Bost content.
- Does not add or reuse the `sikka` glossary term.
- Does not add any coin or reputation effect anywhere in this pass.
- Does not resolve the two-mints dispute or give it a specific named outcome — it stays exactly as ambiguous/unresolved as the frontier's real political fragility is everywhere else in this game.
