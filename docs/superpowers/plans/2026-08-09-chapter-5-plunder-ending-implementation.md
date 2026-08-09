# Chapter 5 (Plunder Ending) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** build and wire in Chapter 5 (`chapter_05_plunder_ending`), the short closing chapter for the plunder-branch substory that began at Farah's fork and continued through Chapter 4B.

**Architecture:** one new content file pair (dialogue JSON + empty glossary JSON) authored and tested standalone in Task 1, then wired into the manifest and into Chapter 4B's two terminal nodes in Task 2. No engine changes — this chapter is pure content, reusing `DialogueEngine`'s existing `requires_flag` gating exactly as Teginabad's letter-callback content already does.

**Tech Stack:** Godot 4.3, GDScript, GUT test framework, JSON content files.

## Global Constraints

- Godot 4.3 floor.
- `JSON.parse_string` deserializes all numbers as `float` — cast to `int` before comparing/assigning anywhere a value is used as `int`. (This chapter itself has no numeric effects at all — no coin, no reputation deltas — so this constraint mainly matters for not breaking the pattern elsewhere.)
- snake_case for node ids, flag names, and JSON keys; PascalCase for any GDScript class references.
- Commit after each task.
- Environment priming: a fresh worktree needs one `godot --headless --path . --editor --quit` run before GUT will find its class names. Running it a second time in the same worktree is known to SIGSEGV harmlessly (a documented, already-investigated Godot/GUT headless quirk unrelated to game code) — do not re-run it if it's already been primed once.

---

### Task 1: Author Chapter 5's content and test it standalone

**Files:**
- Create: `content/chapters/chapter_05_plunder_ending/plunder_ending.json`
- Create: `content/glossary/plunder_ending_terms.json`
- Test: `tests/unit/test_plunder_ending_dialogue_content.gd`

**Interfaces:**
- Consumes: `DialogueEngine.load_tree(nodes, start_id)`, `DialogueEngine.choose(index)`, `DialogueEngine.current_node()`, `DialogueEngine.available_choices()`, `DialogueEngine.flags` (all pre-existing, unchanged — see `engine/dialogue/DialogueEngine.gd`). A choice becomes unavailable when its `requires_flag` key names a flag not present (as `true`) in `DialogueEngine.flags` — this is exactly how `content/chapters/chapter_01_teginabad/teginabad.json`'s letter-callback choice already works; do not re-derive this behavior, just use the same JSON shape.
- Produces: the file `content/chapters/chapter_05_plunder_ending/plunder_ending.json`, whose first node id is `n01_the_road_west` — Task 2 wires this path into the manifest and does not touch this file's content again.

- [ ] **Step 1: Create the glossary file**

`content/glossary/plunder_ending_terms.json`:
```json
{}
```

No new terminology in this chapter — it introduces no new location, NPC, or vocabulary.

- [ ] **Step 2: Create the dialogue content file**

