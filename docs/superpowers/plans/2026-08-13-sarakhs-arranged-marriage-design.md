# Sarakhs — A Wife Also Chosen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add two new dialogue nodes to Sarakhs's optional yard sideroad dramatizing arranged ghulam marriage and the Sebuk-Tegin exception, per `docs/superpowers/specs/2026-08-13-sarakhs-arranged-marriage-design.md`.

**Architecture:** Two new content nodes inserted between two existing, unchanged nodes (`n04a_the_treasurys_long_reach` and `n05_bahram_the_gatekeeper`) by retargeting `n04a`'s single existing choice's `next_id`. This sideroad is optional — only reached via `n02`'s "linger in the yard" choice — so most existing tests (which take the "go straight" path) are unaffected. No new glossary term, no new NPC, no engine changes.

**Tech Stack:** Godot 4.3 / GDScript, GUT (headless).

## Global Constraints

- Godot 4.3.
- Test baseline confirmed on `master` just before this plan was written: **300 tests, 299 passing + 1 pre-existing harmless "risky" zero-assertion test** (`test_every_glossed_term_id_exists_in_the_merv_glossary`, unrelated — do not attempt to fix it). After this change: **302** (two new dialogue-content tests added, none removed), 301 passing + the same 1 pre-existing risky test.
- Neither new choice carries any `coin_spent_dirham_equivalent`, `coin_gained_dirham_equivalent`, or `reputation` effect — flavor-only, per the spec. Do not add any numeric effect to either new node; this is a deliberate design choice, not an oversight.
- Do not add a glossary entry for `ghulam` — it stays plain prose, matching this chapter's own existing, unchanged convention (confirmed: `content/glossary/sarakhs_terms.json` only defines `ghazi`).
- Neither new node uses an `npc_portrait` key at all (omit the key entirely) — the old soldier stays unnamed and unportrayed, matching `n03a`/`n04a`'s own existing treatment of him.
- **Standing override for this project, given directly by the user this session, non-negotiable: the controller must never run this project's GUT test suite, under any circumstances.** The implementer subagent doing this task should still run tests normally as part of verifying their own work — that requirement is unchanged. The controller verifies the result via `git diff` review only, never by re-running any test command.
- Standing project override: **no reviewer subagent dispatch at any stage** — the controller self-verifies every diff (`git diff`) directly instead.
- Isolation: `git worktree add -b sarakhs-arranged-marriage .worktrees/sarakhs-arranged-marriage master` from the repo root — not the generic `EnterWorktree` tool.
- `master`'s `.godot/global_script_class_cache.cfg` is already primed from earlier work this session; this plan introduces no new `class_name` file, so a fresh worktree should not need re-priming.

---

## File Structure

| File | Purpose |
|---|---|
| `content/chapters/chapter_07_sarakhs/sarakhs.json` | Modify — retarget 1 existing choice, add 2 new nodes |
| `tests/unit/test_sarakhs_dialogue_content.gd` | Modify — fix 1 existing test's hop sequence, add 2 new test functions |

---

### Task 1: Add the two new nodes and fix the one affected test

**Files:**
- Modify: `content/chapters/chapter_07_sarakhs/sarakhs.json`
- Modify: `tests/unit/test_sarakhs_dialogue_content.gd`

**Interfaces:** None — this task is fully self-contained, nothing later depends on it.

- [ ] **Step 1: Retarget `n04a`'s choice and insert the two new nodes**

In `content/chapters/chapter_07_sarakhs/sarakhs.json`, find `n04a_the_treasurys_long_reach`. Its current single choice is:

```json
"choices": [{"text": "Continue.", "next_id": "n05_bahram_the_gatekeeper", "effects": {}}]
```

Change only the `next_id` to:

```json
"choices": [{"text": "Continue.", "next_id": "n04b_a_wife_also_chosen", "effects": {}}]
```

Do not change `n04a`'s own `text` or anything else about it.

Then insert these two new node objects into the file (place them right after `n04a_the_treasurys_long_reach` for readability, before `n05_bahram_the_gatekeeper`):

```json
{
	"id": "n04b_a_wife_also_chosen",
	"text": "The old soldier, still talking, nodded toward a woman crossing the yard with water jars balanced across a yoke - his wife, he said, without Farrukh having asked. Turkic-born too, bought young the same as he had been, and given to him the same way his sword and his post had been given to him: by the men who owned both their lives before either of them had any say in the matter. He said it without bitterness, the way he'd said everything else - a fact of the arithmetic, not a wound. \"Sebuk-Tegin married his own master's daughter,\" he added, the same story he'd told before but turned over to a different edge this time. \"That's why men still tell it. The rest of us don't marry up. We marry whoever the ledger already owns.\"",
	"choices": [
		{"text": "Ask if it's always arranged that way.", "next_id": "n04c_what_the_arrangement_makes", "effects": {"flags": ["learned_of_arranged_ghulam_marriages"]}},
		{"text": "Say nothing. It's not yours to ask about.", "next_id": "n05_bahram_the_gatekeeper", "effects": {}}
	]
},
{
	"id": "n04c_what_the_arrangement_makes",
	"text": "\"Always, far as I've ever seen,\" he said. \"Didn't stop anything growing there after, mind - I've two sons and no complaints to make of either her or them. Only that whatever grew, grew from a start neither of us picked.\" He said it the way he'd said everything else in this yard: an arithmetic, not a grievance, and went back to watching his sons' age-mates drill in the dust he'd once drilled in himself.",
	"choices": [{"text": "Continue.", "next_id": "n05_bahram_the_gatekeeper", "effects": {}}]
},
```

