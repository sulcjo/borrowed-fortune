# Bost Suftaja Scene Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a real money-changing scene to Chapter 2 (Bost) and use it to explain the suftaja mechanism in Mihran's own voice, per `docs/superpowers/specs/2026-08-12-bost-suftaja-scene-design.md`.

**Architecture:** Pure content addition — two new dialogue nodes spliced between two existing, unchanged nodes, using only the already-wired `coin_spent_dirham_equivalent`/`reputation` effects keys. No engine code, no new portrait (Mihran already exists and is already generated).

**Tech Stack:** Godot 4.3 / GDScript, GUT (headless).

## Global Constraints

- Godot 4.3.
- Test baseline confirmed on `master` just before this plan was written: **294 tests, 293 passing + 1 pre-existing harmless "risky" zero-assertion test** (`test_every_glossed_term_id_exists_in_the_merv_glossary`, unrelated — do not attempt to fix it).
- Confirmed via direct grep of the real current files, not assumed: `tests/unit/test_bost_dialogue_content.gd` has exactly 2 hardcoded-hop-count functions (both `for i in range(6):`, lines 39 and 53) reaching `n07_the_offer`; `tests/unit/test_chapter_view.gd` has exactly 3 cumulative-total assertions in the whole file (lines 167, 335, 437) — lines 207/212 are unrelated isolated `_apply_effects()` unit tests with their own synthetic input, not full-playthrough walks, and need no change.
- `master`'s `.godot/global_script_class_cache.cfg` is already primed from earlier work this session; this plan introduces no new `class_name` file, so a fresh worktree should not need re-priming for that reason — if the first GUT run in the fresh worktree fails with class-resolution errors anyway, prime once (`godot --headless --path . --editor --quit`, expect a harmless SIGSEGV) and re-run, don't pre-emptively prime.
- Standing project override in effect: **no reviewer subagent dispatch at any stage** — the controller self-verifies every diff (`git diff`) and every test run directly instead.
- Commit per task (this plan is a single task).
- Isolation: `git worktree add -b bost-suftaja-scene .worktrees/bost-suftaja-scene master` from the repo root — not the generic `EnterWorktree` tool.

---

## File Structure

| File | Purpose |
|---|---|
| `content/chapters/chapter_02_bost/bost.json` | Modify — new choice on `n02`, 2 new nodes |
| `content/glossary/bost_terms.json` | Modify — 1 new glossed term |
| `tests/unit/test_bost_dialogue_content.gd` | Modify — 2 fixed hop counts, 1 new test |
| `tests/unit/test_chapter_view.gd` | Modify — 2 of 3 cumulative-total assertions (the third is deliberately left alone) |

---

### Task 1: The ordinary-business scene and its regression fixes

**Files:**
- Modify: `content/chapters/chapter_02_bost/bost.json`
- Modify: `content/glossary/bost_terms.json`
- Modify: `tests/unit/test_bost_dialogue_content.gd`
- Modify: `tests/unit/test_chapter_view.gd`

**Interfaces:**
- Produces: node ids `n02b_the_ordinary_business`, `n02c_mihran_on_letters_of_credit` — nothing else in the codebase references these by name, this is a self-contained content addition.

- [ ] **Step 1: Update `n02_seeking_the_sarraf`'s choice**

In `content/chapters/chapter_02_bost/bost.json`, change only `n02_seeking_the_sarraf`'s `"choices"` line from:
```json
		"choices": [{"text": "Continue.", "next_id": "n03_mihran_examines", "effects": {}}]
```
to:
```json
		"choices": [{"text": "Continue.", "next_id": "n02b_the_ordinary_business", "effects": {}}]
```
Do not change `n02`'s `"text"` or `"npc_portrait"` fields, or any earlier node.

- [ ] **Step 2: Insert the 2 new nodes before `n03_mihran_examines`**

Immediately after `n02_seeking_the_sarraf`'s closing `}` (and before `n03_mihran_examines`'s opening `{`), insert these 2 node objects:

