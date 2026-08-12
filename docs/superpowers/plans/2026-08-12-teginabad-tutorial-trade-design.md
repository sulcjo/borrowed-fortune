# Teginabad Tutorial Trade Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the game's first economic content to Chapter 1 (Teginabad) — three new dialogue nodes at the chapter's end where Farrukh provisions for the desert crossing, per `docs/superpowers/specs/2026-08-12-teginabad-tutorial-trade-design.md`.

**Architecture:** Pure content addition on top of already-shipped, unmodified engine machinery — `coin_spent_dirham_equivalent`/`reputation` effects keys, `DialogueEngine`/`ChapterView._apply_effects()` — plus one new portrait generated via the existing pixellab pipeline. No engine code, no scene changes, no Theme changes.

**Tech Stack:** Godot 4.3 / GDScript, GUT (headless), Python 3 + pixellab SDK (offline dev tool, not shipped).

## Global Constraints

- Godot 4.3.
- Test baseline confirmed on `master` just before this plan was written: **289 tests, 288 passing + 1 pre-existing harmless "risky" zero-assertion test** (`test_every_glossed_term_id_exists_in_the_merv_glossary`, unrelated — do not attempt to fix it).
- Hop counts verified live against the real dialogue tree before writing this plan, not assumed: today, `engine.choose(0)` called 8 times from `n01_teginabad_arrival` reaches `n09_departure_teginabad` (confirmed via a real script run — `visited: 8, final node id: n09_departure_teginabad`). Once `n09` gains its new single choice, reaching `n10_the_provisioner` takes **9** `choose(0)` calls, and reaching the new terminal `n12_departure_provisioned` via always-first-choice takes **10**.
- Confirmed via direct grep: `"n09_departure_teginabad"` appears in exactly 2 places across the entire `tests/` directory, both in `tests/unit/test_teginabad_dialogue_content.gd` (line 24 and line 113) — no other test file references it.
- `master`'s `.godot/global_script_class_cache.cfg` is already primed from earlier work this session; this plan introduces no new `class_name` file, so a fresh worktree should not need re-priming for that reason — if the first GUT run in the fresh worktree fails with class-resolution errors anyway, prime once (`godot --headless --path . --editor --quit`, expect a harmless SIGSEGV) and re-run, don't pre-emptively prime.
- Any pixellab-generated PNG loads at runtime via raw `FileAccess.file_exists()` + `Image.load_from_file()` + `ImageTexture.create_from_image()`, never Godot's `load()` — already true of `ChapterView._load_portrait_texture()`, no change needed there.
- Standing project override in effect: **no reviewer subagent dispatch at any stage** — the controller self-verifies every diff (`git diff`) and every test run directly instead.
- Commit per task.
- Isolation: `git worktree add -b teginabad-tutorial-trade .worktrees/teginabad-tutorial-trade master` from the repo root — not the generic `EnterWorktree` tool.
- Task 2's portrait generation is a real, funded pixellab API call (1 generation) — run it as an explicit, visible step.

---

## File Structure

| File | Task | Purpose |
|---|---|---|
| `content/chapters/chapter_01_teginabad/teginabad.json` | 1 | Modify — new choice on `n09`, 3 new nodes |
| `tests/unit/test_teginabad_dialogue_content.gd` | 1 | Modify — 2 fixed assertions, 4 new tests |
| `tools/pixellab/npcs.json` | 2 | Modify — 1 new NPC entry |
| `assets/portraits/teginabadprovisioner.png` | 2 | Create — real generation |
| `tests/unit/test_npc_portrait_content.gd` | 2 | Modify — 1 new test |

---

### Task 1: Content — three new nodes, chapter end moves to `n12`

**Files:**
- Modify: `content/chapters/chapter_01_teginabad/teginabad.json`
- Modify: `tests/unit/test_teginabad_dialogue_content.gd`

**Interfaces:**
- Produces: node ids `n10_the_provisioner`, `n11_provisioner_pushback`, `n12_departure_provisioned` and flag `haggled_at_teginabad` — Task 2's portrait test (not in this task) references the first two node ids by string; nothing else in the codebase depends on this task's output.

- [ ] **Step 1: Update `n09_departure_teginabad`'s choices**

In `content/chapters/chapter_01_teginabad/teginabad.json`, find the `n09_departure_teginabad` node (currently the last node in the array, with `"choices": []`) and change only its `"choices"` line to:

```json
			"choices": [{"text": "Continue.", "next_id": "n10_the_provisioner", "effects": {}}]
```