`content/chapters/chapter_05_plunder_ending/plunder_ending.json`:
```json
[
	{
		"id": "n01_the_road_west",
		"text": "He left Herat the way he'd left every stop before it - before first light, before the muster drums had found whatever rhythm they were going to keep without him - and did not look back at a city he had arrived in one kind of man and was leaving as some other kind, not yet named. The road west ran on regardless, the way it always had, indifferent to which man was walking it.",
		"choices": [
			{"text": "Continue.", "next_id": "n02_which_road_he_walks", "effects": {}}
		]
	},
	{
		"id": "n02_which_road_he_walks",
		"text": "What he carried out of that quarter with Rostam - the understanding, or the absence of one - was going to matter more on this stretch of road than anything he'd carried out of Farah.",
		"choices": [
			{"text": "Continue.", "requires_flag": "chose_to_stay_entangled", "next_id": "n03a_the_shape_of_the_understanding", "effects": {}},
			{"text": "Continue.", "requires_flag": "chose_to_pivot_away", "next_id": "n03b_the_shape_of_the_refusal", "effects": {}}
		]
	},
	{
		"id": "n03a_the_shape_of_the_understanding",
		"text": "There was no letter to answer, no date circled on any calendar he owned, nothing a qadi could have pointed to and called a contract - and that, he was beginning to understand, was precisely the design of it. An understanding without an end date didn't need enforcing. It only needed remembering, and Farrukh found he was already doing that without being asked, the way a man checks a debt is still there before he's even asked to pay it.",
		"choices": [
			{"text": "Continue.", "next_id": "n04a_the_watchfulness_learned", "effects": {}}
		]
	},
	{
		"id": "n04a_the_watchfulness_learned",
		"text": "He caught himself doing it on the third day out - the specific, unhurried way of looking at a stranger's hands before their face, the same appraisal he'd watched Rostam make of every courier who walked into that quarter. He did not remember deciding to learn it. It had simply arrived, the way a language arrives in a house where everyone around you speaks it long enough.",
		"choices": [
			{"text": "Continue.", "next_id": "n05a_the_lie_he_might_tell", "effects": {}}
		]
	},
	{
		"id": "n05a_the_lie_he_might_tell",
		"text": "Somewhere past the last outlying field, walking a road with no name he'd bothered to ask, Farrukh understood that whatever he told himself now about why he'd said yes would very likely be the version he carried the rest of the way west.",
		"choices": [
			{"text": "Tell yourself it was only ever going to be one more errand.", "next_id": "n06a_departure_bound_believed", "effects": {"flags": ["chose_to_believe_the_lie"]}},
			{"text": "Admit, at least to yourself, what you've actually become.", "next_id": "n06a_departure_bound_clear_eyed", "effects": {"flags": ["chose_to_see_clearly"]}}
		]
	},
	{
		"id": "n06a_departure_bound_believed",
		"text": "He told himself it was only ever going to be one more errand, and felt the lie settle into him with the particular ease of a story a man has decided, deliberately, to believe. Avicenna's floating man, stripped of every borrowed sense, was still supposed to know, without instruction, that he existed. Farrukh walked on knowing rather less than that about the man currently doing the walking - only that he was moving, that the road accepted him regardless of which version of himself he'd chosen to carry into it, and that some accountings, unlike his father's, might never come due at all, which was its own kind of debt.",
		"choices": [],
		"next_chapter_id": null
	},
	{
		"id": "n06a_departure_bound_clear_eyed",
		"text": "He did not tell himself it was only one more errand. He let himself know, plainly, walking a road he hadn't bothered to name, exactly what kind of understanding he'd agreed to and exactly what kind of man agreed to that kind of thing without a date attached to it. Avicenna's floating man, stripped of every borrowed sense, was still supposed to know, without instruction, that he existed. Farrukh knew that much too, at least - knew it clearly, for once, without the comfort of not looking - and understood that clarity, on this particular road, was not the same thing as being free.",
		"choices": [],
		"next_chapter_id": null
	},
	{
		"id": "n03b_the_shape_of_the_refusal",
		"text": "He had said no as plainly as a man could say it, and Rostam had let the silence do whatever work he'd decided it needed to do rather than argue - which meant Farrukh had left that quarter without ever actually learning whether a small, quietly delivered refusal was the kind of thing a man like that let go of, or only the kind of thing he set aside to collect later, at his own convenience.",
		"choices": [
			{"text": "Continue.", "next_id": "n04b_watching_the_road_behind", "effects": {}}
		]
	},
	{
		"id": "n04b_watching_the_road_behind",
		"text": "He caught himself doing it on the third day out - glancing back at a stretch of empty road more often than the road itself gave him reason to, the specific attention of a man who has decided a threat unconfirmed is not the same thing as a threat that has passed. Nothing followed that he could see. He was no longer entirely sure that was the same as nothing following.",
		"choices": [
			{"text": "Continue.", "next_id": "n05b_the_bet_he_could_not_confirm", "effects": {}}
		]
	},
	{
		"id": "n05b_the_bet_he_could_not_confirm",
		"text": "Somewhere past the last outlying field, walking a road with no name he'd bothered to ask, Farrukh understood that whatever he told himself now about whether he was actually safe would very likely be the version he carried the rest of the way west.",
		"choices": [
			{"text": "Let yourself believe the danger has passed.", "next_id": "n06b_departure_free_believed", "effects": {"flags": ["chose_to_believe_the_danger_passed"]}},
			{"text": "Accept that you may never know if it has.", "next_id": "n06b_departure_free_uncertain", "effects": {"flags": ["chose_to_accept_uncertainty"]}}
		]
	},
	{
		"id": "n06b_departure_free_believed",
		"text": "He let himself believe it was over, and felt the belief settle into him with the particular relief of a story a man has decided, deliberately, to trust. Avicenna's floating man, stripped of every borrowed sense, was still supposed to know, without instruction, that he existed. Farrukh walked on believing rather more than that about the road behind him - that it was empty, that it would stay empty, that a debt refused was the same as a debt discharged - and did not let himself wonder, more than once or twice a day, whether he'd simply chosen the more comfortable arithmetic.",
		"choices": [],
		"next_chapter_id": null
	},
	{
		"id": "n06b_departure_free_uncertain",
		"text": "He did not let himself believe it was over. He accepted, instead, walking a road he hadn't bothered to name, that some threats don't announce their ending any more clearly than they announced their beginning, and that a man could spend the rest of a long road checking behind him for something that had already stopped watching, or hadn't yet started. Avicenna's floating man, stripped of every borrowed sense, was still supposed to know, without instruction, that he existed. Farrukh knew that much, walking on - only that, and the uncomfortable, clarifying fact that uncertainty, carried far enough, was its own kind of company.",
		"choices": [],
		"next_chapter_id": null
	}
]
```

