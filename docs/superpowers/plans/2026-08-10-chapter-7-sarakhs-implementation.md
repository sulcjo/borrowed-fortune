# Chapter 7 (Sarakhs) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** build and wire in Chapter 7 (`chapter_07_sarakhs`), the long main route's next stop after Chapter 6.

**Architecture:** one new content file pair (dialogue JSON + 1-term glossary JSON) authored and tested standalone in Task 1, then wired into the manifest and into Chapter 6's terminal node in Task 2. No engine changes — pure content, reusing `DialogueEngine`'s existing choice/effects mechanics and the established sideroad-convergence pattern (two choices reaching the same downstream node, exactly like Chapter 4A/4B's mint detour).

**Tech Stack:** Godot 4.3, GDScript, GUT test framework, JSON content files.

## Global Constraints

- Godot 4.3 floor.
- `JSON.parse_string` deserializes all numbers as `float` — cast to `int` before comparing/assigning anywhere a value is used as `int`.
- snake_case for node ids, flag names, and JSON keys; PascalCase for any GDScript class references.
- `ghulam` is reused as **plain prose, no `{{}}` glossary markup** in this chapter's content — it already has a glossary entry from Chapter 3 (Farah), and marking it again here would require a second entry in this chapter's own glossary file, which the cross-chapter term-uniqueness test (`test_glossary_terms_and_flag_names_are_unique_across_all_manifest_chapters`) would then flag as a collision. Only `ghazi` gets `{{ghazi|ghazis}}` markup — it has no prior entry anywhere.
- Commit after each task.
- Environment priming: a fresh worktree needs one `godot --headless --path . --editor --quit` run before GUT will find its class names. Running it a second time in the same worktree is a known, already-investigated, harmless SIGSEGV quirk unrelated to game code — don't re-run it if it's already been primed once.

---

### Task 1: Author Chapter 7's content and test it standalone

**Files:**
- Create: `content/chapters/chapter_07_sarakhs/sarakhs.json`
- Create: `content/glossary/sarakhs_terms.json`
- Test: `tests/unit/test_sarakhs_dialogue_content.gd`

**Interfaces:**
- Consumes: `DialogueEngine.load_tree(nodes, start_id)`, `DialogueEngine.choose(index)`, `DialogueEngine.current_node()`, `DialogueEngine.available_choices()`, `DialogueEngine.is_chapter_end()` (all pre-existing, unchanged). No `requires_flag`/`requires_reputation` used anywhere in this chapter's content — the sideroad is a plain two-choice fork where both choices reach the same downstream node, not a gated choice.
- Produces: the file `content/chapters/chapter_07_sarakhs/sarakhs.json`, first node id `n01_sarakhs_arrival`, single terminal node `n11_departure_sarakhs` — Task 2 wires this path into the manifest and does not touch this file's content again.

- [ ] **Step 1: Create the glossary file**

`content/glossary/sarakhs_terms.json`:
```json
{
	"ghazi": {
		"headword": "Ghazi",
		"definition": "A volunteer frontier fighter, fighting for a share of whatever the campaign produces rather than a soldier's regular wage - unlike the ghulam, bound and paid by the state, a ghazi answers to no roster and owes his loyalty only as long as the campaign does."
	}
}
```

- [ ] **Step 2: Create the dialogue content file**

`content/chapters/chapter_07_sarakhs/sarakhs.json`:
```json
[
	{
		"id": "n01_sarakhs_arrival",
		"text": "Sarakhs called itself the Gate of Khorasan, and for once the name was not a merchant's flourish - the fortress sat squarely across the road on the Tejen's near bank, walls thick enough that Farrukh understood, without being told, that everything east of this river had already decided this was the line worth holding. Herat had worried about a muster. Pushang had worried about what the muster cost. Sarakhs simply was the muster, in stone.",
		"choices": [
			{"text": "Continue.", "next_id": "n02_the_choice_at_the_yard", "effects": {}}
		]
	},
	{
		"id": "n02_the_choice_at_the_yard",
		"text": "His caravan guide had business inside the walls that would take the better part of an hour, which left Farrukh time enough to see something of the place before finding whoever actually ran it.",
		"choices": [
			{"text": "Linger in the garrison's outer yard.", "next_id": "n03a_the_ghulams_road", "effects": {}},
			{"text": "Go straight to whoever commands this gate.", "next_id": "n05_bahram_the_gatekeeper", "effects": {}}
		]
	},
	{
		"id": "n03a_the_ghulams_road",
		"text": "The yard was busy with the specific, unhurried competence of men who had done this exact drilling for years rather than weeks - {{ghulam|ghulams}}, mostly, Turkic-born and bought young, trained from boyhood into the one trade the empire actually trusted with its own survival. An old one, resting between drills, told Farrukh without much prompting that men like him weren't soldiers by accident of birth the way a levied farmer was - they were raised to it, owned by it in a way that cut both directions, and the lucky ones climbed further than any free man's son from a shop like Farrukh's ever would. He named, with the particular relish of a story told many times before, one of Sebuk-Tegin's own ghulams who'd ended up governing an entire province on the empire's far side. Farrukh did not know whether to envy that or not.",
		"choices": [
			{"text": "Continue.", "next_id": "n04a_the_treasurys_long_reach", "effects": {}}
		]
	},
	{
		"id": "n04a_the_treasurys_long_reach",
		"text": "Not every man swinging a blade at this wall was paid the same way, or paid at all. The {{ghazi|ghazis}} camped at the yard's ragged edge fought for their own reasons and their own share of whatever the fighting produced, volunteers rather than soldiers, and nobody at the gate seemed to expect loyalty from them beyond the length of a single campaign. The ghulams, by contrast, drew real coin - minted in Ghazni, carried the whole distance out here by the same kind of caravans Farrukh himself was part of, which meant, the old soldier said without much comfort in it, that a bad season on the road back home was every bit as dangerous to this garrison as a bad season at the wall. Farrukh understood, not for the first time, that an empire this size ran on exactly the kind of fragile arithmetic his own father's ledger had.",
		"choices": [
			{"text": "Continue.", "next_id": "n05_bahram_the_gatekeeper", "effects": {}}
		]
	},
	{
		"id": "n05_bahram_the_gatekeeper",
		"text": "The man actually holding this gate, Farrukh was told, was a ghulam himself, one rank below whoever technically commanded the province - a soldier named Bahram, older than most of the men drilling in his yard, who looked over Farrukh's manifest with the flat, practiced patience of someone who had processed a great many travelers and expected to process a great many more before this posting, whatever it turned out to be, was finished.",
		"choices": [
			{"text": "Continue.", "next_id": "n06_what_nasa_taught_him", "effects": {}}
		]
	},
	{
		"id": "n06_what_nasa_taught_him",
		"text": "Bahram didn't need Farrukh to explain why he was nervous about the road behind him. \"Nasa,\" he said, when Farrukh mentioned the riders' rumors that had reached Ghazni before his father's death. \"Begtoghdi had men enough, on paper. It didn't matter.\" He said it the way a man states an old wound rather than an open one - not asking for sympathy, just establishing, plainly, that he'd already done the arithmetic Farrukh was still working through.",
		"choices": [
			{"text": "Continue.", "next_id": "n07_a_quiet_request", "effects": {}}
		]
	},
	{
		"id": "n07_a_quiet_request",
		"text": "He handed the manifest back, business concluded, and then didn't quite let Farrukh go - the particular hesitation of a man deciding whether a stranger passing through was worth a favor he had no official standing to ask for.",
		"choices": [
			{"text": "Continue.", "next_id": "n08_the_commanders_charge", "effects": {}}
		]
	},
	{
		"id": "n08_the_commanders_charge",
		"text": "\"I have a token,\" Bahram said finally. \"Small. Nothing a customs man would even blink at. It goes to my wife's people, west of here, if - \" he didn't finish the sentence, and didn't need to. \"Nobody requires this of you. I'm asking a stranger because a stranger is exactly what I need - someone this gate won't remember once you're through it.\"",
		"choices": [
			{"text": "Take it. Ask for nothing in return.", "next_id": "n09a_accepted_freely", "effects": {"flags": ["carries_the_commanders_token"], "reputation": {"ghaznavid_officials": 1}}},
			{"text": "Take it, but only for a fair price.", "next_id": "n09b_accepted_for_coin", "effects": {"flags": ["carries_the_commanders_token", "accepted_the_charge_for_payment"], "coin_gained_dirham_equivalent": 12.0}},
			{"text": "Decline. You already carry enough.", "next_id": "n09c_declined_plainly", "effects": {"flags": ["declined_the_commanders_charge"]}}
		]
	},
	{
		"id": "n09a_accepted_freely",
		"text": "Farrukh took the token without naming a price, the same reflex, he understood even as it happened, that had put him at his father's grave promising a debt nobody made him promise. Bahram's relief was almost imperceptible - a man filing away, the way Ardashir once had, that this particular stranger didn't need managing, or paying, to be trusted.",
		"choices": [
			{"text": "Continue.", "next_id": "n10_after_the_gate", "effects": {}}
		]
	},
	{
		"id": "n09b_accepted_for_coin",
		"text": "Farrukh named a price, and Bahram paid it without complaint or particular warmth - a transaction rather than a trust, which suited them both well enough. The token weighed exactly the same in his pack either way. What it meant to carry it, Farrukh suspected, did not.",
		"choices": [
			{"text": "Continue.", "next_id": "n10_after_the_gate", "effects": {}}
		]
	},
	{
		"id": "n09c_declined_plainly",
		"text": "Farrukh said no, as gently as refusing a dying man's request could be said, and told him the truth of it: he already carried one man's unfinished business the entire length of this road, and didn't trust himself to add a second without dropping one or the other somewhere between here and Nishapur. Bahram took the refusal exactly as evenly as he'd taken everything else, and did not ask again.",
		"choices": [
			{"text": "Continue.", "next_id": "n10_after_the_gate", "effects": {}}
		]
	},
	{
		"id": "n10_after_the_gate",
		"text": "Whatever he carried or didn't, out of Sarakhs, Farrukh understood the Gate of Khorasan for what it actually was: not a wall so much as a promise, made by an empire to itself, that this was the line past which the frontier's failure would finally have to stop being somebody else's problem. He did not know, walking away from it, how many more seasons that promise had left in it.",
		"choices": [
			{"text": "Continue.", "next_id": "n11_departure_sarakhs", "effects": {}}
		]
	},
	{
		"id": "n11_departure_sarakhs",
		"text": "He left Sarakhs behind him and Nishapur somewhere ahead, ordinary and unremarkable and the wrong side of that unspoken promise regardless. Whatever Bahram's token was worth, wherever it ended up, the road west went on carrying it - and him - toward whatever waited at the end of a debt he still hadn't finished understanding, let alone repaying.",
		"choices": [],
		"next_chapter_id": null
	}
]
```

- [ ] **Step 3: Write the failing tests**

`tests/unit/test_sarakhs_dialogue_content.gd`:
```gdscript
extends GutTest

func _load_nodes() -> Array:
	var file := FileAccess.open("res://content/chapters/chapter_07_sarakhs/sarakhs.json", FileAccess.READ)
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
	assert_eq(end_node_ids, ["n11_departure_sarakhs"])

func test_the_terminal_node_has_a_null_next_chapter_id():
	var nodes := _load_nodes()
	for node in nodes:
		if node["id"] == "n11_departure_sarakhs":
			assert_true(node.has("next_chapter_id"))
			assert_eq(node["next_chapter_id"], null)

func test_every_glossed_term_id_exists_in_the_sarakhs_glossary():
	var nodes := _load_nodes()
	var glossary_file := FileAccess.open("res://content/glossary/sarakhs_terms.json", FileAccess.READ)
	var glossary_data = JSON.parse_string(glossary_file.get_as_text())
	glossary_file.close()
	for node in nodes:
		for term_id in GlossedTextParser.extract_term_ids(node["text"]):
			assert_true(glossary_data.has(term_id), "node %s glosses unknown term '%s'" % [node["id"], term_id])

func test_choosing_the_yard_visits_the_sideroad_then_converges():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_sarakhs_arrival")
	engine.choose(0) # n01 -> n02
	engine.choose(0) # "Linger in the garrison's outer yard." -> n03a
	assert_eq(engine.current_node()["id"], "n03a_the_ghulams_road")
	engine.choose(0)
	assert_eq(engine.current_node()["id"], "n04a_the_treasurys_long_reach")
	engine.choose(0)
	assert_eq(engine.current_node()["id"], "n05_bahram_the_gatekeeper", "the sideroad must converge on the same node the direct choice reaches")

func test_choosing_straight_to_the_commander_skips_the_sideroad():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_sarakhs_arrival")
	engine.choose(0) # n01 -> n02
	engine.choose(1) # "Go straight to whoever commands this gate." -> n05 directly
	assert_eq(engine.current_node()["id"], "n05_bahram_the_gatekeeper")

func test_the_accept_freely_choice_reaches_its_outcome_and_effects():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_sarakhs_arrival")
	engine.choose(0) # n01 -> n02
	engine.choose(1) # n02 -> n05, skip sideroad ("Go straight to whoever commands this gate.")
	for i in range(3):
		engine.choose(0) # n05 -> n06 -> n07 -> n08
	assert_eq(engine.current_node()["id"], "n08_the_commanders_charge")
	var effects := engine.choose(0) # "Take it. Ask for nothing in return."
	assert_eq(effects["flags"], ["carries_the_commanders_token"])
	assert_eq(int(effects["reputation"]["ghaznavid_officials"]), 1)
	assert_eq(engine.current_node()["id"], "n09a_accepted_freely")

func test_the_accept_for_coin_choice_reaches_its_outcome_and_effects():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_sarakhs_arrival")
	engine.choose(0) # n01 -> n02
	engine.choose(1) # n02 -> n05, skip sideroad
	for i in range(3):
		engine.choose(0) # n05 -> n06 -> n07 -> n08
	var effects := engine.choose(1) # "Take it, but only for a fair price."
	assert_eq(effects["flags"], ["carries_the_commanders_token", "accepted_the_charge_for_payment"])
	assert_almost_eq(float(effects["coin_gained_dirham_equivalent"]), 12.0, 0.0001)
	assert_eq(engine.current_node()["id"], "n09b_accepted_for_coin")

func test_the_decline_choice_reaches_its_outcome_and_effects():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_sarakhs_arrival")
	engine.choose(0) # n01 -> n02
	engine.choose(1) # n02 -> n05, skip sideroad
	for i in range(3):
		engine.choose(0) # n05 -> n06 -> n07 -> n08
	var effects := engine.choose(2) # "Decline. You already carry enough."
	assert_eq(effects["flags"], ["declined_the_commanders_charge"])
	assert_eq(effects.get("coin_gained_dirham_equivalent", 0.0), 0.0)
	assert_eq(effects.get("reputation", {}), {})
	assert_eq(engine.current_node()["id"], "n09c_declined_plainly")

func test_the_full_tree_is_walkable_from_start_to_end_via_first_choices():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_sarakhs_arrival")
	var visited := 0
	while not engine.is_chapter_end() and visited < 100:
		engine.choose(0)
		visited += 1
	assert_true(engine.is_chapter_end())
	assert_eq(engine.current_node()["id"], "n11_departure_sarakhs")
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gselect=test_sarakhs_dialogue_content -gexit`
Expected: PASS, 10/10.

- [ ] **Step 5: Commit**

```bash
git add content/chapters/chapter_07_sarakhs/sarakhs.json content/glossary/sarakhs_terms.json tests/unit/test_sarakhs_dialogue_content.gd
git commit -m "feat: add Chapter 7 (Sarakhs) dialogue content"
```

---

### Task 2: Wire Chapter 7 into the manifest and Chapter 6's terminal node

**Files:**
- Modify: `content/chapters/manifest.json`
- Modify: `content/chapters/chapter_06_pushang/pushang.json`
- Modify: `tests/unit/test_pushang_dialogue_content.gd`
- Modify: `tests/unit/test_chapter_view.gd`

**Interfaces:**
- Consumes: `chapter_07_sarakhs`'s dialogue/glossary paths from Task 1 (`content/chapters/chapter_07_sarakhs/sarakhs.json`, `content/glossary/sarakhs_terms.json`), first node id `n01_sarakhs_arrival`.
- Produces: nothing further consumed by any other task — this is the last task in the plan.

- [ ] **Step 1: Add the manifest entry**

In `content/chapters/manifest.json`, add this entry (keep every existing entry unchanged):
```json
	"chapter_07_sarakhs": {
		"dialogue_path": "res://content/chapters/chapter_07_sarakhs/sarakhs.json",
		"glossary_path": "res://content/glossary/sarakhs_terms.json",
		"next_chapter_id": null
	}
```

- [ ] **Step 2: Wire Chapter 6's terminal node to Chapter 7**

In `content/chapters/chapter_06_pushang/pushang.json`, change `n12_departure_pushang`'s `next_chapter_id` from `null` to `"chapter_07_sarakhs"`. Change only that field — leave the node's `text` and `choices` untouched.

- [ ] **Step 3: Grep before touching any test — do not trust one remembered test name or count**

Before editing any test file, run:
```bash
grep -rn "n12_departure_pushang" tests/
```
Enumerate every match yourself. At the time this plan was written there were exactly 4 matches across 2 files (`tests/unit/test_pushang_dialogue_content.gd` and `tests/unit/test_chapter_view.gd`) — but re-run the grep rather than trusting that count, in case anything changed between writing this plan and executing it. Read every match and update any that assert the old `null` value; note anything unexpected in your report even if you leave it unchanged.

- [ ] **Step 4: Update the test that asserts the OLD null value on the node itself**

In `tests/unit/test_pushang_dialogue_content.gd`, find:
```gdscript
func test_the_terminal_node_has_a_null_next_chapter_id():
	var nodes := _load_nodes()
	for node in nodes:
		if node["id"] == "n12_departure_pushang":
			assert_true(node.has("next_chapter_id"))
			assert_eq(node["next_chapter_id"], null)
```
Replace it with (renamed to reflect what it now asserts — do not delete it, per this project's established precedent):
```gdscript
func test_the_terminal_node_now_points_at_chapter_7():
	var nodes := _load_nodes()
	for node in nodes:
		if node["id"] == "n12_departure_pushang":
			assert_true(node.has("next_chapter_id"))
			assert_eq(node["next_chapter_id"], "chapter_07_sarakhs")
```

- [ ] **Step 5: Extend the mystery-branch full-playthrough test in test_chapter_view.gd**

Find `test_a_full_playthrough_via_the_mystery_branch_carries_prologue_flags_through_farah`. Because `ChapterView`'s auto-transition fires transparently whenever a chapter ends with a resolved `next_chapter_id`, the existing `while chapter_view.dialogue_engine.available_choices().size() > 0` loop will now continue automatically from Chapter 6 straight into Chapter 7's nodes once Step 2 above is done — no new loop logic needed, only an added save-file clear-block and updated post-loop assertions.

Add `sarakhs_save_path` into the existing five-element clear-array (turning it into six):
```gdscript
	var sarakhs_save_path := "user://borrowed_fortune_chapter_07_sarakhs.json"
	for path in [teginabad_save_path, bost_save_path, farah_save_path, herat_save_path, pushang_save_path, sarakhs_save_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		assert_false(FileAccess.file_exists(path), "the previous save should be cleared before the playthrough starts")
```
This replaces the existing five-element `for path in [...]` clear-loop — declare `sarakhs_save_path` alongside the other `_save_path` variables, then use the six-element array in the one clear-loop.

Then replace the post-loop assertions (currently ending in `chapter_06_pushang` / `n12_departure_pushang`) with:
```gdscript
	assert_eq(chapter_view.chapter_id, "chapter_07_sarakhs")
	assert_eq(chapter_view.dialogue_engine.current_node()["id"], "n11_departure_sarakhs", "always pressing choice 0 takes the sideroad at Sarakhs's own yard fork, then 'Take it. Ask for nothing in return.' at the commander's charge")
	assert_eq(chapter_view.next_chapter_id, null, "Chapter 7 has no Chapter 8 yet")
	assert_true(chapter_view.dialogue_engine.flags.get("vowed_kafala", false), "the Prologue's kafala vow flag must survive all the way into Sarakhs")
	assert_true(chapter_view.dialogue_engine.flags.get("knows_the_second_marks_name", false))
	assert_true(chapter_view.dialogue_engine.flags.get("partial_network_reveal", false))
	assert_false(chapter_view.dialogue_engine.flags.get("full_network_reveal", false))
	assert_true(chapter_view.dialogue_engine.flags.get("carries_the_commanders_token", false), "index 0 at n08_the_commanders_charge is 'Take it. Ask for nothing in return.'")
	assert_false(chapter_view.dialogue_engine.flags.get("declined_the_commanders_charge", false))
	assert_almost_eq(chapter_view.ledger.total_wealth_dirham_equivalent(), -57.0, 0.0001, "unchanged since Chapter 6 - accepting the commander's charge freely has no coin effect")
	assert_true(FileAccess.file_exists(teginabad_save_path), "passing through Teginabad on the way to Sarakhs must still write Teginabad's save file")
	assert_true(FileAccess.file_exists(bost_save_path), "passing through Bost on the way to Sarakhs must still write Bost's save file")
	assert_true(FileAccess.file_exists(farah_save_path), "passing through Farah on the way to Sarakhs must still write Farah's save file")
	assert_true(FileAccess.file_exists(herat_save_path), "passing through Chapter 4A on the way to Sarakhs must still write its own save file")
	assert_true(FileAccess.file_exists(pushang_save_path), "Chapter 6 is no longer the final chapter, but passing through it must still write its own save file")
	assert_true(FileAccess.file_exists(sarakhs_save_path), "reaching Chapter 7's ending must write its own save file")
```

- [ ] **Step 6: Run the full suite to verify everything passes**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`
Expected: PASS, full suite green (206/206 — 196 before this plan + 10 new content tests in Task 1 + 1 renamed test in Task 2, a 1:1 replacement, not a net addition).

- [ ] **Step 7: Commit**

```bash
git add content/chapters/manifest.json content/chapters/chapter_06_pushang/pushang.json tests/unit/test_pushang_dialogue_content.gd tests/unit/test_chapter_view.gd
git commit -m "feat: wire Chapter 7 (Sarakhs) into the manifest via Chapter 6's terminal node"
```

## Verification

- [ ] Full GUT suite green, 206/206, before calling this plan done.
- [ ] Confirm `content/chapters/manifest.json` has exactly one new entry (`chapter_07_sarakhs`) and every other entry unchanged.
- [ ] Re-run `grep -rn "n12_departure_pushang" tests/` one more time after Task 2 lands — every match found should now assert the new `"chapter_07_sarakhs"` value where it asserts `next_chapter_id` at all, with no leftover assertion of the old `null`.
