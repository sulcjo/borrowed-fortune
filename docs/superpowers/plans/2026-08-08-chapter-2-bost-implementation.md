# Chapter 2 (Bost) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Chapter 2 (Bost) to *Borrowed Fortune* — its content (11 dialogue nodes, one real fork, 2 glossary terms) and one manifest update wiring it after Chapter 1, with zero new engine work.

**Architecture:** Pure content authoring on top of the fully-existing engine (`DialogueEngine`, `MarginGlossary`, `ChapterView`, the chapter-manifest mechanism) — no `.gd` file is modified anywhere in this plan except adding the manifest wiring. Content structure and testing pattern mirror Chapters 0 and 1 exactly.

**Tech Stack:** Godot 4.3 (GDScript), GUT (already vendored), plain JSON content.

## Global Constraints

Reused verbatim from the two prior plans, still fully in force:

- **Godot version floor: 4.3.**
- **No combat system.**
- **Engine layer purity.** No file under `engine/` is touched by this plan at all.
- **Factions are plain strings.** This plan uses `"trading_families"` and `"townsfolk"`.
- **Content is plain JSON, not compiled Resources**, under `content/`.
- **Naming idiom override:** GDScript's own idiom (`snake_case` functions/vars, `PascalCase` `class_name` types).
- **JSON numbers deserialize as `float`, never `int` — this is now a hard rule, not a lesson to relearn.** Any test comparing a JSON-sourced value against a GDScript int literal must either cast the JSON-sourced side with `int(...)` or compare per-key rather than asserting a whole `Dictionary` equal to a literal containing ints. Two prior plans hit this the hard way (once as a mid-task discovery, once as a final-review fix) — every test in this plan is written correctly from the start.
- **`DialogueEngine.load_tree()` validates node graphs and asserts on failure** (duplicate ids, dangling `next_id`, unparsed `{{...}}` gloss residue) — already existing, nothing new needed for this plan's content to be checked.
- **Chapter transitions are re-entrancy-guarded.** `ChapterView._save_and_finish()` already refuses to auto-transition into a chapter already on the current transition chain — nothing new needed here either, but it's why an end-to-end playthrough test (Task 3) is safe to write as an unbounded-looking `while` loop.
- **Priming command:** on a fresh checkout, if GUT reports "class_names have not been imported", run `godot --headless --path . --editor --quit` once first.
- **Commit after every task.**

---

## File Structure

```
borrowed-fortune/
├── content/
│   ├── chapters/
│   │   ├── manifest.json                              (modified: add chapter_02_bost, update chapter_01_teginabad's next_chapter_id)
│   │   └── chapter_02_bost/
│   │       └── bost.json                               (new: 11 dialogue nodes)
│   └── glossary/
│       └── bost_terms.json                              (new: 2 terms)
└── tests/unit/
    ├── test_bost_glossary_content.gd                    (new)
    ├── test_bost_dialogue_content.gd                    (new)
    └── test_chapter_view.gd                              (extended: 1 new end-to-end playthrough test)
```

---

### Task 1: Bost glossary content

**Files:**
- Create: `content/glossary/bost_terms.json`
- Test: `tests/unit/test_bost_glossary_content.gd`

**Interfaces:**
- Consumes: `MarginGlossary` (existing, unmodified).
- Produces: a loadable glossary content file at `res://content/glossary/bost_terms.json` containing exactly the 2 terms Chapter 2's dialogue (Task 2) glosses. Used by Task 3 (the manifest).

- [ ] **Step 1: Write the failing content-integrity test**

Create `tests/unit/test_bost_glossary_content.gd`:

```gdscript
extends GutTest

const REQUIRED_TERM_IDS := ["sarraf", "jizya"]

func _load_glossary() -> MarginGlossary:
	var file := FileAccess.open("res://content/glossary/bost_terms.json", FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	var glossary := MarginGlossary.new()
	glossary.load_entries(data)
	return glossary

func test_every_required_term_is_present_with_headword_and_definition():
	var glossary := _load_glossary()
	for term_id in REQUIRED_TERM_IDS:
		assert_true(glossary.has_entry(term_id), "missing glossary entry: %s" % term_id)
		var entry := glossary.get_entry(term_id)
		assert_true(entry.get("headword", "").length() > 0, "%s has an empty headword" % term_id)
		assert_true(entry.get("definition", "").length() > 0, "%s has an empty definition" % term_id)
```

