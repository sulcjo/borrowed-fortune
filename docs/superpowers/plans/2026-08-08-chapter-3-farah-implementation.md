# Chapter 3: Farah Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship Chapter 3 (Farah) — a 27-node chapter with three reconverging forks, a true fork that produces two distinct terminal nodes, and the game's first real trade mechanic — wired into the existing 3-chapter campaign so a fresh playthrough auto-chains Prologue → Teginabad → Bost → Farah.

**Architecture:** Content-only in the areas the existing engine already supports (dialogue nodes, glossary, manifest), plus three small, additive engine changes: `Ledger` gains a coin-spend accumulator, `ChapterView._apply_effects()` gains a `coin_spent_dirham_equivalent` effects key, and `ChapterView._save_and_finish()` resolves its next-chapter id from the current terminal node first, falling back to the chapter's manifest default — this is what lets two different terminal nodes in the same chapter point at two different (future) next chapters.

**Tech Stack:** Godot 4.3 (GDScript), GUT test framework.

**Design doc:** `docs/superpowers/specs/2026-08-08-chapter-3-farah-design.md` — read this for the narrative rationale. This plan's briefs contain everything needed to implement it; you should not need to re-read the design doc.

## Global Constraints

- Godot 4.3 floor. Priming command for a fresh checkout, run once before the first test run: `godot --headless --path . --editor --quit`.
- Headless test run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`.
- Engine-layer classes (`engine/**`) are `RefCounted`, never `Node` — no exception in this plan.
- Naming idiom: GDScript's own idiom throughout — `snake_case` functions/variables, `PascalCase` types — not the user's general camelCase preference. This is a deliberate, standing exception.
- **Hard rule: `JSON.parse_string` always deserializes numbers as `float`, never `int`.** Any test comparing a JSON-sourced effects value against a GDScript int literal must cast with `int(...)` or compare per-key. Never `assert_eq(whole_dict, {...with int literals...})` against JSON-sourced data.
- **Choice ordering convention (binding for Task 3):** in every dialogue node with more than one choice, the choice that is always available (no `requires_flag`) is always listed *before* any `requires_flag`-gated choice in the JSON `choices` array. This is what makes `available_choices()[0]` — and therefore every `choose(0)` in this plan's tests — deterministic regardless of which flags are set. Get this wrong and the press-counts in Task 3 and Task 4's tests will resolve to the wrong node.
- Single-choice "continue" nodes use the exact choice text `"Continue."` — matches the convention in `content/chapters/chapter_02_bost/bost.json` and `chapter_01_teginabad/teginabad.json`.
- Commit after each task.

---

### Task 1: Engine changes — Ledger coin-spend, effects wiring, per-node next-chapter override

**Files:**
- Modify: `engine/ledger/Ledger.gd` (lines 9, 15-23, 51-66)
- Modify: `scenes/chapter_view/ChapterView.gd` (lines 93-99, 109-126)
- Test: `tests/unit/test_ledger.gd` (append)
- Test: `tests/unit/test_chapter_view.gd` (append)

**Interfaces:**
- Produces: `Ledger.spend_dirham_equivalent(amount: float) -> void`, `Ledger.spent_dirham_equivalent: float` field. `total_wealth_dirham_equivalent()` now subtracts accumulated spend. `to_dict()`/`load_from_dict()` round-trip the new field.
- Produces: `ChapterView._apply_effects()` now handles an optional `"coin_spent_dirham_equivalent"` key in an effects dict by calling `ledger.spend_dirham_equivalent()`.
- Produces: `ChapterView._save_and_finish()` now resolves the chapter transition target from `dialogue_engine.current_node().get("next_chapter_id", next_chapter_id)` instead of `next_chapter_id` directly — a terminal dialogue node may carry its own `"next_chapter_id"` key that overrides the chapter's manifest-level default. Existing chapters' terminal nodes have no such key, so their behavior is unchanged.
- Consumes: nothing new from earlier tasks — this task is pure engine/scene-layer work, independent of Task 2/3's content.

- [ ] **Step 1: Write the failing Ledger tests**

Append to `tests/unit/test_ledger.gd`:

```gdscript
func test_spend_dirham_equivalent_reduces_total_wealth():
	var ledger := Ledger.new()
	ledger.add_coin(Coin.minted_dirham(1.0))
	ledger.spend_dirham_equivalent(0.4)
	assert_almost_eq(ledger.total_wealth_dirham_equivalent(), 0.6, 0.0001)

func test_spend_dirham_equivalent_accumulates_across_multiple_calls():
	var ledger := Ledger.new()
	ledger.spend_dirham_equivalent(15.0)
	ledger.spend_dirham_equivalent(6.0)
	assert_almost_eq(ledger.total_wealth_dirham_equivalent(), -21.0, 0.0001)

func test_to_dict_and_from_dict_round_trip_spent_dirham_equivalent():
	var original := Ledger.new()
	original.spend_dirham_equivalent(9.0)

	var restored := Ledger.new()
	restored.load_from_dict(original.to_dict())

	assert_almost_eq(restored.spent_dirham_equivalent, 9.0, 0.0001)
	assert_almost_eq(restored.total_wealth_dirham_equivalent(), -9.0, 0.0001)
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_ledger.gd -gexit`
Expected: FAIL — `spend_dirham_equivalent` and `spent_dirham_equivalent` don't exist yet.

- [ ] **Step 3: Implement the Ledger changes**

In `engine/ledger/Ledger.gd`, change line 9 from:

```gdscript
var purse: Array[Coin] = []
var debts: Array[Debt] = []
```

to:

```gdscript
var purse: Array[Coin] = []
var debts: Array[Debt] = []
var spent_dirham_equivalent: float = 0.0
```

Change `total_wealth_dirham_equivalent()` (lines 15-23) from:

```gdscript
func total_wealth_dirham_equivalent() -> float:
	var total := 0.0
	for coin in purse:
		if coin.metal == Coin.Metal.GOLD:
			var dinar_equivalent := coin.pure_metal_grams() / Coin.DINAR_NOMINAL_WEIGHT_GRAMS
			total += dinar_equivalent * GOLD_TO_SILVER_VALUE_RATIO
		else:
			total += coin.pure_metal_grams() / Coin.DIRHAM_NOMINAL_WEIGHT_GRAMS
	return total
```

to:

```gdscript
func spend_dirham_equivalent(amount: float) -> void:
	spent_dirham_equivalent += amount

func total_wealth_dirham_equivalent() -> float:
	var total := -spent_dirham_equivalent
	for coin in purse:
		if coin.metal == Coin.Metal.GOLD:
			var dinar_equivalent := coin.pure_metal_grams() / Coin.DINAR_NOMINAL_WEIGHT_GRAMS
			total += dinar_equivalent * GOLD_TO_SILVER_VALUE_RATIO
		else:
			total += coin.pure_metal_grams() / Coin.DIRHAM_NOMINAL_WEIGHT_GRAMS
	return total
```

Change `to_dict()`/`load_from_dict()` (lines 51-66) from:

```gdscript
func to_dict() -> Dictionary:
	var purse_data: Array = []
	for coin in purse:
		purse_data.append(coin.to_dict())
	var debts_data: Array = []
	for debt in debts:
		debts_data.append(debt.to_dict())
	return {"purse": purse_data, "debts": debts_data}

func load_from_dict(data: Dictionary) -> void:
	purse.clear()
	for coin_data in data.get("purse", []):
		purse.append(Coin.from_dict(coin_data))
	debts.clear()
	for debt_data in data.get("debts", []):
		debts.append(Debt.from_dict(debt_data))
```

to:

```gdscript
func to_dict() -> Dictionary:
	var purse_data: Array = []
	for coin in purse:
		purse_data.append(coin.to_dict())
	var debts_data: Array = []
	for debt in debts:
		debts_data.append(debt.to_dict())
	return {"purse": purse_data, "debts": debts_data, "spent_dirham_equivalent": spent_dirham_equivalent}

func load_from_dict(data: Dictionary) -> void:
	purse.clear()
	for coin_data in data.get("purse", []):
		purse.append(Coin.from_dict(coin_data))
	debts.clear()
	for debt_data in data.get("debts", []):
		debts.append(Debt.from_dict(debt_data))
	spent_dirham_equivalent = data.get("spent_dirham_equivalent", 0.0)
```

- [ ] **Step 4: Run Ledger tests to verify they pass**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_ledger.gd -gexit`
Expected: PASS, all tests including the pre-existing ones.

- [ ] **Step 5: Commit**

```bash
git add engine/ledger/Ledger.gd tests/unit/test_ledger.gd
git commit -m "feat: add coin-spend accumulator to Ledger"
```

- [ ] **Step 6: Write the failing ChapterView tests**

Append to `tests/unit/test_chapter_view.gd`. These use the same `res://tests/fixtures/manifest_fixture.json` fixture chapters already used by the tests around line 73-96 (`fixture_chapter_a`, `fixture_chapter_b`, `fixture_chapter_terminal`, `fixture_chapter_cycle_a`) — read that fixture file and its paired dialogue/glossary fixtures first so the new fixture nodes you add are consistent with the existing ones' shape (same field names, same directory).

```gdscript
func test_apply_effects_with_coin_spent_dirham_equivalent_spends_from_the_ledger():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view._apply_effects({"coin_spent_dirham_equivalent": 6.0})
	assert_almost_eq(chapter_view.ledger.total_wealth_dirham_equivalent(), -6.0, 0.0001)

func test_a_terminal_nodes_own_next_chapter_id_overrides_the_manifest_default():
	# fixture_chapter_terminal_override is a new fixture chapter (add it to
	# tests/fixtures/manifest_fixture.json and its own dialogue fixture file)
	# whose manifest entry has next_chapter_id: null, but whose single node is
	# already a terminal node (choices: []) carrying its own
	# "next_chapter_id": "fixture_chapter_a" — proving the node-level value wins.
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter_by_id("fixture_chapter_terminal_override", "res://tests/fixtures/manifest_fixture.json")
	assert_eq(chapter_view.chapter_id, "fixture_chapter_a", "the terminal node's own next_chapter_id should have won over the manifest's null")

func test_a_terminal_node_without_its_own_next_chapter_id_falls_back_to_the_manifest():
	# Regression guard: fixture_chapter_terminal (already used above) has no
	# per-node next_chapter_id, only the manifest's "fixture_chapter_b" ->
	# next_chapter_id "fixture_chapter_terminal" -> (terminal, no override) chain
	# already covered by test_reaching_chapter_end_with_a_next_chapter_id_auto_transitions.
	# This test covers the opposite direction: a terminal chapter whose manifest
	# entry's next_chapter_id is null and whose node also sets no override stays put.
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter_by_id("fixture_chapter_b", "res://tests/fixtures/manifest_fixture.json")
	assert_eq(chapter_view.chapter_id, "fixture_chapter_b")
```

For the second test, add a new fixture. Read `tests/fixtures/manifest_fixture.json` and whichever dialogue fixture file `fixture_chapter_a` points at first, to match the exact shape (glossary path, field names). Then:
- Add a `fixture_chapter_terminal_override` entry to `tests/fixtures/manifest_fixture.json` with `"next_chapter_id": null` and a new dialogue fixture path (reuse the existing fixture glossary path — any valid one already referenced by another fixture entry).
- Create that dialogue fixture file with exactly one node: `id` your choice (e.g. `"only_node"`), `"choices": []`, and `"next_chapter_id": "fixture_chapter_a"`.

- [ ] **Step 7: Implement the ChapterView changes**

In `scenes/chapter_view/ChapterView.gd`, change `_apply_effects()` (lines 93-99) from:

```gdscript
func _apply_effects(effects: Dictionary) -> void:
	for faction_id in effects.get("reputation", {}):
		# effects come from JSON, where all numbers parse as float - cast
		# explicitly since adjust_reputation's delta parameter is typed int.
		reputation_tracker.adjust_reputation(faction_id, int(effects["reputation"][faction_id]))
	for debt_data in effects.get("debts", []):
		ledger.guarantee_debt_via_kafala(debt_data["creditor_name"], debt_data["amount_dirham_equivalent"])
```

to:

```gdscript
func _apply_effects(effects: Dictionary) -> void:
	for faction_id in effects.get("reputation", {}):
		# effects come from JSON, where all numbers parse as float - cast
		# explicitly since adjust_reputation's delta parameter is typed int.
		reputation_tracker.adjust_reputation(faction_id, int(effects["reputation"][faction_id]))
	for debt_data in effects.get("debts", []):
		ledger.guarantee_debt_via_kafala(debt_data["creditor_name"], debt_data["amount_dirham_equivalent"])
	if effects.has("coin_spent_dirham_equivalent"):
		ledger.spend_dirham_equivalent(effects["coin_spent_dirham_equivalent"])
```

Change `_save_and_finish()` (lines 109-126) from:

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
	if next_chapter_id == null:
		return
	if _auto_transition_chain_ids.has(next_chapter_id):
		push_error("ChapterView: chapter manifest '%s' loops back to '%s' without any player input in between; stopping the auto-transition chain" % [_manifest_path, next_chapter_id])
		return
	_auto_transition_chain_ids[next_chapter_id] = true
	load_chapter_by_id(next_chapter_id, _manifest_path)
	_auto_transition_chain_ids.erase(next_chapter_id)
```

to:

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
	# A terminal node may name its own next chapter (used when a chapter ends in more
	# than one place, e.g. a true story fork) - that wins over the chapter's manifest
	# default. Existing terminal nodes have no "next_chapter_id" key, so they fall
	# through to next_chapter_id unchanged.
	var resolved_next_chapter_id = dialogue_engine.current_node().get("next_chapter_id", next_chapter_id)
	if resolved_next_chapter_id == null:
		return
	if _auto_transition_chain_ids.has(resolved_next_chapter_id):
		push_error("ChapterView: chapter manifest '%s' loops back to '%s' without any player input in between; stopping the auto-transition chain" % [_manifest_path, resolved_next_chapter_id])
		return
	_auto_transition_chain_ids[resolved_next_chapter_id] = true
	load_chapter_by_id(resolved_next_chapter_id, _manifest_path)
	_auto_transition_chain_ids.erase(resolved_next_chapter_id)
```

- [ ] **Step 8: Run the full suite to verify everything passes**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`
Expected: PASS, no new failures, no new float/int warnings.

- [ ] **Step 9: Commit**

```bash
git add scenes/chapter_view/ChapterView.gd tests/unit/test_chapter_view.gd tests/fixtures/
git commit -m "feat: resolve chapter transitions per-terminal-node, spend coin via effects"
```

---

### Task 2: Farah glossary content

**Files:**
- Create: `content/glossary/farah_terms.json`
- Test: `tests/unit/test_farah_glossary_content.gd`

**Interfaces:**
- Consumes: nothing from Task 1.
- Produces: `content/glossary/farah_terms.json` with exactly these 5 term ids, consumed by Task 3's dialogue content and Task 4's manifest wiring: `ghulam`, `dallal`, `amana`, `ghanima`, `khums`.

- [ ] **Step 1: Write the failing test**

Create `tests/unit/test_farah_glossary_content.gd`:

```gdscript
extends GutTest

func test_farah_glossary_has_the_five_expected_terms_with_headword_and_definition():
	var file := FileAccess.open("res://content/glossary/farah_terms.json", FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()

	var expected_ids := ["ghulam", "dallal", "amana", "ghanima", "khums"]
	assert_eq(data.keys().size(), expected_ids.size())
	for term_id in expected_ids:
		assert_true(data.has(term_id), "missing glossary term '%s'" % term_id)
		assert_true(data[term_id].has("headword"))
		assert_true(data[term_id].has("definition"))
		assert_false(data[term_id]["headword"].is_empty())
		assert_false(data[term_id]["definition"].is_empty())
```

- [ ] **Step 2: Run test to verify it fails**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_farah_glossary_content.gd -gexit`
Expected: FAIL — file does not exist.

- [ ] **Step 3: Create the glossary file**

Create `content/glossary/farah_terms.json`:

```json
{
	"ghulam": {
		"headword": "Ghulam",
		"definition": "A Turkic soldier, typically purchased and raised from youth within the royal household, forming the professional backbone of the Ghaznavid army - more directly loyal to the sultan than levies drawn from tribes or hereditary nobility."
	},
	"dallal": {
		"headword": "Dallal",
		"definition": "A broker or intermediary - in trade, someone who connected buyers and sellers, verified goods, or carried messages and money between merchants who trusted his (or her) network more than any single stranger."
	},
	"amana": {
		"headword": "Amana",
		"definition": "A trust or deposit held in safekeeping - the basic concept underlying informal courier and broker networks, where reputation, not paperwork, secured someone else's money or message."
	},
	"ghanima": {
		"headword": "Ghanima",
		"definition": "The spoils of war under Islamic law - movable property seized in a successful campaign, subject to specific rules for its division among the ruler, the army, and other stakeholders."
	},
	"khums": {
		"headword": "Khums",
		"definition": "Literally \"one-fifth.\" The Quranically mandated share of ghanima (war spoils) reserved for the ruler and state - historically a major, and controversial, source of treasury income from campaigns like Mahmud's raids into India."
	}
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_farah_glossary_content.gd -gexit`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add content/glossary/farah_terms.json tests/unit/test_farah_glossary_content.gd
git commit -m "feat: add Farah glossary terms"
```

---

### Task 3: Farah dialogue content — 27 nodes, three reconverging forks, one true fork

**Files:**
- Create: `content/chapters/chapter_03_farah/farah.json`
- Test: `tests/unit/test_farah_dialogue_content.gd`

**Interfaces:**
- Consumes: nothing from Task 1 or 2 directly (this task tests the dialogue tree via `DialogueEngine` in isolation, not through `ChapterView` or the manifest — that integration is Task 4's job). The glossed terms in this content (`ghulam`, `dallal`, `amana`, `ghanima`, `khums`) must match Task 2's `farah_terms.json` exactly, or Task 4's cross-chapter uniqueness test and the "every glossed term id exists in the glossary" test below will fail.
- Produces: `content/chapters/chapter_03_farah/farah.json`, an array of exactly 27 nodes, start node `n01_farah_arrival`, exactly two terminal nodes (`choices: []`): `n18a_departure_farah_mystery` (with `"next_chapter_id": null`) and `n19b_departure_farah_plunder` (with `"next_chapter_id": null`). Task 4 will wire the manifest and, eventually, a future plan will change these two `null` values to two different Chapter 4 variant ids.

This task's dialogue text, choice text, `next_id` wiring, and effects are given in full below — copy them verbatim into the JSON array, in this order.

- [ ] **Step 1: Write the failing tests**

Create `tests/unit/test_farah_dialogue_content.gd`:

```gdscript
extends GutTest

func _load_nodes() -> Array:
	var file := FileAccess.open("res://content/chapters/chapter_03_farah/farah.json", FileAccess.READ)
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
	assert_eq(end_node_ids, ["n18a_departure_farah_mystery", "n19b_departure_farah_plunder"])

func test_both_terminal_nodes_carry_their_own_null_next_chapter_id():
	var nodes := _load_nodes()
	var by_id: Dictionary = {}
	for node in nodes:
		by_id[node["id"]] = node
	assert_true(by_id["n18a_departure_farah_mystery"].has("next_chapter_id"))
	assert_eq(by_id["n18a_departure_farah_mystery"]["next_chapter_id"], null)
	assert_true(by_id["n19b_departure_farah_plunder"].has("next_chapter_id"))
	assert_eq(by_id["n19b_departure_farah_plunder"]["next_chapter_id"], null)

func test_every_glossed_term_id_exists_in_the_farah_glossary():
	var nodes := _load_nodes()
	var glossary_file := FileAccess.open("res://content/glossary/farah_terms.json", FileAccess.READ)
	var glossary_data = JSON.parse_string(glossary_file.get_as_text())
	glossary_file.close()

	for node in nodes:
		for term_id in GlossedTextParser.extract_term_ids(node["text"]):
			assert_true(glossary_data.has(term_id), "node %s glosses unknown term '%s'" % [node["id"], term_id])

func test_the_checkpoint_fork_sets_distinct_flags_and_reputation():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_farah_arrival")
	for i in range(3):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n04_the_choice_at_the_checkpoint")
	var vouch_effects := engine.choose(0) # "Tell him they're traveling with you."
	assert_eq(vouch_effects["flags"], ["vouched_for_the_family_at_farah"])
	assert_eq(int(vouch_effects["reputation"]["townsfolk"]), 2)
	assert_eq(int(vouch_effects["reputation"]["ghaznavid_officials"]), -1)

func test_the_checkpoint_forks_other_branch_sets_its_own_flag_and_reputation():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_farah_arrival")
	for i in range(3):
		engine.choose(0)
	var uninvolved_effects := engine.choose(1) # "Say nothing. It isn't your caravan to risk."
	assert_eq(uninvolved_effects["flags"], ["stayed_uninvolved_at_farah"])
	assert_eq(int(uninvolved_effects["reputation"]["ghaznavid_officials"]), 1)

func test_the_family_again_bonus_is_available_when_vouched():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_farah_arrival")
	for i in range(11):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n12_the_common_room")
	assert_eq(engine.available_choices().size(), 2, "the family-again bonus should be visible because index 0 at the checkpoint choice vouches for the family")

func test_the_family_again_bonus_is_hidden_when_uninvolved():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_farah_arrival")
	for i in range(3):
		engine.choose(0)
	engine.choose(1) # "Say nothing. It isn't your caravan to risk." - does not set the vouched flag
	for i in range(7):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n12_the_common_room")
	assert_eq(engine.available_choices().size(), 1, "the family-again bonus should be hidden because the family was never vouched for")

func test_the_price_of_a_bed_fork_carries_coin_spent_and_reputation_differently():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_farah_arrival")
	for i in range(9):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n10_the_price_of_a_bed")
	var paid_full_effects := engine.choose(0) # "Pay what she asks."
	assert_almost_eq(float(paid_full_effects["coin_spent_dirham_equivalent"]), 15.0, 0.0001)
	assert_eq(int(paid_full_effects["reputation"]["trading_families"]), 1)

func test_the_haggle_branch_costs_less_coin_and_no_reputation():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_farah_arrival")
	for i in range(9):
		engine.choose(0)
	var haggled_effects := engine.choose(1) # "Haggle her down."
	assert_almost_eq(float(haggled_effects["coin_spent_dirham_equivalent"]), 6.0, 0.0001)
	assert_eq(haggled_effects.get("reputation", {}), {})

func test_the_name_already_known_bonus_is_gated_on_the_bost_pressed_flag():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_farah_arrival")
	for i in range(13):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n14_the_choice", "without the flag, index 0 at n13 should always skip straight past the bonus")

func test_the_name_already_known_bonus_is_visible_when_the_flag_is_set():
	var engine := DialogueEngine.new()
	engine.flags["pressed_mihran_for_the_name"] = true
	engine.load_tree(_load_nodes(), "n01_farah_arrival")
	for i in range(12):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n13_two_doors")
	assert_eq(engine.available_choices().size(), 2, "the name-already-known bonus should be visible because pressed_mihran_for_the_name is set")

func test_the_mystery_path_is_walkable_and_sets_its_flags_and_reputation():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_farah_arrival")
	for i in range(13):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n14_the_choice")
	var fork_effects := engine.choose(0) # "Go to Umm-Kavus's channel."
	assert_eq(fork_effects["flags"], ["chose_golnars_channel"])
	assert_eq(int(fork_effects["reputation"]["trading_families"]), 1)
	engine.choose(0) # n15a_golnars_channel -> continue
	engine.choose(0) # n16a_the_wait -> continue
	var name_effects := engine.choose(0) # n17a_the_name_given_cleanly -> continue
	assert_eq(name_effects["flags"], ["knows_the_second_marks_name"])
	assert_eq(int(name_effects["reputation"]["trading_families"]), 1)
	assert_eq(engine.current_node()["id"], "n18a_departure_farah_mystery")
	assert_true(engine.is_chapter_end())
	assert_true(engine.flags.get("chose_golnars_channel", false))
	assert_true(engine.flags.get("knows_the_second_marks_name", false))

func test_the_plunder_path_is_walkable_and_sets_its_flags_and_reputation():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_farah_arrival")
	for i in range(13):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n14_the_choice")
	var fork_effects := engine.choose(1) # "Seek out Tahir."
	assert_eq(fork_effects["flags"], ["chose_tahirs_price"])
	assert_eq(int(fork_effects["reputation"]["trading_families"]), -1)
	engine.choose(0) # n15b_finding_tahir -> continue
	engine.choose(0) # n16b_tahirs_price -> continue
	engine.choose(0) # n17b_the_war_he_carries -> continue
	var favor_effects := engine.choose(0) # n18b_the_favor_owed -> continue
	assert_eq(favor_effects["flags"], ["knows_the_second_marks_name", "owes_tahir_a_favor"])
	assert_eq(int(favor_effects["reputation"]["townsfolk"]), -1)
	assert_eq(engine.current_node()["id"], "n19b_departure_farah_plunder")
	assert_true(engine.is_chapter_end())
	assert_true(engine.flags.get("chose_tahirs_price", false))
	assert_true(engine.flags.get("owes_tahir_a_favor", false))

func test_the_full_tree_is_walkable_from_start_to_end_via_first_choices():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_farah_arrival")
	var visited := 0
	while not engine.is_chapter_end() and visited < 100:
		engine.choose(0)
		visited += 1
	assert_true(engine.is_chapter_end())
	assert_eq(engine.current_node()["id"], "n18a_departure_farah_mystery")
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_farah_dialogue_content.gd -gexit`
Expected: FAIL — `content/chapters/chapter_03_farah/farah.json` does not exist.

- [ ] **Step 3: Create the dialogue content**

Create `content/chapters/chapter_03_farah/farah.json` as a JSON array containing exactly these 27 node objects, in this order, with these exact `text`, `choices[].text`, `choices[].next_id`, `choices[].requires_flag`, and `choices[].effects` values:

1. `id: "n01_farah_arrival"`, one choice `"Continue."` → `n02_the_checkpoint`, no effects.
   text: `"Farah did not announce itself the way Teginabad or Bost had - no wall worth the name, no palace skyline, only a scatter of mud-brick and tamarisk windbreak at a crossing of tracks in country that seemed to have given up deciding whether it was desert or something less committed. What green there was ran along channels dug by hands generations dead - a thin, stubborn irrigation the road's guide called older than any dynasty currently claiming this ground, older probably than the idea of Ghazni itself. If the frontier the riders had spoken of at Ghazni was truly failing, Farah was less a place it would fail at than a place it would simply pass through unremarked - one more relay a courier used and forgot. Farrukh's caravan master called it a good place to sleep and a bad place to be remembered, in the same breath, and did not explain further."`

2. `id: "n02_the_checkpoint"`, one choice `"Continue."` → `n03_the_officers_arithmetic`, no effects.
   text: `"A half-dozen mounted men in state colors had a family off the road before Farrukh's caravan even reached the crossing - a father, two children, a grandmother too proud to sit in the dust though she'd clearly been made to. Nasa people, by the accent, though nobody had asked their names before assuming the worst of them. Their leader sat his horse with the particular stillness of a man who did not need to raise his voice to be obeyed, a stillness Farrukh had learned, since Ghazni, to associate less with rank than with the specific kind of training that produced it."`

3. `id: "n03_the_officers_arithmetic"`, one choice `"Continue."` → `n04_the_choice_at_the_checkpoint`, no effects.
   text: `"He was a {{ghulam|ghulam}} - one of the Turkic soldiers bought young, raised in the palace's own household, and made into the empire's actual sword arm, more reliably loyal to the Sultan than any tribal levy or hereditary noble ever managed to be, or so the arrangement's defenders always said. He looked Farrukh's caravan over the way a man appraises livestock, not unkindly, and said, when Farrukh asked - more from nerves than courage - what the family had done: \"Done. Nothing, probably. Fled something, which is worse for my purposes, because it means somebody above me will ask what fled toward us, and I have no answer that doesn't sound like a confession of a border I can't actually hold.\" He said it without bitterness, a professional stating a professional's problem, and Farrukh understood, not for the first time this journey, that the men enforcing the frontier's edge often believed in its failure more thoroughly than anyone they were failing to protect."`

   Note the gloss token uses `{{ghulam|ghulam}}` (lowercase display text) rather than the macron spelling used in the design doc's prose block - JSON string escaping for `ū` is unnecessary complexity this content doesn't need; plain ASCII `ghulam` as both the id and the display text keeps the file simple and still reads naturally. Apply the same simplification to every other gloss token below: use the plain ASCII term as both the id and the display text (`{{dallal|dallal}}`, `{{amana|amana}}`, `{{ghanima|ghanima}}`, `{{khums|khums}}`), even where the design doc's prose used a macron. The glossary headwords (Task 2) keep the nicer typography; the inline gloss tokens do not need to match the headword's exact styling, only the term id.

4. `id: "n04_the_choice_at_the_checkpoint"`, two choices:
   - `"Tell him they're traveling with you."` → `n05a_vouched`, effects `{"flags": ["vouched_for_the_family_at_farah"], "reputation": {"townsfolk": 2, "ghaznavid_officials": -1}}`
   - `"Say nothing. It isn't your caravan to risk."` → `n05b_uninvolved`, effects `{"flags": ["stayed_uninvolved_at_farah"], "reputation": {"ghaznavid_officials": 1}}`
   text: `"The ghulam's patience, such as it was, had a shape Farrukh could see closing. He glanced at Farrukh's manifest with the same open invitation Sa'id's men had offered back in Teginabad, though this offer had nothing to do with silk or seals: say these are yours, and this becomes simple for both of us. Refuse, and simple stops being available to anyone."`

5. `id: "n05a_vouched"`, one choice `"Continue."` → `n06_after_the_checkpoint`, no effects.
   text: `"Farrukh said it before he'd fully decided to - the same reflex, he would think later, that had put him at his father's grave promising a debt nobody made him promise. The ghulam weighed the lie for exactly as long as it took to decide it wasn't worth the paperwork of disbelieving, and let the family fall in with the caravan's rear, the grandmother's eyes on Farrukh the entire time with an expression that was not quite gratitude - more like a woman recalculating how much she now owed a stranger, which was a feeling Farrukh understood better than he wanted to."`

6. `id: "n05b_uninvolved"`, one choice `"Continue."` → `n06_after_the_checkpoint`, no effects.
   text: `"Farrukh said nothing, and the caravan master, without being asked, steered their party wide around the checkpoint's business as if it were weather. Whatever happened to the family happened behind him; he did not look back to find out, and told himself, not quite believing it, that a man carrying one dead man's debt already had no coin left over to spend on anyone else's trouble."`

7. `id: "n06_after_the_checkpoint"`, one choice `"Continue."` → `n07_arrival_at_the_caravanserai`, no effects.
   text: `"He found himself, walking the last stretch into Farah proper, doing the counting exercise again - the one the old letter-writer in Ghazni had given him without quite meaning to teach it. Whether he'd claimed the family or let them pass him by, the choice itself had not been his to avoid; only its shape had been his to choose, the way a man floating in Avicenna's old thought-experiment, suspended in darkness with every limb cut off from sensation, still could not stop being a self that reasoned and chose, even stripped of every borrowed thing that usually told him who he was. His father's debt was borrowed obligation, freely re-chosen. This one - a stranger's family, a soldier's arithmetic he'd either fed or starved with one sentence - had not even offered him the dignity of a grave to swear it at. He had simply had to decide, in a moment, what kind of man made that decision, and live afterward with whichever one had answered."`

8. `id: "n07_arrival_at_the_caravanserai"`, one choice `"Continue."` → `n08_umm_kavus_introduced`, no effects.
   text: `"The caravanserai occupied the better half of what passed for Farah's center - low, mud-brick, built around a courtyard where animals and men shared space with the practiced indifference of people who had done this every night of their working lives. A Balkh horse-trader argued prices with a man Farrukh didn't recognize; a Sistan indigo-seller's mules stood tethered near enough that the dye-stained sacks perfumed half the yard. Trade did not stop for a failing frontier, Farrukh was beginning to understand. It simply grew more careful about which roads it trusted."`

9. `id: "n08_umm_kavus_introduced"`, one choice `"Continue."` → `n09_umm_kavus_backstory`, no effects.
   text: `"The caravanserai was kept by a woman the road called Umm-Kavus - Kavus being, Farrukh gathered before he'd even set down his load, a son three years dead of a fever that had also taken the husband who'd built the place. She ran it now alone, with the particular competence of someone who had stopped expecting help and adjusted accordingly, weighing new arrivals for trouble the way Mihran in Bost had weighed silver - and serving, Farrukh would learn before the night was through, as Farah's {{dallal|dallal}} besides: broker, message-carrier, and informal banker to whichever merchants trusted her enough to use her, on nothing sturdier than {{amana|amana}} - a trust deposited on reputation, not on any paper a qadi would recognize."`

10. `id: "n09_umm_kavus_backstory"`, one choice `"Continue."` → `n10_the_price_of_a_bed`, no effects.
    text: `"Farrukh asked her, once the introductions were done, why she'd kept the caravanserai instead of selling it and going to family somewhere easier. She looked at him for a moment the way Mihran had looked at him in Bost - recognizing something before being told it. \"Because it was his,\" she said, \"and because keeping a thing running is a way of arguing with the fact that the man who built it isn't. You'll understand that better than most travelers I get through here, I think, carrying what you're carrying.\" She did not ask what, specifically, he was carrying. She didn't need to; men his age traveling alone on this road were carrying some version of the same thing, and she had learned, she said, not to make them say it aloud before she'd fed them."`

11. `id: "n10_the_price_of_a_bed"`, two choices:
    - `"Pay what she asks."` → `n11a_paid_full`, effects `{"coin_spent_dirham_equivalent": 15.0, "reputation": {"trading_families": 1}}`
    - `"Haggle her down."` → `n11b_haggled`, effects `{"coin_spent_dirham_equivalent": 6.0}`
    text: `"She named a price for a room, feed for the animals, and a meal that did not pretend to be more than it was - lentils, bread, a name pronounced like a formality rather than an introduction. It was, Farrukh judged, a fair price for a woman running the last real roof before empty country. It was also, by the custom of every bazaar he'd ever stood in, a price that expected to be argued with."`

12. `id: "n11a_paid_full"`, one choice `"Continue."` → `n12_the_common_room`, no effects.
    text: `"Farrukh counted out her full price without a word of argument, and something in her posture eased by a fraction she didn't announce - not gratitude exactly, more the relief of a woman who'd braced for one more traveler treating her arithmetic as an opening bid. \"Not everyone does that,\" she said, in the tone of someone filing the fact away rather than thanking him for it."`

13. `id: "n11b_haggled"`, one choice `"Continue."` → `n12_the_common_room`, no effects.
    text: `"Farrukh talked her down the way his father had taught him without ever calling it teaching - patiently, without insult, treating her number as a starting position rather than an offense. She gave ground exactly as far as a woman running the only inn for a day's ride needed to and not a hand's width further, and seemed, if anything, to respect the attempt more than she would have respected silent payment. Coin was coin either way; what a man did with the asking was its own kind of introduction."`

14. `id: "n12_the_common_room"`, two choices:
    - `"Continue."` (always available, no `requires_flag`) → `n13_two_doors`, no effects.
    - `"See how the family is settling in."`, `requires_flag: "vouched_for_the_family_at_farah"` → `n12x_the_family_again`, no effects.
    text: `"Supper ran long, the way it does at the last real stop before empty country - travelers trading news the way they'd trade goods, weighing each rumor's worth before passing it on. Someone had heard Sarakhs's garrison had been reinforced; someone else swore the opposite, that it had been quietly thinned to reinforce somewhere closer to Ghazni. Nobody at the table had anything reliable to say about Nasa beyond what Farrukh had already carried out of the capital himself, which told him, more than any single rumor did, how far that particular piece of bad news had already traveled ahead of accurate detail."`

15. `id: "n12x_the_family_again"`, one choice `"Continue."` → `n13_two_doors`, effects `{"reputation": {"townsfolk": 1}}`.
    text: `"The grandmother found him before he found her - upright now, dust brushed off with what dignity the road allowed, the children asleep somewhere behind her. She didn't thank him, exactly; she told him, instead, the name of the village they'd left and the name of the one they hoped still existed for them to reach, as if trusting a near-stranger with two names was its own kind of payment. \"You didn't have to know either of those,\" she said. \"Most men who help you don't want to know what they've helped with.\" It was, Farrukh thought, a fair description of most of what he'd done since his father's grave."`

16. `id: "n13_two_doors"`, two choices:
    - `"Ask her plainly about it."` (always available, no `requires_flag`) → `n14_the_choice`, no effects.
    - `"Mention you already have a name from Bost."`, `requires_flag: "pressed_mihran_for_the_name"` → `n13x_the_name_already_known`, no effects.
    text: `"Over the meal, in the unhurried way innkeepers dispense information they've decided is safe, Umm-Kavus mentioned - not quite offering it, not quite withholding it - that a name like the one on the paper Farrukh was chasing could be found two ways in a place like Farah. She herself moved money for merchants who trusted her network of couriers and correspondents, the same quiet channels that had once carried her late husband's trade; if the second mark's name ran through anyone's books, it likely ran through someone she could ask. Or - and here her voice flattened slightly - there was a man on the caravanserai's far edge, a former soldier named Tahir, who dealt in goods that had come west with the army rather than with any merchant's manifest, and who made a habit of knowing things that moved through channels less concerned with anyone's good opinion."`

17. `id: "n13x_the_name_already_known"`, one choice `"Continue."` → `n14_the_choice`, effects `{"flags": ["confirmed_the_name_at_farah"]}`.
    text: `"Farrukh told her the name Mihran had given him under duress in Bost. Umm-Kavus went still in the same particular way Mihran himself had - a woman recognizing a debt she hadn't been told she owed. \"Then you don't need me to find it,\" she said slowly, \"only to be sure of what you've already got. That, at least, I can still help with, cheaply.\""`

18. `id: "n14_the_choice"`, two choices:
    - `"Go to Umm-Kavus's channel."` → `n15a_golnars_channel`, effects `{"flags": ["chose_golnars_channel"], "reputation": {"trading_families": 1}}`
    - `"Seek out Tahir."` → `n15b_finding_tahir`, effects `{"flags": ["chose_tahirs_price"], "reputation": {"trading_families": -1}}`
    text: `"She laid the choice out for him as plainly as Mihran never quite had: her own channels would find the name cleanly, honestly, the way her husband had always done business, but it would cost coin and take the better part of two days he didn't have to spare. Tahir would have it faster, possibly by nightfall, and would not want coin at all - men like Tahir dealt in favors, not dirhams, and a favor owed to a man who traded in war's leftovers was not the kind of debt Farrukh's father's kafala had prepared him to carry."`

19. `id: "n15a_golnars_channel"`, one choice `"Continue."` → `n16a_the_wait`, no effects.
    text: `"Umm-Kavus sent word through whoever she sent word through - Farrukh never saw a courier leave, only understood, two days later, that one must have come and gone - and did not ask him for anything beyond the fee she'd already quoted, paid in advance, no argument on either side this time."`

20. `id: "n16a_the_wait"`, one choice `"Continue."` → `n17a_the_name_given_cleanly`, no effects.
    text: `"The two days passed slower than any two days had a right to. Farrukh made himself useful around the caravanserai rather than sit with his own thoughts uninterrupted - mending a strap, watering animals that weren't his, anything with an end he could see. Umm-Kavus caught him at it on the second afternoon and told him, not unkindly, that he didn't have to earn his keep twice. \"I know,\" he said, and kept mending the strap anyway, because the alternative was counting, again, everything that was and wasn't his to carry, and he had done enough of that arithmetic for one week."`

21. `id: "n17a_the_name_given_cleanly"`, one choice `"Continue."` → `n18a_departure_farah_mystery`, effects `{"flags": ["knows_the_second_marks_name"], "reputation": {"trading_families": 1}}`.
    text: `"The answer came back written in a hand Farrukh didn't recognize, on paper that had clearly traveled further than Farah: a name, a city - Rayy again, unsurprisingly, the same house whose seal Mihran had first recognized - and nothing else, no explanation, no warning, exactly the transaction it had been sold as. Farrukh had what he'd paid for and nothing he hadn't. It felt, oddly, like the cleanest thing to happen to him since his father's death, which was its own kind of unsettling."`

22. `id: "n18a_departure_farah_mystery"`, `choices: []`, `"next_chapter_id": null`.
    text: `"He left Farah two days later than planned and, by his own accounting, no poorer in anything that mattered - a debt to Umm-Kavus fully paid, a name in his satchel that owed him nothing further, and a growing, uncomfortable awareness that every clean answer on this road seemed to cost exactly what it claimed to and not one dirham less. She saw him off at the gate herself, which she said she didn't do for every traveler, and told him to come back through with better news than he'd brought this time, if the road ever let him. The track west went on toward Herat and whatever waited there; he did not yet know that the name in his satchel was about to matter more than the road itself."`

23. `id: "n15b_finding_tahir"`, one choice `"Continue."` → `n16b_tahirs_price`, no effects.
    text: `"The caravanserai's far edge was where Umm-Kavus's orderly economy gave way to something looser - a lean-to, a cookfire not quite public, goods stacked with the specific carelessness of a man who didn't expect anyone with authority to ask him to account for them. Tahir kept his own hours and his own company, and the other travelers gave his corner the wide berth people give a dog they aren't sure is friendly."`

24. `id: "n16b_tahirs_price"`, one choice `"Continue."` → `n17b_the_war_he_carries`, no effects.
    text: `"He was younger than Farrukh expected for a veteran of a campaign three years gone, and tired in a way that had nothing to do with the road. He named the second mark's owner before Farrukh had finished asking, the way a man recites something he's said before and will say again - a name, a house, delivered flat, already priced in his head before Farrukh had offered anything."`

25. `id: "n17b_the_war_he_carries"`, one choice `"Continue."` → `n18b_the_favor_owed`, no effects.
    text: `"Farrukh, against his better judgment, asked him what it had actually been like - the campaign, the wealth, the stories that made it back to Ghazni's bazaars taller than anything a soldier could have carried home himself. Tahir laughed, once, without much humor in it. \"Twenty million dinars, a temple's doors made of sandalwood, gates men still swear were dragged all the way back to Ghazni,\" he said. \"Ask ten men who were actually there and you'll get ten different numbers, all of them smaller than the one you've heard, and none of us in a position to correct the ones telling it bigger, because the bigger version pays better in a bazaar story than the truth does. What I carried back fit in two saddlebags and a debt to a quartermaster who overcharged every soldier under him for the privilege of a horse. That's the campaign nobody sings about.\" He didn't say it like a man asking for pity, only like a man setting a ledger straight for its own sake, the way Farrukh's father might have, if his father had ever seen anything worth calling war."`

26. `id: "n18b_the_favor_owed"`, one choice `"Continue."` → `n19b_departure_farah_plunder`, effects `{"flags": ["knows_the_second_marks_name", "owes_tahir_a_favor"], "reputation": {"townsfolk": -1}}`.
    text: `"\"No coin,\" Tahir said, when Farrukh reached for his purse out of habit. \"I don't need coin. I need someone who isn't me to carry a message to a house in Herat, when you're passing through it, to a man who won't take it from my hand.\" He did not say why the man wouldn't take it from his hand, and Farrukh, looking at the wrapped goods stacked against the wall - things that had come west as {{ghanima|ghanima}}, the spoils of a war three years cold, never logged, never taxed, or taxed only once, the {{khums|khums}} skimmed off the top for a sultan who would never see this particular bundle again - decided he did not especially want to ask. He had his name. He also, he understood with a clarity that felt almost physical, now owed something to a man who traded in the leftovers of Mahmud's wars, and had no idea yet what that something would turn out to cost."`

27. `id: "n19b_departure_farah_plunder"`, `choices: []`, `"next_chapter_id": null`.
    text: `"He left Farah on schedule, a day ahead of where Umm-Kavus's channel would have put him, a name in his satchel that had cost him nothing he could count and something he suspected he'd be counting for a long while yet. The wrapped bundle Tahir had pressed him to carry rode in his own pack now, unexamined, addressed to a house in Herat he had never heard of until an hour ago. Somewhere behind him, he understood, Mahmud's campaigns had left a residue that didn't stay in Bost's painted walls, and didn't stay in a soldier's two saddlebags either - it moved, the way everything on this road moved, through hands willing to carry it for the right kind of debt, and his hands, he was fairly sure, had just joined them."`

Every node other than the two terminal nodes needs `"choices"` populated as described; effects objects that have no `"flags"` or no `"reputation"` key simply omit that key (don't write empty arrays/dicts unless the node genuinely has both) — follow the exact effects shapes given per node above.

- [ ] **Step 4: Run tests to verify they pass**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_farah_dialogue_content.gd -gexit`
Expected: PASS, all tests.

- [ ] **Step 5: Commit**

```bash
git add content/chapters/chapter_03_farah/farah.json tests/unit/test_farah_dialogue_content.gd
git commit -m "feat: add Farah chapter dialogue content"
```

---

### Task 4: Manifest wiring and cross-chapter integration tests

**Files:**
- Modify: `content/chapters/manifest.json`
- Modify: `tests/unit/test_chapter_view.gd`

**Interfaces:**
- Consumes: Task 1's per-node `next_chapter_id` resolution, Task 2's `farah_terms.json`, Task 3's `farah.json`.
- Produces: a working Prologue → Teginabad → Bost → Farah auto-chain, in both of Farah's branches, verified end to end.

- [ ] **Step 1: Wire the manifest**

In `content/chapters/manifest.json`, change `chapter_02_bost`'s `next_chapter_id` from `null` to `"chapter_03_farah"`, and add a new entry:

```json
	"chapter_03_farah": {
		"dialogue_path": "res://content/chapters/chapter_03_farah/farah.json",
		"glossary_path": "res://content/glossary/farah_terms.json",
		"next_chapter_id": null
	}
```

(Chapter-level `next_chapter_id: null` here is effectively unreachable — both of Farah's terminal nodes always carry their own `next_chapter_id`, currently both `null` too, until Chapter 4's two variants exist. It stays `null` rather than pointing anywhere, matching how every chapter's leading edge has looked in this codebase so far.)

- [ ] **Step 2: Update the renamed full-playthrough test**

The existing test `test_a_full_playthrough_carries_prologue_flags_and_writes_each_chapter_save` (around line 129 of `tests/unit/test_chapter_view.gd`) currently asserts Bost is the last chapter. Now that Bost leads into Farah, extend it. Rename it and update its body from:

```gdscript
func test_a_full_playthrough_carries_prologue_flags_and_writes_each_chapter_save():
	# Clear any saves left by an earlier run first, or the file_exists() assertions below
	# would pass on stale files instead of on ones this playthrough actually wrote.
	var teginabad_save_path := "user://borrowed_fortune_chapter_01_teginabad.json"
	var bost_save_path := "user://borrowed_fortune_chapter_02_bost.json"
	for path in [teginabad_save_path, bost_save_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		assert_false(FileAccess.file_exists(path), "the previous save should be cleared before the playthrough starts")

	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter_by_id("chapter_00_prologue")
	# Press "first choice" until the story is over. The Prologue's auto-transition lands on a
	# non-terminal node, so available_choices() keeps being non-empty and the same loop keeps
	# walking through Teginabad and on into Bost, since Teginabad's manifest entry now points
	# at chapter_02_bost too. Checking the condition before each press matters - pressing into
	# an empty available_choices() would re-render and re-fire _save_and_finish.
	var presses := 0
	while chapter_view.dialogue_engine.available_choices().size() > 0 and presses < 200:
		chapter_view._on_choice_pressed(0)
		presses += 1
	assert_lt(presses, 200, "the playthrough should end on its own, not hit the safety cap")

	assert_eq(chapter_view.chapter_id, "chapter_02_bost")
	assert_eq(chapter_view.dialogue_engine.current_node()["id"], "n10_departure_bost")
	assert_eq(chapter_view.next_chapter_id, null, "Bost is the last chapter, so nothing should auto-load after it")
	assert_true(chapter_view.dialogue_engine.flags.get("vowed_kafala", false), "the Prologue's kafala vow flag must survive into Bost")
	assert_true(FileAccess.file_exists(teginabad_save_path), "passing through Teginabad on the way to Bost must still write Teginabad's save file")
	assert_true(FileAccess.file_exists(bost_save_path), "reaching Bost's last line must write its own save file")
```

to:

```gdscript
func test_a_full_playthrough_via_the_mystery_branch_carries_prologue_flags_through_farah():
	# Clear any saves left by an earlier run first, or the file_exists() assertions below
	# would pass on stale files instead of on ones this playthrough actually wrote.
	var teginabad_save_path := "user://borrowed_fortune_chapter_01_teginabad.json"
	var bost_save_path := "user://borrowed_fortune_chapter_02_bost.json"
	var farah_save_path := "user://borrowed_fortune_chapter_03_farah.json"
	for path in [teginabad_save_path, bost_save_path, farah_save_path]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		assert_false(FileAccess.file_exists(path), "the previous save should be cleared before the playthrough starts")

	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter_by_id("chapter_00_prologue")
	# Press "first choice" until the story is over. Every reconverging fork in this chain
	# (Prologue, Teginabad, Bost, and Farah's checkpoint/trade/two-doors forks) lists its
	# always-available choice at index 0, and Farah's true fork's index 0 is the mystery
	# branch (Umm-Kavus's channel) - so "always press 0" walks the whole chain and lands
	# on Farah's mystery-branch terminal node, not the plunder one.
	var presses := 0
	while chapter_view.dialogue_engine.available_choices().size() > 0 and presses < 200:
		chapter_view._on_choice_pressed(0)
		presses += 1
	assert_lt(presses, 200, "the playthrough should end on its own, not hit the safety cap")

	assert_eq(chapter_view.chapter_id, "chapter_03_farah")
	assert_eq(chapter_view.dialogue_engine.current_node()["id"], "n18a_departure_farah_mystery")
	assert_eq(chapter_view.next_chapter_id, null, "Farah's mystery branch has no Chapter 4 yet")
	assert_true(chapter_view.dialogue_engine.flags.get("vowed_kafala", false), "the Prologue's kafala vow flag must survive into Farah")
	assert_true(chapter_view.dialogue_engine.flags.get("knows_the_second_marks_name", false))
	assert_true(FileAccess.file_exists(teginabad_save_path), "passing through Teginabad on the way to Farah must still write Teginabad's save file")
	assert_true(FileAccess.file_exists(bost_save_path), "passing through Bost on the way to Farah must still write Bost's save file")
	assert_true(FileAccess.file_exists(farah_save_path), "reaching Farah's mystery-branch ending must write its own save file")
```

- [ ] **Step 3: Add a dedicated plunder-branch playthrough test**

Append to `tests/unit/test_chapter_view.gd`:

```gdscript
func test_a_full_playthrough_via_the_plunder_branch_reaches_its_own_terminal_node():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter_by_id("chapter_00_prologue")
	# Walk with "always press 0" until Farah's true fork, exactly like the mystery-branch
	# playthrough above - but stop by node id rather than a hardcoded press count, since
	# that count would silently go stale if any earlier chapter's node count ever changes.
	var presses := 0
	while chapter_view.dialogue_engine.current_node().get("id", "") != "n14_the_choice" and presses < 200:
		chapter_view._on_choice_pressed(0)
		presses += 1
	assert_eq(chapter_view.dialogue_engine.current_node()["id"], "n14_the_choice", "should reach Farah's true fork by always taking the first choice through every earlier chapter and fork")
	chapter_view._on_choice_pressed(1) # "Seek out Tahir."
	presses = 0
	while chapter_view.dialogue_engine.available_choices().size() > 0 and presses < 200:
		chapter_view._on_choice_pressed(0)
		presses += 1
	assert_lt(presses, 200, "the plunder branch should end on its own, not hit the safety cap")

	assert_eq(chapter_view.chapter_id, "chapter_03_farah")
	assert_eq(chapter_view.dialogue_engine.current_node()["id"], "n19b_departure_farah_plunder")
	assert_eq(chapter_view.next_chapter_id, null, "Farah's plunder branch has no Chapter 4 yet")
	assert_true(chapter_view.dialogue_engine.flags.get("owes_tahir_a_favor", false))
	assert_true(chapter_view.dialogue_engine.flags.get("knows_the_second_marks_name", false))
	assert_true(FileAccess.file_exists("user://borrowed_fortune_chapter_03_farah.json"))
```

- [ ] **Step 4: Run the ChapterView and cross-chapter tests**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_chapter_view.gd -gexit`
Expected: PASS, including `test_glossary_terms_and_flag_names_are_unique_across_all_manifest_chapters` (around line 159), which walks the manifest generically and needs no changes to pick up `chapter_03_farah` — if it fails, it means a Farah flag name or glossary term id collided with an earlier chapter's; re-check Task 3's flag names and Task 2's term ids against the earlier chapters' before changing this test.

- [ ] **Step 5: Commit**

```bash
git add content/chapters/manifest.json tests/unit/test_chapter_view.gd
git commit -m "feat: wire Farah into the chapter manifest, extend playthrough tests"
```

---

### Task 5: Full-suite verification

**Files:** none (verification only).

**Interfaces:** none.

- [ ] **Step 1: Run the entire suite headless**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`

- [ ] **Step 2: Confirm a clean pass**

Read the full output. Confirm:
- Every test passes (0 failures, 0 errors).
- No float/int comparison warnings (these only show up running the full suite, not individual files — a known gap in this codebase's history; re-check carefully).
- The total test/assert counts increased from the pre-Farah baseline (95 tests / 305 asserts) by roughly the number of new tests this plan added across Tasks 1-4.

If anything is unclean, fix it before proceeding — do not defer to the final whole-branch review.

- [ ] **Step 3: Report**

No commit for this task (verification only). Report the final pass/fail counts in the task report.

---

## Post-Plan Note

Chapter 4 is genuinely two chapters' worth of work now, not one: `n18a_departure_farah_mystery` and `n19b_departure_farah_plunder` both need their own `next_chapter_id` pointing at two different chapter ids, and each of those needs its own content reflecting a different persistent state. Budget planning time accordingly — this is a bigger step-change than any prior "next chapter" transition in this project.