- [ ] **Step 3: Write the failing tests**

`tests/unit/test_plunder_ending_dialogue_content.gd`:
```gdscript
extends GutTest

func _load_nodes() -> Array:
	var file := FileAccess.open("res://content/chapters/chapter_05_plunder_ending/plunder_ending.json", FileAccess.READ)
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

func test_exactly_four_nodes_have_no_choices_and_they_are_the_four_terminal_nodes():
	var nodes := _load_nodes()
	var end_node_ids: Array = []
	for node in nodes:
		if node.get("choices", []).is_empty():
			end_node_ids.append(node["id"])
	end_node_ids.sort()
	assert_eq(end_node_ids, ["n06a_departure_bound_believed", "n06a_departure_bound_clear_eyed", "n06b_departure_free_believed", "n06b_departure_free_uncertain"])

func test_all_four_terminal_nodes_carry_their_own_null_next_chapter_id():
	var nodes := _load_nodes()
	var by_id: Dictionary = {}
	for node in nodes:
		by_id[node["id"]] = node
	for terminal_id in ["n06a_departure_bound_believed", "n06a_departure_bound_clear_eyed", "n06b_departure_free_believed", "n06b_departure_free_uncertain"]:
		assert_true(by_id[terminal_id].has("next_chapter_id"), "%s must carry its own next_chapter_id" % terminal_id)
		assert_eq(by_id[terminal_id]["next_chapter_id"], null, "%s must end the game (this is Chapter 5's own final state, no further chapter exists yet)" % terminal_id)

func test_the_fork_only_shows_the_bound_choice_when_that_flag_is_set():
	var engine := DialogueEngine.new()
	engine.flags["chose_to_stay_entangled"] = true
	engine.load_tree(_load_nodes(), "n01_the_road_west")
	engine.choose(0) # n01 -> n02
	assert_eq(engine.available_choices().size(), 1, "only the bound branch's choice should be visible")
	engine.choose(0)
	assert_eq(engine.current_node()["id"], "n03a_the_shape_of_the_understanding")

func test_the_fork_only_shows_the_free_choice_when_that_flag_is_set():
	var engine := DialogueEngine.new()
	engine.flags["chose_to_pivot_away"] = true
	engine.load_tree(_load_nodes(), "n01_the_road_west")
	engine.choose(0)
	assert_eq(engine.available_choices().size(), 1, "only the free branch's choice should be visible")
	engine.choose(0)
	assert_eq(engine.current_node()["id"], "n03b_the_shape_of_the_refusal")

func test_the_bound_branch_believed_path_is_walkable_and_sets_its_flag():
	var engine := DialogueEngine.new()
	engine.flags["chose_to_stay_entangled"] = true
	engine.load_tree(_load_nodes(), "n01_the_road_west")
	for i in range(4):
		engine.choose(0) # n01 -> n02 -> n03a -> n04a -> n05a
	assert_eq(engine.current_node()["id"], "n05a_the_lie_he_might_tell")
	var effects := engine.choose(0) # "Tell yourself it was only ever going to be one more errand."
	assert_eq(effects["flags"], ["chose_to_believe_the_lie"])
	assert_eq(engine.current_node()["id"], "n06a_departure_bound_believed")
	assert_true(engine.is_chapter_end())

func test_the_bound_branch_clear_eyed_path_is_walkable_and_sets_its_flag():
	var engine := DialogueEngine.new()
	engine.flags["chose_to_stay_entangled"] = true
	engine.load_tree(_load_nodes(), "n01_the_road_west")
	for i in range(4):
		engine.choose(0)
	var effects := engine.choose(1) # "Admit, at least to yourself, what you've actually become."
	assert_eq(effects["flags"], ["chose_to_see_clearly"])
	assert_eq(engine.current_node()["id"], "n06a_departure_bound_clear_eyed")
	assert_true(engine.is_chapter_end())

func test_the_free_branch_believed_path_is_walkable_and_sets_its_flag():
	var engine := DialogueEngine.new()
	engine.flags["chose_to_pivot_away"] = true
	engine.load_tree(_load_nodes(), "n01_the_road_west")
	for i in range(4):
		engine.choose(0) # n01 -> n02 -> n03b -> n04b -> n05b
	assert_eq(engine.current_node()["id"], "n05b_the_bet_he_could_not_confirm")
	var effects := engine.choose(0) # "Let yourself believe the danger has passed."
	assert_eq(effects["flags"], ["chose_to_believe_the_danger_passed"])
	assert_eq(engine.current_node()["id"], "n06b_departure_free_believed")
	assert_true(engine.is_chapter_end())

func test_the_free_branch_uncertain_path_is_walkable_and_sets_its_flag():
	var engine := DialogueEngine.new()
	engine.flags["chose_to_pivot_away"] = true
	engine.load_tree(_load_nodes(), "n01_the_road_west")
	for i in range(4):
		engine.choose(0)
	var effects := engine.choose(1) # "Accept that you may never know if it has."
	assert_eq(effects["flags"], ["chose_to_accept_uncertainty"])
	assert_eq(engine.current_node()["id"], "n06b_departure_free_uncertain")
	assert_true(engine.is_chapter_end())
```

