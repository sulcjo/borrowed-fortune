# Merv Branch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** build and wire in the optional Merv branch (`chapter_07b_merv`), the last unbuilt content from the master spec's original scope — and the first plan in this project that surgically edits already-shipped content's internal structure, not just a terminal node's `next_chapter_id` field.

**Architecture:** Task 1 creates the new Merv chapter content standalone, exactly like every prior chapter's first task. Task 2 is different from every prior wiring task: it inserts a new fork node into Chapter 7 (Sarakhs)'s existing, shipped `sarakhs.json`, deliberately scoped so the existing terminal node `n11_departure_sarakhs` stays byte-for-byte unchanged — both its id and its text — so every existing test that names it or reaches it via the "always press choice 0" pattern keeps passing without modification.

**Tech Stack:** Godot 4.3, GDScript, GUT test framework, JSON content files.

## Global Constraints

- Godot 4.3 floor.
- `JSON.parse_string` deserializes all numbers as `float` — cast to `int` before comparing/assigning anywhere a value is used as `int`. Relevant for Task 1's haggle scene (a reputation effect); not relevant for Task 2's new nodes, which have no effects at all.
- snake_case for node ids, flag names, and JSON keys.
- `DialogueEngine.choose(choice_index)` indexes into `available_choices()` (the filtered, currently-visible list), not the raw JSON array — confirmed by reading `engine/dialogue/DialogueEngine.gd` directly in an earlier chapter's plan. Every `choose(N)` in this plan's tests has already been traced against this behavior.
- Commit after each task.
- Environment priming: a fresh worktree needs one `godot --headless --path . --editor --quit` run before GUT will find its class names. Running it a second time in the same worktree is a known, already-investigated, harmless SIGSEGV quirk — don't re-run it if it's already been primed once.

---

### Task 1: Author the Merv chapter's content and test it standalone

**Files:**
- Create: `content/chapters/chapter_07b_merv/merv.json`
- Create: `content/glossary/merv_terms.json`
- Test: `tests/unit/test_merv_dialogue_content.gd`