```json
		{
			"id": "n02b_the_ordinary_business",
			"text": "Before Farrukh could say why he'd come, Mihran glanced at the pouch on his belt - the same unspoken question, Farrukh guessed, that any sarraf put to a travel-worn stranger before business of any other kind. \"Thorough, or quick?\" Mihran asked, already reaching for his scale. \"Thorough, I check every coin against the stones myself. Costs a little more. Quick, I go by eye - and my eye is usually right, for what that's worth to you.\"",
			"npc_portrait": "mihran",
			"choices": [
				{"text": "Thorough. Weigh every coin.", "next_id": "n02c_mihran_on_letters_of_credit", "effects": {"coin_spent_dirham_equivalent": 2.0}},
				{"text": "Quick is fine. I trust you.", "next_id": "n02c_mihran_on_letters_of_credit", "effects": {"coin_spent_dirham_equivalent": 1.0, "reputation": {"trading_families": 1}}}
			]
		},
		{
			"id": "n02c_mihran_on_letters_of_credit",
			"text": "He worked as he talked, unbothered by silence but not opposed to filling it either. \"Where are you bound?\" Farrukh said Farah, and past it, though not why. Mihran nodded like he'd heard the shape of that answer before. \"Then you're carrying your coin the wrong way,\" he said. \"Every dirham on you past here is a dirham a bad road or a worse man can take from you. Men who move money seriously don't carry it at all - they carry paper. A letter naming a sum, and a name in some other city who already owes the man who wrote it that much, or trusts him enough to advance it without asking why. The coin never travels. Only the promise does, city to city, banker to banker, on nothing but each man's word that the last one was good for it.\" He said it the way a man recites something true and faintly boring - a fact of his trade, not a marvel. Farrukh set his father's {{suftaja|suftaja}} on the counter without a word. The same kind of paper Mihran had just finished describing. He suspected this one would not turn out to be boring at all.",
			"npc_portrait": "mihran",
			"choices": [{"text": "Continue.", "next_id": "n03_mihran_examines", "effects": {}}]
		},
```

`n03_mihran_examines` and every node after it are unchanged — do not edit them at all.

- [ ] **Step 3: Add the new glossary entry**

In `content/glossary/bost_terms.json`, add this entry to the existing object (alongside `sarraf`/`jizya`, which are unchanged):

```json
	"suftaja": {
		"headword": "Suftaja",
		"definition": "A letter of credit used across the medieval Islamic world - a name and a sum written on paper, redeemable through a network of bankers who trusted each other's word, so a merchant's money never had to survive the road in coin."
	}
```

- [ ] **Step 4: Fix the 2 hop-count assertions in `test_bost_dialogue_content.gd`**

Change both occurrences of:
```gdscript
	for i in range(6):
```
(one in `test_the_pressed_path_is_walkable_and_sets_its_flag_and_reputation()`, one in `test_the_patient_path_is_walkable_and_converges_on_the_same_node()`) to:
```gdscript
	for i in range(8):
```
Nothing else in either function changes — the `assert_eq(engine.current_node()["id"], "n07_the_offer")` line right after stays exactly as it is; only the hop count leading up to it changes.

- [ ] **Step 5: Add the new regression test to `test_bost_dialogue_content.gd`**

Add this function anywhere after the existing tests:

```gdscript
func test_the_ordinary_business_choices_have_the_right_effects():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_bost_arrival")
	for i in range(2):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n02b_the_ordinary_business")
	assert_eq(engine.current_node()["npc_portrait"], "mihran")

	var thorough_effects := engine.choose(0) # "Thorough. Weigh every coin."
	assert_eq(thorough_effects.size(), 1)
	assert_eq(int(thorough_effects["coin_spent_dirham_equivalent"]), 2)
	assert_eq(engine.current_node()["id"], "n02c_mihran_on_letters_of_credit")
	assert_eq(engine.current_node()["npc_portrait"], "mihran")

func test_taking_the_quick_option_spends_less_and_gains_reputation():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_bost_arrival")
	for i in range(2):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n02b_the_ordinary_business")
	var quick_effects := engine.choose(1) # "Quick is fine. I trust you."
	assert_eq(quick_effects.size(), 2)
	assert_eq(int(quick_effects["coin_spent_dirham_equivalent"]), 1)
	assert_eq(quick_effects["reputation"].size(), 1)
	assert_eq(int(quick_effects["reputation"]["trading_families"]), 1)
	assert_eq(engine.current_node()["id"], "n02c_mihran_on_letters_of_credit")
```

- [ ] **Step 6: Fix the 2 cumulative-total assertions in `test_chapter_view.gd` that this pass affects**