- [ ] **Step 4: Run the tests to verify they fail**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gselect=test_plunder_ending_dialogue_content -gexit`
Expected: FAIL — the content files don't exist yet (if Steps 1-2 are done first, the tests should instead PASS; write the test file before the content files if you want a true RED step, or accept that in a content-authoring task the natural order is content-then-test with an immediate GREEN, which is fine — the important verification is Step 5, not a contrived RED).

- [ ] **Step 5: Run the tests to verify they pass**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gselect=test_plunder_ending_dialogue_content -gexit`
Expected: PASS, 9/9.

- [ ] **Step 6: Commit**

```bash
git add content/chapters/chapter_05_plunder_ending/plunder_ending.json content/glossary/plunder_ending_terms.json tests/unit/test_plunder_ending_dialogue_content.gd
git commit -m "feat: add Chapter 5 (plunder ending) dialogue content"
```

---

### Task 2: Wire Chapter 5 into the manifest and Chapter 4B's terminal nodes

**Files:**
- Modify: `content/chapters/manifest.json`
- Modify: `content/chapters/chapter_04b_herat_favor/herat_favor.json`
- Modify: `tests/unit/test_herat_favor_dialogue_content.gd`
- Modify: `tests/unit/test_chapter_view.gd`

**Interfaces:**
- Consumes: `chapter_05_plunder_ending`'s dialogue/glossary paths from Task 1 (`content/chapters/chapter_05_plunder_ending/plunder_ending.json`, `content/glossary/plunder_ending_terms.json`), first node id `n01_the_road_west`.
- Produces: nothing further consumed by any other task — this is the last task in the plan.