**Interfaces:**
- Consumes: `DialogueEngine.load_tree(nodes, start_id)`, `DialogueEngine.choose(index)`, `DialogueEngine.current_node()`, `DialogueEngine.is_chapter_end()` (all pre-existing, unchanged). No `requires_flag`/`requires_reputation` used anywhere in this chapter — it has no fork of its own, only a single linear path with one 3-way choice.
- Produces: the file `content/chapters/chapter_07b_merv/merv.json`, first node id `n01_merv_arrival`, single terminal node `n07_departure_merv` (`next_chapter_id: "chapter_08_nishapur"` — this converges back into the main route, unlike every prior chapter's most-recently-built terminal, which pointed to `null`). Task 2 wires `chapter_07b_merv` into the manifest and does not touch this file's content again.

- [ ] **Step 1: Create the glossary file**

`content/glossary/merv_terms.json`:
```json
{}
```

No new terminology — this chapter's real grounding (suftaja, hawala, sarraf) is already-established vocabulary from earlier chapters, reused as plain prose. Same precedent as Chapter 5 (plunder ending)'s empty glossary file.

- [ ] **Step 2: Create the dialogue content file**

`content/chapters/chapter_07b_merv/merv.json`:
```json
[
	{
		"id": "n01_merv_arrival",
		"text": "Merv announced itself the way a name announces a reputation older than the man carrying it - a market town grown into a provincial capital, threaded by canals that had been running the same patient water since long before any Ghaznavid, or whoever came before them, had bothered to tax it. Farrukh's guide called it the best oasis on this whole stretch of road, and for once didn't seem to be exaggerating for the sake of a story.",
		"choices": [
			{"text": "Continue.", "next_id": "n02_the_citadel_that_was", "effects": {}}
		]
	},
	{
		"id": "n02_the_citadel_that_was",
		"text": "A third of the old city, his guide told him, had emptied out entirely in his own father's lifetime - not abandoned exactly, just outgrown, its business and its people drifting toward the newer walls a short walk east, the way a river finds a straighter channel and simply stops bothering with the old one. Farrukh understood the shape of it without needing the explanation: a city didn't have to be dying to have parts of itself the present had quietly moved past.",
		"choices": [
			{"text": "Continue.", "next_id": "n03_the_bazaar_at_the_crossing", "effects": {}}
		]
	},
	{
		"id": "n03_the_bazaar_at_the_crossing",
		"text": "The bazaar here ran to a scale Teginabad and Bost's markets hadn't prepared him for - a domed crossing where four main streets converged, money-changers and goldsmiths and weavers and coppersmiths each keeping to their own stretch of it, the whole arrangement running with the unhurried, settled competence of a trade pattern old enough that nobody currently working it had ever had to invent it.",
		"choices": [
			{"text": "Continue.", "next_id": "n04_a_network_reaching_far", "effects": {}}
		]
	},
	{
		"id": "n04_a_network_reaching_far",
		"text": "A money-changer working the bazaar's money-changing row mentioned, when Farrukh asked after sending word ahead of himself, that a correspondent three doors down had once relayed word all the way to the Mongolian steppe inside a single season - a story told with the specific pride of a city that measured its own importance by how far its letters could travel rather than by anything closer to home.",
		"choices": [
			{"text": "Continue.", "next_id": "n05_the_sarrafs_price", "effects": {}}
		]
	},
	{
		"id": "n05_the_sarrafs_price",
		"text": "The correspondent in question named a fee for carrying word ahead to Nishapur - nothing urgent in the message itself, only that a traveler was coming, the kind of ordinary courtesy that kept a household from being caught flat-footed by an arrival at its door.",
		"choices": [
			{"text": "Pay what she asks.", "next_id": "n06a_word_sent", "effects": {"coin_spent_dirham_equivalent": 8.0, "reputation": {"trading_families": 1}}},
			{"text": "Try to talk her down.", "next_id": "n06b_word_sent_cheaper", "effects": {"coin_spent_dirham_equivalent": 5.0}},
			{"text": "Decide the word can wait. Keep the coin.", "next_id": "n06c_word_unsent", "effects": {}}
		]
	},
	{
		"id": "n06a_word_sent",
		"text": "She took the fee without argument and wrote quickly, in a hand Farrukh couldn't read upside down, whatever a professional correspondent actually wrote in these situations. It was, he suspected, the smallest and least complicated transaction he'd make on this entire road.",
		"choices": [
			{"text": "Continue.", "next_id": "n07_departure_merv", "effects": {}}
		]
	},
	{
		"id": "n06b_word_sent_cheaper",
		"text": "She gave a little ground on the price, the way every sarraf on this road eventually did when pressed without heat, and wrote the same message regardless of what it had cost to commission it.",
		"choices": [
			{"text": "Continue.", "next_id": "n07_departure_merv", "effects": {}}
		]
	},
	{
		"id": "n06c_word_unsent",
		"text": "Farrukh decided a household that had gone this long without word from him could manage a few more days of it, and kept walking instead of paying anyone to say otherwise.",
		"choices": [
			{"text": "Continue.", "next_id": "n07_departure_merv", "effects": {}}
		]
	},
	{
		"id": "n07_departure_merv",
		"text": "He left Merv the way he'd left every stop on this road, carrying a little more of it than he'd arrived with and a little less coin than he'd have liked - west now, properly, toward Nishapur and whatever waited for him there, the longer road behind him exactly as unremarkable, up close, as any of the shorter ones had been.",
		"choices": [],
		"next_chapter_id": "chapter_08_nishapur"
	}
]
```

- [ ] **Step 3: Write the failing tests**

`tests/unit/test_merv_dialogue_content.gd`:
```gdscript
extends GutTest

func _load_nodes() -> Array:
	var file := FileAccess.open("res://content/chapters/chapter_07b_merv/merv.json", FileAccess.READ)
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
	assert_eq(end_node_ids, ["n07_departure_merv"])

func test_the_terminal_node_points_at_chapter_8():
	var nodes := _load_nodes()
	for node in nodes:
		if node["id"] == "n07_departure_merv":
			assert_true(node.has("next_chapter_id"))
			assert_eq(node["next_chapter_id"], "chapter_08_nishapur")

func test_every_glossed_term_id_exists_in_the_merv_glossary():
	var nodes := _load_nodes()
	var glossary_file := FileAccess.open("res://content/glossary/merv_terms.json", FileAccess.READ)
	var glossary_data = JSON.parse_string(glossary_file.get_as_text())
	glossary_file.close()
	for node in nodes:
		for term_id in GlossedTextParser.extract_term_ids(node["text"]):
			assert_true(glossary_data.has(term_id), "node %s glosses unknown term '%s'" % [node["id"], term_id])

func test_the_pay_in_full_choice_reaches_its_outcome_and_effects():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_merv_arrival")
	for i in range(4):
		engine.choose(0) # n01 -> n02 -> n03 -> n04 -> n05
	assert_eq(engine.current_node()["id"], "n05_the_sarrafs_price")
	var effects := engine.choose(0) # "Pay what she asks."
	assert_almost_eq(float(effects["coin_spent_dirham_equivalent"]), 8.0, 0.0001)
	assert_eq(int(effects["reputation"]["trading_families"]), 1)
	assert_eq(engine.current_node()["id"], "n06a_word_sent")

func test_the_haggle_choice_reaches_its_outcome_and_effects():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_merv_arrival")
	for i in range(4):
		engine.choose(0)
	var effects := engine.choose(1) # "Try to talk her down."
	assert_almost_eq(float(effects["coin_spent_dirham_equivalent"]), 5.0, 0.0001)
	assert_eq(effects.get("reputation", {}), {})
	assert_eq(engine.current_node()["id"], "n06b_word_sent_cheaper")

func test_the_decline_choice_reaches_its_outcome_and_effects():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_merv_arrival")
	for i in range(4):
		engine.choose(0)
	var effects := engine.choose(2) # "Decide the word can wait. Keep the coin."
	assert_eq(effects, {})
	assert_eq(engine.current_node()["id"], "n06c_word_unsent")

func test_the_full_tree_is_walkable_from_start_to_end_via_first_choices():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_merv_arrival")
	var visited := 0
	while not engine.is_chapter_end() and visited < 100:
		engine.choose(0)
		visited += 1
	assert_true(engine.is_chapter_end())
	assert_eq(engine.current_node()["id"], "n07_departure_merv", "index 0 at n05_the_sarrafs_price is 'Pay what she asks.' -> n06a_word_sent, which itself has one more 'Continue.' choice to the chapter's true final node n07")
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gselect=test_merv_dialogue_content -gexit`
Expected: PASS, 8/8.

- [ ] **Step 5: Commit**

```bash
git add content/chapters/chapter_07b_merv/merv.json content/glossary/merv_terms.json tests/unit/test_merv_dialogue_content.gd
git commit -m "feat: add Merv branch dialogue content"
```

---

### Task 2: Wire the Merv branch into Chapter 7's ending and the manifest

**Files:**
- Modify: `content/chapters/chapter_07_sarakhs/sarakhs.json`
- Modify: `content/chapters/manifest.json`
- Modify: `tests/unit/test_sarakhs_dialogue_content.gd`

**Interfaces:**
- Consumes: `chapter_07b_merv`'s dialogue/glossary paths from Task 1, first node id `n01_merv_arrival`.
- Produces: nothing further consumed by any other task — this is the last task in the plan.

- [ ] **Step 1: Modify sarakhs.json — exact before/after**

The file currently ends (verified by reading it directly before writing this plan) with these two nodes, in this exact shape:

```json
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
		"next_chapter_id": "chapter_08_nishapur"
	}
]
```

Change **only** `n10_after_the_gate`'s `next_id` value, from `"n11_departure_sarakhs"` to `"n10b_the_road_forks"`. Leave every other field on `n10_after_the_gate` untouched, and leave `n11_departure_sarakhs` **completely byte-for-byte unchanged** — same id, same text, same `next_chapter_id`. Then insert two new nodes between them (order in the file doesn't affect behavior, but insert them in this order for readability):