- [ ] **Step 2: Run to verify failure**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_bost_glossary_content.gd -gexit`
Expected: FAIL — the content file does not exist yet.

- [ ] **Step 3: Write the glossary content**

Create `content/glossary/bost_terms.json`:

```json
{
	"sarraf": {
		"headword": "Sarraf",
		"definition": "A moneychanger - weighed and verified coin for a cut, and often served as an informal banker for traveling merchants."
	},
	"jizya": {
		"headword": "Jizya",
		"definition": "A per-capita tax levied on non-Muslim subjects (dhimmi) under Islamic rule, in exchange for protection and exemption from military service."
	}
}
```

- [ ] **Step 4: Run to verify the test passes**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_bost_glossary_content.gd -gexit`
Expected: 1 test, 1 pass.

- [ ] **Step 5: Commit**

```bash
git add content/glossary/bost_terms.json tests/unit/test_bost_glossary_content.gd
git commit -m "content: add Bost glossary entries for The Margin"
```

---

### Task 2: Bost dialogue content

**Files:**
- Create: `content/chapters/chapter_02_bost/bost.json`
- Test: `tests/unit/test_bost_dialogue_content.gd`

**Interfaces:**
- Consumes: `DialogueEngine` (existing, including its `validate_tree()`/`assert()` check), `GlossedTextParser` (existing), the glossary content from Task 1.
- Produces: a loadable dialogue tree at `res://content/chapters/chapter_02_bost/bost.json`, starting at `"n01_bost_arrival"`, ending at `"n10_departure_bost"`. Used by Task 3 (the manifest).

This is the scene from the design doc's Section 4, verbatim, split into 11 nodes with one real fork (`n07_the_offer`).

- [ ] **Step 1: Write the failing content-integrity tests**

Create `tests/unit/test_bost_dialogue_content.gd`:

```gdscript
extends GutTest

func _load_nodes() -> Array:
	var file := FileAccess.open("res://content/chapters/chapter_02_bost/bost.json", FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	return data

func test_every_next_id_points_at_a_node_that_exists():
	var nodes := _load_nodes()
	var known_ids: Dictionary = {}
	for node in nodes:
		known_ids[node["id"]] = true
	for node in nodes:
		for choice in node.get("choices", []):
			assert_true(known_ids.has(choice["next_id"]), "%s -> next_id '%s' does not exist" % [node["id"], choice["next_id"]])

func test_exactly_one_node_has_no_choices_and_it_is_the_last_node():
	var nodes := _load_nodes()
	var end_node_ids: Array = []
	for node in nodes:
		if node.get("choices", []).is_empty():
			end_node_ids.append(node["id"])
	assert_eq(end_node_ids, ["n10_departure_bost"])

func test_every_glossed_term_id_exists_in_the_bost_glossary():
	var nodes := _load_nodes()
	var glossary_file := FileAccess.open("res://content/glossary/bost_terms.json", FileAccess.READ)
	var glossary_data = JSON.parse_string(glossary_file.get_as_text())
	glossary_file.close()

	for node in nodes:
		for term_id in GlossedTextParser.extract_term_ids(node["text"]):
			assert_true(glossary_data.has(term_id), "node %s glosses unknown term '%s'" % [node["id"], term_id])

func test_the_pressed_path_is_walkable_and_sets_its_flag_and_reputation():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_bost_arrival")
	for i in range(6):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n07_the_offer")
	var effects := engine.choose(0) # "Ask him plainly."
	assert_eq(effects["flags"], ["pressed_mihran_for_the_name"])
	assert_eq(int(effects["reputation"]["trading_families"]), -1)
	assert_eq(int(effects["reputation"]["townsfolk"]), -1)
	engine.choose(0) # n08a_pressed -> continue
	assert_eq(engine.current_node()["id"], "n09_the_palace_glimpsed")
	assert_true(engine.flags.get("pressed_mihran_for_the_name", false))

func test_the_patient_path_is_walkable_and_converges_on_the_same_node():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_bost_arrival")
	for i in range(6):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n07_the_offer")
	var effects := engine.choose(1) # "Don't make him say it."
	assert_eq(effects["flags"], ["earned_mihrans_trust"])
	assert_eq(int(effects["reputation"]["trading_families"]), 2)
	engine.choose(0) # n08b_patient -> continue
	assert_eq(engine.current_node()["id"], "n09_the_palace_glimpsed")
	assert_true(engine.flags.get("earned_mihrans_trust", false))

func test_the_full_tree_is_walkable_from_start_to_end_via_first_choices():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_bost_arrival")
	var visited := 0
	while not engine.is_chapter_end() and visited < 100:
		engine.choose(0)
		visited += 1
	assert_true(engine.is_chapter_end())
	assert_eq(engine.current_node()["id"], "n10_departure_bost")
```