In `test_a_full_playthrough_via_the_mystery_branch_carries_prologue_flags_through_farah()`, change:
```gdscript
	assert_almost_eq(chapter_view.ledger.total_wealth_dirham_equivalent(), -65.0, 0.0001, "unchanged since Chapter 6 - neither Chapter 7 nor Chapter 8 has any coin effect on this path")
```
to:
```gdscript
	assert_almost_eq(chapter_view.ledger.total_wealth_dirham_equivalent(), -67.0, 0.0001, "unchanged since Chapter 6 - neither Chapter 7 nor Chapter 8 has any coin effect on this path")
```

In `test_a_full_playthrough_via_the_plunder_branch_reaches_its_own_terminal_node()`, change:
```gdscript
	assert_almost_eq(chapter_view.ledger.total_wealth_dirham_equivalent(), -8.0, 0.0001, "unchanged since Chapter 4B - Chapter 5 has no coin effects at all")
```
to:
```gdscript
	assert_almost_eq(chapter_view.ledger.total_wealth_dirham_equivalent(), -10.0, 0.0001, "unchanged since Chapter 4B - Chapter 5 has no coin effects at all")
```

**Do NOT touch** `test_the_full_truth_is_reachable_with_strong_accumulated_reputation()`'s `assert_eq(chapter_view.reputation_tracker.get_reputation("trading_families"), 9, ...)` line, or its trace-comment block above it — this is deliberate. The new node's reputation-bearing choice ("Quick is fine, I trust you") is at choice index 1; every full-playthrough test in this file walks via `_on_choice_pressed(0)`/`choose(0)` (always the first choice), so it always takes "Thorough" instead, which has no reputation effect. The `9` is genuinely unaffected by this pass.

- [ ] **Step 7: Run the Bost content tests**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=tests/unit/test_bost_dialogue_content.gd -gexit
```

Expected: `9/9 passed` (7 existing + 2 new), 0 failures.

- [ ] **Step 8: Run the full suite**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected: 296 tests total (294 baseline + 2 new), 295 passing + the same 1 pre-existing risky test, no new failures.

- [ ] **Step 9: Commit**

```bash
git add content/chapters/chapter_02_bost/bost.json content/glossary/bost_terms.json tests/unit/test_bost_dialogue_content.gd tests/unit/test_chapter_view.gd
git commit -m "content: add the ordinary-business scene and suftaja explainer to Chapter 2 (Bost)"
```

---

## Self-Review

**Spec coverage:**
- New nodes `n02b`/`n02c` with exact text/choices/effects → Step 2, transcribed verbatim from the spec. ✓
- `n02`'s unchanged text, new single choice pointing at `n02b` → Step 1. ✓
- New `suftaja` glossary entry → Step 3, verbatim from the spec. ✓
- 2 hop-count fixes in `test_bost_dialogue_content.gd` → Step 4. ✓
- 2 (not 3) cumulative-total fixes in `test_chapter_view.gd`, with the third's deliberate non-change explicitly called out and explained → Step 6. ✓
- New regression coverage for both `n02b` choices' effects → Step 5. ✓
- No engine change, no new portrait, no manifest change, no touch to `n03`-`n10` → confirmed, this single task never edits `engine/`, `tools/pixellab/`, `content/chapters/manifest.json`, or any node past `n02c` in `bost.json`. ✓

**Placeholder scan:** no "TBD"/"TODO"; every code/JSON block is complete and verbatim from the spec.

**Type/signature consistency:** node ids (`n02b_the_ordinary_business`, `n02c_mihran_on_letters_of_credit`) are spelled identically in the content JSON, both new test functions, and this plan's own prose. Effects dict keys (`coin_spent_dirham_equivalent`, `reputation`) match the exact keys `ChapterView._apply_effects()` already reads — no new key invented.

**Hop-count and cumulative-total verification:** re-confirmed live against the actual current files before writing this plan (not assumed): exactly 2 occurrences of `for i in range(6):` in `test_bost_dialogue_content.gd` (lines 39, 53), exactly 3 cumulative-total assertions in `test_chapter_view.gd` (lines 167, 335, 437), and the two `_apply_effects()`-only unit tests at lines 207/212 confirmed unrelated (synthetic input, no chapter walk) and correctly excluded from this plan's scope.

**Task granularity check:** one task, matching the spec's genuinely small scope — a pure content-and-test change with no independent sub-pieces (unlike the Teginabad plan, there's no separate real-money portrait-generation step here, since Mihran already exists). Splitting further would separate a content change from its own required regression-test fixes, which this project's established convention folds together deliberately.
