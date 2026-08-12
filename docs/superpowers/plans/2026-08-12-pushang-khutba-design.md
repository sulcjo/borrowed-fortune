# Pushang — The Khutba (Legitimacy at a Distance) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add two new dialogue nodes to Pushang dramatizing the khutba's legitimacy claim against the frontier's visible decline, per `docs/superpowers/specs/2026-08-12-pushang-khutba-design.md`.

**Architecture:** Two new content nodes inserted between two existing, unchanged nodes (`n08_the_sultans_three_tongues` and `n09_the_officers_demand`) by retargeting `n08`'s single existing choice's `next_id`. One new glossed term. No new NPC, no engine changes.

**Tech Stack:** Godot 4.3 / GDScript, GUT (headless).

## Global Constraints

- Godot 4.3.
- Test baseline confirmed on `master` just before this plan was written: **298 tests, 297 passing + 1 pre-existing harmless "risky" zero-assertion test** (`test_every_glossed_term_id_exists_in_the_merv_glossary`, unrelated — do not attempt to fix it). After this change: **300** (two new dialogue-content tests added, none removed), 299 passing + the same 1 pre-existing risky test.
- Neither new choice carries any `coin_spent_dirham_equivalent`, `coin_gained_dirham_equivalent`, or `reputation` effect — flavor-only, per the spec. Do not add any numeric effect to either new node; this is a deliberate design choice, not an oversight.
- Do not reuse or redefine the `sikka` glossary term (already glossed in `content/glossary/herat_favor_terms.json`). The new term for this pass is `khutba`, added fresh to `content/glossary/pushang_terms.json` — confirmed via direct grep to not already exist as a glossary key anywhere in the project.
- Neither new node uses an `npc_portrait` key at all (omit the key entirely, do not set it to `null`), matching this chapter's own established style for its atmospheric, no-central-NPC beats (`n01`, `n02`, `n07`, `n08` all omit it too).
- **Standing override for this project, given directly by the user this session, non-negotiable: the controller must never run this project's GUT test suite, under any circumstances.** The implementer subagent doing this task should still run tests normally as part of verifying their own work — that requirement is unchanged. The controller verifies the result via `git diff` review only, never by re-running any test command.
- Standing project override: **no reviewer subagent dispatch at any stage** — the controller self-verifies every diff (`git diff`) directly instead.
- Isolation: `git worktree add -b pushang-khutba .worktrees/pushang-khutba master` from the repo root — not the generic `EnterWorktree` tool.
- `master`'s `.godot/global_script_class_cache.cfg` is already primed from earlier work this session; this plan introduces no new `class_name` file, so a fresh worktree should not need re-priming.

---

## File Structure

| File | Purpose |
|---|---|
| `content/chapters/chapter_06_pushang/pushang.json` | Modify — retarget 1 existing choice, add 2 new nodes |
| `content/glossary/pushang_terms.json` | Modify — add 1 new glossed term (`khutba`) |
| `tests/unit/test_pushang_dialogue_content.gd` | Modify — bump 4 hop-counts, update 1 chain comment, add 2 new test functions |

---

### Task 1: Add the two new nodes, the glossary term, and fix all affected tests

**Files:**
- Modify: `content/chapters/chapter_06_pushang/pushang.json`
- Modify: `content/glossary/pushang_terms.json`
- Modify: `tests/unit/test_pushang_dialogue_content.gd`

**Interfaces:** None — this task is fully self-contained, nothing later depends on it.

- [ ] **Step 1: Retarget `n08`'s choice and insert the two new nodes**

In `content/chapters/chapter_06_pushang/pushang.json`, find `n08_the_sultans_three_tongues`. Its current single choice is:

```json
"choices": [{"text": "Continue.", "next_id": "n09_the_officers_demand", "effects": {}}]
```

Change only the `next_id` to:

```json
"choices": [{"text": "Continue.", "next_id": "n08b_the_khutba", "effects": {}}]
```

Do not change `n08`'s own `text` or anything else about it.

Then insert these two new node objects into the file (place them right after `n08_the_sultans_three_tongues` for readability, before `n09_the_officers_demand`):

```json
{
	"id": "n08b_the_khutba",
	"text": "The midday call to prayer caught up with him near the town's own mosque, close enough that the {{khutba|khutba}} carried into the street whether he stopped to listen or not. The khatib named them both, in the same practiced breath he'd clearly used every Friday of his life - the Commander of the Faithful, Caliph al-Qa'im in Baghdad, and after him, without a pause long enough to suggest the order mattered less than it should, Sultan Mas'ud, may God grant him victory. It was the same formula Farrukh had heard read in Ghazni's own grand mosque a hundred times, word for word, as if the two men named in it governed a single, unbroken thing rather than whatever this fraying stretch of road actually was.",
	"choices": [
		{"text": "Ask a passerby if the khutba's always this exact.", "next_id": "n08c_the_passerbys_answer", "effects": {"flags": ["asked_about_the_khutba"]}},
		{"text": "Notice how practiced the words sound, and say nothing.", "next_id": "n09_the_officers_demand", "effects": {}}
	]
},
{
	"id": "n08c_the_passerbys_answer",
	"text": "The man he asked - waiting out the same patch of shade, by the look of him, for reasons of his own - didn't seem to think it an odd question. \"Every week. Word for word, far as I've ever caught it.\" He considered that a moment longer than the answer needed. \"Suppose that's the one thing round here that hasn't had to change.\" He said it without much weight either way, the way a man mentions weather he's stopped having opinions about, and went back to waiting.",
	"choices": [{"text": "Continue.", "next_id": "n09_the_officers_demand", "effects": {}}]
},
```

