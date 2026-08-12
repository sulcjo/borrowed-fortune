# Farah — Umm-Kavus's Channel Fee Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Umm-Kavus's channel fee (already described in prose) actually cost coin, per `docs/superpowers/specs/2026-08-12-farah-umm-kavus-fee-design.md`.

**Architecture:** A single new effects-dict key on one existing choice, plus one existing test's numeric literal updated to match. No new nodes, no engine changes.

**Tech Stack:** Godot 4.3 / GDScript, GUT (headless).

## Global Constraints

- Godot 4.3.
- Test baseline confirmed on `master` just before this plan was written: **296 tests, 295 passing + 1 pre-existing harmless "risky" zero-assertion test** (`test_every_glossed_term_id_exists_in_the_merv_glossary`, unrelated — do not attempt to fix it). After this change: still **296** — no test is added or removed, only one existing assertion's numeric literal changes.
- Confirmed via direct reading of the real current test files, not assumed: exactly one cumulative-total assertion in the whole project is affected by this change (`test_a_full_playthrough_via_the_mystery_branch_carries_prologue_flags_through_farah()` in `tests/unit/test_chapter_view.gd`). The other two full-playthrough tests are confirmed unaffected — one diverts onto a different branch at this exact fork, the other asserts reputation only. `tests/unit/test_farah_dialogue_content.gd` needs no change at all — it captures this choice's effects dict but never asserts its total size/key count.
- No new node means no hop-count shift anywhere in any test.
- **Standing override for this project, given directly by the user this session, non-negotiable: the controller must never run this project's GUT test suite, under any circumstances.** The implementer subagent doing this task should still run tests normally as part of verifying their own work — that requirement is unchanged. The controller verifies the result via `git diff` review only, never by re-running any test command.
- Standing project override: **no reviewer subagent dispatch at any stage** — the controller self-verifies every diff (`git diff`) directly instead.
- Isolation: `git worktree add -b farah-umm-kavus-fee .worktrees/farah-umm-kavus-fee master` from the repo root — not the generic `EnterWorktree` tool.
- `master`'s `.godot/global_script_class_cache.cfg` is already primed from earlier work this session; this plan introduces no new `class_name` file, so a fresh worktree should not need re-priming.

---

## File Structure

| File | Purpose |
|---|---|
| `content/chapters/chapter_03_farah/farah.json` | Modify — one new effects key on one existing choice |
| `tests/unit/test_chapter_view.gd` | Modify — one numeric literal |

---

### Task 1: Add the missing coin effect and fix the one affected total

**Files:**
- Modify: `content/chapters/chapter_03_farah/farah.json`
- Modify: `tests/unit/test_chapter_view.gd`

**Interfaces:** None — this task is fully self-contained, nothing later depends on it.

- [ ] **Step 1: Add the coin effect to `n14_the_choice`'s first choice**

In `content/chapters/chapter_03_farah/farah.json`, find `n14_the_choice` and change only its first choice's `"effects"` value from:

```json
			{"text": "Go to Umm-Kavus's channel.", "next_id": "n15a_umm_kavus_channel", "effects": {"flags": ["chose_umm_kavus_channel"], "reputation": {"trading_families": 1}}},
```

to:

```json
			{"text": "Go to Umm-Kavus's channel.", "next_id": "n15a_umm_kavus_channel", "effects": {"coin_spent_dirham_equivalent": 10.0, "flags": ["chose_umm_kavus_channel"], "reputation": {"trading_families": 1}}},
```

Do not change the second choice ("Seek out Tahir."), the node's `"text"`, or anything else in the file.

- [ ] **Step 2: Fix the one affected cumulative-total assertion**

In `tests/unit/test_chapter_view.gd`, inside `test_a_full_playthrough_via_the_mystery_branch_carries_prologue_flags_through_farah()`, change:

```gdscript
	assert_almost_eq(chapter_view.ledger.total_wealth_dirham_equivalent(), -67.0, 0.0001, "unchanged since Chapter 6 - neither Chapter 7 nor Chapter 8 has any coin effect on this path")
```

to:

```gdscript
	assert_almost_eq(chapter_view.ledger.total_wealth_dirham_equivalent(), -77.0, 0.0001, "unchanged since Chapter 6 - neither Chapter 7 nor Chapter 8 has any coin effect on this path")
```

**Do not touch** `test_a_full_playthrough_via_the_plunder_branch_reaches_its_own_terminal_node()`'s `-10.0` wealth assertion (confirmed by direct reading: that test explicitly presses choice 1, "Seek out Tahir," at this exact fork, so it never takes Umm-Kavus's channel) or `test_the_full_truth_is_reachable_with_strong_accumulated_reputation()`'s reputation assertion of `9` (confirmed: that assertion is reputation-only, and no reputation effect is changing here).

Also confirm — but do not change — that `tests/unit/test_farah_dialogue_content.gd`'s `test_the_mystery_path_is_walkable_and_sets_its_flags_and_reputation()` still passes: it captures this choice's effects dict (`fork_effects := engine.choose(0)`) and asserts `fork_effects["flags"]` and `fork_effects["reputation"]["trading_families"]` individually, never the dict's total key count, so the new `coin_spent_dirham_equivalent` key does not affect it.

- [ ] **Step 3: Run the affected test files**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=tests/unit/test_farah_dialogue_content.gd -gexit
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=tests/unit/test_chapter_view.gd -gexit
```

Expected: all tests in both files pass, 0 failures.

- [ ] **Step 4: Run the full suite**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected: 296 tests total (unchanged count), 295 passing + the 1 pre-existing risky test, no new failures.

- [ ] **Step 5: Commit**

```bash
git add content/chapters/chapter_03_farah/farah.json tests/unit/test_chapter_view.gd
git commit -m "content: make Umm-Kavus's channel fee actually cost coin in Farah"
```

---

## Self-Review

**Spec coverage:** the one effects-dict addition → Step 1, verbatim from the spec. The one affected total → Step 2, with the two confirmed-unaffected assertions explicitly called out so nobody "helpfully" touches them. The confirmed-no-change file → Step 2's closing note. ✓ Nothing else in the spec requires a task — it explicitly scopes out new content, Teginabad's parallel gap, and any manifest/glossary change.

**Placeholder scan:** none.

**Type/signature consistency:** the effects key (`coin_spent_dirham_equivalent`) and value (`10.0`) match exactly between the content JSON and this plan's own prose; no new function or signature is introduced anywhere.

**Task granularity check:** one task, matching the spec's genuinely minimal scope — there is no independently-testable sub-piece to split out.
