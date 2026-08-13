# Nishapur — Word to Nasuh (Debt Repayment)

**Status:** approved, pending implementation plan.

## Goal

Eighth installment of the content-expansion initiative, and the first to be a genuinely substantial addition rather than a small flavor vignette — per direct user request to build real, mechanically meaningful content into the previously-untouched chapters (Prologue, 4A, 4B, 5, Merv, Nishapur), starting with Nishapur.

**Real finding that motivated this:** `Ledger.pay_debt(debt, amount)` is a fully built, fully unit-tested engine method (`tests/unit/test_ledger.gd`'s `test_pay_debt_reduces_remaining_amount()` and `test_pay_debt_in_full_removes_it_from_the_ledger()`) that is never called from any content anywhere in the shipped game. The Prologue's `n06_vow` establishes 3 real named debts (Ibrahim al-Sarraf's house, 340.0; Rukn ibn Faramarz's house, 210.0; Nasuh's own back wages, 60.0), all displayed via `StatusReadout` the entire game, none ever mechanically reduced. `ChapterView._apply_effects()` has no effects key that would trigger a repayment at all — building this requires a genuine engine addition, not just content.

**Confirmed with the user directly:** land this at Nishapur, as an ending-adjacent beat, not earlier. Nishapur's existing ending scope was previously confirmed (per project memory) as "character arc only, the debt and mystery stay open" — this pass preserves that for the two larger, more abstract institutional debts, and uses the mechanic specifically and only for Nasuh's smaller, personal one, which the numbers already support (20 of 60 is a real, achievable, still-incomplete gesture) and which pays off Nasuh's own small subplot from the Prologue rather than resolving the central mystery/debt.

## The content

**Engine change:** a new `"debt_repaid"` effects key, handled in `scenes/chapter_view/ChapterView.gd`'s `_apply_effects()`:

```gdscript
if effects.has("debt_repaid"):
	var repayment: Dictionary = effects["debt_repaid"]
	var matched_debt: Debt = null
	for debt in ledger.debts:
		if debt.creditor_name == repayment["creditor_name"]:
			matched_debt = debt
			break
	assert(matched_debt != null, "debt_repaid effect references unknown creditor '%s'" % repayment["creditor_name"])
	ledger.pay_debt(matched_debt, repayment["amount_dirham_equivalent"])
	ledger.spend_dirham_equivalent(repayment["amount_dirham_equivalent"])
```

Placed after the existing `"debts"` loop, before the `coin_spent_dirham_equivalent` check. The `assert()` matches this project's established convention (`DialogueEngine.validate_tree()`) of failing loudly on malformed content rather than silently no-op'ing. Paying a debt also spends from the day-to-day wealth ledger — consistent with how *guaranteeing* a debt via kafala (`n06_vow`) costs nothing until it's actually paid.

**Content:** retarget `n03_the_turquoise_and_the_ledger`'s single existing choice (`"Continue."`) from `next_id: "n04_the_choice_before_the_khaneqah"` to `next_id: "n03b_word_to_nasuh"`. Its own `text` and `effects` (`{}`) stay unchanged. Two new nodes inserted between it and the existing, unchanged `n04_the_choice_before_the_khaneqah`:

**`n03b_word_to_nasuh`**: Farrukh, watching Nishapur's courier trade, thinks of his father's suftaja and then of Nasuh — four months unpaid, still minding a dead man's shop because nobody told him not to. Two choices:
- `"Send what you can spare toward Nasuh's wages."` (index 0) → `n03c_what_was_sent`, effects `{"debt_repaid": {"creditor_name": "Nasuh's own back wages, unpaid four months", "amount_dirham_equivalent": 20.0}}`.
- `"There's nothing to spare. Let it wait."` (index 1) → straight to `n04_the_choice_before_the_khaneqah`, effects `{}` — no penalty, matching this game's established "declining a personal matter costs nothing" precedent (Sarakhs's `n09c_declined_plainly`, this same chapter's own fallback at `n04`).

**`n03c_what_was_sent`** (only reached via "Send"): twenty dirham, folded into a letter Farrukh rewrote three times, goes west with a courier paid extra to remember his name — "not four months of wages... not even half. But it was more than a promise." One choice, `"Continue."` → `n04_the_choice_before_the_khaneqah`, effects `{}`.

Both paths converge on the existing `n04_the_choice_before_the_khaneqah`, unchanged — including its own "a smaller matter to settle, or not" line, which continues to refer only to Bahram's family token, not this new scene.

No new glossary term (this chapter already established `suftaja`-adjacent courier/credit concepts via the Prologue and Bost; this scene mentions "suftaja" and "courier" as plain prose, no new markup). No new flag — the `debt_repaid` effect itself is the trackable state change; a redundant flag on top of it would be clutter.

## Testing

Verified directly against the real current test files, not assumed:

- **New engine-level test** in `tests/unit/test_chapter_view.gd`, alongside the existing `test_apply_effects_with_coin_spent_dirham_equivalent_spends_from_the_ledger()` / `test_apply_effects_with_coin_gained_dirham_equivalent_receives_into_the_ledger()` pair: guarantee a debt via `ledger.guarantee_debt_via_kafala()`, apply a `debt_repaid` effect, assert both `total_debt_owed()` and `total_wealth_dirham_equivalent()` moved correctly.
- `tests/unit/test_nishapur_dialogue_content.gd` has 4 tests using a fixed hop-count to reach past `n04`: `test_the_family_sideroad_is_hidden_without_the_token_flag()` and `test_the_family_sideroad_is_visible_and_taken_with_the_token_flag()` (`for i in range(3): engine.choose(0)`, comment confirms `n01 -> n02 -> n03 -> n04`) and `test_the_endures_choice_reaches_its_terminal_and_sets_its_flag()` / `test_the_dissolved_choice_reaches_its_terminal_and_sets_its_flag()` (`range(7)`, reaching `n09_the_final_choice`). Inserting 2 sequential nodes where a single direct link (`n03 -> n04`, 1 press) previously existed makes that leg `n03 -> n03b -> n03c -> n04` (3 presses, taking "Send," index 0) — a net **+2**, same arithmetic shape as every prior installment's sequential-node insertion this session. `range(3)` becomes `range(5)`; `range(7)` becomes `range(9)`.
- Two new test functions needed for the new nodes: one walking "Send" through to `n03c_what_was_sent` and confirming the debt/wealth effect + eventual convergence on `n04`, one walking "There's nothing to spare" straight to `n04` with empty effects.
- `test_every_next_id_points_at_a_node_that_exists`, `test_exactly_two_nodes_have_no_choices_and_they_are_the_two_terminal_nodes`, `test_both_terminal_nodes_carry_their_own_null_next_chapter_id`, and `test_every_glossed_term_id_exists_in_the_nishapur_glossary` all automatically cover the new nodes — no manual change needed, and no new glossed term is introduced.
- `test_the_full_tree_is_walkable_from_start_to_end_via_first_choices()` uses an uncapped `while` loop — absorbs the extra hops with no assertion change needed.
- **This sits on the "always press 0" path**, so `test_chapter_view.gd`'s `test_a_full_playthrough_via_the_mystery_branch_carries_prologue_flags_through_farah()` (the only full-playthrough test that reaches Nishapur) needs its wealth assertion updated: `-83.0` → `-103.0` (an additional 20.0 spent via the new `debt_repaid` effect on the default "Send" path). Confirmed via direct reading that this test uses `chapter_view._on_choice_pressed(0)` in its loop, which correctly routes through `_apply_effects()` — the new effect genuinely fires in this full-playthrough context, not just in isolated unit tests. **A new assertion should be added** confirming `total_debt_owed() == 590.0` at the same point, to verify the wiring end-to-end in the full-playthrough context, not only via unit-level dialogue-content tests.
- The two other full-playthrough tests (`test_a_full_playthrough_via_the_plunder_branch...`, `test_a_full_playthrough_via_the_pivot_away_path...`) and the reputation-only `test_the_full_truth_is_reachable_with_strong_accumulated_reputation()` are confirmed **unaffected** — none of them reach Chapter 8 (Nishapur is the long/mystery-route's exclusive finale; the plunder and pivot-away paths both terminate at Chapter 5).
- `tests/unit/test_ledger.gd`'s existing `pay_debt` tests need no change — they test the engine method directly, independent of this new effects-key wiring.
- The full existing suite (302 tests as of the last merge to `master`) must grow by exactly 3 (1 new engine-level test + 2 new dialogue-content tests) to 305, with no failures.

## What this pass does not do

- Does not touch the two larger debts (Ibrahim al-Sarraf's 340.0, Rukn ibn Faramarz's 210.0) — they remain fully unresolved, preserving this chapter's already-confirmed "character arc only, the debt and mystery stay open" ending scope.
- Does not touch `n04`'s own text, choices, or its existing Bahram's-family sideroad, or any other already-shipped Nishapur content (including the existing final philosophical choice at `n09`/`n10a`/`n10b`).
- Does not add any reputation effect.
- Does not add a `"debt_repaid"` handler anywhere else, or retrofit it onto any earlier chapter's content — this is the mechanic's first and, for now, only use.