Do not change `n09`'s `"text"` field or any earlier node.

- [ ] **Step 2: Append the 3 new nodes**

Immediately after `n09_departure_teginabad`'s closing `}`, add these 3 node objects (before the array's closing `]`):

```json
		{
			"id": "n10_the_provisioner",
			"text": "At the last stall before the gate closed off the desert road, a woman was calling out prices for waterskins, dried dates, and feed enough for two animals across empty country - the same unglamorous arithmetic Farrukh had waved past an hour before, when the caravan master's fee hadn't seemed worth arguing over. This time, for no reason he could have named, it did. She named eight dirhams for the lot, in the flat voice of someone who'd already decided what she'd settle for and wasn't going to say so first.",
			"npc_portrait": "teginabadprovisioner",
			"choices": [
				{"text": "Pay what she asks.", "next_id": "n12_departure_provisioned", "effects": {"coin_spent_dirham_equivalent": 8.0, "reputation": {"trading_families": 1}}},
				{"text": "Try to talk her down.", "next_id": "n11_provisioner_pushback", "effects": {}},
				{"text": "Take the water, skip the rest, and go.", "next_id": "n12_departure_provisioned", "effects": {"coin_spent_dirham_equivalent": 3.0}}
			]
		},
		{
			"id": "n11_provisioner_pushback",
			"text": "She didn't look up from tying off a waterskin. \"Eight is the price for a man who wants to reach Bost with feed left over,\" she said. \"I can do seven, if you're the praying kind and don't mind your animals thinking hard thoughts about you around Bost.\" It wasn't much of a concession. It was, Farrukh noted with something almost like satisfaction, a concession.",
			"npc_portrait": "teginabadprovisioner",
			"choices": [
				{"text": "Take the seven.", "next_id": "n12_departure_provisioned", "effects": {"coin_spent_dirham_equivalent": 7.0, "flags": ["haggled_at_teginabad"]}},
				{"text": "Pay the eight after all.", "next_id": "n12_departure_provisioned", "effects": {"coin_spent_dirham_equivalent": 8.0, "reputation": {"trading_families": 1}}}
			]
		},
		{
			"id": "n12_departure_provisioned",
			"text": "The gate fell behind him with the animals fed and the waterskins full, whatever that had cost. It was a small thing - a woman's asking price, met or shaved down by one dirham, nothing that would have troubled his father's ledgers for a moment - but it was the first arithmetic since Ghazni that Farrukh had done because he wanted to, and not because grief or custom or a customs officer's patience had required it of him. The desert road to Bost opened out ahead, indifferent to the distinction, the way roads are.",
			"choices": []
		}
```