Note the two per-path tests compare `effects["flags"]` (an `Array` of `String`s — no float/int issue) directly, but compare `effects["reputation"]`'s individual values through `int(...)` casts, per the Global Constraints rule — do not change these to a single `assert_eq(effects, {...})` comparing the whole dict against a literal, even though it looks more concise; it will intermittently fail depending on Godot's Dictionary comparison semantics for JSON-sourced floats vs. GDScript int literals.

- [ ] **Step 2: Run to verify failure**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_bost_dialogue_content.gd -gexit`
Expected: FAIL — the content file does not exist yet.

- [ ] **Step 3: Write the Bost dialogue content**

Create `content/chapters/chapter_02_bost/bost.json`:

```json
[
	{
		"id": "n01_bost_arrival",
		"text": "After Teginabad's flat customs-wall discipline, Bost announced Ghaznavid wealth a different way - not with a gate and a ledger, but with a skyline. Across the canal-fed green, low domes and a long red-brick palace face caught the last sun: the sultan's winter residence, Lashkari Bazar, more garrison-town than palace grounds, more market than either. Farrukh had no business inside those walls and no wish to acquire any. His business was smaller, and stranger: a piece of paper from a house in Rayy that his father's accounts should never have mentioned.",
		"choices": [{"text": "Continue.", "next_id": "n02_seeking_the_sarraf", "effects": {}}]
	},
	{
		"id": "n02_seeking_the_sarraf",
		"text": "Every winter-quartered army needs men who can turn one kingdom's coin into another's, and Bost had no shortage of them. Farrukh found the one the caravan drivers trusted on reputation alone - a narrow shopfront off the bazaar's spine, scales hung by the door, a {{sarraf|sarraf}} named Mihran who weighed silver for a living and, by the look of the room, had done it long enough to stop being impressed by anyone's coin.",
		"choices": [{"text": "Continue.", "next_id": "n03_mihran_examines", "effects": {}}]
	},
	{
		"id": "n03_mihran_examines",
		"text": "Mihran took the suftaja without much interest until he actually read it, and then went quiet in a way Farrukh was beginning to recognize - the particular stillness of a man deciding how much of what he'd noticed was safe to say aloud.",
		"choices": [{"text": "Continue.", "next_id": "n04_the_second_mark", "effects": {}}]
	},
	{
		"id": "n04_the_second_mark",
		"text": "\"This seal I know,\" he said finally, turning the paper toward the light. \"The house in Rayy - a real house, good credit, before -\" he stopped himself. \"Before some things changed there. But this\" - he touched a second mark beneath the first, smaller, easy to miss - \"this I have seen exactly twice in eleven years, and both times I wished I hadn't.\"",
		"choices": [{"text": "Continue.", "next_id": "n05_ibn_hasan", "effects": {}}]
	},
	{
		"id": "n05_ibn_hasan",
		"text": "He set the paper down without being asked and looked at Farrukh properly for the first time. \"Ibn Hasan,\" he said - not a question. \"You have his hands. He came through here four, five years running, always the same honest weight, never once tried to pass me clipped silver like half these road-merchants do. I am sorry for him. Whatever this is\" - he touched the paper again, carefully, as if it might be warm - \"he did not deserve to carry it alone. Whether he understood he was carrying it at all, I couldn't say.\"",
		"choices": [{"text": "Continue.", "next_id": "n06_the_danger", "effects": {}}]
	},
	{
		"id": "n06_the_danger",
		"text": "Farrukh asked what the second mark meant. Mihran's hand actually moved to cover it, an old instinct. \"A name goes with it,\" he said. \"I could give you the name. I could also tell you that I pay the {{jizya|jizya}} every year specifically so that men in robes with questions never have reason to visit my shop - and a name like this one is exactly the kind of thing that brings them anyway, whether I meant to say it or not.\"",
		"choices": [{"text": "Continue.", "next_id": "n07_the_offer", "effects": {}}]
	},
	{
		"id": "n07_the_offer",
		"text": "He looked at Farrukh, weighing something that had nothing to do with silver. \"I will tell you, if you ask me plainly,\" he said. \"But I would rather you didn't have to.\"",
		"choices": [
			{"text": "Ask him plainly.", "next_id": "n08a_pressed", "effects": {"flags": ["pressed_mihran_for_the_name"], "reputation": {"trading_families": -1, "townsfolk": -1}}},
			{"text": "Don't make him say it.", "next_id": "n08b_patient", "effects": {"flags": ["earned_mihrans_trust"], "reputation": {"trading_families": 2}}}
		]
	},
	{
		"id": "n08a_pressed",
		"text": "Farrukh asked. Mihran told him - a name, a city, nothing more, delivered in the flat voice of a man crossing a line he'd hoped to avoid - then wrapped the suftaja back into its cloth with hands that were, for the first time since Farrukh had walked in, not entirely steady. \"Don't come back here,\" he said, not unkindly. \"Not because of the debt. Because of this.\" Farrukh had his lead. He had also, he suspected, spent something he could not get back.",
		"choices": [{"text": "Continue.", "next_id": "n09_the_palace_glimpsed", "effects": {}}]
	},
	{
		"id": "n08b_patient",
		"text": "Farrukh didn't ask. Mihran seemed to relax by a fraction he probably didn't notice himself. \"I'll tell you this much for nothing,\" he said. \"Whoever sent that second mark moves money the way water moves through Bost's canals - underground, on purpose, surfacing only where someone built a channel for it to surface. Follow the channels, not the water. You'll find your name eventually, and it will still be true when you do.\" It was less than a name. It felt, somehow, like more.",
		"choices": [{"text": "Continue.", "next_id": "n09_the_palace_glimpsed", "effects": {}}]
	},
	{
		"id": "n09_the_palace_glimpsed",
		"text": "Farrukh left Mihran's shop as the winter light went copper over Lashkari Bazar's long brick face, close enough now to make out painted guardsmen on the palace's outer wall - a hundred still figures keeping a watch that had never once been real. He thought of what it must have cost, all of it - the paint, the brick, the canals, the garrison that ate a season's wages just by existing - and did not let himself finish the thought all the way to where it wanted to go. That accounting was for another day, on another road. Tonight there was only Farah ahead, and a channel somewhere with his father's name written on it in water.",
		"choices": [{"text": "Continue.", "next_id": "n10_departure_bost", "effects": {}}]
	},
	{
		"id": "n10_departure_bost",
		"text": "He set out before the palace's watch-fires were lit, the caravan small now, the guide new, the road west running straight into a dark that Nasa's riders had already told him was not as empty as it used to be.",
		"choices": []
	}
]
```

- [ ] **Step 4: Run to verify the tests pass**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_bost_dialogue_content.gd -gexit`
Expected: 6 tests, 6 pass.

