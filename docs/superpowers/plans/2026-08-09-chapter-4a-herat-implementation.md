# Chapter 4A: Herat Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship Chapter 4A (Herat, the clean-lead continuation of Farah's mystery branch) — 26 nodes, one optional sideroad, two multi-round haggle scenes, and the game's first `requires_reputation`-gated story reveal — wired into the manifest so Prologue → Teginabad → Bost → Farah(mystery) → Herat auto-chains.

**Architecture:** One small engine prerequisite (shape-validate `requires_reputation` in `DialogueEngine.validate_tree()`, per the trading engine's final review), then pure content authoring using primitives that already ship (`v0.5-trading-engine`): the haggle template, `requires_reputation`, `coin_spent_dirham_equivalent`. No new engine capability beyond the validation task.

**Design doc:** `docs/superpowers/specs/2026-08-09-chapter-4a-herat-design.md` — read for narrative rationale. This plan's briefs are self-sufficient.

## Global Constraints

- Godot 4.3 floor. Priming command for a fresh checkout: `godot --headless --path . --editor --quit`.
- Headless test run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`.
- Engine-layer classes (`engine/**`) are `RefCounted`, never `Node`.
- Naming idiom: GDScript's own idiom — `snake_case` functions/variables, `PascalCase` types.
- **Hard rule: `JSON.parse_string` always deserializes numbers as `float`, never `int`.** Cast with `int(...)` before comparing against an int literal or assigning into an `int`-typed variable.
- **Choice ordering convention:** in every node with more than one choice where at least one choice is gated (`requires_flag` or `requires_reputation`), the always-available choice must be listed *before* the gated one, so `available_choices()[0]` is deterministic. (This chapter's three-way haggle-opening choices — accept/argue/walk-away — are all ungated, so this rule doesn't constrain their relative order; only `n18_the_moment_of_truth`'s two choices are order-constrained.)
- Single-choice "continue" nodes use the exact choice text `"Continue."`.
- This chapter reuses `trading_families` as the reputation faction throughout — no new faction id.
- Commit after each task.

---

### Task 1: Engine prerequisite — validate `requires_reputation`'s shape

**Files:**
- Modify: `engine/dialogue/DialogueEngine.gd` (inside `validate_tree()`, the choices loop at lines 31-34)
- Test: `tests/unit/test_dialogue_engine.gd` (append)

**Interfaces:**
- Produces: `validate_tree()` now appends an error for any choice whose `requires_reputation` is present but malformed — not a `Dictionary`, missing `faction_id` (must be a `String`), or missing `min_score` (must be numeric). This makes a malformed gate an `assert()` failure at `load_tree()` time (loud, at chapter-load), not a silent runtime hole.
- **Do NOT implement this as `.get(...)` with defaults.** A prior review worked the arithmetic: `.get("faction_id", "")` / `.get("min_score", 0)` makes a malformed gate evaluate `reputation.get("", 0) < 0` → `false` → the gate silently *passes*, exposing the choice to every player. Validate the shape; do not paper over it with defaults in the runtime check.
- Consumes: nothing new. Independent of Tasks 2-4.

- [ ] **Step 1: Write the failing tests**

Append to `tests/unit/test_dialogue_engine.gd`:

```gdscript
func test_validate_tree_flags_a_requires_reputation_missing_faction_id():
	var nodes := [
		{"id": "a", "text": "one", "choices": [{"text": "go", "next_id": "b", "requires_reputation": {"min_score": 2}}]},
		{"id": "b", "text": "end", "choices": []},
	]
	var errors := DialogueEngine.new().validate_tree(nodes)
	assert_true(errors.size() > 0)
	assert_string_contains(errors[0], "requires_reputation")

func test_validate_tree_flags_a_requires_reputation_missing_min_score():
	var nodes := [
		{"id": "a", "text": "one", "choices": [{"text": "go", "next_id": "b", "requires_reputation": {"faction_id": "trading_families"}}]},
		{"id": "b", "text": "end", "choices": []},
	]
	var errors := DialogueEngine.new().validate_tree(nodes)
	assert_true(errors.size() > 0)
	assert_string_contains(errors[0], "requires_reputation")

func test_validate_tree_flags_a_requires_reputation_that_is_not_a_dictionary():
	var nodes := [
		{"id": "a", "text": "one", "choices": [{"text": "go", "next_id": "b", "requires_reputation": "trading_families"}]},
		{"id": "b", "text": "end", "choices": []},
	]
	var errors := DialogueEngine.new().validate_tree(nodes)
	assert_true(errors.size() > 0)
	assert_string_contains(errors[0], "requires_reputation")

func test_validate_tree_accepts_a_well_formed_requires_reputation():
	var nodes := [
		{"id": "a", "text": "one", "choices": [{"text": "go", "next_id": "b", "requires_reputation": {"faction_id": "trading_families", "min_score": 2}}]},
		{"id": "b", "text": "end", "choices": []},
	]
	var errors := DialogueEngine.new().validate_tree(nodes)
	assert_eq(errors, [])
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_dialogue_engine.gd -gexit`
Expected: FAIL on the first three (no validation exists yet); the fourth already passes (nothing currently rejects a well-formed one).

- [ ] **Step 3: Implement the validation**

In `engine/dialogue/DialogueEngine.gd`, inside `validate_tree()`'s choices loop, change:

```gdscript
		for choice in node.get("choices", []):
			var next_id = choice.get("next_id")
			if next_id != null and not known_ids.has(next_id):
				errors.append("node '%s' has a choice with dangling next_id '%s'" % [node_id, next_id])
```

to:

```gdscript
		for choice in node.get("choices", []):
			var next_id = choice.get("next_id")
			if next_id != null and not known_ids.has(next_id):
				errors.append("node '%s' has a choice with dangling next_id '%s'" % [node_id, next_id])
			var requires_reputation = choice.get("requires_reputation", null)
			if requires_reputation != null and not (requires_reputation is Dictionary and requires_reputation.get("faction_id") is String and (requires_reputation.get("min_score") is float or requires_reputation.get("min_score") is int)):
				errors.append("node '%s' has a choice with a malformed requires_reputation (needs a String faction_id and a numeric min_score)" % node_id)
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_dialogue_engine.gd -gexit`
Expected: PASS, all tests including pre-existing ones.

- [ ] **Step 5: Run the full suite**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`
Expected: PASS — no existing chapter's content uses `requires_reputation` yet except none, so nothing else should be affected.

- [ ] **Step 6: Commit**

```bash
git add engine/dialogue/DialogueEngine.gd tests/unit/test_dialogue_engine.gd
git commit -m "feat: validate requires_reputation's shape in DialogueEngine.validate_tree()"
```

---

### Task 2: Herat glossary content

**Files:**
- Create: `content/glossary/herat_terms.json`
- Test: `tests/unit/test_herat_glossary_content.gd`

**Interfaces:**
- Produces: `content/glossary/herat_terms.json` with exactly 2 term ids: `hashar`, `dai`. Consumed by Task 3's dialogue content.

- [ ] **Step 1: Write the failing test**

Create `tests/unit/test_herat_glossary_content.gd`:

```gdscript
extends GutTest

func test_herat_glossary_has_the_two_expected_terms_with_headword_and_definition():
	var file := FileAccess.open("res://content/glossary/herat_terms.json", FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()

	var expected_ids := ["hashar", "dai"]
	assert_eq(data.keys().size(), expected_ids.size())
	for term_id in expected_ids:
		assert_true(data.has(term_id), "missing glossary term '%s'" % term_id)
		assert_true(data[term_id].has("headword"))
		assert_true(data[term_id].has("definition"))
		assert_false(data[term_id]["headword"].is_empty())
		assert_false(data[term_id]["definition"].is_empty())
```

- [ ] **Step 2: Run test to verify it fails**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_herat_glossary_content.gd -gexit`
Expected: FAIL — file does not exist.

- [ ] **Step 3: Create the glossary file**

Create `content/glossary/herat_terms.json`:

```json
{
	"hashar": {
		"headword": "Hashar",
		"definition": "An emergency levy of ordinary townsmen and farmers, called up for military service in a crisis - distinct from a standing army's professional soldiers (such as the ghulam), and a real sign of a state under strain."
	},
	"dai": {
		"headword": "Da'i",
		"definition": "Literally \"one who summons\" - a missionary or propagandist for the Ismaili Shia cause, historically directed and funded from Fatimid Cairo, operating underground in Sunni-ruled territory where the activity was treated as a capital offense."
	}
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_herat_glossary_content.gd -gexit`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add content/glossary/herat_terms.json tests/unit/test_herat_glossary_content.gd
git commit -m "feat: add Herat glossary terms"
```

---

### Task 3: Herat dialogue content — 26 nodes, one optional sideroad, two haggle scenes, one reputation-gated reveal

**Files:**
- Create: `content/chapters/chapter_04a_herat/herat.json`
- Test: `tests/unit/test_herat_dialogue_content.gd`

**Interfaces:**
- Consumes: Task 1's `requires_reputation` validation (this content is the first real user of it — if a typo in your JSON breaks the shape, `load_tree()` will `assert()` loudly, which is correct and expected). Gloss tokens `hashar` and `dai` must match Task 2's `herat_terms.json` exactly.
- Produces: `content/chapters/chapter_04a_herat/herat.json`, 26 nodes, start node `n01_herat_arrival`, exactly one terminal node (`choices: []`): `n21_departure_herat`, with `"next_chapter_id": null` (Task 4 does not change this — Chapter 5 doesn't exist yet).

This task tests the tree via `DialogueEngine` directly, in isolation — not through `ChapterView` or the manifest (Task 4 does that integration).

- [ ] **Step 1: Write the failing tests**

Create `tests/unit/test_herat_dialogue_content.gd`:

```gdscript
extends GutTest

func _load_nodes() -> Array:
	var file := FileAccess.open("res://content/chapters/chapter_04a_herat/herat.json", FileAccess.READ)
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
	assert_eq(end_node_ids, ["n21_departure_herat"])

func test_the_terminal_node_has_a_null_next_chapter_id():
	var nodes := _load_nodes()
	for node in nodes:
		if node["id"] == "n21_departure_herat":
			assert_true(node.has("next_chapter_id"))
			assert_eq(node["next_chapter_id"], null)

func test_every_glossed_term_id_exists_in_the_herat_glossary():
	var nodes := _load_nodes()
	var glossary_file := FileAccess.open("res://content/glossary/herat_terms.json", FileAccess.READ)
	var glossary_data = JSON.parse_string(glossary_file.get_as_text())
	glossary_file.close()
	for node in nodes:
		for term_id in GlossedTextParser.extract_term_ids(node["text"]):
			assert_true(glossary_data.has(term_id), "node %s glosses unknown term '%s'" % [node["id"], term_id])

func test_choosing_the_bazaar_directly_skips_the_sideroad():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival")
	engine.choose(0) # n01 -> n02
	engine.choose(1) # "Head straight for the bazaar." -> n05 directly
	assert_eq(engine.current_node()["id"], "n05_the_bazaar_of_herat")

func test_choosing_the_garrison_gate_visits_the_old_soldier_then_converges():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival")
	engine.choose(0) # n01 -> n02
	engine.choose(0) # "Let the garrison gate draw you first." -> n03a
	assert_eq(engine.current_node()["id"], "n03a_the_old_soldier")
	engine.choose(0)
	assert_eq(engine.current_node()["id"], "n04a_the_1020_muster")
	engine.choose(0)
	assert_eq(engine.current_node()["id"], "n05_the_bazaar_of_herat", "the sideroad must converge on the same node the direct-to-bazaar choice reaches")

func test_the_first_haggles_fair_path():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival")
	for i in range(6):
		engine.choose(0) # n01 -> n02 -> n03a -> n04a -> n05 -> n06 -> n07
	assert_eq(engine.current_node()["id"], "n07_the_exchange_rate")
	var effects := engine.choose(0) # "Accept his rate."
	assert_almost_eq(float(effects["coin_spent_dirham_equivalent"]), 10.0, 0.0001)
	assert_eq(effects.get("reputation", {}), {})
	assert_eq(engine.current_node()["id"], "n08a_accepted_the_rate")

func test_the_first_haggles_push_too_far_path():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival")
	for i in range(6):
		engine.choose(0)
	engine.choose(1) # "Argue the discount." -> n08b
	assert_eq(engine.current_node()["id"], "n08b_argued_the_discount")
	var effects := engine.choose(1) # "Push further." -> n09
	assert_almost_eq(float(effects["coin_spent_dirham_equivalent"]), 5.0, 0.0001)
	assert_eq(int(effects["reputation"]["trading_families"]), -1)
	assert_eq(engine.current_node()["id"], "n09_grudging_exchange")

func test_the_first_haggles_backing_off_reaches_the_same_node_as_accepting():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival")
	for i in range(6):
		engine.choose(0)
	engine.choose(1) # argue -> n08b
	engine.choose(0) # "Back off, accept his rate." -> n08a
	assert_eq(engine.current_node()["id"], "n08a_accepted_the_rate")

func test_the_first_haggles_walk_away_path_has_no_effects():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival")
	for i in range(6):
		engine.choose(0)
	var effects := engine.choose(2) # "Walk away, keep the old coin."
	assert_eq(effects, {})
	assert_eq(engine.current_node()["id"], "n08c_kept_the_old_coin")

func test_the_second_haggles_fair_path():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival")
	for i in range(9):
		engine.choose(0) # reach n07, accept (0), continue to n10, continue to n11
	assert_eq(engine.current_node()["id"], "n11_the_correspondence")
	var effects := engine.choose(0) # "Pay what he asks."
	assert_almost_eq(float(effects["coin_spent_dirham_equivalent"]), 20.0, 0.0001)
	assert_eq(int(effects["reputation"]["trading_families"]), 1)
	assert_eq(engine.current_node()["id"], "n12a_paid_in_full")

func test_the_second_haggles_push_too_far_path():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival")
	for i in range(9):
		engine.choose(0)
	engine.choose(1) # "Try to talk him down." -> n12b
	assert_eq(engine.current_node()["id"], "n12b_haggled_the_fee")
	var effects := engine.choose(1) # "Keep pushing." -> n14
	assert_almost_eq(float(effects["coin_spent_dirham_equivalent"]), 10.0, 0.0001)
	assert_eq(int(effects["reputation"]["trading_families"]), -2)
	assert_eq(engine.current_node()["id"], "n14_pushed_too_far")

func test_the_second_haggles_reduced_fee_path():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival")
	for i in range(9):
		engine.choose(0)
	engine.choose(1) # haggle -> n12b
	var effects := engine.choose(0) # "Accept a small reduction." -> n13
	assert_almost_eq(float(effects["coin_spent_dirham_equivalent"]), 14.0, 0.0001)
	assert_eq(int(effects["reputation"]["trading_families"]), 1)
	assert_eq(engine.current_node()["id"], "n13_reduced_fee")

func test_the_second_haggles_decline_path_has_no_effects():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival")
	for i in range(9):
		engine.choose(0)
	var effects := engine.choose(2) # "Decide you don't need the service."
	assert_eq(effects, {})
	assert_eq(engine.current_node()["id"], "n12c_declined_the_service")

func test_the_default_path_reaches_the_partial_truth():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival")
	for i in range(14):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n18_the_moment_of_truth")
	assert_eq(engine.available_choices().size(), 1, "reputation defaults to empty, so the gated choice must be hidden")
	var effects := engine.choose(0) # "Ask him plainly, one merchant to another."
	assert_eq(effects["flags"], ["partial_network_reveal"])
	assert_eq(engine.current_node()["id"], "n19a_the_partial_truth")
	engine.choose(0) # continue -> n20
	assert_eq(engine.current_node()["id"], "n20_aftermath")

func test_sufficient_reputation_reveals_the_full_truth_choice():
	var engine := DialogueEngine.new()
	engine.reputation = {"trading_families": 4}
	engine.load_tree(_load_nodes(), "n01_herat_arrival")
	for i in range(14):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n18_the_moment_of_truth")
	assert_eq(engine.available_choices().size(), 2, "reputation >= 4 should reveal the gated choice")
	var effects := engine.choose(1) # "Remind him what you've shown him, fairly, since you arrived."
	assert_eq(effects["flags"], ["full_network_reveal"])
	assert_eq(int(effects["reputation"]["trading_families"]), 1)
	assert_eq(engine.current_node()["id"], "n19b_the_full_truth")

func test_insufficient_reputation_still_hides_the_gated_choice():
	var engine := DialogueEngine.new()
	engine.reputation = {"trading_families": 3}
	engine.load_tree(_load_nodes(), "n01_herat_arrival")
	for i in range(14):
		engine.choose(0)
	assert_eq(engine.available_choices().size(), 1, "3 < 4, the gated choice must stay hidden")

func test_the_full_tree_is_walkable_from_start_to_end_via_first_choices():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival")
	var visited := 0
	while not engine.is_chapter_end() and visited < 100:
		engine.choose(0)
		visited += 1
	assert_true(engine.is_chapter_end())
	assert_eq(engine.current_node()["id"], "n21_departure_herat")
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_herat_dialogue_content.gd -gexit`
Expected: FAIL — `content/chapters/chapter_04a_herat/herat.json` does not exist.

- [ ] **Step 3: Create the dialogue content**

Create `content/chapters/chapter_04a_herat/herat.json` as a JSON array of exactly these 26 node objects, in this order, with these exact `text`, `choices[].text`, `choices[].next_id`, `choices[].requires_reputation`, and `choices[].effects` values. Every node other than the terminal node needs `"choices"` populated; effects objects omit any key the node genuinely has nothing to say about (don't write empty `[]`/`{}` for a key that isn't present in the list below).

1. `id: "n01_herat_arrival"`, one choice `"Continue."` → `n02_the_citys_pulse`, no effects.
   text: `"Herat announced itself before the eye found any wall - a green so sudden after the Farah road's thin channels that Farrukh's caravan guide, a Heratigan by birth, laughed out loud at his own relief. The Hari Rud ran wide and steady here, feeding orchards and fields that had outlasted every dynasty that had ever claimed them, and the city itself sat in the middle of all that green like a fact nobody had gotten around to arguing with yet. Bost had been a palace pretending to be a market. Herat was simply a city - the biggest, Farrukh understood without being told, since Ghazni itself."`

2. `id: "n02_the_citys_pulse"`, two choices:
   - `"Let the garrison gate draw you first."` → `n03a_the_old_soldier`, no effects.
   - `"Head straight for the bazaar."` → `n05_the_bazaar_of_herat`, no effects.
   text: `"It did not take an afternoon to learn that Herat struck its own coin - one of six mints still answering to the Sultan, the guide said, with the particular pride of a man reciting a fact about his home he'd repeated to a thousand strangers before Farrukh. It took rather less time to notice the other thing everyone in the bazaar seemed to be discussing in lowered voices: a muster, called sooner and thinner than anyone remembered the last one being, men going to garrison duty who'd expected another season free of it."`

3. `id: "n03a_the_old_soldier"`, one choice `"Continue."` → `n04a_the_1020_muster`, no effects.
   text: `"An old soldier sat by the garrison gate doing the particular kind of nothing men do when they've been told to wait and given no further instruction - watching new levies shuffle through with the flat expression of someone who has seen this exact scene often enough that the details have stopped mattering to him individually. Farrukh asked, since the man seemed willing to be asked things, what all the hurry was for."`

4. `id: "n04a_the_1020_muster"`, one choice `"Continue."` → `n05_the_bazaar_of_herat`, no effects.
   text: `"\"Hurry.\" The old soldier said the word like it tasted wrong. \"I mustered here myself, boy, near twenty years gone now - when the young prince who's Sultan today first called men up in this very yard, before he'd worn the title a season. That muster had banners, had a march worth remembering, had somewhere real to go and something real to be marching toward.\" He nodded at the {{hashar|hashar}} shuffling past - farmers and shopkeepers pressed into service rather than soldiers bred to it. \"This is a man patching a roof with whatever's on hand because he can't wait for proper tile. Nobody's said the word Seljuk to me directly. Nobody needs to.\" He didn't say anything further, and didn't seem to expect Farrukh to either."`

5. `id: "n05_the_bazaar_of_herat"`, one choice `"Continue."` → `n06_ardashir_introduced`, no effects.
   text: `"Herat's bazaar ran long enough that a man could lose an entire day just walking its length without transacting a single dirham - dyers, ironworkers, a street that smelled entirely of saffron, and, threaded through all of it, the particular hush of stalls where actual silver changed hands rather than goods, run by men who weighed coin for a living the way Mihran had in Bost, except here with a mint's own authority standing behind whatever they said a coin was worth."`

6. `id: "n06_ardashir_introduced"`, one choice `"Continue."` → `n07_the_exchange_rate`, no effects.
   text: `"Farrukh found the one the road's own gossip had already half-pointed him toward before he'd finished asking - a sarraf named Ardashir, older than Mihran, quieter than Umm-Kavus, running a stall so plain and so trusted that half the caravan trade passing through Herat used no other scale. He took Farrukh's coin for a first, small exchange without comment, weighed it, and named a rate that was, Farrukh judged, exactly fair and not a hair more generous than that."`

7. `id: "n07_the_exchange_rate"`, three choices:
   - `"Accept his rate."` → `n08a_accepted_the_rate`, effects `{"coin_spent_dirham_equivalent": 10.0}`
   - `"Argue the discount."` → `n08b_argued_the_discount`, no effects.
   - `"Walk away, keep the old coin."` → `n08c_kept_the_old_coin`, effects `{}`
   text: `"He offered to take Farrukh's travel-worn coin off his hands - foreign mintings, clipped edges, the ordinary wreckage of a long road - and give him clean Herat silver in exchange, at a rate that discounted for the wear rather more heavily than Farrukh's own eye judged fair."`

8. `id: "n08a_accepted_the_rate"`, one choice `"Continue."` → `n10_after_first_exchange`, no effects.
   text: `"Farrukh took the rate without argument. Ardashir counted out the clean silver with the same unhurried precision he'd used to name the discount in the first place, and said nothing further about it - a man who had made his offer honestly and expected to be dealt with the same way in return."`

9. `id: "n08b_argued_the_discount"`, two choices:
   - `"Back off, accept his rate."` → `n08a_accepted_the_rate` (same node/effects as item 8's node — this choice's own effects are `{"coin_spent_dirham_equivalent": 10.0}`, matching the destination)
   - `"Push further."` → `n09_grudging_exchange`, effects `{"coin_spent_dirham_equivalent": 5.0, "reputation": {"trading_families": -1}}`
   text: `"Farrukh pointed out, as evenly as he could manage, that the discount ran heavier than the coins' actual wear justified. Ardashir looked at him for a moment with something that might have been mild interest. \"It does,\" he agreed, entirely unbothered. \"Most men don't notice, or don't say so if they do. What would you have it be instead?\""`

10. `id: "n09_grudging_exchange"`, one choice `"Continue."` → `n10_after_first_exchange`, no effects.
    text: `"Farrukh pushed harder than the moment strictly called for, and got a better rate for it - a smaller one than he'd hoped, and a longer silence from Ardashir afterward than the transaction itself required. Coin was coin. Whatever he'd spent to get it back was harder to weigh."`

11. `id: "n08c_kept_the_old_coin"`, one choice `"Continue."` → `n10_after_first_exchange`, no effects.
    text: `"Farrukh decided the worn coin would spend well enough elsewhere and declined the exchange. Ardashir shrugged, entirely untroubled either way, and went back to whatever he'd been doing before Farrukh's shadow had fallen across his stall."`

12. `id: "n10_after_first_exchange"`, one choice `"Continue."` → `n11_the_correspondence`, no effects.
    text: `"Farrukh lingered a moment longer than the transaction required, the way a man does when he has a second, harder question waiting behind the first easy one."`

13. `id: "n11_the_correspondence"`, three choices:
    - `"Pay what he asks."` → `n12a_paid_in_full`, effects `{"coin_spent_dirham_equivalent": 20.0, "reputation": {"trading_families": 1}}`
    - `"Try to talk him down."` → `n12b_haggled_the_fee`, no effects.
    - `"Decide you don't need the service."` → `n12c_declined_the_service`, effects `{}`
    text: `"\"You're not here for silver,\" Ardashir said, before Farrukh had found a way to raise it himself. \"Men who are, don't linger.\" He named a fee, plainly, for sending word through the correspondents he kept in cities a caravan guide wouldn't think to ask about - the kind of service, he made clear without quite saying so, that existed for exactly the sort of question Farrukh hadn't asked yet."`

14. `id: "n12a_paid_in_full"`, one choice `"Continue."` → `n15_after_second_exchange`, no effects.
    text: `"Farrukh paid what he asked, without argument, the same way he'd learned to pay Umm-Kavus in Farah - and watched something in Ardashir's manner ease by the same small fraction it had eased in hers."`

15. `id: "n12b_haggled_the_fee"`, two choices:
    - `"Accept a small reduction."` → `n13_reduced_fee`, effects `{"coin_spent_dirham_equivalent": 14.0, "reputation": {"trading_families": 1}}`
    - `"Keep pushing."` → `n14_pushed_too_far`, effects `{"coin_spent_dirham_equivalent": 10.0, "reputation": {"trading_families": -2}}`
    text: `"Farrukh tried the fee the way he'd tried the exchange rate - reasonably, without heat. Ardashir's expression didn't change, but he named a slightly lower figure, the kind of movement that cost him nothing and told Farrukh nothing either, except that the door hadn't closed."`

16. `id: "n13_reduced_fee"`, one choice `"Continue."` → `n15_after_second_exchange`, no effects.
    text: `"Farrukh accepted the reduction and paid it, and let the matter rest there. It was, he judged, exactly the right amount of pressing - enough to show he wasn't being careless with his father's remaining coin, not so much that it read as anything other than ordinary bazaar custom."`

17. `id: "n14_pushed_too_far"`, one choice `"Continue."` → `n15_after_second_exchange`, no effects.
    text: `"Farrukh pressed a second time, the way he had at the exchange rate, and this time Ardashir's patience visibly thinned. He gave the reduction anyway - a sarraf's professional habit outlasting his personal irritation - but the ease that had been building between them closed over like a door shutting quietly rather than being slammed."`

18. `id: "n12c_declined_the_service"`, one choice `"Continue."` → `n15_after_second_exchange`, no effects.
    text: `"Farrukh decided the fee wasn't worth what it bought and said so, and Ardashir took the refusal exactly as evenly as he'd taken everything else - a man who sold a service, not a man invested in anyone buying it. It left the door to Rayy no more open than Farrukh's own nerve would make it, a few minutes from now, without a paid pretext to lean on."`

19. `id: "n15_after_second_exchange"`, one choice `"Continue."` → `n16_raising_the_rayy_connection`, no effects.
    text: `"Whatever Ardashir made of him after two rounds of ordinary bazaar business, Farrukh had run out of pretexts for lingering a third time without simply asking."`

20. `id: "n16_raising_the_rayy_connection"`, one choice `"Continue."` → `n17_ardashirs_hesitation`, no effects.
    text: `"Farrukh laid it out as plainly as he could manage - the suftaja, the second mark Mihran had recognized and refused to fully explain, the house in Rayy his father's accounts should never have mentioned at all. Ardashir listened without once looking up from the coins he was still, out of habit, sorting."`

21. `id: "n17_ardashirs_hesitation"`, one choice `"Continue."` → `n18_the_moment_of_truth`, no effects.
    text: `"When he finally did look up, it was with the same particular stillness Farrukh had seen twice already on this road - a man doing the arithmetic of how much a stranger's trustworthiness was actually worth, weighed against what the honest answer might cost him if he'd guessed wrong."`

22. `id: "n18_the_moment_of_truth"`, two choices:
    - `"Ask him plainly, one merchant to another."` (always available, no `requires_reputation`) → `n19a_the_partial_truth`, effects `{"flags": ["partial_network_reveal"]}`
    - `"Remind him what you've shown him, fairly, since you arrived."`, `requires_reputation: {"faction_id": "trading_families", "min_score": 4}` → `n19b_the_full_truth`, effects `{"flags": ["full_network_reveal"], "reputation": {"trading_families": 1}}`
    text: `"\"I could tell you what I actually know,\" Ardashir said at last, \"or I could tell you the version of it that's safe for both of us regardless of who you turn out to be. Which one you get isn't really my decision to make anymore. It's whatever you've already shown me, added up.\""`

23. `id: "n19a_the_partial_truth"`, one choice `"Continue."` → `n20_aftermath`, no effects.
    text: `"\"The house had trouble,\" Ardashir said, choosing his words the way a man picks a path across a floor he doesn't trust. \"Trouble tied to things that happened in Rayy a while back - things men in my trade learned not to discuss above a whisper, even now. Your father's paper is a piece of that trouble, passed down further than anyone probably meant it to travel. That's what I can safely give you.\" It was, Farrukh understood, exactly as much as a cautious stranger owed another cautious stranger, and not one word more."`

24. `id: "n19b_the_full_truth"`, one choice `"Continue."` → `n20_aftermath`, no effects.
    text: `"\"Nine years ago,\" Ardashir said, \"Rayy had a ruler of its own house - the last of the old Buyid line, a man named Majd al-Dawla - until your Sultan's father took the city and put him somewhere comfortable and permanent in Ghazni instead. That was the political half of it. The other half happened the same year: men were crucified in Rayy's streets for belonging to a network the state called dangerous enough to kill for - {{dai|da'i}}, missionaries for a cause based in Cairo, funded from Cairo, answerable to nobody the Sultan recognized as legitimate. What's left of both collapses - the old house's money, and whatever survived of that network - didn't vanish. It went quiet, and it went underground, and some of it apparently still moves, carefully, through paper like your father's. I don't know why he was carrying it. I don't think you'll like finding out, whenever you do.\""`

25. `id: "n20_aftermath"`, one choice `"Continue."` → `n21_departure_herat`, no effects.
    text: `"Farrukh walked back through Herat's long bazaar without seeing much of it, turning the shape of what he now knew over in his hands like a coin he couldn't yet tell was genuine. His father had never so much as mentioned Rayy at the dinner table, had never once used a word like Buyid or missionary in Farrukh's hearing - and yet here it was, folded into a debt Farrukh had sworn at a graveside to carry without knowing what, exactly, he'd agreed to be responsible for. Avicenna's floating man, stripped of every borrowed sense, was still supposed to know he existed. Farrukh was beginning to suspect a man could know considerably less than that about the debts he'd sworn to."`

26. `id: "n21_departure_herat"`, `choices: []`, `"next_chapter_id": null`.
    text: `"He left Herat before the muster drums had found their full rhythm, west toward Pushang and whatever came after it, carrying a name from Rayy that had stopped being merely mysterious and started being dangerous, in roughly the proportion Ardashir had warned him it would."`

- [ ] **Step 4: Run tests to verify they pass**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_herat_dialogue_content.gd -gexit`
Expected: PASS, all tests.

- [ ] **Step 5: Commit**

```bash
git add content/chapters/chapter_04a_herat/herat.json tests/unit/test_herat_dialogue_content.gd
git commit -m "feat: add Chapter 4A (Herat) dialogue content"
```

---

### Task 4: Manifest wiring and cross-chapter integration tests

**Files:**
- Modify: `content/chapters/manifest.json`
- Modify: `content/chapters/chapter_03_farah/farah.json` (one field on one node)
- Modify: `tests/unit/test_farah_dialogue_content.gd`
- Modify: `tests/unit/test_chapter_view.gd`

**Interfaces:**
- Consumes: Task 1's validation, Task 2's glossary, Task 3's dialogue content.
- Produces: a working Prologue → Teginabad → Bost → Farah(mystery) → Herat auto-chain, verified end to end, without breaking the existing Farah(plunder) branch (which still has no Chapter 4B and must still stop cleanly at its own terminal node).

- [ ] **Step 1: Wire the manifest**

Add a new entry to `content/chapters/manifest.json`:

```json
	"chapter_04a_herat": {
		"dialogue_path": "res://content/chapters/chapter_04a_herat/herat.json",
		"glossary_path": "res://content/glossary/herat_terms.json",
		"next_chapter_id": null
	}
```

Do **not** change `chapter_03_farah`'s own manifest-level `next_chapter_id` (it's already `null`, and stays `null` — the two Farah terminal nodes each carry their own value, per Chapter 3's design).

- [ ] **Step 2: Wire Farah's mystery terminal node**

In `content/chapters/chapter_03_farah/farah.json`, find the node with `"id": "n18a_departure_farah_mystery"` and change its `"next_chapter_id": null` to `"next_chapter_id": "chapter_04a_herat"`. Do **not** touch `n19b_departure_farah_plunder`'s `next_chapter_id` — it stays `null` (Chapter 4B doesn't exist yet).

- [ ] **Step 3: Update Farah's own content test**

In `tests/unit/test_farah_dialogue_content.gd`, find `test_both_terminal_nodes_carry_their_own_null_next_chapter_id` and replace it with two tests — one per terminal node, since they no longer share the same value:

```gdscript
func test_the_plunder_terminal_node_still_has_a_null_next_chapter_id():
	var nodes := _load_nodes()
	var by_id: Dictionary = {}
	for node in nodes:
		by_id[node["id"]] = node
	assert_true(by_id["n19b_departure_farah_plunder"].has("next_chapter_id"))
	assert_eq(by_id["n19b_departure_farah_plunder"]["next_chapter_id"], null)

func test_the_mystery_terminal_node_now_points_at_chapter_4a():
	var nodes := _load_nodes()
	var by_id: Dictionary = {}
	for node in nodes:
		by_id[node["id"]] = node
	assert_eq(by_id["n18a_departure_farah_mystery"]["next_chapter_id"], "chapter_04a_herat")
```

- [ ] **Step 4: Extend the mystery-branch full-playthrough test**

In `tests/unit/test_chapter_view.gd`, `test_a_full_playthrough_via_the_mystery_branch_carries_prologue_flags_through_farah` currently asserts the playthrough ends at Farah. Since Farah's mystery terminal now auto-transitions into Herat, the "always press index 0" loop continues further: index 0 at Herat's `n02_the_citys_pulse` is the garrison-gate sideroad, index 0 at both haggle openings is the fair/pay-in-full option, and index 0 at `n18_the_moment_of_truth` resolves to the always-available (partial-truth) choice, since a press-0-only playthrough's accumulated `trading_families` reputation does not reach the gate's threshold of 4.

Change the function's final assertions from:

```gdscript
	assert_eq(chapter_view.chapter_id, "chapter_03_farah")
	assert_eq(chapter_view.dialogue_engine.current_node()["id"], "n18a_departure_farah_mystery")
	assert_eq(chapter_view.next_chapter_id, null, "Farah's mystery branch has no Chapter 4 yet")
	assert_true(chapter_view.dialogue_engine.flags.get("vowed_kafala", false), "the Prologue's kafala vow flag must survive into Farah")
	assert_true(chapter_view.dialogue_engine.flags.get("knows_the_second_marks_name", false))
	assert_almost_eq(chapter_view.ledger.total_wealth_dirham_equivalent(), -15.0, 0.0001)
	assert_true(FileAccess.file_exists(teginabad_save_path), "passing through Teginabad on the way to Farah must still write Teginabad's save file")
	assert_true(FileAccess.file_exists(bost_save_path), "passing through Bost on the way to Farah must still write Bost's save file")
	assert_true(FileAccess.file_exists(farah_save_path), "reaching Farah's mystery-branch ending must write its own save file")
```

to:

```gdscript
	assert_eq(chapter_view.chapter_id, "chapter_04a_herat")
	assert_eq(chapter_view.dialogue_engine.current_node()["id"], "n21_departure_herat")
	assert_eq(chapter_view.next_chapter_id, null, "Chapter 4A has no Chapter 5 yet")
	assert_true(chapter_view.dialogue_engine.flags.get("vowed_kafala", false), "the Prologue's kafala vow flag must survive all the way into Herat")
	assert_true(chapter_view.dialogue_engine.flags.get("knows_the_second_marks_name", false))
	assert_true(chapter_view.dialogue_engine.flags.get("partial_network_reveal", false), "an always-press-0 playthrough never builds enough trading_families reputation to reach the gated full-truth choice")
	assert_false(chapter_view.dialogue_engine.flags.get("full_network_reveal", false))
	assert_almost_eq(chapter_view.ledger.total_wealth_dirham_equivalent(), -45.0, 0.0001, "Farah's -15.0 plus Herat's two accepted-rate haggles: -10.0 and -20.0")
	assert_true(FileAccess.file_exists(teginabad_save_path), "passing through Teginabad on the way to Herat must still write Teginabad's save file")
	assert_true(FileAccess.file_exists(bost_save_path), "passing through Bost on the way to Herat must still write Bost's save file")
	assert_true(FileAccess.file_exists(farah_save_path), "passing through Farah on the way to Herat must still write Farah's save file")
	assert_true(FileAccess.file_exists("user://borrowed_fortune_chapter_04a_herat.json"), "reaching Herat's ending must write its own save file")
```

Also add `"user://borrowed_fortune_chapter_04a_herat.json"` to the list of paths cleared at the top of the test (the `for path in [...]` loop), alongside the three existing save paths, so a stale file from an earlier run can't produce a false pass.

- [ ] **Step 5: Add a dedicated test proving the full-truth reveal is reachable**

Append to `tests/unit/test_chapter_view.gd`:

```gdscript
func test_the_full_truth_is_reachable_with_strong_accumulated_reputation():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter_by_id("chapter_00_prologue")
	# Walk to Bost's fork by node id, then choose the patient path (index 1) for +2
	# trading_families - the highest-reputation option anywhere in the game so far.
	var presses := 0
	while chapter_view.dialogue_engine.current_node().get("id", "") != "n07_the_offer" and presses < 200:
		chapter_view._on_choice_pressed(0)
		presses += 1
	assert_eq(chapter_view.dialogue_engine.current_node()["id"], "n07_the_offer")
	chapter_view._on_choice_pressed(1) # "Don't make him say it." -> earned_mihrans_trust, trading_families +2

	# Continue with index 0 through the rest of Bost and all of Farah - index 0 at
	# Farah's n10_the_price_of_a_bed is "Pay what she asks" (+1), and index 0 at
	# n14_the_choice is Umm-Kavus's channel (+1, and the only way into Chapter 4A at all).
	presses = 0
	while chapter_view.dialogue_engine.current_node().get("id", "") != "n07_the_exchange_rate" and presses < 200:
		chapter_view._on_choice_pressed(0)
		presses += 1
	assert_eq(chapter_view.dialogue_engine.current_node()["id"], "n07_the_exchange_rate", "should have reached Herat's first haggle via Farah's mystery branch")

	# In Herat, take the non-aggressive path through both haggles: accept the exchange
	# rate (0 reputation cost), then pay the correspondence fee in full (+1).
	chapter_view._on_choice_pressed(0) # "Accept his rate." -> n08a
	presses = 0
	while chapter_view.dialogue_engine.current_node().get("id", "") != "n11_the_correspondence" and presses < 200:
		chapter_view._on_choice_pressed(0)
		presses += 1
	assert_eq(chapter_view.dialogue_engine.current_node()["id"], "n11_the_correspondence")
	chapter_view._on_choice_pressed(0) # "Pay what he asks." -> n12a, +1 trading_families

	presses = 0
	while chapter_view.dialogue_engine.current_node().get("id", "") != "n18_the_moment_of_truth" and presses < 200:
		chapter_view._on_choice_pressed(0)
		presses += 1
	assert_eq(chapter_view.dialogue_engine.current_node()["id"], "n18_the_moment_of_truth")
	assert_eq(chapter_view.reputation_tracker.get_reputation("trading_families"), 5, "2 from Bost's patient path + 1 from Farah's bed paid in full + 1 from Farah's fork into Umm-Kavus's channel + 0 from Herat's first haggle (accepted the rate) + 1 from Herat's second haggle (paid in full) = 5")
	assert_eq(chapter_view.dialogue_engine.available_choices().size(), 2, "5 >= 4, the gated choice should be visible")
	chapter_view._on_choice_pressed(1) # the reputation-gated "Remind him what you've shown him..."
	assert_eq(chapter_view.dialogue_engine.current_node()["id"], "n19b_the_full_truth")
	assert_true(chapter_view.dialogue_engine.flags.get("full_network_reveal", false))
```

If `assert_eq(chapter_view.reputation_tracker.get_reputation("trading_families"), 5, ...)` fails, the arithmetic above has an error somewhere in this test's own choice sequence relative to Task 3's effects — trace it by printing `chapter_view.reputation_tracker.get_reputation("trading_families")` at each of the three checkpoint presses (after Bost's fork, after Herat's first haggle, after Herat's second haggle) to find exactly where the running total diverges from 2 → 2 → 3, before touching the final assertions.

- [ ] **Step 6: Run the ChapterView and content tests**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_chapter_view.gd -gexit`
Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_farah_dialogue_content.gd -gexit`
Expected: PASS, including `test_glossary_terms_and_flag_names_are_unique_across_all_manifest_chapters`, which needs no changes to pick up `chapter_04a_herat` — if it fails, a Herat flag name or glossary term id collided with an earlier chapter's; re-check Task 2/3 against the earlier chapters before changing this test.

- [ ] **Step 7: Commit**

```bash
git add content/chapters/manifest.json content/chapters/chapter_03_farah/farah.json tests/unit/test_farah_dialogue_content.gd tests/unit/test_chapter_view.gd
git commit -m "feat: wire Chapter 4A into the manifest via Farah's mystery terminal node"
```

---

### Task 5: Full-suite verification

**Files:** none (verification only).

**Interfaces:** none.

- [ ] **Step 1: Run the entire suite headless**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`

- [ ] **Step 2: Confirm a clean pass**

Confirm: every test passes, no float/int comparison warnings, and the total test/assert counts increased from the pre-Chapter-4A baseline (126 tests / 446 asserts) by roughly the number of new tests this plan added (4 in Task 1, 1 in Task 2, 17 in Task 3, 2 net-new in Task 4 — `test_both_terminal_nodes_carry_their_own_null_next_chapter_id` is replaced by 2 tests, plus 1 new full-truth-reachability test).

If the GUT GUI-asset import noise from a fresh worktree shows up again (unrelated `addons/gut/` font/image resource errors, not float/int warnings) — this was already investigated and confirmed non-blocking during the trading-engine plan (see that plan's ledger history if you need the full reasoning); don't re-litigate it, just confirm the actual test pass/fail counts are clean.

- [ ] **Step 3: Report**

No commit for this task (verification only). Report the final pass/fail counts in the task report.

---

## Post-Plan Note

Chapter 4A does not fork further — `n21_departure_herat`'s `next_chapter_id` stays `null` until a Chapter 5 (likely Pushang, per the original 8-stop route) exists for the long/clean route. Chapter 4B (the Farah-plunder branch's own Herat chapter, confirmed as fully distinct content, not sharing this chapter's authored material) is separate future work with its own internal true-fork (an unsettling merchant reveal) converging into a *different*, shared Chapter 5 that ends the game for that branch — do not confuse the two Chapter 5s when that work begins.
