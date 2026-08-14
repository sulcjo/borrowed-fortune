# Herat — The Mint's Delay Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add two new dialogue nodes to Herat (Chapter 4A) dramatizing the city's mint under strain from the muster, per `docs/superpowers/specs/2026-08-13-herat-mint-delay-design.md`.

**Architecture:** Two new content nodes inserted between two existing, unchanged nodes (`n05_the_bazaar_of_herat` and `n06_ardashir_introduced`) by retargeting `n05`'s single existing choice's `next_id`. No new NPC, no new glossary term, no engine changes, and critically **no coin or reputation effect anywhere** — this chapter's reveal-gate threshold (`n18`'s `min_score: 4` on `trading_families`) was calibrated via exhaustive path analysis and must not be perturbed.

**Tech Stack:** Godot 4.3 / GDScript, GUT (headless).

## Global Constraints

- Godot 4.3.
- Test baseline confirmed on `master` just before this plan was written: **310 tests, 309 passing + 1 pre-existing harmless "risky" zero-assertion test** (`test_every_glossed_term_id_exists_in_the_merv_glossary`, unrelated — do not attempt to fix it). After this change: **312** (two new dialogue-content tests added, none removed), 311 passing + the same 1 pre-existing risky test.
- **Neither new choice may carry any `coin_spent_dirham_equivalent`, `coin_gained_dirham_equivalent`, or `reputation` key at all.** This is the hardest constraint in this plan — Herat 4A's `n18_the_moment_of_truth` gates a real story branch on `trading_families >= 4`, calibrated via an exhaustive 5,760-path enumeration earlier in this project. Any reputation effect added anywhere in this chapter would require redoing that analysis. Do not add one "just for flavor" or "to make the choice feel like it matters" — the choice's only trackable effect is the flag described below.
- Do not add a new glossary term — `content/glossary/herat_terms.json` (keys: `hashar`, `dai`) is not touched.
- Do not use the banned demonym "Heratigan" anywhere in the new text (this chapter has a dedicated test guarding against it) — use "Herati."
- Do not state a specific, falsifiable date or numeric figure for the mint's slowdown — keep it impressionistic ("a season" to "half a year"), per the spec.
- **Standing override for this project, given directly by the user this session, non-negotiable: the controller must never run this project's GUT test suite, under any circumstances.** The implementer subagent doing this task should still run tests normally as part of verifying their own work — that requirement is unchanged. The controller verifies the result via `git diff` review only, never by re-running any test command.
- Standing project override: **no reviewer subagent dispatch at any stage** — the controller self-verifies every diff (`git diff`) directly instead.
- Isolation: `git worktree add -b herat-mint-delay .worktrees/herat-mint-delay master` from the repo root — not the generic `EnterWorktree` tool.
- `master`'s `.godot/global_script_class_cache.cfg` is already primed from earlier work this session; this plan introduces no new `class_name` file, so a fresh worktree should not need re-priming.

---

## File Structure

| File | Purpose |
|---|---|
| `content/chapters/chapter_04a_herat/herat.json` | Modify — retarget 1 existing choice, add 2 new nodes |
| `tests/unit/test_herat_dialogue_content.gd` | Modify — bump 8 hop-counts across 8 tests, add 2 new test functions |

---

### Task 1: Add the two new nodes and fix all affected tests

**Files:**
- Modify: `content/chapters/chapter_04a_herat/herat.json`
- Modify: `tests/unit/test_herat_dialogue_content.gd`

**Interfaces:** None — this task is fully self-contained, nothing later depends on it.

- [ ] **Step 1: Retarget `n05`'s choice and insert the two new nodes**

In `content/chapters/chapter_04a_herat/herat.json`, find `n05_the_bazaar_of_herat`. Its current single choice is:

```json
"choices": [{"text": "Continue.", "next_id": "n06_ardashir_introduced", "effects": {}}]
```

Change only the `next_id` to:

