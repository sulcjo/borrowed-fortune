# Chapter 8 (Nishapur) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** build and wire in Chapter 8 (`chapter_08_nishapur`), the long main route's final stop — the actual ending of the long route.

**Architecture:** one new content file pair (dialogue JSON + 2-term glossary JSON) authored and tested standalone in Task 1, then wired into the manifest and into Chapter 7's terminal node in Task 2. No engine changes — pure content, reusing `DialogueEngine`'s existing choice/effects mechanics and the established sideroad-convergence pattern (a `requires_flag`-gated choice plus an always-available fallback, both reaching the same downstream node).

**Tech Stack:** Godot 4.3, GDScript, GUT test framework, JSON content files.

## Global Constraints

- Godot 4.3 floor.
- `JSON.parse_string` deserializes all numbers as `float` — this chapter has no numeric effects at all (no coin, no reputation — the final choice is flag-only, matching Chapter 5's ending precedent), so this constraint mainly matters for not breaking the pattern elsewhere.
- snake_case for node ids, flag names, and JSON keys; PascalCase for any GDScript class references.
- `DialogueEngine.choose(choice_index)` indexes into `available_choices()` (the *filtered* list of currently-visible choices), not into the raw `node["choices"]` array — confirmed by reading `engine/dialogue/DialogueEngine.gd` directly (`choose()` calls `available_choices()` and indexes into that result). When only one choice is visible at a fork, `choose(0)` always picks whichever one that is, regardless of its position in the raw JSON. This matters for Task 1's sideroad tests below — get the index math wrong here and the tests silently assert the wrong thing.
- Commit after each task.
- Environment priming: a fresh worktree needs one `godot --headless --path . --editor --quit` run before GUT will find its class names. Running it a second time in the same worktree is a known, already-investigated, harmless SIGSEGV quirk unrelated to game code — don't re-run it if it's already been primed once.

---

### Task 1: Author Chapter 8's content and test it standalone

**Files:**
- Create: `content/chapters/chapter_08_nishapur/nishapur.json`
- Create: `content/glossary/nishapur_terms.json`
- Test: `tests/unit/test_nishapur_dialogue_content.gd`

**Interfaces:**
- Consumes: `DialogueEngine.load_tree(nodes, start_id)`, `DialogueEngine.choose(index)`, `DialogueEngine.current_node()`, `DialogueEngine.available_choices()`, `DialogueEngine.is_chapter_end()`, `DialogueEngine.flags` (all pre-existing, unchanged).
- Produces: the file `content/chapters/chapter_08_nishapur/nishapur.json`, first node id `n01_nishapur_arrival`, two terminal nodes `n10a_ending_the_self_that_endures` and `n10b_ending_the_self_dissolved` — Task 2 wires this path into the manifest and does not touch this file's content again.

- [ ] **Step 1: Create the glossary file**

`content/glossary/nishapur_terms.json`:
```json
{
	"khaneqah": {
		"headword": "Khaneqah",
		"definition": "A Sufi lodge - a residence and gathering place for a teacher and the students, wanderers, and ordinary townsfolk who came to hear him, eat with him, and sometimes stay."
	},
	"khudi": {
		"headword": "Khudi",
		"definition": "Persian for \"I-ness\" or selfhood - in the vocabulary this teacher used, the one veil a man had to work hardest to see past, the self-assertion standing between him and everything beyond it."
	}
}
```

- [ ] **Step 2: Create the dialogue content file**

`content/chapters/chapter_08_nishapur/nishapur.json`:
```json
[
	{
		"id": "n01_nishapur_arrival",
		"text": "Nishapur announced itself the way a name announces a man he has never met - familiar in shape, entirely strange in substance. His father had carried this city's name his whole life without ever once, that Farrukh knew of, setting foot inside its walls; and now the son who bore it too was arriving for both of them, nineteen years and one grave too late for it to mean what it might have. The turquoise market alone told him he'd reached somewhere the empire still thought worth keeping - stalls of blue-green stone laid out like a wealth that hadn't yet heard the frontier behind it was failing.",
		"choices": [
			{"text": "Continue.", "next_id": "n02_a_city_that_isnt_home", "effects": {}}
		]
	},
	{
		"id": "n02_a_city_that_isnt_home",
		"text": "He had expected, walking in, something closer to homecoming. What he felt instead was closer to visiting a stranger's house that happened to share his family's name on the deed - every street a place his father had chosen never to return to, for reasons Farrukh now understood he would never fully recover, no matter how much of this road he retraced.",
		"choices": [
			{"text": "Continue.", "next_id": "n03_the_turquoise_and_the_ledger", "effects": {}}
		]
	},
	{
		"id": "n03_the_turquoise_and_the_ledger",
		"text": "Nishapur ran on two economies at once, and neither one seemed aware of the other. The turquoise trade filled half the bazaar with a wealth that had outlasted every dynasty that ever taxed it; the other half filled with men arguing points of hadith outside the mosque with the same heat other cities reserved for arguing prices. Farrukh understood, watching both at once, that a city could hold its ground against the frontier's failure a while longer than a fortress could - not because it was stronger, but because it had more than one thing worth defending.",
		"choices": [
			{"text": "Continue.", "next_id": "n04_the_choice_before_the_khaneqah", "effects": {}}
		]
	},
	{
		"id": "n04_the_choice_before_the_khaneqah",
		"text": "Farrukh had heard, before he'd found lodging, that a teacher kept a {{khaneqah|khaneqah}} near the western quarter, and that anyone was welcome to listen at dusk. There was, first, a smaller matter to settle, or not.",
		"choices": [
			{"text": "Seek out the family Bahram asked you to find.", "requires_flag": "carries_the_commanders_token", "next_id": "n05a_bahrams_family", "effects": {}},
			{"text": "Let the city's business come first.", "next_id": "n06_the_khaneqah_at_dusk", "effects": {}}
		]
	},
	{
		"id": "n05a_bahrams_family",
		"text": "He found them by the third house he asked at - a wife and two children who took the token from his hand with the particular stillness of people who had spent every season since the muster deepened waiting for exactly this kind of stranger to appear at their door, and dreading it in equal measure. She did not ask if her husband still lived. Farrukh understood, watching her not-ask, that she already knew he couldn't have told her either way, and had decided not to make him say so aloud.",
		"choices": [
			{"text": "Continue.", "next_id": "n06_the_khaneqah_at_dusk", "effects": {}}
		]
	},
	{
		"id": "n06_the_khaneqah_at_dusk",
		"text": "The khaneqah was smaller than the mosque's arguments outside had led him to expect - a plain room, a teacher old enough to have outlived most of his own scandals, and an audience that had stopped needing to be convinced this was worth their evening some years before Farrukh arrived. Others called him controversial, still, in the tone of people repeating an old argument rather than starting a new one - a man who'd praised a heretic long executed, who let his students sing and dance when devotion was supposed to look more like silence, who'd once been reported to the Sultan himself for exactly those things and had somehow talked his way clear of it. He did not call himself sheikh, or master, or anything at all, as far as Farrukh could tell. Others did that for him.",
		"choices": [
			{"text": "Continue.", "next_id": "n07_nobody_son_of_nobody", "effects": {}}
		]
	},
	{
		"id": "n07_nobody_son_of_nobody",
		"text": "He spoke, when he spoke, almost entirely without the word 'I' - a habit so consistent Farrukh began, uncomfortably, to notice its absence the way a missing tooth makes itself known. Asked once, someone near Farrukh murmured, what his own name really was, he was said to have answered that he was Nobody, son of Nobody - that {{khudi|khudi}}, the self a man spent his whole life insisting on, was the one veil no amount of piety alone could see past, and the entire labor of a life, if a man was fortunate enough to attempt it, was learning to want that veil gone. Farrukh did not know how much of what he was hearing was the man himself and how much was forty years of other people's retelling. It did not, sitting there, seem to matter as much as he'd have guessed.",
		"choices": [
			{"text": "Continue.", "next_id": "n08_the_last_reckoning", "effects": {}}
		]
	},
	{
		"id": "n08_the_last_reckoning",
		"text": "He walked back out into a Nishapur evening turning over an old letter-writer's lesson from Ghazni against this dusk's teaching, the two of them refusing, however he arranged them, to sit comfortably in the same hand. Avicenna's floating man, stripped of every sense, every borrowed thing, was still supposed to know, without instruction, that he existed - a self so bedrock it survived total sensory erasure. This teacher, in the same city, on the same evening, was arguing the opposite case: that the self was not bedrock at all, but the very thing a man had to work hardest to be rid of. Farrukh had carried the first idea the entire length of a debt, a mystery, and a road two provinces long. He did not know, standing in the dark outside a stranger's khaneqah, which of the two ideas he'd actually been practicing this whole time.",
		"choices": [
			{"text": "Continue.", "next_id": "n09_the_final_choice", "effects": {}}
		]
	},
	{
		"id": "n09_the_final_choice",
		"text": "Somewhere behind him, a father's debt he had chosen to carry, a name from Rayy he understood exactly as much or as little as the road had let him, a token delivered or never asked for at all - and ahead of him, still, whatever the rest of a life spent knowing or unknowing himself actually looked like. He had to decide, walking on, which of two men he'd rather have been the whole time.",
		"choices": [
			{"text": "Hold to the self that carried you this far.", "next_id": "n10a_ending_the_self_that_endures", "effects": {"flags": ["chose_the_self_that_endures"]}},
			{"text": "Let go of insisting on being anyone in particular.", "next_id": "n10b_ending_the_self_dissolved", "effects": {"flags": ["chose_the_self_dissolved"]}}
		]
	},
	{
		"id": "n10a_ending_the_self_that_endures",
		"text": "He chose, in the end, to believe Avicenna's floating man over the teacher at the khaneqah - that whatever had been stripped from him since his father's grave, a name, a fortune, an easy road, the man doing the choosing had never once stopped being someone in particular, and never would, all the way to whatever debt or reckoning still waited past Nishapur's walls. It was not peace, exactly. It was, he decided, close enough to it to keep walking on.",
		"choices": [],
		"next_chapter_id": null
	},
	{
		"id": "n10b_ending_the_self_dissolved",
		"text": "He chose, in the end, to believe the teacher at the khaneqah over Avicenna's floating man - that the self he'd spent this entire road insisting on, defending, negotiating, and occasionally sacrificing for a stranger's sake, had never been the point of any of it, and that whatever peace existed past Nishapur's walls would have to be found by a man who'd finally stopped needing to be anyone in particular to find it. It was not relief, exactly. It was, he decided, close enough to it to keep walking on.",
		"choices": [],
		"next_chapter_id": null
	}
]
```

- [ ] **Step 3: Write the failing tests**

`tests/unit/test_nishapur_dialogue_content.gd`:
```gdscript
extends GutTest

func _load_nodes() -> Array:
	var file := FileAccess.open("res://content/chapters/chapter_08_nishapur/nishapur.json", FileAccess.READ)
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

func test_exactly_two_nodes_have_no_choices_and_they_are_the_two_terminal_nodes():
	var nodes := _load_nodes()
	var end_node_ids: Array = []
	for node in nodes:
		if node.get("choices", []).is_empty():
			end_node_ids.append(node["id"])
	end_node_ids.sort()
	assert_eq(end_node_ids, ["n10a_ending_the_self_that_endures", "n10b_ending_the_self_dissolved"])

func test_both_terminal_nodes_carry_their_own_null_next_chapter_id():
	var nodes := _load_nodes()
	var by_id: Dictionary = {}
	for node in nodes:
		by_id[node["id"]] = node
	for terminal_id in ["n10a_ending_the_self_that_endures", "n10b_ending_the_self_dissolved"]:
		assert_true(by_id[terminal_id].has("next_chapter_id"), "%s must carry its own next_chapter_id" % terminal_id)
		assert_eq(by_id[terminal_id]["next_chapter_id"], null, "%s must end the game - this is the long route's actual finale, no Chapter 9 exists" % terminal_id)

func test_every_glossed_term_id_exists_in_the_nishapur_glossary():
	var nodes := _load_nodes()
	var glossary_file := FileAccess.open("res://content/glossary/nishapur_terms.json", FileAccess.READ)
	var glossary_data = JSON.parse_string(glossary_file.get_as_text())
	glossary_file.close()
	for node in nodes:
		for term_id in GlossedTextParser.extract_term_ids(node["text"]):
			assert_true(glossary_data.has(term_id), "node %s glosses unknown term '%s'" % [node["id"], term_id])

func test_the_family_sideroad_is_hidden_without_the_token_flag():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_nishapur_arrival")
	for i in range(3):
		engine.choose(0) # n01 -> n02 -> n03 -> n04
	assert_eq(engine.current_node()["id"], "n04_the_choice_before_the_khaneqah")
	assert_eq(engine.available_choices().size(), 1, "without the flag, only the fallback should be visible")
	engine.choose(0) # the only visible choice is the fallback, "Let the city's business come first."
	assert_eq(engine.current_node()["id"], "n06_the_khaneqah_at_dusk", "the fallback must skip straight past the family sideroad")

func test_the_family_sideroad_is_visible_and_taken_with_the_token_flag():
	var engine := DialogueEngine.new()
	engine.flags["carries_the_commanders_token"] = true
	engine.load_tree(_load_nodes(), "n01_nishapur_arrival")
	for i in range(3):
		engine.choose(0)
	assert_eq(engine.available_choices().size(), 2, "with the flag set, both choices should be visible")
	engine.choose(0) # available_choices()[0] is the gated choice when the flag is set - "Seek out the family..."
	assert_eq(engine.current_node()["id"], "n05a_bahrams_family")
	engine.choose(0)
	assert_eq(engine.current_node()["id"], "n06_the_khaneqah_at_dusk", "the sideroad must converge on the same node the fallback reaches")

func test_the_endures_choice_reaches_its_terminal_and_sets_its_flag():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_nishapur_arrival")
	for i in range(7):
		engine.choose(0) # n01 -> n02 -> n03 -> n04(fallback) -> n06 -> n07 -> n08 -> n09
	assert_eq(engine.current_node()["id"], "n09_the_final_choice")
	var effects := engine.choose(0) # "Hold to the self that carried you this far."
	assert_eq(effects["flags"], ["chose_the_self_that_endures"])
	assert_eq(engine.current_node()["id"], "n10a_ending_the_self_that_endures")
	assert_true(engine.is_chapter_end())

func test_the_dissolved_choice_reaches_its_terminal_and_sets_its_flag():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_nishapur_arrival")
	for i in range(7):
		engine.choose(0)
	var effects := engine.choose(1) # "Let go of insisting on being anyone in particular."
	assert_eq(effects["flags"], ["chose_the_self_dissolved"])
	assert_eq(engine.current_node()["id"], "n10b_ending_the_self_dissolved")
	assert_true(engine.is_chapter_end())

func test_the_full_tree_is_walkable_from_start_to_end_via_first_choices():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_nishapur_arrival")
	var visited := 0
	while not engine.is_chapter_end() and visited < 100:
		engine.choose(0)
		visited += 1
	assert_true(engine.is_chapter_end())
	assert_eq(engine.current_node()["id"], "n10a_ending_the_self_that_endures", "without the token flag, choose(0) at n04 takes the fallback, and choose(0) at n09 takes the 'endures' ending")
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gselect=test_nishapur_dialogue_content -gexit`
Expected: PASS, 9/9.

- [ ] **Step 5: Commit**

```bash
git add content/chapters/chapter_08_nishapur/nishapur.json content/glossary/nishapur_terms.json tests/unit/test_nishapur_dialogue_content.gd
git commit -m "feat: add Chapter 8 (Nishapur) dialogue content"
```

---

### Task 2: Wire Chapter 8 into the manifest and Chapter 7's terminal node

**Files:**
- Modify: `content/chapters/manifest.json`
- Modify: `content/chapters/chapter_07_sarakhs/sarakhs.json`
- Modify: `tests/unit/test_sarakhs_dialogue_content.gd`
- Modify: `tests/unit/test_chapter_view.gd`

**Interfaces:**
- Consumes: `chapter_08_nishapur`'s dialogue/glossary paths from Task 1 (`content/chapters/chapter_08_nishapur/nishapur.json`, `content/glossary/nishapur_terms.json`), first node id `n01_nishapur_arrival`.
- Produces: nothing further consumed by any other task — this is the last task in the plan, and (per the master spec's own 8-stop scope) the last chapter of the long route entirely. No future chapter plan should assume anything is produced here.

- [ ] **Step 1: Add the manifest entry**

In `content/chapters/manifest.json`, add this entry (keep every existing entry unchanged):
```json
	"chapter_08_nishapur": {
		"dialogue_path": "res://content/chapters/chapter_08_nishapur/nishapur.json",
		"glossary_path": "res://content/glossary/nishapur_terms.json",
		"next_chapter_id": null
	}
```

- [ ] **Step 2: Wire Chapter 7's terminal node to Chapter 8**

In `content/chapters/chapter_07_sarakhs/sarakhs.json`, change `n11_departure_sarakhs`'s `next_chapter_id` from `null` to `"chapter_08_nishapur"`. Change only that field — leave the node's `text` and `choices` untouched.

- [ ] **Step 3: Grep before touching any test — do not trust one remembered test name or count**

Before editing any test file, run:
```bash
grep -rn "n11_departure_sarakhs" tests/
```
Enumerate every match yourself. At the time this plan was written there were exactly 4 matches across 2 files (`tests/unit/test_sarakhs_dialogue_content.gd` and `tests/unit/test_chapter_view.gd`) — but re-run the grep rather than trusting that count, in case anything changed between writing this plan and executing it. Read every match and update any that assert the old `null` value; note anything unexpected in your report even if you leave it unchanged.

- [ ] **Step 4: Update the test that asserts the OLD null value on the node itself**

In `tests/unit/test_sarakhs_dialogue_content.gd`, find:
```gdscript
func test_the_terminal_node_has_a_null_next_chapter_id():
	var nodes := _load_nodes()
	for node in nodes:
		if node["id"] == "n11_departure_sarakhs":
			assert_true(node.has("next_chapter_id"))
			assert_eq(node["next_chapter_id"], null)
```
Replace it with (renamed to reflect what it now asserts — do not delete it, per this project's established precedent):
```gdscript
func test_the_terminal_node_now_points_at_chapter_8():
	var nodes := _load_nodes()
	for node in nodes:
		if node["id"] == "n11_departure_sarakhs":
			assert_true(node.has("next_chapter_id"))
			assert_eq(node["next_chapter_id"], "chapter_08_nishapur")
```

- [ ] **Step 5: Extend the mystery-branch full-playthrough test in test_chapter_view.gd**

Find `test_a_full_playthrough_via_the_mystery_branch_carries_prologue_flags_through_farah`. Because `ChapterView`'s auto-transition fires transparently whenever a chapter ends with a resolved `next_chapter_id`, the existing `while chapter_view.dialogue_engine.available_choices().size() > 0` loop will now continue automatically from Chapter 7 straight into Chapter 8's nodes once Step 2 above is done — no new loop logic needed, only an added save-file clear-block entry and updated post-loop assertions.

Add `nishapur_save_path` into the existing six-element clear-array (turning it into seven):
```gdscript
	var nishapur_save_path := "user://borrowed_fortune_chapter_08_nishapur.json"
	for path in [teginabad_save_path, bost_save_path, farah_save_path, herat_save_path, pushang_save_path, sarakhs_save_path, nishapur_save_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		assert_false(FileAccess.file_exists(path), "the previous save should be cleared before the playthrough starts")
```
This replaces the existing six-element `for path in [...]` clear-loop — declare `nishapur_save_path` alongside the other `_save_path` variables, then use the seven-element array in the one clear-loop.

Then replace the post-loop assertions (currently ending in `chapter_07_sarakhs` / `n11_departure_sarakhs`) with:
```gdscript
	assert_eq(chapter_view.chapter_id, "chapter_08_nishapur")
	assert_eq(chapter_view.dialogue_engine.current_node()["id"], "n10a_ending_the_self_that_endures", "carries_the_commanders_token is already true from Sarakhs's own 'always press 0' path, so at n04_the_choice_before_the_khaneqah both choices are visible and index 0 is the gated one ('Seek out the family...'); at n09_the_final_choice index 0 is 'Hold to the self that carried you this far.'")
	assert_eq(chapter_view.next_chapter_id, null, "Chapter 8 is the long route's actual finale - no Chapter 9 exists")
	assert_true(chapter_view.dialogue_engine.flags.get("vowed_kafala", false), "the Prologue's kafala vow flag must survive all the way into Nishapur")
	assert_true(chapter_view.dialogue_engine.flags.get("knows_the_second_marks_name", false))
	assert_true(chapter_view.dialogue_engine.flags.get("partial_network_reveal", false))
	assert_false(chapter_view.dialogue_engine.flags.get("full_network_reveal", false))
	assert_true(chapter_view.dialogue_engine.flags.get("carries_the_commanders_token", false))
	assert_true(chapter_view.dialogue_engine.flags.get("chose_the_self_that_endures", false), "index 0 at n09_the_final_choice is 'Hold to the self that carried you this far.'")
	assert_false(chapter_view.dialogue_engine.flags.get("chose_the_self_dissolved", false))
	assert_almost_eq(chapter_view.ledger.total_wealth_dirham_equivalent(), -57.0, 0.0001, "unchanged since Chapter 6 - neither Chapter 7 nor Chapter 8 has any coin effect on this path")
	assert_true(FileAccess.file_exists(teginabad_save_path), "passing through Teginabad on the way to Nishapur must still write Teginabad's save file")
	assert_true(FileAccess.file_exists(bost_save_path), "passing through Bost on the way to Nishapur must still write Bost's save file")
	assert_true(FileAccess.file_exists(farah_save_path), "passing through Farah on the way to Nishapur must still write Farah's save file")
	assert_true(FileAccess.file_exists(herat_save_path), "passing through Chapter 4A on the way to Nishapur must still write its own save file")
	assert_true(FileAccess.file_exists(pushang_save_path), "passing through Chapter 6 on the way to Nishapur must still write its own save file")
	assert_true(FileAccess.file_exists(sarakhs_save_path), "Chapter 7 is no longer the final chapter, but passing through it must still write its own save file")
	assert_true(FileAccess.file_exists(nishapur_save_path), "reaching Chapter 8's ending must write its own save file")
```

- [ ] **Step 6: Run the full suite to verify everything passes**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`
Expected: PASS, full suite green (215/215 — 206 before this plan + 9 new content tests in Task 1 + 1 renamed test in Task 2, a 1:1 replacement, not a net addition).

- [ ] **Step 7: Commit**

```bash
git add content/chapters/manifest.json content/chapters/chapter_07_sarakhs/sarakhs.json tests/unit/test_sarakhs_dialogue_content.gd tests/unit/test_chapter_view.gd
git commit -m "feat: wire Chapter 8 (Nishapur) into the manifest via Chapter 7's terminal node"
```

## Verification

- [ ] Full GUT suite green, 215/215, before calling this plan done.
- [ ] Confirm `content/chapters/manifest.json` has exactly one new entry (`chapter_08_nishapur`) and every other entry unchanged.
- [ ] Re-run `grep -rn "n11_departure_sarakhs" tests/` one more time after Task 2 lands — every match found should now assert the new `"chapter_08_nishapur"` value where it asserts `next_chapter_id` at all, with no leftover assertion of the old `null`.
- [ ] This is the long route's final chapter per the master spec's scope — confirm nothing in this plan or its implementation implies a Chapter 9 is coming (both terminal nodes' `next_chapter_id: null` is genuinely terminal here, not "more to come" like every prior chapter's).
