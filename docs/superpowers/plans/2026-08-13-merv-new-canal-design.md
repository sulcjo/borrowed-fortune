# Merv — The New Canal Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add one new dialogue node to Merv deepening its established dramatic-irony theme, per `docs/superpowers/specs/2026-08-13-merv-new-canal-design.md`.

**Architecture:** One new content node inserted between two existing, unchanged nodes (`n02_the_citadel_that_was` and `n03_the_bazaar_at_the_crossing`) by retargeting `n02`'s single existing choice's `next_id`. No new NPC, no glossary term, no engine changes, no coin/reputation/flag effect — a single pure-narration node, matching this chapter's own established rhythm.

**Tech Stack:** Godot 4.3 / GDScript, GUT (headless).

## Global Constraints

- Godot 4.3.
- Test baseline confirmed on `master` just before this plan was written: **316 tests, 315 passing + 1 pre-existing harmless "risky" zero-assertion test** (`test_every_glossed_term_id_exists_in_the_merv_glossary`, unrelated — do not attempt to fix it). After this change: **still 316** — no new test function is added; the existing structural/wiring tests already cover any new node automatically.
- This is a **single new node with no choices beyond "Continue," no effects dict content, no flag** — do not add a coin, reputation, or flag effect anywhere in this pass.
- Do not add a new glossary term — express the canal-work content in plain English, no new technical loanword.
- Do not reference Merv's real 1037 fall, its later 12th-century "great city" reputation, or anything the characters couldn't plausibly know in 1035.
- **Standing override for this project, given directly by the user this session, non-negotiable: the controller must never run this project's GUT test suite, under any circumstances.** The implementer subagent doing this task should still run tests normally as part of verifying their own work — that requirement is unchanged. The controller verifies the result via `git diff` review only, never by re-running any test command.
- Standing project override: **no reviewer subagent dispatch at any stage** — the controller self-verifies every diff (`git diff`) directly instead.
- Isolation: `git worktree add -b merv-new-canal .worktrees/merv-new-canal master` from the repo root — not the generic `EnterWorktree` tool.
- `master`'s `.godot/global_script_class_cache.cfg` is already primed from earlier work this session; this plan introduces no new `class_name` file, so a fresh worktree should not need re-priming.

---

## File Structure

| File | Purpose |
|---|---|
| `content/chapters/chapter_07b_merv/merv.json` | Modify — retarget 1 existing choice, add 1 new node |
| `tests/unit/test_merv_dialogue_content.gd` | Modify — bump 3 hop-counts from `range(4)` to `range(5)` |

---

### Task 1: Add the new node and fix the affected tests

**Files:**
- Modify: `content/chapters/chapter_07b_merv/merv.json`
- Modify: `tests/unit/test_merv_dialogue_content.gd`

**Interfaces:** None — this task is fully self-contained, nothing later depends on it.

- [ ] **Step 1: Retarget `n02`'s choice and insert the new node**

In `content/chapters/chapter_07b_merv/merv.json`, find `n02_the_citadel_that_was`. Its current single choice is:

```json
"choices": [{"text": "Continue.", "next_id": "n03_the_bazaar_at_the_crossing", "effects": {}}]
```

Change only the `next_id` to:

```json
"choices": [{"text": "Continue.", "next_id": "n02b_the_new_canal", "effects": {}}]
```

Do not change `n02`'s own `text` or anything else about it.

Then insert this one new node object into the file (place it right after `n02_the_citadel_that_was` for readability, before `n03_the_bazaar_at_the_crossing`):

```json
{
	"id": "n02b_the_new_canal",
	"text": "Past the old quarter's empty lanes, work of a different kind: a new channel being cut from the river itself, laborers up to their knees in mud, widening a stretch of desert into land that would, in a season or two, be worth taxing. His guide pointed it out with the satisfaction of a man discussing his own household's accounts - Merv, he said, had been doing this since before anyone could remember, and would keep doing it long after everyone currently digging was dust. Farrukh had no particular reason to doubt him.",
	"choices": [{"text": "Continue.", "next_id": "n03_the_bazaar_at_the_crossing", "effects": {}}]
},
```

Do not change `n03_the_bazaar_at_the_crossing`'s own `text` or anything else in the file.

- [ ] **Step 2: Bump the three affected hop-count loops**

In `tests/unit/test_merv_dialogue_content.gd`, in each of `test_the_pay_in_full_choice_reaches_its_outcome_and_effects()`, `test_the_haggle_choice_reaches_its_outcome_and_effects()`, and `test_the_decline_choice_reaches_its_outcome_and_effects()`, change:

```gdscript
	for i in range(4):
```

to:

```gdscript
	for i in range(5):
```

This is a **+1** change (not the +2 seen in every other installment this session) — confirmed by hand-tracing the chain in the spec: this pass inserts only **one** new node (not two), so the `n02 -> n03` leg (previously 1 press) becomes 2 presses (`n02 -> n02b -> n03`), a net addition of 1. The first test's inline comment (`# n01 -> n02 -> n03 -> n04 -> n05`) should be updated to `# n01 -> n02 -> n02b -> n03 -> n04 -> n05` to stay accurate. Verify with Step 3 below rather than trusting the arithmetic alone — if any test fails on its post-loop landing-node assertion, trust the actual output over this plan's arithmetic, adjust the count to whatever actually reaches `n05_the_sarrafs_price`, and report exactly what you found and changed.

**Do not touch** `test_every_next_id_points_at_a_node_that_exists`, `test_exactly_one_node_has_no_choices_and_it_is_the_last_node`, `test_the_terminal_node_points_at_chapter_8`, `test_every_glossed_term_id_exists_in_the_merv_glossary`, or `test_the_full_tree_is_walkable_from_start_to_end_via_first_choices()` (uncapped loop) — all confirmed unaffected in the spec. Do not touch anything in `tests/unit/test_chapter_view.gd` — confirmed via direct grep in the spec that no full-playthrough test there ever routes through Merv at all.

- [ ] **Step 3: Run the affected test file**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=tests/unit/test_merv_dialogue_content.gd -gexit
```

Expected: all tests pass, 0 failures.

- [ ] **Step 4: Run the full suite**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected: 316 tests total (unchanged — no new test function added), 315 passing + the 1 pre-existing risky test, no failures.

- [ ] **Step 5: Commit**

```bash
git add content/chapters/chapter_07b_merv/merv.json tests/unit/test_merv_dialogue_content.gd
git commit -m "content: add the new-canal scene to Merv"
```

---

## Self-Review

**Spec coverage:** the one new node and its exact text/wiring → Step 1, verbatim from the spec. The hop-count fix, with the exact +1 arithmetic reasoning (deliberately different from every prior installment's +2) preserved → Step 2. ✓ Nothing else in the spec requires a task — no NPC, no glossary term, no coin/reputation/flag effect, and confirmed zero cross-file test impact.

**Placeholder scan:** none.

**Type/signature consistency:** the node id (`n02b_the_new_canal`) matches exactly between the content JSON and the updated test comment. No new function, flag, or effects key is introduced anywhere.

**Task granularity check:** one task, the smallest-scoped installment of this entire session — a single node, a single-line hop-count fix repeated three times, no new test function needed at all.
