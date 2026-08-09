# Trading Engine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give the game two small, additive engine capabilities — coin income (`Ledger.receive_dirham_equivalent()`) and reputation-gated dialogue choices (`DialogueEngine` `requires_reputation`) — so Chapter 4A/4B can author real, multi-round haggle scenes where reputation actually changes outcomes and coin can flow both ways.

**Architecture:** Two independent, unrelated engine changes bundled into one small plan since each is trivial on its own: (1) `Ledger` gains an income method symmetric to its existing spend method, wired through a new `ChapterView` effects key; (2) `DialogueEngine` gains a `reputation: Dictionary` field and a `requires_reputation` choice-gate, mirroring the existing `flags`/`requires_flag` mechanism exactly, kept in sync by `ChapterView` on every render.

**Design doc:** `docs/superpowers/specs/2026-08-09-trading-engine-design.md`.

## Global Constraints

- Godot 4.3 floor. Priming command for a fresh checkout, run once before the first test run: `godot --headless --path . --editor --quit`.
- Headless test run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`.
- Engine-layer classes (`engine/**`) are `RefCounted`, never `Node` — no exception in this plan.
- Naming idiom: GDScript's own idiom throughout — `snake_case` functions/variables, `PascalCase` types.
- **Hard rule: `JSON.parse_string` always deserializes numbers as `float`, never `int`.** Any test or runtime code comparing a JSON-sourced value against a GDScript int literal (or assigning it into a typed `int` variable) must cast with `int(...)`. This applies directly to `requires_reputation.min_score` in Task 2.
- This plan is engine-only — no chapter content, no manifest changes. No dialogue content anywhere in the shipped game uses `requires_reputation` or `coin_gained_dirham_equivalent` yet; that starts with Chapter 4A/4B.
- Commit after each task.

---

### Task 1: Coin income — `Ledger.receive_dirham_equivalent()` and its effects key

**Files:**
- Modify: `engine/ledger/Ledger.gd` (after line 17)
- Modify: `scenes/chapter_view/ChapterView.gd` (after line 101, inside `_apply_effects()`)
- Test: `tests/unit/test_ledger.gd` (append)
- Test: `tests/unit/test_chapter_view.gd` (append)

**Interfaces:**
- Produces: `Ledger.receive_dirham_equivalent(amount: float) -> void`, symmetric to the existing `spend_dirham_equivalent()` — both operate on the same `spent_dirham_equivalent` accumulator, in opposite directions. `ChapterView._apply_effects()` now handles an optional `"coin_gained_dirham_equivalent"` effects key by calling this method, mirroring the existing `"coin_spent_dirham_equivalent"` handling immediately above it.
- Consumes: nothing from elsewhere in this plan — fully independent of Task 2.

- [ ] **Step 1: Write the failing Ledger tests**

Append to `tests/unit/test_ledger.gd`:

```gdscript
func test_receive_dirham_equivalent_increases_total_wealth():
	var ledger := Ledger.new()
	ledger.receive_dirham_equivalent(20.0)
	assert_almost_eq(ledger.total_wealth_dirham_equivalent(), 20.0, 0.0001)

func test_receive_and_spend_dirham_equivalent_net_correctly():
	var ledger := Ledger.new()
	ledger.receive_dirham_equivalent(20.0)
	ledger.spend_dirham_equivalent(6.0)
	assert_almost_eq(ledger.total_wealth_dirham_equivalent(), 14.0, 0.0001)
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_ledger.gd -gexit`
Expected: FAIL — `receive_dirham_equivalent` doesn't exist yet.

- [ ] **Step 3: Implement `Ledger.receive_dirham_equivalent()`**

In `engine/ledger/Ledger.gd`, immediately after the existing `spend_dirham_equivalent()` method (currently lines 16-17):

```gdscript
func spend_dirham_equivalent(amount: float) -> void:
	spent_dirham_equivalent += amount

func receive_dirham_equivalent(amount: float) -> void:
	spent_dirham_equivalent -= amount
```

- [ ] **Step 4: Run Ledger tests to verify they pass**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_ledger.gd -gexit`
Expected: PASS, all tests including the pre-existing ones.

- [ ] **Step 5: Write the failing ChapterView test**

Append to `tests/unit/test_chapter_view.gd`:

```gdscript
func test_apply_effects_with_coin_gained_dirham_equivalent_receives_into_the_ledger():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view._apply_effects({"coin_gained_dirham_equivalent": 20.0})
	assert_almost_eq(chapter_view.ledger.total_wealth_dirham_equivalent(), 20.0, 0.0001)
```

- [ ] **Step 6: Run test to verify it fails**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_chapter_view.gd -gexit`
Expected: FAIL — `_apply_effects()` doesn't recognize `"coin_gained_dirham_equivalent"` yet, so the ledger stays at 0.0.

- [ ] **Step 7: Implement the `_apply_effects()` change**

In `scenes/chapter_view/ChapterView.gd`, change `_apply_effects()` (currently lines 93-101) from:

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
	if effects.has("coin_gained_dirham_equivalent"):
		ledger.receive_dirham_equivalent(effects["coin_gained_dirham_equivalent"])
```

- [ ] **Step 8: Run test to verify it passes**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_chapter_view.gd -gexit`
Expected: PASS, all tests.

- [ ] **Step 9: Commit**

```bash
git add engine/ledger/Ledger.gd scenes/chapter_view/ChapterView.gd tests/unit/test_ledger.gd tests/unit/test_chapter_view.gd
git commit -m "feat: add coin income to Ledger and its effects key"
```

---

### Task 2: Reputation-gated dialogue choices

**Files:**
- Modify: `engine/dialogue/DialogueEngine.gd` (line 5 area, and lines 60-64)
- Modify: `scenes/chapter_view/ChapterView.gd` (lines 71-73, `_render_current_node()`)
- Test: `tests/unit/test_dialogue_engine.gd` (append)
- Test: `tests/unit/test_chapter_view.gd` (append)

**Interfaces:**
- Produces: `DialogueEngine.reputation: Dictionary` (default `{}`, shape `{faction_id: int}` — structurally identical to what `ReputationTracker.to_dict()` returns). A choice may carry `"requires_reputation": {"faction_id": String, "min_score": <number>}`; `_choice_is_available()` hides it unless `reputation.get(faction_id, 0) >= int(min_score)`. Composes with `requires_flag` — a choice with both must satisfy both.
- Produces: `ChapterView._render_current_node()` now syncs `dialogue_engine.reputation = reputation_tracker.to_dict()` on every render (covers both the initial render after `load_chapter()` and every render after a choice is pressed, since both paths call `_render_current_node()`).
- Consumes: nothing from Task 1 — fully independent.

- [ ] **Step 1: Write the failing DialogueEngine tests**

Append to `tests/unit/test_dialogue_engine.gd`:

```gdscript
func test_reputation_gated_choice_hidden_until_reputation_met():
	var nodes := [
		{
			"id": "n1",
			"text": "A merchant sizes you up.",
			"choices": [
				{"text": "Always available.", "next_id": "n2", "effects": {}},
				{"text": "Invoke your standing.", "next_id": "n2", "requires_reputation": {"faction_id": "trading_families", "min_score": 2}, "effects": {}},
			],
		},
		{"id": "n2", "text": "The end.", "choices": []},
	]
	var engine := DialogueEngine.new()
	engine.load_tree(nodes, "n1")
	assert_eq(engine.available_choices().size(), 1)

	engine.reputation = {"trading_families": 2}
	assert_eq(engine.available_choices().size(), 2)

func test_reputation_gated_choice_uses_at_least_semantics():
	var nodes := [
		{
			"id": "n1",
			"text": "A merchant sizes you up.",
			"choices": [
				{"text": "Invoke your standing.", "next_id": "n2", "requires_reputation": {"faction_id": "trading_families", "min_score": 2}, "effects": {}},
			],
		},
		{"id": "n2", "text": "The end.", "choices": []},
	]
	var engine := DialogueEngine.new()
	engine.load_tree(nodes, "n1")
	engine.reputation = {"trading_families": 5}
	assert_eq(engine.available_choices().size(), 1, "5 >= 2, the choice should be visible")

	engine.reputation = {"trading_families": 1}
	assert_eq(engine.available_choices().size(), 0, "1 < 2, the choice should be hidden")

func test_requires_flag_and_requires_reputation_can_combine():
	var nodes := [
		{
			"id": "n1",
			"text": "Complex gate.",
			"choices": [
				{"text": "Needs both.", "next_id": "n2", "requires_flag": "met_the_merchant", "requires_reputation": {"faction_id": "trading_families", "min_score": 2}, "effects": {}},
			],
		},
		{"id": "n2", "text": "The end.", "choices": []},
	]
	var engine := DialogueEngine.new()
	engine.load_tree(nodes, "n1")
	engine.reputation = {"trading_families": 5}
	assert_eq(engine.available_choices().size(), 0, "flag not set yet, reputation alone isn't enough")

	engine.flags["met_the_merchant"] = true
	assert_eq(engine.available_choices().size(), 1, "both conditions now met")
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_dialogue_engine.gd -gexit`
Expected: FAIL — `reputation` field and `requires_reputation` gating don't exist yet (either a parser error accessing `engine.reputation`, or the gated choices show up when they shouldn't).

- [ ] **Step 3: Implement the DialogueEngine changes**

In `engine/dialogue/DialogueEngine.gd`, change line 5 from:

```gdscript
var flags: Dictionary = {}
```

to:

```gdscript
var flags: Dictionary = {}
var reputation: Dictionary = {}
```

Change `_choice_is_available()` (currently lines 60-64) from:

```gdscript
func _choice_is_available(choice: Dictionary) -> bool:
	var requires_flag = choice.get("requires_flag", null)
	if requires_flag == null:
		return true
	return flags.get(requires_flag, false)
```

to:

```gdscript
func _choice_is_available(choice: Dictionary) -> bool:
	var requires_flag = choice.get("requires_flag", null)
	if requires_flag != null and not flags.get(requires_flag, false):
		return false
	var requires_reputation = choice.get("requires_reputation", null)
	if requires_reputation != null:
		var faction_id: String = requires_reputation["faction_id"]
		var min_score: int = int(requires_reputation["min_score"])
		if reputation.get(faction_id, 0) < min_score:
			return false
	return true
```

- [ ] **Step 4: Run DialogueEngine tests to verify they pass**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_dialogue_engine.gd -gexit`
Expected: PASS, all tests including the pre-existing ones (in particular, `test_gated_choice_hidden_until_flag_is_set_then_appears` must still pass unchanged — the `requires_flag`-only path must behave exactly as before).

- [ ] **Step 5: Write the failing ChapterView integration test**

Append to `tests/unit/test_chapter_view.gd`:

```gdscript
func test_reputation_changes_are_synced_into_the_dialogue_engine_before_rendering():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.reputation_tracker.adjust_reputation("trading_families", 3)
	chapter_view._render_current_node()
	assert_eq(chapter_view.dialogue_engine.reputation.get("trading_families", 0), 3)
```

- [ ] **Step 6: Run test to verify it fails**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_chapter_view.gd -gexit`
Expected: FAIL — `dialogue_engine.reputation` stays `{}` since nothing syncs it yet.

- [ ] **Step 7: Implement the `_render_current_node()` sync**

In `scenes/chapter_view/ChapterView.gd`, change `_render_current_node()` (currently lines 71-73) from:

```gdscript
func _render_current_node() -> void:
	var node := dialogue_engine.current_node()
	narration_label.text = GlossedTextParser.parse_to_bbcode(node.get("text", ""))
```

to:

```gdscript
func _render_current_node() -> void:
	dialogue_engine.reputation = reputation_tracker.to_dict()
	var node := dialogue_engine.current_node()
	narration_label.text = GlossedTextParser.parse_to_bbcode(node.get("text", ""))
```

This one line covers both cases a chapter needs: the first render right after `load_chapter()` (so a chapter's opening nodes see reputation already earned in an earlier chapter — `reputation_tracker` is never recreated between chapters, so its data already carries forward; without this line, `dialogue_engine.reputation` would incorrectly start empty on every new chapter load), and every render after a choice is pressed (so a reputation change from the choice just made is visible immediately).

- [ ] **Step 8: Run test to verify it passes, then run the full suite**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_chapter_view.gd -gexit`
Expected: PASS, all tests.

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`
Expected: PASS, no new failures, no new warnings — in particular, every existing full-playthrough test (Prologue through Farah, both branches) must be unaffected, since none of their content uses `requires_reputation` and the sync is a no-op when a node has no such choice.

- [ ] **Step 9: Commit**

```bash
git add engine/dialogue/DialogueEngine.gd scenes/chapter_view/ChapterView.gd tests/unit/test_dialogue_engine.gd tests/unit/test_chapter_view.gd
git commit -m "feat: add reputation-gated dialogue choices"
```

---

### Task 3: Full-suite verification

**Files:** none (verification only).

**Interfaces:** none.

- [ ] **Step 1: Run the entire suite headless**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`

- [ ] **Step 2: Confirm a clean pass**

Confirm: every test passes, no float/int comparison warnings (only visible running the full suite, not individual files — check carefully), and the total test/assert counts increased from the pre-trading-engine baseline (119 tests / 436 asserts) by roughly the number of new tests this plan added (2 Ledger + 1 ChapterView in Task 1, 3 DialogueEngine + 1 ChapterView in Task 2 — 7 new tests).

- [ ] **Step 3: Report**

No commit for this task (verification only). Report the final pass/fail counts in the task report.

---

## Post-Plan Note

This plan adds capability, not content — nothing in the shipped game exercises `requires_reputation` or `coin_gained_dirham_equivalent` yet. Chapter 4A and 4B are the first real consumers; both should be planned assuming these two primitives already exist and are tested, not re-specified.