```json
"choices": [{"text": "Continue.", "next_id": "n05b_the_mint_of_herat", "effects": {}}]
```

Do not change `n05`'s own `text` or anything else about it.

Then insert these two new node objects into the file (place them right after `n05_the_bazaar_of_herat` for readability, before `n06_ardashir_introduced`):

```json
{
	"id": "n05b_the_mint_of_herat",
	"text": "Further down from the money-changers' stalls stood the building the whole bazaar's silver eventually answered to - low, heavily guarded, its yard stacked with more sacks of raw metal than finished coin. This was the mint itself, one of the Sultan's six, the thing that had made Ardashir's rate and everyone else's meaningful rather than merely agreed-upon. A line of merchants waited outside longer than any of them looked pleased about, clutching worn coin they wanted restruck clean.",
	"choices": [
		{"text": "Ask what's holding up the line.", "next_id": "n05c_what_the_line_knows", "effects": {"flags": ["asked_about_the_mints_delay"]}},
		{"text": "It's not your business today. Move on.", "next_id": "n06_ardashir_introduced", "effects": {}}
	]
},
{
	"id": "n05c_what_the_line_knows",
	"text": "\"Used to turn coin around in a season,\" the man nearest the gate said, not looking especially eager to be overheard saying it. \"Now it's closer to half a year, and getting worse, not better.\" He didn't say why, and didn't need to - every silver dirham the mint restruck was silver the muster wasn't currently spending, and a garrison calling men up sooner and thinner than usual had first claim on whatever metal moved through this city at all.",
	"choices": [{"text": "Continue.", "next_id": "n06_ardashir_introduced", "effects": {}}]
},
```

Do not change `n06_ardashir_introduced`'s own `text` or anything else in the file.

- [ ] **Step 2: Bump the eight hop-count loops**

In `tests/unit/test_herat_dialogue_content.gd`, in each of `test_the_first_haggles_fair_path()`, `test_the_first_haggles_push_too_far_path()`, `test_the_first_haggles_backing_off_reaches_the_same_node_as_accepting()`, and `test_the_first_haggles_walk_away_path_has_no_effects()`, change:

```gdscript
	for i in range(6):
```

to:

```gdscript
	for i in range(8):
```

In each of `test_the_second_haggles_fair_path()`, `test_the_second_haggles_push_too_far_path()`, `test_the_second_haggles_reduced_fee_path()`, and `test_the_second_haggles_decline_path_has_no_effects()`, change:

```gdscript
	for i in range(9):
```

to:

```gdscript
	for i in range(11):
```

In each of `test_the_default_path_reaches_the_partial_truth()`, `test_sufficient_reputation_reveals_the_full_truth_choice()`, and `test_insufficient_reputation_still_hides_the_gated_choice()`, change:

```gdscript
	for i in range(14):
```

to:

```gdscript
	for i in range(16):
```

This is a **+2** change in every case (not +1) — confirmed by hand-tracing the full chain in the spec: `n05`'s single-choice path used to reach `n06` in 1 press; it now reaches `n06` via `n05b` and `n05c` in 3 presses (taking "Ask," index 0, at `n05b`), a net addition of 2. Verify with Step 4 below rather than trusting the arithmetic alone — if any test fails on its post-loop landing-node assertion, trust the actual output over this plan's arithmetic, adjust the count to whatever actually reaches the expected node, and report exactly what you found and changed.

**Do not touch** `test_choosing_the_bazaar_directly_skips_the_sideroad()` or `test_choosing_the_garrison_gate_visits_the_old_soldier_then_converges()` — both stop exactly at `n05` and are confirmed unaffected. Do not touch `test_the_full_tree_is_walkable_from_start_to_end_via_first_choices()` (uncapped loop), `test_aftermath_nodes_do_not_assume_the_gated_full_truth_was_given()`, `test_no_node_uses_the_non_standard_demonym()`, or `test_the_muster_and_rayy_dates_are_anchored_to_the_1035_present()` — none of these are affected by this insertion.

