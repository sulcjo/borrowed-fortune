# Teginabad — Expedited-Passage Bribe Fee Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Sa'id's expedited-passage bribe (already described in prose) actually cost coin, per `docs/superpowers/specs/2026-08-12-teginabad-bribe-fee-design.md`.

**Architecture:** A single new effects-dict key on one existing choice, plus three existing tests' numeric literals updated to match. No new nodes, no engine changes.

**Tech Stack:** Godot 4.3 / GDScript, GUT (headless).

## Global Constraints

- Godot 4.3.
- Test baseline confirmed on `master` just before this plan was written: **296 tests, 295 passing + 1 pre-existing harmless "risky" zero-assertion test** (`test_every_glossed_term_id_exists_in_the_merv_glossary`, unrelated — do not attempt to fix it). After this change: still **296** — no test is added or removed, only existing assertions' literals change.
- Confirmed via direct reading of the real current test files, not assumed: this choice sits at index 0 of `n06_the_choice`, on Chapter 1's "always press 0" path, *before* Farah's fork — so it affects **every** full-playthrough wealth total, unlike Farah's own fix which affected only one. Three assertions across two files need updating; a fourth confirmed unaffected (see below).
- **Standing override for this project, given directly by the user this session, non-negotiable: the controller must never run this project's GUT test suite, under any circumstances.** The implementer subagent doing this task should still run tests normally as part of verifying their own work — that requirement is unchanged. The controller verifies the result via `git diff` review only, never by re-running any test command.
- Standing project override: **no reviewer subagent dispatch at any stage** — the controller self-verifies every diff (`git diff`) directly instead.
- Isolation: `git worktree add -b teginabad-bribe-fee .worktrees/teginabad-bribe-fee master` from the repo root — not the generic `EnterWorktree` tool.
- `master`'s `.godot/global_script_class_cache.cfg` is already primed from earlier work this session; this plan introduces no new `class_name` file, so a fresh worktree should not need re-priming.

---

## File Structure

| File | Purpose |
|---|---|
| `content/chapters/chapter_01_teginabad/teginabad.json` | Modify — one new effects key on one existing choice |
| `tests/unit/test_teginabad_dialogue_content.gd` | Modify — one size-count literal, one new assertion line |
| `tests/unit/test_chapter_view.gd` | Modify — two numeric literals |

---

### Task 1: Add the missing coin effect and fix all affected assertions

**Files:**
- Modify: `content/chapters/chapter_01_teginabad/teginabad.json`
- Modify: `tests/unit/test_teginabad_dialogue_content.gd`
- Modify: `tests/unit/test_chapter_view.gd`

**Interfaces:** None — this task is fully self-contained, nothing later depends on it.

- [ ] **Step 1: Add the coin effect to `n06_the_choice`'s bribe choice**

In `content/chapters/chapter_01_teginabad/teginabad.json`, find `n06_the_choice` and change only the `"Pay for expedited passage."` choice's `"effects"` value from:

```json
{"flags": ["bribed_teginabad_official"], "reputation": {"townsfolk": -1, "trading_families": -1, "ghaznavid_officials": 1}}
```

to:

```json
{"coin_spent_dirham_equivalent": 6.0, "flags": ["bribed_teginabad_official"], "reputation": {"townsfolk": -1, "trading_families": -1, "ghaznavid_officials": 1}}
```

Do not change the other choice ("Let the inspection happen."), the node's `"text"`, or anything else in the file.

- [ ] **Step 2: Fix the size-count assertion and add the new coin assertion in `test_teginabad_dialogue_content.gd`**

In `test_the_bribe_path_is_walkable_and_sets_its_flag_and_reputation()`, change:

```gdscript
	assert_eq(effects.size(), 2)
	assert_eq(effects["flags"], ["bribed_teginabad_official"])
	assert_eq(effects["reputation"].size(), 3)
	assert_eq(int(effects["reputation"]["townsfolk"]), -1)
	assert_eq(int(effects["reputation"]["trading_families"]), -1)
	assert_eq(int(effects["reputation"]["ghaznavid_officials"]), 1)
```

