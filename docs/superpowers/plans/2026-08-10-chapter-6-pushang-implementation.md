# Chapter 6 (Pushang) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** build and wire in Chapter 6 (`chapter_06_pushang`), the long main route's next stop after Chapter 4A.

**Architecture:** one new content file pair (dialogue JSON + 3-term glossary JSON) authored and tested standalone in Task 1, then wired into the manifest and into Chapter 4A's terminal node in Task 2. No engine changes — pure content, reusing `DialogueEngine`'s existing choice/effects mechanics exactly as every prior chapter has (no `requires_flag`/`requires_reputation` gating in this chapter — it has no true fork).

**Tech Stack:** Godot 4.3, GDScript, GUT test framework, JSON content files.

## Global Constraints

- Godot 4.3 floor.
- `JSON.parse_string` deserializes all numbers as `float` — cast to `int` before comparing/assigning anywhere a value is used as `int` (this chapter's reputation effects are ordinary ints on the content side, floats once parsed — any test reading them back must cast).
- snake_case for node ids, flag names, and JSON keys; PascalCase for any GDScript class references.
- Commit after each task.
- Environment priming: a fresh worktree needs one `godot --headless --path . --editor --quit` run before GUT will find its class names. Running it a second time in the same worktree is a known, already-investigated, harmless SIGSEGV quirk unrelated to game code — don't re-run it if it's already been primed once.

---

### Task 1: Author Chapter 6's content and test it standalone

**Files:**
- Create: `content/chapters/chapter_06_pushang/pushang.json`
- Create: `content/glossary/pushang_terms.json`
- Test: `tests/unit/test_pushang_dialogue_content.gd`

**Interfaces:**
- Consumes: `DialogueEngine.load_tree(nodes, start_id)`, `DialogueEngine.choose(index)`, `DialogueEngine.current_node()`, `DialogueEngine.available_choices()`, `DialogueEngine.is_chapter_end()` (all pre-existing, unchanged). No `requires_flag`/`requires_reputation` used anywhere in this chapter's content.
- Produces: the file `content/chapters/chapter_06_pushang/pushang.json`, first node id `n01_pushang_arrival`, single terminal node `n12_departure_pushang` — Task 2 wires this path into the manifest and does not touch this file's content again.

- [ ] **Step 1: Create the glossary file**

`content/glossary/pushang_terms.json`:
```json
{
	"behdin": {
		"headword": "Behdin",
		"definition": "\"Follower of the Good Religion\" - the Zoroastrian community's own term for itself, from the Middle Persian for the faith that predated Islam in Iran and Central Asia. Used in preference to outsider terms like Majus or Gabr, which carry more distance and, in Gabr's case, real pejorative weight."
	},
	"tarsa": {
		"headword": "Tarsa",
		"definition": "From Middle Persian tarsag, \"God-fearing\" - the everyday New Persian word for a Christian, used in ordinary speech both before and long after the Islamic conquest."
	},
	"nasrani": {
		"headword": "Nasrani",
		"definition": "The Qur'anic and Arabic term for a Christian, used in more formal, legal, or administrative registers - the same people the bazaar might call Tarsa."
	}
}
```

- [ ] **Step 2: Create the dialogue content file**

`content/chapters/chapter_06_pushang/pushang.json`:
```json
[
	{
		"id": "n01_pushang_arrival",
		"text": "Pushang announced itself the way a lesser cousin does at a family gathering - present, unmistakably related to the city he'd just left, and unmistakably smaller. Half of Herat's walls, the guide said, before they'd even reached the gate, and Farrukh understood the comparison wasn't unkind so much as exact: the same brick, the same canal-fed green fighting the same patient desert, all of it simply built to a more modest scale, for a town that had never needed to be more than what it was.",
		"choices": [
			{"text": "Continue.", "next_id": "n02_the_towns_face", "effects": {}}
		]
	},
	{
		"id": "n02_the_towns_face",
		"text": "It did not take long to see what the muster had cost a town this size more visibly than it had cost Herat. Stalls stood shuttered at an hour a bazaar should still have been loud. A watch that should have paced the wall in pairs paced it alone, when it paced at all. Whatever news had reached Herat as rumor had reached Pushang, evidently, as arithmetic - fewer men left to spare for anything but the wall itself, and fewer excuses left for pretending otherwise.",
		"choices": [
			{"text": "Continue.", "next_id": "n03_the_behdin_shopkeeper", "effects": {}}
		]
	},
	{
		"id": "n03_the_behdin_shopkeeper",
		"text": "One shop on the bazaar's short spine was still doing business, kept by a woman old enough to have buried a husband and young enough not to have expected to yet, who introduced herself as {{behdin|Behdin}} without being asked - a habit, she said, of a lifetime spent making sure strangers heard it from her before they heard some other word for it from someone else.",
		"choices": [
			{"text": "Continue.", "next_id": "n04_closing_early", "effects": {}}
		]
	},
	{
		"id": "n04_closing_early",
		"text": "She was closing early, she told him, weighing his coin with the same unhurried care Mihran and Ardashir both would have recognized - not because business was bad, though it was, but because a woman alone in a half-emptied garrison town had learned which hours were worth being visible in and which weren't.",
		"choices": [
			{"text": "Tell her you're sorry to hear it.", "next_id": "n05_the_tarsa_merchant", "effects": {"reputation": {"townsfolk": 1}}},
			{"text": "Say nothing. It isn't your business to comment on.", "next_id": "n05_the_tarsa_merchant", "effects": {}}
		]
	},
	{
		"id": "n05_the_tarsa_merchant",
		"text": "Farther down, past the mostly-shuttered stalls, a cloth merchant Farrukh's guide identified under his breath as {{tarsa|Tarsa}} was doing the opposite of closing - laying out goods with the specific, deliberate visibility of a man who had decided that vanishing from view, in a town this nervous, would draw more suspicion than staying exactly where everyone could see him.",
		"choices": [
			{"text": "Continue.", "next_id": "n06_two_names_one_people", "effects": {}}
		]
	},
	{
		"id": "n06_two_names_one_people",
		"text": "An officer's clerk, passing to record the day's arrivals, called the same man {{nasrani|Nasrani}} without a flicker of unkindness in it - the word simply belonging to a different register than the one the bazaar used, the way a qadi's ruling and a neighbor's gossip could describe the identical fact in languages that never quite touched. Farrukh understood, watching the two words pass within a minute of each other over the same unmoved man, that he had just been handed a small lesson about how many different vocabularies a single life in this empire actually required.",
		"choices": [
			{"text": "Continue.", "next_id": "n07_the_garrison_gate", "effects": {}}
		]
	},
	{
		"id": "n07_the_garrison_gate",
		"text": "The garrison gate ran on a different register again. Farrukh caught commands passing between officers in clipped Turkic he didn't follow, watched a Persian-lettered order change hands as if it were the only language administration had ever been conducted in, and noticed, tucked at the bottom of that same order, a line of Arabic script that a qadi would recognize before any soldier did.",
		"choices": [
			{"text": "Continue.", "next_id": "n08_the_sultans_three_tongues", "effects": {}}
		]
	},
	{
		"id": "n08_the_sultans_three_tongues",
		"text": "His guide, watching him watch it, said it was no different at the top than it was at this gate - that the Sultan himself, men said, could turn a line of Arabic verse as easily as he dictated a Persian rescript, and gave his orders to the men who actually swung the swords in the tongue those men had been born to. Three languages for one empire, none of them optional, and Farrukh understood, not for the first time on this road, how much of governing a place this size was simply the discipline of being understood by everyone whose obedience you actually needed.",
		"choices": [
			{"text": "Continue.", "next_id": "n09_the_officers_demand", "effects": {}}
		]
	},
	{
		"id": "n09_the_officers_demand",
		"text": "An officer at the gate - young, tired, working from a list that clearly hadn't gotten shorter all week - looked over Farrukh's manifest with the flat professional interest of a man collecting for a muster that needed feeding regardless of whose caravan happened to be passing through. \"For the garrison,\" he said, naming a sum, in the tone of a man reciting an order rather than making a request.",
		"choices": [
			{"text": "Pay what he asks.", "next_id": "n10a_complied", "effects": {"coin_spent_dirham_equivalent": 12.0, "reputation": {"ghaznavid_officials": 1}}},
			{"text": "Argue him down to something smaller.", "next_id": "n10b_haggled", "effects": {"coin_spent_dirham_equivalent": 6.0}},
			{"text": "Refuse outright.", "next_id": "n10c_refused", "effects": {"reputation": {"ghaznavid_officials": -2}}},
			{"text": "Offer him something quieter, off the list.", "next_id": "n10d_bribed", "effects": {"coin_spent_dirham_equivalent": 10.0, "reputation": {"trading_families": 1, "ghaznavid_officials": -1}}}
		]
	},
	{
		"id": "n10a_complied",
		"text": "Farrukh paid what was asked, and the officer marked his manifest with the small, satisfied economy of a man who had one fewer name left on a list that wasn't shrinking fast enough. It was not robbery, exactly - the garrison's need was real enough, and the muster wasn't his invention - but it did not feel like ordinary trade either, and Farrukh found he had no better word ready for whatever sat in between the two.",
		"choices": [
			{"text": "Continue.", "next_id": "n11_after_the_requisition", "effects": {}}
		]
	},
	{
		"id": "n10b_haggled",
		"text": "Farrukh talked the sum down the way he'd talked down every other price on this road, and the officer let him, with the particular weariness of a man who had heard every argument a caravan merchant could make and had stopped finding any of them worth resisting for more than a minute. He got a smaller number. He did not get the sense that the smaller number had cost the man in front of him anything at all.",
		"choices": [
			{"text": "Continue.", "next_id": "n11_after_the_requisition", "effects": {}}
		]
	},
	{
		"id": "n10c_refused",
		"text": "Farrukh said no, as plainly as he could manage, and watched the officer's tiredness curdle into something closer to genuine irritation - not violence, nothing that reached for a weapon, only the particular friction of a man whose list had just gotten one name longer to explain to whoever he answered to. They held his caravan at the gate longer than the transaction should have taken, checking papers that had already been checked, before finally, without apology, waving him through anyway.",
		"choices": [
			{"text": "Continue.", "next_id": "n11_after_the_requisition", "effects": {}}
		]
	},
	{
		"id": "n10d_bribed",
		"text": "Farrukh offered something smaller and considerably less official, and the officer took it with the practiced discretion of a man who had done this exact quiet transaction before and would do it again before the week was out - the list, technically, staying exactly as long as it had been, the coin simply never having existed as far as anyone above him would ever be told. It cost less than the official sum and considerably more than the haggled one, and Farrukh understood, walking away, that he had just paid specifically for the privilege of nobody official ever knowing he'd paid at all.",
		"choices": [
			{"text": "Continue.", "next_id": "n11_after_the_requisition", "effects": {}}
		]
	},
	{
		"id": "n11_after_the_requisition",
		"text": "Whatever it had cost him, Farrukh left the garrison gate with the same caravan he'd arrived with, which was more than the town's own watch, thinned past pairs, could apparently say for itself these days. A frontier failing was not, he was beginning to understand, one dramatic collapse - it was a hundred small requisitions like this one, in a hundred towns like this one, each individually reasonable, each one shaving a little more off whatever the word 'ordinary' had meant here a year ago.",
		"choices": [
			{"text": "Continue.", "next_id": "n12_departure_pushang", "effects": {}}
		]
	},
	{
		"id": "n12_departure_pushang",
		"text": "He left Pushang smaller than he'd found any city on this road, carrying whatever he'd carried out of Herat - a debt at his back, a name he understood better or worse depending on how the road behind him had gone, and now this too: a clearer sense of what an empire actually spent, day to day, simply to keep failing more slowly than it might have. Sarakhs lay ahead, and past it, however the road let him reach it, Nishapur.",
		"choices": [],
		"next_chapter_id": null
	}
]
```

- [ ] **Step 3: Write the failing tests**

`tests/unit/test_pushang_dialogue_content.gd`:
```gdscript
extends GutTest

func _load_nodes() -> Array:
	var file := FileAccess.open("res://content/chapters/chapter_06_pushang/pushang.json", FileAccess.READ)
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
	assert_eq(end_node_ids, ["n12_departure_pushang"])

func test_the_terminal_node_has_a_null_next_chapter_id():
	var nodes := _load_nodes()
	for node in nodes:
		if node["id"] == "n12_departure_pushang":
			assert_true(node.has("next_chapter_id"))
			assert_eq(node["next_chapter_id"], null)

func test_every_glossed_term_id_exists_in_the_pushang_glossary():
	var nodes := _load_nodes()
	var glossary_file := FileAccess.open("res://content/glossary/pushang_terms.json", FileAccess.READ)
	var glossary_data = JSON.parse_string(glossary_file.get_as_text())
	glossary_file.close()
	for node in nodes:
		for term_id in GlossedTextParser.extract_term_ids(node["text"]):
			assert_true(glossary_data.has(term_id), "node %s glosses unknown term '%s'" % [node["id"], term_id])

func test_the_comply_choice_reaches_its_outcome_and_effects():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_pushang_arrival")
	for i in range(8):
		engine.choose(0) # n01 -> n02 -> n03 -> n04 -> n05 -> n06 -> n07 -> n08 -> n09
	assert_eq(engine.current_node()["id"], "n09_the_officers_demand")
	var effects := engine.choose(0) # "Pay what he asks."
	assert_almost_eq(float(effects["coin_spent_dirham_equivalent"]), 12.0, 0.0001)
	assert_eq(int(effects["reputation"]["ghaznavid_officials"]), 1)
	assert_eq(engine.current_node()["id"], "n10a_complied")

func test_the_haggle_choice_reaches_its_outcome_and_effects():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_pushang_arrival")
	for i in range(8):
		engine.choose(0)
	var effects := engine.choose(1) # "Argue him down to something smaller."
	assert_almost_eq(float(effects["coin_spent_dirham_equivalent"]), 6.0, 0.0001)
	assert_eq(effects.get("reputation", {}), {})
	assert_eq(engine.current_node()["id"], "n10b_haggled")

func test_the_refuse_choice_reaches_its_outcome_and_effects():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_pushang_arrival")
	for i in range(8):
		engine.choose(0)
	var effects := engine.choose(2) # "Refuse outright."
	assert_eq(effects.get("coin_spent_dirham_equivalent", 0.0), 0.0)
	assert_eq(int(effects["reputation"]["ghaznavid_officials"]), -2)
	assert_eq(engine.current_node()["id"], "n10c_refused")

func test_the_bribe_choice_reaches_its_outcome_and_effects():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_pushang_arrival")
	for i in range(8):
		engine.choose(0)
	var effects := engine.choose(3) # "Offer him something quieter, off the list."
	assert_almost_eq(float(effects["coin_spent_dirham_equivalent"]), 10.0, 0.0001)
	assert_eq(int(effects["reputation"]["trading_families"]), 1)
	assert_eq(int(effects["reputation"]["ghaznavid_officials"]), -1)
	assert_eq(engine.current_node()["id"], "n10d_bribed")

func test_the_full_tree_is_walkable_from_start_to_end_via_first_choices():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_pushang_arrival")
	var visited := 0
	while not engine.is_chapter_end() and visited < 100:
		engine.choose(0)
		visited += 1
	assert_true(engine.is_chapter_end())
	assert_eq(engine.current_node()["id"], "n12_departure_pushang")
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gselect=test_pushang_dialogue_content -gexit`
Expected: PASS, 9/9.

- [ ] **Step 5: Commit**

```bash
git add content/chapters/chapter_06_pushang/pushang.json content/glossary/pushang_terms.json tests/unit/test_pushang_dialogue_content.gd
git commit -m "feat: add Chapter 6 (Pushang) dialogue content"
```

---

### Task 2: Wire Chapter 6 into the manifest and Chapter 4A's terminal node

**Files:**
- Modify: `content/chapters/manifest.json`
- Modify: `content/chapters/chapter_04a_herat/herat.json`
- Modify: `tests/unit/test_herat_dialogue_content.gd`
- Modify: `tests/unit/test_chapter_view.gd`

**Interfaces:**
- Consumes: `chapter_06_pushang`'s dialogue/glossary paths from Task 1 (`content/chapters/chapter_06_pushang/pushang.json`, `content/glossary/pushang_terms.json`), first node id `n01_pushang_arrival`.
- Produces: nothing further consumed by any other task — this is the last task in the plan.

- [ ] **Step 1: Add the manifest entry**

In `content/chapters/manifest.json`, add this entry (keep every existing entry unchanged):
```json
	"chapter_06_pushang": {
		"dialogue_path": "res://content/chapters/chapter_06_pushang/pushang.json",
		"glossary_path": "res://content/glossary/pushang_terms.json",
		"next_chapter_id": null
	}
```

- [ ] **Step 2: Wire Chapter 4A's terminal node to Chapter 6**

In `content/chapters/chapter_04a_herat/herat.json`, change `n21_departure_herat`'s `next_chapter_id` from `null` to `"chapter_06_pushang"`. Change only that field — leave the node's `text` and `choices` untouched.

- [ ] **Step 3: Grep before touching any test — do not trust one remembered test name**

Before editing any test file, run:
```bash
grep -rn "n21_departure_herat" tests/
```
Enumerate every match. As of this plan being written there are exactly two: one in `tests/unit/test_herat_dialogue_content.gd` (asserts the node's own `next_chapter_id`) and one in `tests/unit/test_chapter_view.gd` (a full-playthrough test that reaches this node). **Chapter 5's own wiring task just demonstrated why this grep matters: its plan named one playthrough test by name and missed a second, structurally identical one that asserted the same stale value through a different path.** If your grep turns up more than the two matches named in Steps 4 and 5 below, treat every additional match the same way — read it, and update it if it asserts the old `null` value.

- [ ] **Step 4: Update the test that asserts the OLD null value on the node itself**

In `tests/unit/test_herat_dialogue_content.gd`, find:
```gdscript
func test_the_terminal_node_has_a_null_next_chapter_id():
	var nodes := _load_nodes()
	for node in nodes:
		if node["id"] == "n21_departure_herat":
			assert_true(node.has("next_chapter_id"))
			assert_eq(node["next_chapter_id"], null)
```
Replace it with (renamed to reflect what it now asserts — do not delete it, per this project's established precedent):
```gdscript
func test_the_terminal_node_now_points_at_chapter_6():
	var nodes := _load_nodes()
	for node in nodes:
		if node["id"] == "n21_departure_herat":
			assert_true(node.has("next_chapter_id"))
			assert_eq(node["next_chapter_id"], "chapter_06_pushang")
```

- [ ] **Step 5: Extend the mystery-branch full-playthrough test in test_chapter_view.gd**

Find `test_a_full_playthrough_via_the_mystery_branch_carries_prologue_flags_through_farah`. Because `ChapterView`'s auto-transition fires transparently whenever a chapter ends with a resolved `next_chapter_id`, the existing `while chapter_view.dialogue_engine.available_choices().size() > 0` loop will now continue automatically from Chapter 4A straight into Chapter 6's nodes once Step 2 above is done — no new loop logic needed, only an added save-file clear-block and updated post-loop assertions.

Add a new clear-block into the existing loop that clears each save path (right after the existing `herat_save_path` line, inside the same `for path in [...]` array — add `chapter_06_pushang`'s save path to that array rather than writing a second loop):
```gdscript
	var pushang_save_path := "user://borrowed_fortune_chapter_06_pushang.json"
	for path in [teginabad_save_path, bost_save_path, farah_save_path, herat_save_path, pushang_save_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		assert_false(FileAccess.file_exists(path), "the previous save should be cleared before the playthrough starts")
```
This replaces the existing `for path in [teginabad_save_path, bost_save_path, farah_save_path, herat_save_path]:` block — declare `pushang_save_path` alongside the other four `_save_path` variables, then use the five-element array in the one clear-loop.

Then replace the post-loop assertions (currently ending in `chapter_04a_herat` / `n21_departure_herat` / `next_chapter_id == null`) with:
```gdscript
	assert_eq(chapter_view.chapter_id, "chapter_06_pushang")
	assert_eq(chapter_view.dialogue_engine.current_node()["id"], "n12_departure_pushang", "always pressing choice 0 takes the partial-truth path at 4A's gate, then 'Pay what he asks' at Pushang's own requisition choice")
	assert_eq(chapter_view.next_chapter_id, null, "Chapter 6 has no Chapter 7 yet")
	assert_true(chapter_view.dialogue_engine.flags.get("vowed_kafala", false), "the Prologue's kafala vow flag must survive all the way into Pushang")
	assert_true(chapter_view.dialogue_engine.flags.get("knows_the_second_marks_name", false))
	assert_true(chapter_view.dialogue_engine.flags.get("partial_network_reveal", false))
	assert_false(chapter_view.dialogue_engine.flags.get("full_network_reveal", false))
	assert_almost_eq(chapter_view.ledger.total_wealth_dirham_equivalent(), -57.0, 0.0001, "Herat's -45.0 (Farah's -15.0 plus two accepted-rate haggles: -10.0 and -20.0) plus Pushang's comply choice: -12.0")
	assert_true(FileAccess.file_exists(teginabad_save_path), "passing through Teginabad on the way to Pushang must still write Teginabad's save file")
	assert_true(FileAccess.file_exists(bost_save_path), "passing through Bost on the way to Pushang must still write Bost's save file")
	assert_true(FileAccess.file_exists(farah_save_path), "passing through Farah on the way to Pushang must still write Farah's save file")
	assert_true(FileAccess.file_exists(herat_save_path), "Chapter 4A is no longer the final chapter, but passing through it must still write its own save file")
	assert_true(FileAccess.file_exists(pushang_save_path), "reaching Chapter 6's ending must write its own save file")
```

- [ ] **Step 6: Run the full suite to verify everything passes**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`
Expected: PASS, full suite green (196/196 — 187 before this plan + 9 new content tests in Task 1 + 1 renamed test in Task 2, a 1:1 replacement, not a net addition).

- [ ] **Step 7: Commit**

```bash
git add content/chapters/manifest.json content/chapters/chapter_04a_herat/herat.json tests/unit/test_herat_dialogue_content.gd tests/unit/test_chapter_view.gd
git commit -m "feat: wire Chapter 6 (Pushang) into the manifest via Chapter 4A's terminal node"
```

## Verification

- [ ] Full GUT suite green, 196/196, before calling this plan done.
- [ ] Confirm `content/chapters/manifest.json` has exactly one new entry (`chapter_06_pushang`) and every other entry unchanged.
- [ ] Re-run `grep -rn "n21_departure_herat" tests/` one more time after Task 2 lands — every match found should now assert the new `"chapter_06_pushang"` value where it asserts `next_chapter_id` at all, with no leftover assertion of the old `null`.