- [ ] **Step 3: Add two new test functions for the new nodes**

Add these two new functions to `tests/unit/test_herat_dialogue_content.gd` (place them after `test_choosing_the_garrison_gate_visits_the_old_soldier_then_converges()`, before `test_the_first_haggles_fair_path()`):

```gdscript
func test_asking_about_the_mints_delay_sets_a_flag_and_reaches_ardashir():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival")
	engine.choose(0) # n01 -> n02
	engine.choose(1) # "Head straight for the bazaar." -> n05
	assert_eq(engine.current_node()["id"], "n05_the_bazaar_of_herat")
	engine.choose(0) # n05 -> n05b
	assert_eq(engine.current_node()["id"], "n05b_the_mint_of_herat")
	var effects := engine.choose(0) # "Ask what's holding up the line."
	assert_eq(effects["flags"], ["asked_about_the_mints_delay"])
	assert_eq(engine.current_node()["id"], "n05c_what_the_line_knows")
	engine.choose(0) # "Continue."
	assert_eq(engine.current_node()["id"], "n06_ardashir_introduced")
	assert_true(engine.flags.get("asked_about_the_mints_delay", false))

func test_moving_on_from_the_mint_reaches_ardashir_directly():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival")
	engine.choose(0) # n01 -> n02
	engine.choose(1) # "Head straight for the bazaar." -> n05
	engine.choose(0) # n05 -> n05b
	assert_eq(engine.current_node()["id"], "n05b_the_mint_of_herat")
	var effects := engine.choose(1) # "It's not your business today. Move on."
	assert_eq(effects, {})
	assert_eq(engine.current_node()["id"], "n06_ardashir_introduced")
	assert_false(engine.flags.get("asked_about_the_mints_delay", false))
```

Indices confirmed directly against the existing `test_choosing_the_bazaar_directly_skips_the_sideroad()` in the same file: `n01` has a single choice (`choose(0)` reaches `n02`), and `n02`'s "Head straight for the bazaar" is index 1 (its other choice, "Let the garrison gate draw you first," is index 0). Both tests above route through the bazaar-direct path specifically to avoid re-testing the already-covered garrison sideroad.

- [ ] **Step 4: Run the affected test file**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=tests/unit/test_herat_dialogue_content.gd -gexit
```

Expected: all tests pass, 0 failures.

- [ ] **Step 5: Run the full suite**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected: 312 tests total (310 + 2 new), 311 passing + the 1 pre-existing risky test, no failures.

- [ ] **Step 6: Commit**

```bash
git add content/chapters/chapter_04a_herat/herat.json tests/unit/test_herat_dialogue_content.gd
git commit -m "content: add the mint's-delay scene to Herat"
```

---

## Self-Review

**Spec coverage:** the two new nodes and their exact text/wiring → Step 1, verbatim from the spec. The hop-count fix across 8 tests, with the exact +2 arithmetic reasoning preserved → Step 2. The two new dialogue-content tests → Step 3. ✓ Nothing else in the spec requires a task — no NPC, no glossary term, no coin/reputation effect anywhere.

**Placeholder scan:** none.

**Type/signature consistency:** node ids (`n05b_the_mint_of_herat`, `n05c_what_the_line_knows`) and the flag name (`asked_about_the_mints_delay`) match exactly between the content JSON and the test code.

**Self-caught inconsistency, fixed inline during this review:** an earlier draft of Step 3's tests used `choose(1)` for the `n01 -> n02` step, which is wrong — `n01` has only one choice (index 0). Fixed directly by cross-checking against the existing `test_choosing_the_bazaar_directly_skips_the_sideroad()` test already in the file, which proves both indices used above.

**Task granularity check:** one task. The content addition and its test fixes are inseparable — a reviewer could not sensibly approve one without the other, since the new nodes don't exist without their own tests, and the existing tests don't pass without both the retargeting and the hop-count fix.
