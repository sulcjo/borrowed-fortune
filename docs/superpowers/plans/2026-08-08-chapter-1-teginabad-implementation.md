# Chapter 1 (Teginabad) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Chapter 1 (Teginabad) to *Borrowed Fortune* — its content (11 dialogue nodes, one real fork, 4 glossary terms) plus the two small engine additions needed to wire it to the already-shipped Prologue: a merging `MarginGlossary`, and a minimal chapter-transition mechanism, so a full playthrough flows Ghazni → Teginabad automatically in one sitting.

**Architecture:** Every existing engine class (`Ledger`, `ReputationTracker`, `DialogueEngine`, `MarginGlossary`, `GlossedTextParser`, `GameState`, `SaveManager`, `ChapterView`, `MarginPopup`, `Main`) is reused unchanged except two additive changes: `MarginGlossary.load_entries()` becomes merge-not-replace, and `ChapterView` gains `load_chapter_by_id()` plus `next_chapter_id` auto-transition logic on top of its existing, untouched `load_chapter()`. Content is plain JSON exactly as in the Prologue.

**Tech Stack:** Godot 4.3 (GDScript), GUT (already vendored at `addons/gut/`), plain JSON content.

## Global Constraints

Reused verbatim from `docs/superpowers/plans/2026-08-07-prologue-implementation.md`, still fully in force:

- **Godot version floor: 4.3.** Godot 4.x APIs only.
- **No combat system.**
- **Engine layer purity.** Every file under `engine/` extends `RefCounted`, never `Node`.
- **Money is dirham-equivalent internally** (via `Ledger`, unaffected by this plan — no task here touches money).
- **Factions are plain strings.** Known ids used by this plan: `"townsfolk"`, `"trading_families"`, `"ghaznavid_officials"`.
- **Content is plain JSON, not compiled Resources**, under `content/`.
- **Naming idiom override:** GDScript's own idiom (`snake_case` functions/vars, `PascalCase` `class_name` types) over generic camelCase.
- **JSON numbers deserialize as `float`, never `int`.** Cast explicitly wherever a typed-`int` parameter (e.g. `ReputationTracker.adjust_reputation`'s `delta`) consumes JSON-sourced data — `ChapterView._apply_effects` already does this; nothing in this plan needs a new cast site, but don't remove the existing one.
- **`DialogueEngine.load_tree()` now validates node graphs and asserts on failure** (added after the Prologue's final review): duplicate node ids, dangling `next_id` references, and unparsed `{{...}}` gloss residue all fail loudly at load time. This means Chapter 1's content, once written, is already checked by existing engine code — no new validation task is needed, only correct content.
- **Priming command:** on a fresh checkout, if GUT reports "class_names have not been imported", run `godot --headless --path . --editor --quit` once first.
- **Commit after every task.**

---

## File Structure

```
borrowed-fortune/
├── engine/
│   └── margin/
│       └── MarginGlossary.gd                          (modified: merge, not replace)
├── scenes/
│   ├── chapter_view/
│   │   └── ChapterView.gd                              (modified: load_chapter_by_id, next_chapter_id, auto-transition)
│   └── main/
│       └── Main.gd                                     (modified: boots via load_chapter_by_id)
├── content/
│   ├── chapters/
│   │   ├── manifest.json                               (new: chapter_id -> {dialogue_path, glossary_path, next_chapter_id})
│   │   ├── chapter_00_prologue/                        (untouched content, now referenced by the manifest)
│   │   └── chapter_01_teginabad/
│   │       └── teginabad.json                          (new: 11 dialogue nodes)
│   └── glossary/
│       └── teginabad_terms.json                        (new: 4 terms)
└── tests/
    ├── fixtures/                                        (new: small synthetic manifest+content, engine-test-only)
    │   ├── manifest_fixture.json
    │   ├── dialogue_fixture_a.json
    │   ├── dialogue_fixture_terminal.json
    │   ├── dialogue_fixture_b.json
    │   └── glossary_fixture_a.json
    └── unit/
        ├── test_margin_glossary.gd                     (extended: 1 new test)
        ├── test_chapter_view.gd                        (extended: 5 new tests — 2 for load_chapter_by_id, 2 for auto-transition, 1 for the real cross-chapter flag integration)
        ├── test_teginabad_glossary_content.gd           (new)
        └── test_teginabad_dialogue_content.gd           (new)
```

---

### Task 1: `MarginGlossary.load_entries()` merges instead of replaces

**Files:**
- Modify: `engine/margin/MarginGlossary.gd`
- Test: `tests/unit/test_margin_glossary.gd`

**Interfaces:**
- Consumes: nothing new.
- Produces: `load_entries(entries: Dictionary)` now accumulates across calls instead of replacing `_entries` wholesale. Every other method (`has_entry`, `get_entry`, `unlock`, `is_unlocked`, `unlocked_term_ids`) is unchanged. Relied on by Task 6 (loading Chapter 0's glossary, then Chapter 1's, into the same `MarginGlossary` instance without losing Chapter 0's terms).

- [ ] **Step 1: Write the failing test**

Append to `tests/unit/test_margin_glossary.gd`:

```gdscript
func test_load_entries_merges_rather_than_replaces():
	var glossary := MarginGlossary.new()
	glossary.load_entries({"khwaja": {"headword": "Khwaja", "definition": "A respectful address."}})
	glossary.load_entries({"amid": {"headword": "Amid", "definition": "A Ghaznavid administrative title."}})
	assert_true(glossary.has_entry("khwaja"), "first load's entries must survive a second load")
	assert_true(glossary.has_entry("amid"), "second load's entries must also be present")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_margin_glossary.gd -gexit`
Expected: FAIL — `test_load_entries_merges_rather_than_replaces` fails because the current implementation replaces `_entries`, so `khwaja` is gone after the second `load_entries()` call.

- [ ] **Step 3: Fix the implementation**

In `engine/margin/MarginGlossary.gd`, replace:

```gdscript
func load_entries(entries: Dictionary) -> void:
	_entries = entries
```

with:

```gdscript
func load_entries(entries: Dictionary) -> void:
	for term_id in entries:
		_entries[term_id] = entries[term_id]
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_margin_glossary.gd -gexit`
Expected: 6 tests, 6 pass (the 5 existing plus the new one — none of the existing 5 call `load_entries()` more than once per instance, so merge-vs-replace is unobservable to them; they must still pass unchanged).

- [ ] **Step 5: Commit**

```bash
git add engine/margin/MarginGlossary.gd tests/unit/test_margin_glossary.gd
git commit -m "fix: MarginGlossary.load_entries merges instead of replacing"
```

---

### Task 2: `ChapterView.load_chapter_by_id()` and the chapter manifest format

**Files:**
- Modify: `scenes/chapter_view/ChapterView.gd`
- Create: `tests/fixtures/manifest_fixture.json`
- Create: `tests/fixtures/dialogue_fixture_a.json`
- Create: `tests/fixtures/glossary_fixture_a.json`
- Create: `tests/fixtures/dialogue_fixture_b.json`
- Test: `tests/unit/test_chapter_view.gd`

**Interfaces:**
- Consumes: `ChapterView.load_chapter(dialogue_path: String, glossary_path: String)` (existing, unchanged — Task 2 calls it, does not modify it).
- Produces: `ChapterView.load_chapter_by_id(id: String, manifest_path: String = "res://content/chapters/manifest.json") -> void`, and a new public field `next_chapter_id` (`String` or `null`, default `null`). Manifest JSON shape: `{"<chapter_id>": {"dialogue_path": "res://...", "glossary_path": "res://...", "next_chapter_id": "<chapter_id>" | null}}`. Used by Task 3 (auto-transition) and Task 6 (the real manifest + Main.gd).

- [ ] **Step 1: Create the test fixtures**

Create `tests/fixtures/glossary_fixture_a.json`:

```json
{}
```

Create `tests/fixtures/dialogue_fixture_a.json`:

```json
[
	{"id": "start", "text": "Fixture A.", "choices": [{"text": "Continue.", "next_id": "end", "effects": {}}]},
	{"id": "end", "text": "Fixture A end.", "choices": []}
]
```

Create `tests/fixtures/dialogue_fixture_b.json`:

```json
[
	{"id": "start", "text": "Fixture B.", "choices": []}
]
```

Create `tests/fixtures/manifest_fixture.json`:

```json
{
	"fixture_chapter_a": {
		"dialogue_path": "res://tests/fixtures/dialogue_fixture_a.json",
		"glossary_path": "res://tests/fixtures/glossary_fixture_a.json",
		"next_chapter_id": "fixture_chapter_b"
	},
	"fixture_chapter_b": {
		"dialogue_path": "res://tests/fixtures/dialogue_fixture_b.json",
		"glossary_path": "res://tests/fixtures/glossary_fixture_a.json",
		"next_chapter_id": null
	}
}
```

(`fixture_chapter_terminal` is added in Task 3, once it's needed — don't add it here.)

- [ ] **Step 2: Write the failing tests**

Append to `tests/unit/test_chapter_view.gd`:

```gdscript
func test_load_chapter_by_id_resolves_manifest_and_sets_chapter_id():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter_by_id("fixture_chapter_a", "res://tests/fixtures/manifest_fixture.json")
	assert_eq(chapter_view.chapter_id, "fixture_chapter_a")
	assert_eq(chapter_view.next_chapter_id, "fixture_chapter_b")
	assert_true(chapter_view.dialogue_engine.current_node()["text"].contains("Fixture A"))

func test_load_chapter_by_id_with_null_next_chapter_id():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter_by_id("fixture_chapter_b", "res://tests/fixtures/manifest_fixture.json")
	assert_eq(chapter_view.next_chapter_id, null)
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_chapter_view.gd -gexit`
Expected: FAIL — `load_chapter_by_id` does not exist yet.

- [ ] **Step 4: Implement `load_chapter_by_id`**

In `scenes/chapter_view/ChapterView.gd`, add two new fields near the other `var` declarations at the top of the script:

```gdscript
var next_chapter_id = null
var _manifest_path := "res://content/chapters/manifest.json"
```

`_manifest_path` remembers whichever manifest the CURRENT chapter was actually loaded from (default or overridden) — Task 3 needs this so that auto-transitioning to the next chapter reuses the same manifest, rather than silently falling back to the default path.

Add the new method (anywhere among the other `func`s):

```gdscript
func load_chapter_by_id(id: String, manifest_path: String = "res://content/chapters/manifest.json") -> void:
	_manifest_path = manifest_path
	var manifest_file := FileAccess.open(manifest_path, FileAccess.READ)
	if manifest_file == null:
		push_error("ChapterView: could not open chapter manifest: %s" % manifest_path)
		return
	var manifest = JSON.parse_string(manifest_file.get_as_text())
	manifest_file.close()
	if manifest == null or not manifest.has(id):
		push_error("ChapterView: chapter id not found in manifest '%s': %s" % [manifest_path, id])
		return
	var entry: Dictionary = manifest[id]
	chapter_id = id
	next_chapter_id = entry.get("next_chapter_id", null)
	load_chapter(entry["dialogue_path"], entry["glossary_path"])
```

Note this calls the existing `load_chapter()` unchanged — do not modify `load_chapter()` in this task.

- [ ] **Step 5: Run tests to verify they pass**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_chapter_view.gd -gexit`
Expected: all tests in this file pass (the 4 pre-existing plus these 2 new ones = 6).

- [ ] **Step 6: Commit**

```bash
git add scenes/chapter_view/ChapterView.gd tests/fixtures/manifest_fixture.json tests/fixtures/dialogue_fixture_a.json tests/fixtures/dialogue_fixture_b.json tests/fixtures/glossary_fixture_a.json tests/unit/test_chapter_view.gd
git commit -m "feat: add ChapterView.load_chapter_by_id and the chapter manifest format"
```

---

### Task 3: Wire chapter-end auto-transition into `_save_and_finish()`

**Files:**
- Modify: `scenes/chapter_view/ChapterView.gd`
- Create: `tests/fixtures/dialogue_fixture_terminal.json`
- Test: `tests/unit/test_chapter_view.gd`

**Interfaces:**
- Consumes: `load_chapter_by_id` and `next_chapter_id` (Task 2).
- Produces: `_save_and_finish()` now calls `load_chapter_by_id(next_chapter_id)` after saving, when `next_chapter_id` is not `null`. Relied on by Task 6 (the real Prologue → Teginabad transition).

- [ ] **Step 1: Create the terminal fixture and extend the manifest fixture**

Create `tests/fixtures/dialogue_fixture_terminal.json`:

```json
[
	{"id": "start", "text": "Immediately over.", "choices": []}
]
```

Edit `tests/fixtures/manifest_fixture.json` to add a third entry (keep the existing two exactly as they are):

```json
{
	"fixture_chapter_a": {
		"dialogue_path": "res://tests/fixtures/dialogue_fixture_a.json",
		"glossary_path": "res://tests/fixtures/glossary_fixture_a.json",
		"next_chapter_id": "fixture_chapter_b"
	},
	"fixture_chapter_terminal": {
		"dialogue_path": "res://tests/fixtures/dialogue_fixture_terminal.json",
		"glossary_path": "res://tests/fixtures/glossary_fixture_a.json",
		"next_chapter_id": "fixture_chapter_b"
	},
	"fixture_chapter_b": {
		"dialogue_path": "res://tests/fixtures/dialogue_fixture_b.json",
		"glossary_path": "res://tests/fixtures/glossary_fixture_a.json",
		"next_chapter_id": null
	}
}
```

- [ ] **Step 2: Write the failing tests**

Append to `tests/unit/test_chapter_view.gd`:

```gdscript
func test_reaching_chapter_end_with_a_next_chapter_id_auto_transitions():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter_by_id("fixture_chapter_terminal", "res://tests/fixtures/manifest_fixture.json")
	assert_eq(chapter_view.chapter_id, "fixture_chapter_b")
	assert_true(chapter_view.dialogue_engine.current_node()["text"].contains("Fixture B"))

func test_reaching_chapter_end_with_no_next_chapter_id_does_not_transition():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter_by_id("fixture_chapter_b", "res://tests/fixtures/manifest_fixture.json")
	assert_eq(chapter_view.chapter_id, "fixture_chapter_b")
	assert_eq(chapter_view.next_chapter_id, null)
```

- [ ] **Step 3: Run tests to verify the first one fails**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_chapter_view.gd -gexit`
Expected: `test_reaching_chapter_end_with_a_next_chapter_id_auto_transitions` FAILS — loading `fixture_chapter_terminal` saves but does not yet transition, so `chapter_view.chapter_id` is still `"fixture_chapter_terminal"`. `test_reaching_chapter_end_with_no_next_chapter_id_does_not_transition` already passes (nothing to transition to), which is fine — it exists to guard against a regression once Step 4 lands.

- [ ] **Step 4: Wire the transition**

In `scenes/chapter_view/ChapterView.gd`, find `_save_and_finish()`:

```gdscript
func _save_and_finish() -> void:
	var state := GameState.new()
	state.chapter_id = chapter_id
	state.dialogue_node_id = dialogue_engine.current_node_id
	state.dialogue_flags = dialogue_engine.flags
	state.reputation_data = reputation_tracker.to_dict()
	state.unlocked_glossary_terms = margin_glossary.unlocked_term_ids()
	state.ledger_data = ledger.to_dict()
	save_manager.save(state, save_path())
```

Add one line at the end:

```gdscript
func _save_and_finish() -> void:
	var state := GameState.new()
	state.chapter_id = chapter_id
	state.dialogue_node_id = dialogue_engine.current_node_id
	state.dialogue_flags = dialogue_engine.flags
	state.reputation_data = reputation_tracker.to_dict()
	state.unlocked_glossary_terms = margin_glossary.unlocked_term_ids()
	state.ledger_data = ledger.to_dict()
	save_manager.save(state, save_path())
	if next_chapter_id != null:
		load_chapter_by_id(next_chapter_id, _manifest_path)
```

Passing `_manifest_path` here (not relying on the parameter's default) is what makes this work correctly for both the fixture tests in this task (which load from `tests/fixtures/manifest_fixture.json`) and the real game (which loads from the default path) — without it, a chapter loaded via a non-default manifest would try to transition using the wrong manifest and fail to find the next chapter.

- [ ] **Step 5: Run tests to verify they pass**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_chapter_view.gd -gexit`
Expected: all tests in this file pass (8 total: the original 4, Task 2's 2, and these 2).

- [ ] **Step 6: Commit**

```bash
git add scenes/chapter_view/ChapterView.gd tests/fixtures/dialogue_fixture_terminal.json tests/fixtures/manifest_fixture.json tests/unit/test_chapter_view.gd
git commit -m "feat: auto-transition to the next chapter when one is set"
```

---

### Task 4: Teginabad glossary content

**Files:**
- Create: `content/glossary/teginabad_terms.json`
- Test: `tests/unit/test_teginabad_glossary_content.gd`

**Interfaces:**
- Consumes: `MarginGlossary` (existing, from Task 1's fix onward).
- Produces: a loadable glossary content file at `res://content/glossary/teginabad_terms.json` containing exactly the 4 terms Chapter 1's dialogue (Task 5) glosses. Used by Task 6 (the real manifest).

- [ ] **Step 1: Write the failing content-integrity test**

Create `tests/unit/test_teginabad_glossary_content.gd`:

```gdscript
extends GutTest

const REQUIRED_TERM_IDS := ["amid", "ushr", "zuhr", "adhan"]

func _load_glossary() -> MarginGlossary:
	var file := FileAccess.open("res://content/glossary/teginabad_terms.json", FileAccess.READ)
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

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_teginabad_glossary_content.gd -gexit`
Expected: FAIL — the content file does not exist yet.

- [ ] **Step 3: Write the glossary content**

Create `content/glossary/teginabad_terms.json`:

```json
{
	"amid": {
		"headword": "Amid",
		"definition": "A Ghaznavid administrative title for a mid-level civil or financial official - used here for the officer overseeing a customs post."
	},
	"ushr": {
		"headword": "'Ushr",
		"definition": "A customs tithe on goods entering or crossing Muslim territory - roughly 5% for Muslim traders, up to double for non-Muslim or foreign ones - collected at frontier posts like this one."
	},
	"zuhr": {
		"headword": "Zuhr",
		"definition": "One of the five daily prayers, performed after the sun passes its zenith at midday."
	},
	"adhan": {
		"headword": "Adhan",
		"definition": "The Islamic call to prayer, sounded aloud to mark each of the five daily prayer times."
	}
}
```

- [ ] **Step 4: Run to verify the test passes**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_teginabad_glossary_content.gd -gexit`
Expected: 1 test, 1 pass.

- [ ] **Step 5: Commit**

```bash
git add content/glossary/teginabad_terms.json tests/unit/test_teginabad_glossary_content.gd
git commit -m "content: add Teginabad glossary entries for The Margin"
```

---

### Task 5: Teginabad dialogue content

**Files:**
- Create: `content/chapters/chapter_01_teginabad/teginabad.json`
- Test: `tests/unit/test_teginabad_dialogue_content.gd`

**Interfaces:**
- Consumes: `DialogueEngine` (existing, including its `validate_tree()`/`assert()` check from the Prologue's post-review fix wave), `GlossedTextParser` (existing), the glossary content from Task 4.
- Produces: a loadable dialogue tree at `res://content/chapters/chapter_01_teginabad/teginabad.json`, starting at `"n01_teginabad_arrival"`, ending at `"n09_departure_teginabad"`. Used by Task 6 (the real manifest).

This is the scene from the design doc's Section 4, verbatim, split into 11 nodes with one real fork (`n06_the_choice`) and one flag-gated bonus choice (`n07b_inspection`'s second option, gated on `read_unsigned_letter` — the Prologue's own flag).

- [ ] **Step 1: Write the failing content-integrity tests**

Create `tests/unit/test_teginabad_dialogue_content.gd`:

```gdscript
extends GutTest

func _load_nodes() -> Array:
	var file := FileAccess.open("res://content/chapters/chapter_01_teginabad/teginabad.json", FileAccess.READ)
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
	assert_eq(end_node_ids, ["n09_departure_teginabad"])

func test_every_glossed_term_id_exists_in_the_teginabad_glossary():
	var nodes := _load_nodes()
	var glossary_file := FileAccess.open("res://content/glossary/teginabad_terms.json", FileAccess.READ)
	var glossary_data = JSON.parse_string(glossary_file.get_as_text())
	glossary_file.close()

	for node in nodes:
		for term_id in GlossedTextParser.extract_term_ids(node["text"]):
			assert_true(glossary_data.has(term_id), "node %s glosses unknown term '%s'" % [node["id"], term_id])

func test_the_bribe_path_is_walkable_and_sets_its_flag_and_reputation():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_teginabad_arrival")
	for i in range(5):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n06_the_choice")
	var effects := engine.choose(0) # "Pay for expedited passage."
	assert_eq(effects, {"flags": ["bribed_teginabad_official"], "reputation": {"townsfolk": -1, "trading_families": -1, "ghaznavid_officials": 1}})
	engine.choose(0) # n07a_bribe -> continue
	assert_eq(engine.current_node()["id"], "n08_guide_transition")
	assert_true(engine.flags.get("bribed_teginabad_official", false))

func test_the_honest_path_is_walkable_and_converges_on_the_same_node():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_teginabad_arrival")
	for i in range(5):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n06_the_choice")
	var effects := engine.choose(1) # "Let the inspection happen."
	assert_eq(effects, {"flags": ["honest_at_teginabad"], "reputation": {"ghaznavid_officials": 2}})
	engine.choose(0) # n07b_inspection -> "Say nothing."
	assert_eq(engine.current_node()["id"], "n08_guide_transition")
	assert_true(engine.flags.get("honest_at_teginabad", false))

func test_letter_callback_choice_only_appears_with_the_prologue_flag_set():
	var engine_without_flag := DialogueEngine.new()
	engine_without_flag.load_tree(_load_nodes(), "n01_teginabad_arrival")
	for i in range(5):
		engine_without_flag.choose(0)
	engine_without_flag.choose(1) # "Let the inspection happen."
	assert_eq(engine_without_flag.available_choices().size(), 1)

	var engine_with_flag := DialogueEngine.new()
	engine_with_flag.load_tree(_load_nodes(), "n01_teginabad_arrival")
	engine_with_flag.flags["read_unsigned_letter"] = true
	for i in range(5):
		engine_with_flag.choose(0)
	engine_with_flag.choose(1)
	assert_eq(engine_with_flag.available_choices().size(), 2)

	var chosen_effects := engine_with_flag.choose(1) # "Tell him what you read..."
	assert_eq(chosen_effects, {"flags": ["revealed_letter_to_said"], "reputation": {"ghaznavid_officials": 1}})
	engine_with_flag.choose(0) # n07b_letter_callback -> continue
	assert_eq(engine_with_flag.current_node()["id"], "n08_guide_transition")

func test_the_full_tree_is_walkable_from_start_to_end_via_first_choices():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_teginabad_arrival")
	var visited := 0
	while not engine.is_chapter_end() and visited < 100:
		engine.choose(0)
		visited += 1
	assert_true(engine.is_chapter_end())
	assert_eq(engine.current_node()["id"], "n09_departure_teginabad")
```

- [ ] **Step 2: Run to verify failure**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_teginabad_dialogue_content.gd -gexit`
Expected: FAIL — the content file does not exist yet.

- [ ] **Step 3: Write the Teginabad dialogue content**

Create `content/chapters/chapter_01_teginabad/teginabad.json`:

```json
[
	{
		"id": "n01_teginabad_arrival",
		"text": "Teginabad was not a city pretending to be one. It was a wall, a gate, and the men who stood in it - a fortress squatting on patterned brick where the Ghazni road narrowed toward the desert crossing beyond. After the capital's crowded lanes, the outpost felt like a held breath. Farrukh's caravan guide reined in a full bowshot before the gate, the way a man slows before knocking on a door he isn't sure will open.",
		"choices": [{"text": "Continue.", "next_id": "n02_the_official", "effects": {}}]
	},
	{
		"id": "n02_the_official",
		"text": "A man came out to meet them before they'd finished dismounting - young for the {{amid|amid}} he claimed, his robe good cloth gone thin at the cuffs, the particular tiredness of someone paid to want more from travelers than they wished to give. He named himself Sa'id ibn Yaqub, amid of the Teginabad customs post, and asked, with the practiced patience of a man who has asked it a thousand times, to see the manifest.",
		"choices": [{"text": "Continue.", "next_id": "n03_politics", "effects": {}}]
	},
	{
		"id": "n03_politics",
		"text": "He did not ask unkindly. That, Farrukh would learn, was almost worse - Sa'id had the manner of a man doing arithmetic in his head at all times, converting every traveler into a quota he owed someone above him, and that someone into a quota owed to Ghazni, and Ghazni, lately, into a court nervous about a frontier that kept sending back worse news than it sent revenue. \"They tell us collect what Nasa isn't sending anymore,\" he said, not quite to Farrukh, checking a seal against a wax impression in his own ledger. \"As if a customs post can tax a rumor.\"",
		"choices": [{"text": "Continue.", "next_id": "n04_the_demand", "effects": {}}]
	},
	{
		"id": "n04_the_demand",
		"text": "He found the discrepancy the way men who have found a thousand discrepancies find them - without surprise, only a faint, professional interest. The {{ushr|'ushr}} was already logged and paid; that was never in question. This was a different matter: a weight of silk logged as originating from a house in Rayy that no merchant road from Ghazni to Teginabad had any business touching. \"Interesting bill of lading, this,\" Sa'id said, not looking up. \"I'll need to open the crates.\"",
		"choices": [{"text": "Continue.", "next_id": "n05_prayer_interlude", "effects": {}}]
	},
	{
		"id": "n05_prayer_interlude",
		"text": "The call to {{zuhr|midday prayer}} rose from the post's small mosque before Farrukh could answer him - the {{adhan|adhan}}, unhurried, indifferent to customs disputes. Sa'id closed his ledger at the sound the way another man might close a door. \"God's business first,\" he said, and went, leaving Farrukh standing in the yard with the crates still sealed and the whole caravan's fate apparently subordinate to the sun's position in the sky. Farrukh did not pray, not then - grief had made his prayers thin and mechanical since Ghazni, words without the man behind them believing they reached anywhere - but he found himself doing the other thing the old letter-writer had given him instead: counting what in this moment was borrowed and what, if anything, was his. The crates were not his - his father's, or his father's creditors', depending on which qadi you asked, though none had asked. The debt was his, by his own mouth, at a graveside, to no one's compulsion. Perhaps that was the one contingent thing a man got to choose for himself: not what he was given, but what he agreed to carry.",
		"choices": [{"text": "Continue.", "next_id": "n06_the_choice", "effects": {}}]
	},
	{
		"id": "n06_the_choice",
		"text": "Sa'id returned unhurried, prayer's calm still on him, and made Farrukh an offer with the same flat patience he'd made every other statement: the inspection could happen, properly, crate by crate, manifest against goods - a process that would take the rest of the day and might, Sa'id did not pretend otherwise, turn up exactly the kind of irregularity that got shipments impounded and merchants questioned by men less patient than himself. Or the post's fee for \"expedited passage\" could be settled now, quietly, and the caravan could be through the gate before the sun moved another hand's width.",
		"choices": [
			{"text": "Pay for expedited passage.", "next_id": "n07a_bribe", "effects": {"flags": ["bribed_teginabad_official"], "reputation": {"townsfolk": -1, "trading_families": -1, "ghaznavid_officials": 1}}},
			{"text": "Let the inspection happen.", "next_id": "n07b_inspection", "effects": {"flags": ["honest_at_teginabad"], "reputation": {"ghaznavid_officials": 2}}}
		]
	},
	{
		"id": "n07a_bribe",
		"text": "Farrukh paid it. He told himself, counting the coins into Sa'id's palm, that this was arithmetic and nothing else - the same arithmetic Sa'id himself was always doing, obligation converted to obligation, all the way up to a Sultan who'd never see a dirham of it and all the way down to a father's debt Farrukh was still, by his own word, carrying. It did not feel like arithmetic. It felt like the first small dishonesty of the man he might become on this road, and he could not yet tell if that was a cost or simply a toll, the same as any other.",
		"choices": [{"text": "Continue.", "next_id": "n08_guide_transition", "effects": {}}]
	},
	{
		"id": "n07b_inspection",
		"text": "Farrukh let him look. Sa'id's men worked through the crates with the bored thoroughness of soldiers who had done this a hundred times and expected the hundred-and-first to be exactly as dull - until one of them went still over an unmarked bolt of cloth, wrapped inside it something that was plainly not cloth at all, and Sa'id crouched to look himself, and did not immediately say what he saw.",
		"choices": [
			{"text": "Say nothing. Let him wonder.", "next_id": "n08_guide_transition", "effects": {}},
			{"text": "Tell him what you read in the unsigned letter back in Ghazni.", "next_id": "n07b_letter_callback", "requires_flag": "read_unsigned_letter", "effects": {"flags": ["revealed_letter_to_said"], "reputation": {"ghaznavid_officials": 1}}}
		]
	},
	{
		"id": "n07b_letter_callback",
		"text": "\"There was a second paper,\" Farrukh said, before he'd decided to say it - the same way he'd once stepped forward at a grave. \"Unsigned. My father's clerk wouldn't finish reading it aloud.\" Sa'id looked up at him for a long moment, weighing something that had nothing to do with customs law. \"Then you already know more than I do,\" he said, \"which is not usually true of the men I stop at this gate.\" He did not write anything further in his ledger that day.",
		"choices": [{"text": "Continue.", "next_id": "n08_guide_transition", "effects": {}}]
	},
	{
		"id": "n08_guide_transition",
		"text": "The caravan guide who'd brought them from Ghazni collected his fee at the gate and turned back the way they'd come - his contract, like the road behind them, ended at Teginabad. Farrukh spent what remained of the afternoon doing the ordinary, unglamorous work of the road: asking after a caravan master bound for Bost who'd take on a smaller party, haggling nothing, since there was nothing left in him to haggle with, and simply agreeing to the first honest face that offered a fair arrangement - a decision he suspected his father would have made faster, and better, and made anyway.",
		"choices": [{"text": "Continue.", "next_id": "n09_departure_teginabad", "effects": {}}]
	},
	{
		"id": "n09_departure_teginabad",
		"text": "They left Teginabad in the last honest light of the day, patterned brick walls behind them, Sa'id already a receding figure who would forget Farrukh's face by nightfall and remember, if he remembered anything, only the shipment's strange manifest. The road to Bost ran through country that still, for one more year, called itself Ghaznavid without irony. Farrukh did not know yet how short a lease that word had left. He knew only that the debt was still his, the letter's secret still unresolved, and that somewhere ahead, his father's actual road - not the one Nasuh's ledger recorded, but the one the man had actually walked - was still waiting to be found.",
		"choices": []
	}
]
```

- [ ] **Step 4: Run to verify the tests pass**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_teginabad_dialogue_content.gd -gexit`
Expected: 6 tests, 6 pass.

- [ ] **Step 5: Commit**

```bash
git add content/chapters/chapter_01_teginabad/teginabad.json tests/unit/test_teginabad_dialogue_content.gd
git commit -m "content: add Chapter 1 (Teginabad) dialogue tree"
```

---

### Task 6: The real chapter manifest, `Main.gd`, and the end-to-end cross-chapter test

**Files:**
- Create: `content/chapters/manifest.json`
- Modify: `scenes/main/Main.gd`
- Test: `tests/unit/test_chapter_view.gd`

**Interfaces:**
- Consumes: `load_chapter_by_id` (Task 2/3), Chapter 0's existing content (`content/chapters/chapter_00_prologue/prologue.json`, `content/glossary/prologue_terms.json`), Chapter 1's new content (Tasks 4/5).
- Produces: the real, playable chapter chain. Nothing later in this plan depends on new interfaces from this task — it's the integration point.

- [ ] **Step 1: Write the real manifest**

Create `content/chapters/manifest.json`:

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
		"next_chapter_id": null
	}
}
```

- [ ] **Step 2: Update `Main.gd`**

Replace the body of `scenes/main/Main.gd`'s `_ready()`:

```gdscript
func _ready() -> void:
	chapter_view.load_chapter(
		"res://content/chapters/chapter_00_prologue/prologue.json",
		"res://content/glossary/prologue_terms.json"
	)
```

with:

```gdscript
func _ready() -> void:
	chapter_view.load_chapter_by_id("chapter_00_prologue")
```

- [ ] **Step 3: Write the failing end-to-end test**

Append to `tests/unit/test_chapter_view.gd`:

```gdscript
func test_completing_the_prologue_via_the_real_manifest_loads_teginabad():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter_by_id("chapter_00_prologue")
	for i in range(11):
		chapter_view._on_choice_pressed(0)
	assert_eq(chapter_view.chapter_id, "chapter_01_teginabad")
	assert_true(chapter_view.dialogue_engine.current_node()["text"].contains("Teginabad"))

func test_a_prologue_flag_survives_into_teginabad_and_gates_the_letter_callback():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter_by_id("chapter_00_prologue")
	# Walk to n09_suftaja_letter_choice (8 presses), then choose "read the letter in full" (index 0).
	for i in range(8):
		chapter_view._on_choice_pressed(0)
	chapter_view._on_choice_pressed(0)
	# Finish the Prologue (2 more presses) - this sets read_unsigned_letter and, at the end, auto-transitions.
	for i in range(2):
		chapter_view._on_choice_pressed(0)
	assert_eq(chapter_view.chapter_id, "chapter_01_teginabad")
	# Walk to Teginabad's fork (5 presses), then choose the honest path (index 1).
	for i in range(5):
		chapter_view._on_choice_pressed(0)
	chapter_view._on_choice_pressed(1)
	assert_eq(chapter_view.dialogue_engine.available_choices().size(), 2, "the letter-callback choice should be visible because read_unsigned_letter carried over from the Prologue")
```

- [ ] **Step 4: Run to verify failure, then verify manually before moving on**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_chapter_view.gd -gexit`
Expected: FAIL until `content/chapters/manifest.json` exists (Step 1) and `Main.gd` is updated (Step 2) — if you're doing TDD strictly, write Step 3's test first and confirm it fails with "could not open chapter manifest" before writing Step 1/2's files. Either order is fine as long as you end with a passing run.

- [ ] **Step 5: Run tests to verify they pass**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_chapter_view.gd -gexit`
Expected: all tests in this file pass (8 from Tasks 2/3 plus these 2 = 10).

- [ ] **Step 6: Commit**

```bash
git add content/chapters/manifest.json scenes/main/Main.gd tests/unit/test_chapter_view.gd
git commit -m "feat: wire the real chapter manifest and boot via load_chapter_by_id"
```

---

### Task 7: Full-suite verification, manual playtest, and close-out

**Files:** none created; this task only runs and verifies.

**Interfaces:**
- Consumes: everything from Tasks 1–6, plus the Prologue's existing 70 tests.
- Produces: confirmation the entire suite passes together, and a tagged milestone.

- [ ] **Step 1: Run the entire suite together**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`
Expected: all tests pass — the Prologue's 70 plus this plan's new ones (1 + 2 + 2 + 1 + 6 + 2 = 14), for roughly 84 total. If any pre-existing Prologue test fails, suspect an accidental edit to `load_chapter()`, `_render_current_node()`'s pre-existing body, or `MarginGlossary`'s other methods — none of those should have changed.

- [ ] **Step 2: Manual playtest**

Open the project in the Godot editor (or run `godot --path .` for a real window) and press Play. Confirm, by hand:
1. The Prologue plays exactly as before (nothing regressed).
2. On reaching the Prologue's ending, the screen transitions directly into Teginabad's opening line ("Teginabad was not a city pretending to be one...") without any menu or pause.
3. The fork at "Sa'id returned unhurried..." presents two real choices; picking either reaches the guide-transition scene, but only the honest path (and only if you read the unsigned letter back in Ghazni) offers the "Tell him what you read..." option.
4. `{{amid|amid}}`, `{{ushr|'ushr}}`, `{{zuhr|midday prayer}}`, and `{{adhan|adhan}}` all render as clickable links opening correct Margin entries.
5. Reaching Teginabad's final line saves a file — check the console output for the save path, or that `user://borrowed_fortune_chapter_01_teginabad.json` exists.

- [ ] **Step 3: Tag the milestone**

```bash
git tag -a v0.2-teginabad -m "Chapter 1 (Teginabad) playable, auto-chained from the Prologue"
```

No further commit is needed — this task verifies and tags what Tasks 1–6 already committed.

---

## Post-Plan Note

Chapters 2–7 are not part of this plan. The chapter-manifest mechanism this plan introduces means each future chapter needs only: its own `content/chapters/chapter_0N_*/` dialogue JSON, its own glossary JSON, and one new entry in `content/chapters/manifest.json` (plus updating the *previous* chapter's `next_chapter_id`) — no further engine work, unless a future chapter is the one that finally introduces real trade mechanics (still explicitly deferred) or a real save/resume-on-boot feature (also still explicitly deferred — closing the game and reopening it always restarts at the Prologue).
