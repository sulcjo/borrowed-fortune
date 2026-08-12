# Farah — Umm-Kavus's Channel Fee

**Status:** approved, pending implementation plan.

## Goal

Third installment of the content-expansion initiative (after Teginabad's tutorial trade and Bost's suftaja scene). Unlike those two, Chapter 3 (Farah) is already the richest chapter in the game and does not need new content — it has a real, narrow mechanical/narrative mismatch instead: `n14_the_choice`'s own prose says Umm-Kavus's clean information channel "would cost coin," and the very next node (`n15a_umm_kavus_channel`) says the fee was "paid in advance, no argument on either side this time" — but the choice's `"effects"` dict that leads there has no `coin_spent_dirham_equivalent` at all. The text asserts a payment that never actually happens mechanically. Tahir's parallel path is correctly coin-free (his character's whole point is "no coin, I need a favor" — not a gap).

Confirmed with the user: fix only this one gap. Do not add new content to Farah, and do not also fix Teginabad's parallel gap (`n07a_bribe` has the identical pattern — prose describes a bribe payment, no `coin_spent_dirham_equivalent` effect — noted for a possible future installment, out of scope here).

## The fix

In `content/chapters/chapter_03_farah/farah.json`, `n14_the_choice`'s `"Go to Umm-Kavus's channel."` choice gains `"coin_spent_dirham_equivalent": 10.0` alongside its existing, unchanged `"flags": ["chose_umm_kavus_channel"]` and `"reputation": {"trading_families": 1}`. No other node, choice, or text in the file changes. 10.0 sits between the caravanserai bed's full price (15.0, `n10_the_price_of_a_bed`) and Bost's coin-check fee (2.0/1.0) — a flat, non-haggled professional service fee, matching the prose's own "no argument on either side this time."

## Testing

Verified directly against the real current test files, not assumed:

- `tests/unit/test_farah_dialogue_content.gd`'s `test_the_mystery_path_is_walkable_and_sets_its_flags_and_reputation()` walks this exact choice (`fork_effects := engine.choose(0) # "Go to Umm-Kavus's channel."`) but only asserts `fork_effects["flags"]` and `fork_effects["reputation"]["trading_families"]` individually — it never asserts the dict's total size or key count, so adding a new `coin_spent_dirham_equivalent` key does not break it. No change needed to this file.
- No new node means no hop-count shift anywhere — every existing `for i in range(N): engine.choose(0)` walk in every test file that passes through Farah still lands on exactly the same nodes after exactly the same number of hops.
- `tests/unit/test_chapter_view.gd` has 3 full-playthrough tests that touch this fork, checked individually, not assumed to all be affected:
  - `test_a_full_playthrough_via_the_mystery_branch_carries_prologue_flags_through_farah()` walks "always press choice 0" the whole way, and its own existing comment confirms index 0 at Farah's fork is Umm-Kavus's channel — this test's wealth assertion moves from `-67.0` to `-77.0`.
  - `test_a_full_playthrough_via_the_plunder_branch_reaches_its_own_terminal_node()` explicitly presses choice 1 ("Seek out Tahir") at this exact fork to divert onto the plunder branch — it never takes Umm-Kavus's channel at all, so its `-10.0` wealth assertion is unaffected.
  - `test_the_full_truth_is_reachable_with_strong_accumulated_reputation()` does pass through Umm-Kavus's channel (needed to reach Chapter 4A), but its own assertion is reputation-only (`trading_families == 9`) — no reputation effect changes here, only coin, so this assertion is unaffected.
- The full existing suite (296 tests as of the last merge to `master`) must stay green, no new tests added or removed.

## What this pass does not do

- Does not add any new dialogue node, NPC, or portrait.
- Does not touch Tahir's path, the checkpoint/family fork, the bed-price haggle, or any other already-shipped Farah content.
- Does not fix Teginabad's parallel `n07a_bribe` gap — noted as a candidate for a future installment, not this one.
- Does not change `content/chapters/manifest.json` or any glossary file.