Do not change `n09_the_officers_demand`'s own `text` or anything else in the file.

- [ ] **Step 2: Add the new glossary term**

In `content/glossary/pushang_terms.json`, add a new key `khutba`:

```json
"khutba": {
	"headword": "Khutba",
	"definition": "The sermon delivered at Friday communal prayer, in which the ruling authority is formally named and blessed - one of the two classical markers of political legitimacy in Islamic political theory, alongside the sikka (the right to strike one's name on coin). Which name a khutba invokes, and in what order, is itself a political statement."
}
```

Match the file's existing JSON formatting/indentation style for its other entries.

- [ ] **Step 3: Bump the four hop-count loops and update the chain comment**

In `tests/unit/test_pushang_dialogue_content.gd`, in each of `test_the_comply_choice_reaches_its_outcome_and_effects()`, `test_the_haggle_choice_reaches_its_outcome_and_effects()`, `test_the_refuse_choice_reaches_its_outcome_and_effects()`, and `test_the_bribe_choice_reaches_its_outcome_and_effects()`, change:

```gdscript
	for i in range(8):
```

to:

```gdscript
	for i in range(10):
```

This is a **+2** change (not +1) — confirmed by hand-tracing the full chain in the spec: `n08`'s single-choice path used to reach `n09` in 1 press; it now reaches `n09` via `n08b` and `n08c` in 3 presses (taking the "Ask" choice, index 0, at `n08b`), a net addition of 2.

Also update the inline comment in `test_the_comply_choice_reaches_its_outcome_and_effects()` from:

```gdscript
		engine.choose(0) # n01 -> n02 -> n03 -> n04 -> n05 -> n06 -> n07 -> n08 -> n09
```

to:

```gdscript
		engine.choose(0) # n01 -> n02 -> n03 -> n04 -> n05 -> n06 -> n07 -> n08 -> n08b -> n08c -> n09
```

After this loop, each of the 4 tests still expects `engine.current_node()["id"] == "n09_the_officers_demand"` (only the first test asserts this explicitly right after the loop — the other 3 rely on the same loop landing there before making their own choice). Verify this with Step 5 below rather than trusting the arithmetic alone — if any test fails on that landing node, the actual node reached will tell you whether the count needs adjusting; trust that output over this plan's arithmetic if they disagree, and report back what the real count needed to be.

- [ ] **Step 4: Add two new test functions for the new nodes**

Add these two new functions to `tests/unit/test_pushang_dialogue_content.gd` (place them after `test_the_bribe_choice_reaches_its_outcome_and_effects()`, before `test_the_full_tree_is_walkable_from_start_to_end_via_first_choices()`):

```gdscript
func test_asking_about_the_khutba_sets_a_flag_and_reaches_the_officers_demand():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_pushang_arrival")
	for i in range(8):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n08b_the_khutba")
	var effects := engine.choose(0) # "Ask a passerby if the khutba's always this exact."
	assert_eq(effects["flags"], ["asked_about_the_khutba"])
	assert_eq(engine.current_node()["id"], "n08c_the_passerbys_answer")
	engine.choose(0) # "Continue."
	assert_eq(engine.current_node()["id"], "n09_the_officers_demand")
	assert_true(engine.flags.get("asked_about_the_khutba", false))

func test_noticing_the_khutba_silently_reaches_the_officers_demand_directly():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_pushang_arrival")
	for i in range(8):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n08b_the_khutba")
	var effects := engine.choose(1) # "Notice how practiced the words sound, and say nothing."
	assert_eq(effects, {})
	assert_eq(engine.current_node()["id"], "n09_the_officers_demand")
	assert_false(engine.flags.get("asked_about_the_khutba", false))
```

Note these two new tests walk only 8 presses (to `n08b`, not `n09`) before making their own choice — that count is unaffected by Step 3's `range(8)` → `range(10)` change, since it stops one node earlier (at `n08b` itself, which is unchanged at 8 presses from `n01`).

- [ ] **Step 5: Run the affected test file**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=tests/unit/test_pushang_dialogue_content.gd -gexit
```

Expected: all tests pass, 0 failures.

- [ ] **Step 6: Run the full suite**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected: 300 tests total (298 + 2 new), 299 passing + the 1 pre-existing risky test, no failures.

- [ ] **Step 7: Commit**

```bash
git add content/chapters/chapter_06_pushang/pushang.json content/glossary/pushang_terms.json tests/unit/test_pushang_dialogue_content.gd
git commit -m "content: add the khutba legitimacy scene to Pushang"
```

---

## Self-Review

**Spec coverage:** the two new nodes and their exact text/wiring → Step 1, verbatim from the spec. The new glossary term → Step 2. The hop-count fix and chain-comment update, with the exact +2 arithmetic reasoning preserved → Step 3. The two new dialogue-content tests → Step 4. ✓ Nothing else in the spec requires a task — no NPC, no coin/reputation effect anywhere, no `sikka` reuse.

**Placeholder scan:** none.

**Type/signature consistency:** node ids (`n08b_the_khutba`, `n08c_the_passerbys_answer`), the glossary term id (`khutba`), and the flag name (`asked_about_the_khutba`) match exactly between the content JSON, the glossary JSON, and the test code. No new function or signature is introduced anywhere.

**Task granularity check:** one task. The content addition, its glossary term, and its test fixes are inseparable — a reviewer could not sensibly approve one without the others, since the new nodes don't pass their own glossary test without the term, and the existing tests don't pass without both the retargeting and the hop-count fix.