- [ ] **Step 5: Commit**

```bash
git add content/chapters/chapter_02_bost/bost.json tests/unit/test_bost_dialogue_content.gd
git commit -m "content: add Chapter 2 (Bost) dialogue tree"
```

---

### Task 3: Wire the manifest and add the three-chapter playthrough test

**Files:**
- Modify: `content/chapters/manifest.json`
- Test: `tests/unit/test_chapter_view.gd`

**Interfaces:**
- Consumes: `ChapterView.load_chapter_by_id` and the auto-transition wiring in `_save_and_finish()` (both existing, unmodified — this task touches no `.gd` file), the glossary/dialogue content from Tasks 1-2.
- Produces: the real, playable three-chapter chain (Ghazni → Teginabad → Bost). Nothing later in this plan depends on new interfaces from this task.

- [ ] **Step 1: Update the real manifest**

Read the current `content/chapters/manifest.json` first — it has two entries (`chapter_00_prologue`, `chapter_01_teginabad`). Change `chapter_01_teginabad`'s `next_chapter_id` from `null` to `"chapter_02_bost"`, and add a new `chapter_02_bost` entry. The full file should read:

```json
{
	"chapter_00_prologue": {
		"dialogue_path": "res://content/chapters/chapter_00_prologue/prologue.json",
		"glossary_path": "res://content/glossary/prologue_terms.json",
		"next_chapter_id": "chapter_01_teginabad"
	},
	"chapter_01_teginabad": {
		"dialogue_path": "res://content/chapters/chapter_01_teginabad/teginabad.json",
		"glossary_path": "res://content/glossary/teginabad_terms.json",
		"next_chapter_id": "chapter_02_bost"
	},
	"chapter_02_bost": {
		"dialogue_path": "res://content/chapters/chapter_02_bost/bost.json",
		"glossary_path": "res://content/glossary/bost_terms.json",
		"next_chapter_id": null
	}
}
```