`n12_departure_provisioned` has no `"npc_portrait"` key (Farrukh is alone again) and no `"next_chapter_id"` key (defers to the manifest's existing `chapter_02_bost` default for this chapter, exactly as `n09` did before this change).

- [ ] **Step 3: Fix the 2 existing tests that assert the old terminal node**

In `tests/unit/test_teginabad_dialogue_content.gd`:

Change:
```gdscript
	assert_eq(end_node_ids, ["n09_departure_teginabad"])
```
to:
```gdscript
	assert_eq(end_node_ids, ["n12_departure_provisioned"])
```

And change:
```gdscript
	assert_eq(engine.current_node()["id"], "n09_departure_teginabad")
```
to:
```gdscript
	assert_eq(engine.current_node()["id"], "n12_departure_provisioned")
```

Nothing else in either function changes.

- [ ] **Step 4: Add 4 new tests for the provisioner scene**

Add these functions to `tests/unit/test_teginabad_dialogue_content.gd` (anywhere after the existing tests):

```gdscript
func test_paying_the_provisioner_fair_price_spends_eight_and_gains_reputation():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_teginabad_arrival")
	for i in range(9):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n10_the_provisioner")
	var effects := engine.choose(0) # "Pay what she asks."
	# See NOTE in test_the_bribe_path_is_walkable_and_sets_its_flag_and_reputation() above
	# on why this is split instead of one assert_eq(effects, {...}).
	assert_eq(effects.size(), 2)
	assert_eq(int(effects["coin_spent_dirham_equivalent"]), 8)
	assert_eq(effects["reputation"].size(), 1)
	assert_eq(int(effects["reputation"]["trading_families"]), 1)
	assert_eq(engine.current_node()["id"], "n12_departure_provisioned")

func test_haggling_then_accepting_the_counter_spends_seven_and_sets_the_flag():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_teginabad_arrival")
	for i in range(9):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n10_the_provisioner")
	engine.choose(1) # "Try to talk her down."
	assert_eq(engine.current_node()["id"], "n11_provisioner_pushback")
	var effects := engine.choose(0) # "Take the seven."
	assert_eq(effects.size(), 2)
	assert_eq(int(effects["coin_spent_dirham_equivalent"]), 7)
	assert_eq(effects["flags"], ["haggled_at_teginabad"])
	assert_eq(engine.current_node()["id"], "n12_departure_provisioned")
	assert_true(engine.flags.get("haggled_at_teginabad", false))

func test_haggling_then_backing_off_spends_eight_and_still_gains_reputation():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_teginabad_arrival")
	for i in range(9):
		engine.choose(0)
	engine.choose(1) # "Try to talk her down."
	assert_eq(engine.current_node()["id"], "n11_provisioner_pushback")
	var effects := engine.choose(1) # "Pay the eight after all."
	assert_eq(effects.size(), 2)
	assert_eq(int(effects["coin_spent_dirham_equivalent"]), 8)
	assert_eq(effects["reputation"].size(), 1)
	assert_eq(int(effects["reputation"]["trading_families"]), 1)
	assert_eq(engine.current_node()["id"], "n12_departure_provisioned")
	assert_false(engine.flags.get("haggled_at_teginabad", false), "backing off must not set the flag the accept-the-counter path sets")

func test_taking_only_water_spends_three_with_no_reputation_or_flag():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_teginabad_arrival")
	for i in range(9):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n10_the_provisioner")
	var effects := engine.choose(2) # "Take the water, skip the rest, and go."
	assert_eq(effects.size(), 1)
	assert_eq(int(effects["coin_spent_dirham_equivalent"]), 3)
	assert_eq(engine.current_node()["id"], "n12_departure_provisioned")
```

- [ ] **Step 5: Run the Teginabad content tests**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=tests/unit/test_teginabad_dialogue_content.gd -gexit
```

Expected: `11/11 passed` (7 existing + 4 new), 0 failures.

- [ ] **Step 6: Run the full suite**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected: 293 tests total (289 baseline + 4 new — this task adds no new tests to any other file), 292 passing + the same 1 pre-existing risky test, no new failures.

- [ ] **Step 7: Commit**

```bash
git add content/chapters/chapter_01_teginabad/teginabad.json tests/unit/test_teginabad_dialogue_content.gd
git commit -m "content: add tutorial trade at the end of Chapter 1 (Teginabad)"
```

---

### Task 2: New portrait — the provisioner

**Files:**
- Modify: `tools/pixellab/npcs.json`
- Create (regenerate): `assets/portraits/teginabadprovisioner.png`
- Modify: `tests/unit/test_npc_portrait_content.gd`

**Interfaces:**
- Consumes: node ids `n10_the_provisioner`/`n11_provisioner_pushback`/`n12_departure_provisioned` from Task 1's content (by string, to locate them in the test) — does not require Task 1's tests to have been run first; `ChapterView._load_portrait_texture()`'s null-safe fallback means this task's own tests do not depend on Task 1 having completed, and vice versa. Sequenced second here only because Task 1 is the larger, more central piece.
- Produces: nothing consumed by a later task.

- [ ] **Step 1: Add the new NPC entry**

In `tools/pixellab/npcs.json`, add this entry to the `"npcs"` array (anywhere in the list — order doesn't matter, the generator iterates the whole array):

```json
    {
      "id": "teginabadprovisioner",
      "description": "a weathered provisioner woman at a roadside stall, waterskins and dried dates on display, practical desert-travel dress, waist-up portrait bust"
    }
```

- [ ] **Step 2: Generate the portrait**

This is a real, funded pixellab API call — one generation. Do **not** pass `--force` — every other already-generated portrait must be left untouched; this run should only generate the one new file that doesn't exist yet.

```bash
/run/media/sulcjo/sulcjo-data/fun/borrowed-fortune/.venv-pixellab/bin/python3 tools/pixellab/generate_portraits.py
```

Expected: a line reading `generated teginabadprovisioner -> assets/portraits/teginabadprovisioner.png (usage: ...)`, and every other existing NPC/Farrukh-stage entry printed as `skip <id> (already exists)` — if any OTHER portrait shows `generated` instead of `skip`, stop and investigate; that would mean an existing, already-shipped portrait got overwritten, which this step must not do.

- [ ] **Step 3: Verify only the new file was written**

```bash
git status --short assets/portraits/
```

Expected: exactly one new untracked file, `assets/portraits/teginabadprovisioner.png`. No existing portrait file should show as modified.

- [ ] **Step 4: Add the portrait test**

Add this function to `tests/unit/test_npc_portrait_content.gd` (anywhere after the existing tests, following the file's own `_portrait_for()` helper pattern):

```gdscript
func test_teginabad_provisioner_portrait_is_set_on_both_haggle_nodes():
	var nodes := _load_dialogue("res://content/chapters/chapter_01_teginabad/teginabad.json")
	assert_eq(_portrait_for(nodes, "n10_the_provisioner"), "teginabadprovisioner")
	assert_eq(_portrait_for(nodes, "n11_provisioner_pushback"), "teginabadprovisioner")
	assert_null(_portrait_for(nodes, "n12_departure_provisioned"), "Farrukh is alone again by departure")
```

- [ ] **Step 5: Run the portrait content tests**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=tests/unit/test_npc_portrait_content.gd -gexit
```

Expected: all tests in this file pass (6 existing + 1 new = 7), 0 failures.

- [ ] **Step 6: Run the full suite (final regression gate for this plan)**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected: 294 tests total (293 after Task 1 + 1 new here), 293 passing + the 1 pre-existing risky test, 0 new failures.

- [ ] **Step 7: Commit**

```bash
git add tools/pixellab/npcs.json assets/portraits/teginabadprovisioner.png tests/unit/test_npc_portrait_content.gd
git commit -m "feat: generate the Teginabad provisioner's portrait"
```

---

## Self-Review

**Spec coverage:**
- New nodes `n10`/`n11`/`n12` with exact text/choices/effects → Task 1 Steps 1-2, transcribed verbatim from the spec. ✓
- `n09` unchanged text, new single choice → Task 1 Step 1. ✓
- "Pay the eight after all" gets the same reputation as paying fair directly (the spec's own self-review catch) → Task 1 Step 2's node text includes `"reputation": {"trading_families": 1}` on that exact choice, and Task 1 Step 4's `test_haggling_then_backing_off_spends_eight_and_still_gains_reputation` test asserts it explicitly, plus asserts the flag is *not* set (distinguishing it from the accept-the-counter path). ✓
- 2 existing tests fixed to the new terminal node → Task 1 Step 3. ✓
- New portrait, `npcs.json` entry, non-forced generation, verification that nothing else regenerated → Task 2 Steps 1-3. ✓
- New portrait test following the established `_portrait_for()` pattern → Task 2 Step 4. ✓
- No manifest change, no engine change, no glossary change → no task touches `content/chapters/manifest.json`, `engine/`, or any glossary file. ✓
- No tutorial-hint/narrator-aside text → none of the new node text breaks the fourth wall; confirmed by re-reading Task 1 Step 2's text against the spec. ✓

**Placeholder scan:** no "TBD"/"TODO"; every code/JSON block is complete and verbatim from the spec, not paraphrased.

**Type/signature consistency:** node ids (`n10_the_provisioner`, `n11_provisioner_pushback`, `n12_departure_provisioned`) and the flag name (`haggled_at_teginabad`) are spelled identically everywhere they appear — Task 1's content, Task 1's tests, and Task 2's portrait test and lookup. Effects dict keys (`coin_spent_dirham_equivalent`, `reputation`, `flags`) match the exact keys `ChapterView._apply_effects()` already reads (confirmed by reading that method directly before writing the spec) — no new key is invented.

**Hop-count verification:** re-confirmed live against the actual current dialogue tree before writing this plan (not assumed): 8 `choose(0)` calls reach today's `n09` end node; this plan's new tests use 9 (to land on `n10`) since `n09` gains one more hop. Cross-checked against the existing `test_the_bribe_path_is_walkable_...`/`test_the_honest_path_is_walkable_...` tests' own already-correct 5-hop count to `n06_the_choice` (unaffected by this plan, included here only as an internal consistency check on the counting method itself).

**Task granularity check:** 2 tasks matches the spec's actual scope — Task 1 is the real content-and-test change; Task 2 is a small, genuinely independent addition (a new portrait) that doesn't gate or get gated by Task 1's own tests, per `_load_portrait_texture()`'s existing null-safe behavior. Splitting further would create a task too small to carry its own meaningful test cycle; combining them would conflate a pure-content task with a real-money API call, worth keeping separate for commit-message clarity alone.
