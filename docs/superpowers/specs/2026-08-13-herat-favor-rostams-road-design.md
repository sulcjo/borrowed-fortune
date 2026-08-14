# Herat Favor — Rostam's Own Road

**Status:** approved, pending implementation plan.

## Goal

Tenth content-expansion installment. Chapter 4B (Herat, the favor/plunder branch) is already tight and mechanically coherent, with no prose/mechanics mismatch found on direct reading of all 22 nodes. Unlike Chapter 4A's reveal-gate, this chapter has **no exhaustive-path-calibrated mechanic** (confirmed via direct grep: no `requires_reputation` anywhere in this file), so a real reputation-affecting addition is lower-risk here than it would be in 4A.

**Confirmed with the user directly:** Rostam — the "second, uglier layer" profiteer Farrukh delivers to — is currently flat, characterized by a single line (`n13_the_weight_of_knowing`: "men who weren't part of whatever cause it once served, just men who'd found a profitable way to stand in its shadow"). A backstory beat for him deepens the moral weight of `n14_the_choice` (entangle further vs. pivot away) without touching the Rayy/Buyid mystery at all — this chapter's own established design keeps that mystery deliberately unresolved (confirmed by the existing `test_the_weight_of_knowing_hedges_rather_than_asserts_the_gated_backstory` test, which the new content must not violate), and Rostam's *personal* history is a wholly separate thread from it. **Confirmed: carries real `hidden_network` reputation stakes**, not flavor-only — the user's explicit preference this round.

## The content

Retarget `n12_rostams_boast`'s single existing choice (`"Continue."`) from `next_id: "n13_the_weight_of_knowing"` to `next_id: "n12b_rostams_own_road"`. Its own `text` and `effects` (`{}`) stay unchanged. Two new nodes inserted between it and the existing, unchanged `n13_the_weight_of_knowing`:

**`n12b_rostams_own_road`**: prompted by nothing in particular (the wine, or the boast itself loosening something), Rostam reveals he started exactly where Farrukh is now — one delivery, years back, for coin he needed badly enough not to ask questions, telling himself it was the one time. Farrukh recognizes it as the same lie he'd just heard Rostam not-quite tell about the last courier (`n12_rostams_boast`) — except this one happened to Rostam himself. A direct, deliberate echo of `n15a_entangled_deeper`'s own later line ("It was, he told himself, only ever going to be one more errand") — Rostam's past previews Farrukh's possible future, without either node needing to state that connection outright. Two choices:
- `"Tell him you understand more than he thinks."` (index 0) → `n12c_a_moment_of_recognition`, effects `{"reputation": {"hidden_network": 1}}` — a real, if small, gesture of solidarity/recognition.
- `"Say nothing. It's not your place."` (index 1) → straight to `n13_the_weight_of_knowing`, effects `{}` — no penalty, matching this game's established "declining a personal matter costs nothing" precedent.

**`n12c_a_moment_of_recognition`** (only reached via "understand"): Rostam's practiced unhurriedness slips, briefly, into something closer to relief — a man who has spent a long time being seen only as dangerous, seen for a moment as something closer to human. One choice, `"Continue."` → `n13_the_weight_of_knowing`, effects `{}`.

Both paths converge on the existing `n13_the_weight_of_knowing`, unchanged. Neither new node references the Buyid/Rayy backstory, the word "crucified," or any of the specific gated-reveal content that `n13`'s own test explicitly guards against — Rostam's history is personal and self-contained, never touching the mystery.

## Testing

Verified directly against the real current test file, not assumed:

- Exactly **two** existing tests need updating: `test_the_stay_entangled_path_is_walkable_and_sets_its_flags_and_reputation()` and `test_the_pivot_away_path_is_walkable_and_sets_its_flags_and_reputation()`, both of which currently use `for i in range(12): engine.choose(0)` to reach `n14_the_choice`. Inserting 2 sequential nodes where a single direct link (`n12 -> n13`, 1 press) previously existed makes that leg `n12 -> n12b -> n12c -> n13` (3 presses, taking "understand," index 0) — a net **+2**, same arithmetic shape as every prior sequential-node insertion this session. Both `range(12)` calls become `range(14)`.
- Every other test in `test_herat_favor_dialogue_content.gd` is confirmed **unaffected**: `test_choosing_rostam_directly_skips_the_sideroad()` and `test_choosing_the_mint_visits_the_sideroad_then_converges()` both stop at `n05`, well before this insertion point; the four `test_the_payment_negotiations_*` tests all use `range(7)` to reach `n08`, also well before this insertion point; `test_the_full_tree_is_walkable_from_start_to_end_via_first_choices()` uses an uncapped `while` loop; `test_no_node_mentions_ardashir_or_the_non_standard_demonym()` and `test_the_weight_of_knowing_hedges_rather_than_asserts_the_gated_backstory()` check specific existing nodes' text content, unrelated to this insertion.
- Two new test functions needed for the new nodes: one walking "understand" through to `n12c_a_moment_of_recognition` and confirming the reputation effect + eventual convergence on `n13`, one walking "say nothing" straight to `n13` with empty effects.
- **This insertion sits on the "always press 0" path for both of Chapter 4B's own downstream forks** (the stay-entangled and pivot-away branches both pass through `n12`/`n13` identically before diverging at `n14`), so `tests/unit/test_chapter_view.gd`'s two full-playthrough tests that reach Chapter 4B both need their `hidden_network` totals updated:
  - `test_a_full_playthrough_via_the_plunder_branch_reaches_its_own_terminal_node()`: currently asserts `total == 2` (comment: "unchanged since Chapter 4B - Chapter 5 has no reputation effects at all"). New total: `n09a_paid_as_agreed` (+1) + this new node's "understand" choice (+1) + `n14`'s stay-entangled option (+1) = **3**.
  - `test_a_full_playthrough_via_the_pivot_away_path_reaches_its_own_terminal_node()`: currently asserts `total == 0` (comment: "n09a_paid_as_agreed (+1) + n14_the_choice's pivot-away option (-1) = 0"). New total: +1 (`n09a`) + 1 (this new node) − 1 (`n14` pivot-away) = **1**.
- `test_every_next_id_points_at_a_node_that_exists`, `test_exactly_two_nodes_have_no_choices_and_they_are_the_two_terminal_nodes`, and `test_every_glossed_term_id_exists_in_the_herat_favor_glossary` all automatically cover the new nodes — no manual change needed, and no new glossed term is introduced.
- The full existing suite (312 tests as of the last merge to `master`) must grow by exactly 2 (the two new dialogue-content tests) to 314, with no failures.

## What this pass does not do

- Does not reveal, hint at, or overclaim anything about the Rayy/Buyid/da'i backstory — that stays exclusive to Chapter 4A's gated reveal, per this chapter's own existing test coverage.
- Does not touch `n12`'s or `n13`'s own text, or any other already-shipped Herat-favor content.
- Does not add a coin effect anywhere — the stakes here are relational (`hidden_network` reputation), not economic.
- Does not add a new glossary term.