- [ ] **Step 2: Write the failing three-chapter playthrough test**

Append to `tests/unit/test_chapter_view.gd`:

```gdscript
func test_a_full_playthrough_runs_ghazni_through_bost_and_saves():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter_by_id("chapter_00_prologue")
	var presses := 0
	while chapter_view.dialogue_engine.available_choices().size() > 0 and presses < 200:
		chapter_view._on_choice_pressed(0)
		presses += 1
	assert_eq(chapter_view.chapter_id, "chapter_02_bost")
	assert_eq(chapter_view.dialogue_engine.current_node()["id"], "n10_departure_bost")
	assert_true(FileAccess.file_exists("user://borrowed_fortune_chapter_02_bost.json"))
```

This test always picks choice index 0 at every decision point (including Teginabad's and Bost's forks, so it exercises the bribe/pressed paths, not the honest/patient ones — that's fine, the per-chapter content tests already cover both fork paths in isolation; this test's job is proving the three-chapter chain connects and terminates correctly, not re-testing fork content). It doesn't hardcode a press count — it stops naturally when no choices remain, which only happens at Bost's true terminal node, `n10_departure_bost`, since every other node in all three chapters has at least one choice.

- [ ] **Step 3: Run to verify failure**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_chapter_view.gd -gexit`
Expected: FAIL — `content/chapters/manifest.json` doesn't yet point Teginabad at Bost (or, if you did Step 1 first, this confirms Step 1 already works — either order is fine, but run this check before considering the task done).

- [ ] **Step 4: Run to verify it passes**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_chapter_view.gd -gexit`
Expected: all tests in this file pass (the pre-existing count plus this one new test).

- [ ] **Step 5: Commit**

```bash
git add content/chapters/manifest.json tests/unit/test_chapter_view.gd
git commit -m "feat: wire Chapter 2 (Bost) into the chapter manifest"
```

---

### Task 4: Full-suite verification, manual playtest, and close-out

**Files:** none created; this task only runs and verifies.

**Interfaces:**
- Consumes: everything from Tasks 1-3, plus the existing suite from Chapters 0-1.
- Produces: confirmation the entire suite passes together, and a tagged milestone.

- [ ] **Step 1: Run the entire suite together**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`
Expected: all tests pass, pristine output (no warnings — if any "Float/Int comparison" warnings appear, find and fix the offending comparison per the Global Constraints rule before proceeding, don't just note it and move on).

- [ ] **Step 2: Real headless boot check**

Run: `godot --headless --path .` and confirm no script errors in the console output.

- [ ] **Step 3: Tag the milestone**

```bash
git tag -a v0.3-bost -m "Chapter 2 (Bost) playable, auto-chained from Teginabad"
```

No further commit is needed — this task verifies and tags what Tasks 1-3 already committed.

---

## Post-Plan Note

Chapters 3-7 are not part of this plan. The chapter-manifest mechanism continues to generalize exactly as intended: each future chapter needs only its own content directory, its own glossary file, and one new manifest entry (plus updating the previous chapter's `next_chapter_id`). Trading/haggling mechanics remain deliberately unimplemented — per the design doc, this is a standing commitment for a future, bigger bazaar chapter (e.g. Herat or Nishapur per the original design spec), not something to keep deferring indefinitely once enough story structure exists.