- [ ] **Step 1: Add the manifest entry**

In `content/chapters/manifest.json`, add this entry (keep existing entries unchanged):
```json
	"chapter_05_plunder_ending": {
		"dialogue_path": "res://content/chapters/chapter_05_plunder_ending/plunder_ending.json",
		"glossary_path": "res://content/glossary/plunder_ending_terms.json",
		"next_chapter_id": null
	}
```

- [ ] **Step 2: Wire Chapter 4B's two terminal nodes to Chapter 5**

In `content/chapters/chapter_04b_herat_favor/herat_favor.json`, change:
```json
		"id": "n17a_departure_bound",
		...
		"next_chapter_id": null
```
to:
```json
		"id": "n17a_departure_bound",
		...
		"next_chapter_id": "chapter_05_plunder_ending"
```
and likewise for `n17b_departure_free`'s `next_chapter_id`, from `null` to `"chapter_05_plunder_ending"`. Change only the `next_chapter_id` value on each node — leave every other field (`text`, `choices`) untouched.

- [ ] **Step 3: Update the test that currently asserts the OLD null value**

In `tests/unit/test_herat_favor_dialogue_content.gd`, find:
```gdscript
func test_both_terminal_nodes_carry_their_own_null_next_chapter_id():
	var nodes := _load_nodes()
	var by_id: Dictionary = {}
	for node in nodes:
		by_id[node["id"]] = node
	assert_true(by_id["n17a_departure_bound"].has("next_chapter_id"))
	assert_eq(by_id["n17a_departure_bound"]["next_chapter_id"], null)
	assert_true(by_id["n17b_departure_free"].has("next_chapter_id"))
	assert_eq(by_id["n17b_departure_free"]["next_chapter_id"], null)
```
Replace it with (renamed to reflect what it now actually asserts — do not delete it, per this project's established precedent of strengthening a stale wiring test rather than deleting it):
```gdscript
func test_both_terminal_nodes_now_point_at_chapter_5():
	var nodes := _load_nodes()
	var by_id: Dictionary = {}
	for node in nodes:
		by_id[node["id"]] = node
	assert_true(by_id["n17a_departure_bound"].has("next_chapter_id"))
	assert_eq(by_id["n17a_departure_bound"]["next_chapter_id"], "chapter_05_plunder_ending")
	assert_true(by_id["n17b_departure_free"].has("next_chapter_id"))
	assert_eq(by_id["n17b_departure_free"]["next_chapter_id"], "chapter_05_plunder_ending")
```

- [ ] **Step 4: Extend the plunder-branch full-playthrough test in test_chapter_view.gd**

Find `test_a_full_playthrough_via_the_plunder_branch_reaches_its_own_terminal_node` (it currently clears `user://borrowed_fortune_chapter_04b_herat_favor.json`, walks the "always press 0" loop, and asserts the playthrough stops inside Chapter 4B). Because `ChapterView`'s auto-transition (`_save_and_finish()` → `load_chapter_by_id()`) fires transparently whenever a chapter ends with a resolved `next_chapter_id`, the *same* `while chapter_view.dialogue_engine.available_choices().size() > 0` loop will now continue automatically from Chapter 4B straight into Chapter 5's nodes once Task 2 Step 2 is done — no new loop logic is needed, only updated assertions for the new final state and a new save-file clear-block for Chapter 5's own save path (per this project's established lesson: every test asserting a save path needs its own independent clear-block, even if another test clears the same-named path elsewhere).