Do not change `n05_bahram_the_gatekeeper`'s own `text` or anything else in the file.

- [ ] **Step 2: Fix the one affected existing test**

In `tests/unit/test_sarakhs_dialogue_content.gd`, in `test_choosing_the_yard_visits_the_sideroad_then_converges()`, change:

```gdscript
	engine.choose(0)
	assert_eq(engine.current_node()["id"], "n04a_the_treasurys_long_reach")
	engine.choose(0)
	assert_eq(engine.current_node()["id"], "n05_bahram_the_gatekeeper", "the sideroad must converge on the same node the direct choice reaches")
```

to:

```gdscript
	engine.choose(0)
	assert_eq(engine.current_node()["id"], "n04a_the_treasurys_long_reach")
	engine.choose(0)
	assert_eq(engine.current_node()["id"], "n04b_a_wife_also_chosen")
	engine.choose(0) # "Ask if it's always arranged that way."
	assert_eq(engine.current_node()["id"], "n04c_what_the_arrangement_makes")
	engine.choose(0)
	assert_eq(engine.current_node()["id"], "n05_bahram_the_gatekeeper", "the sideroad must converge on the same node the direct choice reaches")
```

**Do not touch** any other test in this file — `test_choosing_straight_to_the_commander_skips_the_sideroad()` and every test that takes `n02`'s "Go straight to whoever commands this gate" choice (index 1) skip this sideroad entirely and are confirmed unaffected by the spec's own tracing. Do not add hop-count changes to any of them.

- [ ] **Step 3: Add two new test functions for the new nodes**

Add these two new functions to `tests/unit/test_sarakhs_dialogue_content.gd` (place them after `test_choosing_the_yard_visits_the_sideroad_then_converges()`, before `test_choosing_straight_to_the_commander_skips_the_sideroad()`):

```gdscript
func test_asking_about_the_arrangement_sets_a_flag_and_reaches_bahram():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_sarakhs_arrival")
	engine.choose(0) # n01 -> n02
	engine.choose(0) # "Linger in the garrison's outer yard." -> n03a
	engine.choose(0) # n03a -> n04a
	engine.choose(0) # n04a -> n04b
	assert_eq(engine.current_node()["id"], "n04b_a_wife_also_chosen")
	var effects := engine.choose(0) # "Ask if it's always arranged that way."
	assert_eq(effects["flags"], ["learned_of_arranged_ghulam_marriages"])
	assert_eq(engine.current_node()["id"], "n04c_what_the_arrangement_makes")
	engine.choose(0) # "Continue."
	assert_eq(engine.current_node()["id"], "n05_bahram_the_gatekeeper")
	assert_true(engine.flags.get("learned_of_arranged_ghulam_marriages", false))

func test_saying_nothing_about_the_arrangement_reaches_bahram_directly():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_sarakhs_arrival")
	engine.choose(0) # n01 -> n02
	engine.choose(0) # "Linger in the garrison's outer yard." -> n03a
	engine.choose(0) # n03a -> n04a
	engine.choose(0) # n04a -> n04b
	assert_eq(engine.current_node()["id"], "n04b_a_wife_also_chosen")
	var effects := engine.choose(1) # "Say nothing. It's not yours to ask about."
	assert_eq(effects, {})
	assert_eq(engine.current_node()["id"], "n05_bahram_the_gatekeeper")
	assert_false(engine.flags.get("learned_of_arranged_ghulam_marriages", false))
```

- [ ] **Step 4: Run the affected test file**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=tests/unit/test_sarakhs_dialogue_content.gd -gexit
```

Expected: all tests pass, 0 failures.

- [ ] **Step 5: Run the full suite**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected: 302 tests total (300 + 2 new), 301 passing + the 1 pre-existing risky test, no failures. If this fails, it most likely means the "always press 0" full-playthrough tests in `test_chapter_view.gd` hit an unexpected effect from this sideroad (which sits on their default path) — the spec traced this as safe (no coin/reputation effects added), but confirm the actual failure output rather than assuming, and report back exactly what you find before attempting a fix.

- [ ] **Step 6: Commit**

```bash
git add content/chapters/chapter_07_sarakhs/sarakhs.json tests/unit/test_sarakhs_dialogue_content.gd
git commit -m "content: add the arranged-marriage scene to Sarakhs's yard sideroad"
```

---

## Self-Review

**Spec coverage:** the two new nodes and their exact text/wiring → Step 1, verbatim from the spec. The one affected existing test's fix → Step 2, with every other test explicitly called out as unaffected so nobody "helpfully" touches them. The two new dialogue-content tests → Step 3. ✓ Nothing else in the spec requires a task — no NPC, no glossary term, no coin/reputation effect anywhere.

**Placeholder scan:** none.

**Type/signature consistency:** node ids (`n04b_a_wife_also_chosen`, `n04c_what_the_arrangement_makes`) and the flag name (`learned_of_arranged_ghulam_marriages`) match exactly between the content JSON and the test code. No new function or signature is introduced anywhere.

**Task granularity check:** one task. The content addition and its test fixes are inseparable — a reviewer could not sensibly approve one without the other, since the new nodes don't exist without their own tests, and the existing sideroad-convergence test doesn't pass without the retargeting.