to:

```gdscript
	assert_eq(effects.size(), 3)
	assert_eq(int(effects["coin_spent_dirham_equivalent"]), 6)
	assert_eq(effects["flags"], ["bribed_teginabad_official"])
	assert_eq(effects["reputation"].size(), 3)
	assert_eq(int(effects["reputation"]["townsfolk"]), -1)
	assert_eq(int(effects["reputation"]["trading_families"]), -1)
	assert_eq(int(effects["reputation"]["ghaznavid_officials"]), 1)
```

The `int(...)` cast on the new coin assertion matches this file's own established style for coin assertions (see the provisioner's own coin assertions elsewhere in this same file, e.g. `assert_eq(int(effects["coin_spent_dirham_equivalent"]), 8)`).

**Do not touch** `test_the_honest_path_is_walkable_and_converges_on_the_same_node()` — it exercises the *other* choice at this same node and its own `effects.size() == 1` assertion is unrelated.

- [ ] **Step 3: Fix the two affected cumulative-total assertions in `test_chapter_view.gd`**

Change:

```gdscript
	assert_almost_eq(chapter_view.ledger.total_wealth_dirham_equivalent(), -77.0, 0.0001, "unchanged since Chapter 6 - neither Chapter 7 nor Chapter 8 has any coin effect on this path")
```

to:

```gdscript
	assert_almost_eq(chapter_view.ledger.total_wealth_dirham_equivalent(), -83.0, 0.0001, "unchanged since Chapter 6 - neither Chapter 7 nor Chapter 8 has any coin effect on this path")
```

(inside `test_a_full_playthrough_via_the_mystery_branch_carries_prologue_flags_through_farah()`), and change:

```gdscript
	assert_almost_eq(chapter_view.ledger.total_wealth_dirham_equivalent(), -10.0, 0.0001, "unchanged since Chapter 4B - Chapter 5 has no coin effects at all")
```

to:

```gdscript
	assert_almost_eq(chapter_view.ledger.total_wealth_dirham_equivalent(), -16.0, 0.0001, "unchanged since Chapter 4B - Chapter 5 has no coin effects at all")
```

(inside `test_a_full_playthrough_via_the_plunder_branch_reaches_its_own_terminal_node()`).

**Do not touch** `test_a_full_playthrough_via_the_pivot_away_path_reaches_its_own_terminal_node()` (confirmed by direct reading: this test has no wealth assertion at all) or `test_the_full_truth_is_reachable_with_strong_accumulated_reputation()`'s reputation assertion of `9` (confirmed: reputation-only, no reputation effect is changing here).

- [ ] **Step 4: Run the affected test files**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=tests/unit/test_teginabad_dialogue_content.gd -gexit
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=tests/unit/test_chapter_view.gd -gexit
```

Expected: all tests in both files pass, 0 failures.

- [ ] **Step 5: Run the full suite**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected: 296 tests total (unchanged count), 295 passing + the 1 pre-existing risky test, no new failures.

- [ ] **Step 6: Commit**

```bash
git add content/chapters/chapter_01_teginabad/teginabad.json tests/unit/test_teginabad_dialogue_content.gd tests/unit/test_chapter_view.gd
git commit -m "content: make Sa'id's expedited-passage bribe actually cost coin in Teginabad"
```

---

## Self-Review

**Spec coverage:** the one effects-dict addition → Step 1, verbatim from the spec. All three affected assertions (one dialogue-content size/coin check, two cumulative totals) → Steps 2-3, with the two confirmed-unaffected assertions explicitly called out so nobody "helpfully" touches them. ✓ Nothing else in the spec requires a task.

**Placeholder scan:** none.

**Type/signature consistency:** the effects key (`coin_spent_dirham_equivalent`) and value (`6.0`) match exactly between the content JSON and this plan's own prose; the arithmetic (`-77.0 - 6.0 = -83.0`, `-10.0 - 6.0 = -16.0`) is verified. No new function or signature is introduced anywhere.

**Task granularity check:** one task, matching the spec's genuinely minimal scope — there is no independently-testable sub-piece to split out.
