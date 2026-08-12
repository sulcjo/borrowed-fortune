# Teginabad — Expedited-Passage Bribe Fee

**Status:** approved, pending implementation plan.

## Goal

Fourth installment of the content-expansion initiative (after Teginabad's tutorial trade, Bost's suftaja scene, Farah's Umm-Kavus fee fix). Same defect class as the Farah fix, flagged as deferred at the time: `n06_the_choice`'s own prose says the post's fee for "expedited passage" could be "settled now, quietly," and the very next node (`n07a_bribe`) says "Farrukh paid it... counting the coins into Sa'id's palm" — but the choice's `"effects"` dict that leads there has no `coin_spent_dirham_equivalent` at all. The text asserts a payment that never happens mechanically. The honest-inspection path (`n07b_inspection`) is correctly coin-free — nothing is paid there, it's the whole point of refusing the bribe.

## The fix

In `content/chapters/chapter_01_teginabad/teginabad.json`, `n06_the_choice`'s `"Pay for expedited passage."` choice gains `"coin_spent_dirham_equivalent": 6.0` alongside its existing, unchanged `"flags": ["bribed_teginabad_official"]` and `"reputation": {"townsfolk": -1, "trading_families": -1, "ghaznavid_officials": 1}`. No other node, choice, or text in the file changes. 6.0 sits between the provisioner's haggled-fallback price (7.0, `n11_provisioner_pushback`) and Bost's coin-check fees (2.0/1.0) — confirmed with the user directly: mid-range, more than a routine toll, less than the provisioner's full fair price, matching the weight of a real risk (a day's inspection, possible impoundment) being bought off rather than a minor convenience fee.

## Testing

Verified directly against the real current test files, not assumed:

- `tests/unit/test_teginabad_dialogue_content.gd`'s `test_the_bribe_path_is_walkable_and_sets_its_flag_and_reputation()` **does need a change**, unlike Farah's parallel test — it asserts `effects.size() == 2` (line 52) before individually checking `flags`/`reputation`, so adding a third key breaks that count assertion. Needs: `effects.size()` 2 → 3, plus a new `assert_eq(int(effects["coin_spent_dirham_equivalent"]), 6)` line, matching this same file's existing style for the provisioner's own coin assertions (`assert_eq(int(effects["coin_spent_dirham_equivalent"]), 8)` etc. at lines 125/140/154/168).
- `test_the_honest_path_is_walkable_and_converges_on_the_same_node()` (the other choice at `n06_the_choice`) is untouched — its own `effects.size() == 1` assertion is for a different choice entirely.
- This choice is choice index 0 at `n06_the_choice`, and `n06_the_choice` sits on the "always press 0" path in Chapter 1, *before* Farah's fork — so, unlike Farah's fix (which only affected the mystery-branch total), this shifts **every** full-playthrough wealth total in `tests/unit/test_chapter_view.gd`:
  - `test_a_full_playthrough_via_the_mystery_branch_carries_prologue_flags_through_farah()`: wealth assertion moves from `-77.0` to `-83.0`.
  - `test_a_full_playthrough_via_the_plunder_branch_reaches_its_own_terminal_node()`: wealth assertion moves from `-10.0` to `-16.0`.
  - `test_a_full_playthrough_via_the_pivot_away_path_reaches_its_own_terminal_node()`: confirmed by direct reading — this test has **no wealth assertion at all**, nothing to change.
  - `test_the_full_truth_is_reachable_with_strong_accumulated_reputation()`: reputation-only assertion (`trading_families == 9`), unaffected — no reputation effect is changing here, only coin.
- No new node means no hop-count shift anywhere.
- The full existing suite (296 tests as of the last merge to `master`) must stay green, no new tests added or removed.

## What this pass does not do

- Does not add any new dialogue node, NPC, or portrait.
- Does not touch the honest-inspection path, the letter callback, or any other already-shipped Teginabad content.
- Does not change `content/chapters/manifest.json` or any glossary file.