```json
	{
		"id": "n10b_the_road_forks",
		"text": "Sarakhs behind him now in more than one sense, Farrukh found the road forked in a way his guide hadn't mentioned until they were standing at it - the straight route west toward Nishapur, or a longer swing through Merv first, a city his guide swore was worth the extra days to anyone who'd never seen it.",
		"choices": [
			{"text": "Take the road straight to Nishapur.", "next_id": "n11_departure_sarakhs", "effects": {}},
			{"text": "Take the longer road through Merv first.", "next_id": "n11b_departure_via_merv", "effects": {}}
		]
	},
```
(insert this immediately after `n10_after_the_gate`, before `n11_departure_sarakhs`)

```json
	{
		"id": "n11b_departure_via_merv",
		"text": "He left Sarakhs by the longer road, telling himself an extra handful of days was a small enough price for seeing a city this size before whatever came next made seeing it harder to reach. Whatever Bahram's token was worth, wherever it ended up, it would simply have to wait a little longer than the straight road would have made him wait.",
		"choices": [],
		"next_chapter_id": "chapter_07b_merv"
	}
```
(insert this immediately after `n11_departure_sarakhs`, as the file's new final node)

The resulting file has 13 nodes total (11 original + 2 new), with **two** terminal nodes now: `n11_departure_sarakhs` (unchanged) and `n11b_departure_via_merv` (new).

- [ ] **Step 2: Add the manifest entry**

In `content/chapters/manifest.json`, add this entry (keep every existing entry unchanged):
```json
	"chapter_07b_merv": {
		"dialogue_path": "res://content/chapters/chapter_07b_merv/merv.json",
		"glossary_path": "res://content/glossary/merv_terms.json",
		"next_chapter_id": null
	}
```

- [ ] **Step 3: Update the now-incorrect terminal-count test**

In `tests/unit/test_sarakhs_dialogue_content.gd`, find (currently at lines 18-24):
```gdscript
func test_exactly_one_node_has_no_choices_and_it_is_the_last_node():
	var nodes := _load_nodes()
	var end_node_ids: Array = []
	for node in nodes:
		if node.get("choices", []).is_empty():
			end_node_ids.append(node["id"])
	assert_eq(end_node_ids, ["n11_departure_sarakhs"])
```
Replace it with:
```gdscript
func test_exactly_two_nodes_have_no_choices_and_they_are_the_two_terminal_nodes():
	var nodes := _load_nodes()
	var end_node_ids: Array = []
	for node in nodes:
		if node.get("choices", []).is_empty():
			end_node_ids.append(node["id"])
	end_node_ids.sort()
	assert_eq(end_node_ids, ["n11_departure_sarakhs", "n11b_departure_via_merv"])
```

- [ ] **Step 4: Add tests for the new fork**

Append to `tests/unit/test_sarakhs_dialogue_content.gd`:
```gdscript
func test_the_merv_terminal_node_points_at_the_merv_chapter():
	var nodes := _load_nodes()
	for node in nodes:
		if node["id"] == "n11b_departure_via_merv":
			assert_true(node.has("next_chapter_id"))
			assert_eq(node["next_chapter_id"], "chapter_07b_merv")

func test_the_road_fork_straight_to_nishapur_reaches_the_unchanged_terminal():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_sarakhs_arrival")
	engine.choose(0) # n01 -> n02
	engine.choose(1) # n02 -> n05, skip sideroad
	for i in range(6):
		engine.choose(0) # n05 -> n06 -> n07 -> n08 -> n09a (accept freely) -> n10_after_the_gate -> n10b_the_road_forks
	assert_eq(engine.current_node()["id"], "n10b_the_road_forks")
	engine.choose(0) # "Take the road straight to Nishapur."
	assert_eq(engine.current_node()["id"], "n11_departure_sarakhs")
	assert_true(engine.is_chapter_end())

func test_the_road_fork_via_merv_reaches_its_own_terminal():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_sarakhs_arrival")
	engine.choose(0) # n01 -> n02
	engine.choose(1) # n02 -> n05, skip sideroad
	for i in range(6):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n10b_the_road_forks")
	engine.choose(1) # "Take the longer road through Merv first."
	assert_eq(engine.current_node()["id"], "n11b_departure_via_merv")
	assert_true(engine.is_chapter_end())
```

- [ ] **Step 5: Do NOT edit test_the_full_tree_is_walkable_from_start_to_end_via_first_choices unless it actually fails**

This existing test (currently lines 98-106) asserts that "always press choice 0" reaches `n11_departure_sarakhs`. Because `n10b_the_road_forks`'s first choice ("Take the road straight to Nishapur.") is index 0, this exact path is preserved — the test should pass unmodified. Run it as part of Step 6's full-suite run; if it unexpectedly fails, that means Step 1 was not applied correctly (most likely: "Take the road straight to Nishapur." ended up at index 1 instead of index 0, or `n11_departure_sarakhs`'s own content was accidentally changed) — fix Step 1, don't edit this test to match a wrong implementation.

- [ ] **Step 6: Run the full suite to verify everything passes**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`
Expected: PASS, full suite green (226/226 — 215 before this plan + 8 new content tests in Task 1 + 3 brand-new tests in Task 2 (`test_the_merv_terminal_node_points_at_the_merv_chapter`, `test_the_road_fork_straight_to_nishapur_reaches_the_unchanged_terminal`, `test_the_road_fork_via_merv_reaches_its_own_terminal`) + 1 renamed replacement (net zero) = 215 + 8 + 3 = 226).

Also confirm as part of this step: `tests/unit/test_chapter_view.gd` needed **no edits at all**. Its Chapter 8 full-playthrough assertions depend only on Sarakhs's "always press 0" path reaching `n11_departure_sarakhs` with its existing, unchanged `next_chapter_id` — which this task preserves exactly. If that file's tests are failing, something in Step 1 broke `n11_departure_sarakhs` itself; do not patch `test_chapter_view.gd` to match — fix the content instead.

- [ ] **Step 7: Commit**

```bash
git add content/chapters/chapter_07_sarakhs/sarakhs.json content/chapters/manifest.json tests/unit/test_sarakhs_dialogue_content.gd
git commit -m "feat: add the Merv detour fork to Chapter 7's ending"
```

## Verification

- [ ] Full GUT suite green, 226/226, before calling this plan done.
- [ ] Confirm `n11_departure_sarakhs` in `sarakhs.json` is byte-for-byte identical to what it was before this plan (same id, same text, same `next_chapter_id`) — this is the plan's central risk-mitigation and worth a direct diff check, not just passing tests.
- [ ] Confirm `content/chapters/manifest.json` has exactly one new entry (`chapter_07b_merv`) and every other entry unchanged.
- [ ] Confirm `tests/unit/test_chapter_view.gd` was not modified by this plan at all.