Add a second clear-block right after the existing one for `chapter_04b_herat_favor`:
```gdscript
	var plunder_ending_save_path := "user://borrowed_fortune_chapter_05_plunder_ending.json"
	if FileAccess.file_exists(plunder_ending_save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(plunder_ending_save_path))
	assert_false(FileAccess.file_exists(plunder_ending_save_path), "the previous save should be cleared before the playthrough starts")
```

Then replace the post-loop assertions (currently ending in `chapter_04b_herat_favor` / `n17a_departure_bound` / `next_chapter_id == null`) with:
```gdscript
	assert_eq(chapter_view.chapter_id, "chapter_05_plunder_ending")
	assert_eq(chapter_view.dialogue_engine.current_node()["id"], "n06a_departure_bound_believed", "always pressing choice 0 takes 'Agree to keep working with him' at Ch4B's own fork, then 'Tell yourself it was only ever going to be one more errand' at Ch5's own fork")
	assert_eq(chapter_view.next_chapter_id, null, "Chapter 5 is the true end of the plunder branch")
	assert_true(chapter_view.dialogue_engine.flags.get("owes_tahir_a_favor", false), "Farah's flag must survive all the way into Chapter 5")
	assert_true(chapter_view.dialogue_engine.flags.get("knows_the_second_marks_name", false))
	assert_true(chapter_view.dialogue_engine.flags.get("chose_to_stay_entangled", false))
	assert_false(chapter_view.dialogue_engine.flags.get("chose_to_pivot_away", false))
	assert_true(chapter_view.dialogue_engine.flags.get("chose_to_believe_the_lie", false))
	assert_false(chapter_view.dialogue_engine.flags.get("chose_to_see_clearly", false))
	assert_eq(chapter_view.reputation_tracker.get_reputation("hidden_network"), 2, "unchanged since Chapter 4B - Chapter 5 has no reputation effects at all")
	assert_almost_eq(chapter_view.ledger.total_wealth_dirham_equivalent(), 0.0, 0.0001, "unchanged since Chapter 4B - Chapter 5 has no coin effects at all")
	assert_true(FileAccess.file_exists("user://borrowed_fortune_chapter_03_farah.json"), "passing through Farah on the way to Herat must still write Farah's save file")
	assert_true(FileAccess.file_exists("user://borrowed_fortune_chapter_04b_herat_favor.json"), "Chapter 4B is no longer the final chapter, but passing through it must still write its own save file")
	assert_true(FileAccess.file_exists(plunder_ending_save_path), "reaching Chapter 5's ending must write its own save file")
```

- [ ] **Step 5: Run the full suite to verify everything passes**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`
Expected: PASS, full suite green (187/187 — 178 before this plan + 9 new content tests in Task 1 + 1 renamed test in Task 2, which stays a 1:1 replacement, not a net addition).

- [ ] **Step 6: Commit**

```bash
git add content/chapters/manifest.json content/chapters/chapter_04b_herat_favor/herat_favor.json tests/unit/test_herat_favor_dialogue_content.gd tests/unit/test_chapter_view.gd
git commit -m "feat: wire Chapter 5 (plunder ending) into the manifest via Chapter 4B's terminal nodes"
```

## Verification

- [ ] Full GUT suite green, 187/187, before calling this plan done.
- [ ] Confirm `content/chapters/manifest.json` has exactly one new entry (`chapter_05_plunder_ending`) and every other entry unchanged.
- [ ] Confirm no other test in the suite still references `n17a_departure_bound`/`n17b_departure_free`'s old `null` `next_chapter_id` value (grep `tests/` for both node ids once more after Task 2 lands, since a stale assertion elsewhere would silently pass if it happens to check something other than `next_chapter_id`).
