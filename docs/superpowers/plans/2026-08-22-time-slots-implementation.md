# Named Time Slots Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A city stay you spend — several opportunities, named slots of time, and a record of what you declined.

**Architecture:** A chapter's manifest entry declares named slots. One node in the chapter is marked as the stay hub; its choices are the opportunities, each optionally spending a slot. When the slots run out the engine writes a flag for every opportunity never taken, and the hub's exit choice appears. All gating rides on `_conditions_met()`, which choices and `text_variants` already share.

**Tech Stack:** Godot 4.3, GDScript, GUT (vendored at `addons/gut/`).

**Spec:** `docs/superpowers/specs/2026-08-21-time-slots-design.md`

## Global Constraints

- **Base:** `2cd96f2` (master with PR #7 merged). `DialogueEngine` already has `current_text()` and the shared `_conditions_met()`.
- **Priming a fresh worktree:** `godot --headless --import` (exits 0; do not use `--editor --quit`, which aborts).
- **Full suite:** `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`
- **Single file:** `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/<file>.gd -gexit`
- **Rendered layout check** (needs a display): `godot --path . -s tools/verify_folio_layout.gd` — must exit 0. The colophon grows by a slot name and must not overflow the folio.
- **Known-failing baseline: 22 failing, 1 risky**, all pre-existing content-navigation staleness. Compare against that, never against zero.
- **Do not round-trip content JSON through `json.load`/`json.dump`.** The repo keeps choice objects on single compact lines; `dump` expands every one, turning a 4-line insertion into a 172-line diff. Edit the text directly.
- **A chapter with no `stay` key must behave exactly as it does today.** Every existing chapter stays untouched by this plan.

## Addition found while planning

The spec did not say how the engine knows *which* node is the hub. It matters: once an opportunity is taken, `current_node_id` has moved into that branch, so at the moment the slots run out the hub is no longer current and its untaken choices cannot be found.

This plan marks it explicitly — a node carries `"stay_hub": true` — and the engine remembers the last hub it was on. That makes exhaustion deterministic and lets validation require exactly one hub in a chapter that declares a stay.

---

### Task 1: Slot state and the two new conditions

**Files:**
- Modify: `engine/dialogue/DialogueEngine.gd`
- Test: `tests/unit/test_dialogue_engine.gd`

**Interfaces:**
- Consumes: `_conditions_met()` as merged in PR #7.
- Produces: `DialogueEngine.slots: Array`, `slot_index: int`, `current_slot_name() -> String`, `slots_spent() -> bool`, plus `forbids_flag` and `requires_slots_spent` honoured by `_conditions_met()`.

- [ ] **Step 1: Write the failing test**

Append to `tests/unit/test_dialogue_engine.gd`:

```gdscript
func test_current_slot_name_is_empty_when_no_stay_is_declared():
	var engine := DialogueEngine.new()
	assert_eq(engine.current_slot_name(), "")

func test_current_slot_name_tracks_the_slot_index():
	var engine := DialogueEngine.new()
	engine.slots = ["the first evening", "the next morning"]
	assert_eq(engine.current_slot_name(), "the first evening")
	engine.slot_index = 1
	assert_eq(engine.current_slot_name(), "the next morning")

func test_current_slot_name_is_empty_once_the_slots_are_spent():
	var engine := DialogueEngine.new()
	engine.slots = ["the first evening"]
	engine.slot_index = 1
	assert_eq(engine.current_slot_name(), "")

func test_slots_spent_is_false_when_no_stay_is_declared():
	# A chapter without a stay must behave exactly as it does today, which means an
	# exit gated on requires_slots_spent would be permanently hidden there - so this
	# returning false is deliberate, and Task 6 validates against that mistake.
	var engine := DialogueEngine.new()
	assert_false(engine.slots_spent())

func test_slots_spent_flips_when_the_index_reaches_the_end():
	var engine := DialogueEngine.new()
	engine.slots = ["one", "two"]
	assert_false(engine.slots_spent())
	engine.slot_index = 2
	assert_true(engine.slots_spent())

func test_forbids_flag_hides_a_choice_once_its_flag_is_set():
	var engine := DialogueEngine.new()
	var holder := {"forbids_flag": "already_went"}
	assert_true(engine._conditions_met(holder))
	engine.flags["already_went"] = true
	assert_false(engine._conditions_met(holder))

func test_requires_slots_spent_hides_a_choice_while_time_remains():
	var engine := DialogueEngine.new()
	engine.slots = ["one"]
	var holder := {"requires_slots_spent": true}
	assert_false(engine._conditions_met(holder))
	engine.slot_index = 1
	assert_true(engine._conditions_met(holder))

func test_all_four_conditions_can_combine_on_one_choice():
	var engine := DialogueEngine.new()
	engine.slots = ["one"]
	var holder := {
		"requires_flag": "has_token",
		"forbids_flag": "already_went",
		"requires_reputation": {"faction_id": "officials", "min_score": 1},
		"requires_slots_spent": true,
	}
	engine.flags["has_token"] = true
	engine.reputation["officials"] = 1
	engine.slot_index = 1
	assert_true(engine._conditions_met(holder))
	engine.flags["already_went"] = true
	assert_false(engine._conditions_met(holder), "forbids_flag must still veto")
```

- [ ] **Step 2: Run to verify it fails**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_dialogue_engine.gd -gexit`

Expected: the eight new tests error or fail — `slots`, `slot_index`, `current_slot_name()` and `slots_spent()` do not exist, and `_conditions_met()` ignores the two new keys.

- [ ] **Step 3: Add the state and the conditions**

In `engine/dialogue/DialogueEngine.gd`, beside the existing state:

```gdscript
# Named slots of time for this chapter's stay, supplied by ChapterView from the
# manifest. Empty for a chapter that declares no stay, which must behave exactly as
# it did before this feature existed.
var slots: Array = []
var slot_index: int = 0
```

Then, near `current_text()`:

```gdscript
# The slot the stay is currently in, for display. Empty when the chapter declares no
# stay, or when the stay is spent.
func current_slot_name() -> String:
	if slot_index < 0 or slot_index >= slots.size():
		return ""
	return str(slots[slot_index])

# True once every slot has been spent. Always false where no stay is declared: a
# chapter without slots has no time to run out of.
func slots_spent() -> bool:
	return not slots.is_empty() and slot_index >= slots.size()
```

And extend `_conditions_met()`, before its final `return true`:

```gdscript
	var forbids_flag = condition_holder.get("forbids_flag", null)
	if forbids_flag != null and flags.get(forbids_flag, false):
		return false
	if condition_holder.get("requires_slots_spent", false) and not slots_spent():
		return false
```

- [ ] **Step 4: Run to verify it passes**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_dialogue_engine.gd -gexit`

Expected: PASS. The tests inherited from PR #7 are the proof that adding conditions did not disturb the existing ones.

- [ ] **Step 5: Commit**

```bash
git add engine/dialogue/DialogueEngine.gd tests/unit/test_dialogue_engine.gd
git commit -m "feat: add slot state and the forbids_flag and requires_slots_spent conditions"
```

---

### Task 2: Spending a slot

**Files:**
- Modify: `engine/dialogue/DialogueEngine.gd` (`choose`)
- Test: `tests/unit/test_dialogue_engine.gd`

**Interfaces:**
- Consumes: Task 1's `slot_index`.
- Produces: `choose()` advances `slot_index` when the taken choice carries `spends_slot`.

- [ ] **Step 1: Write the failing test**

```gdscript
func _hub_nodes() -> Array:
	return [
		{
			"id": "hub",
			"stay_hub": true,
			"text": "The city, and time enough for some of it.",
			"choices": [
				{"text": "Visit the widow.", "next_id": "widow", "spends_slot": true,
				 "forbids_flag": "visited_widow", "forgone_flag": "never_visited_widow",
				 "effects": {"flags": ["visited_widow"]}},
				{"text": "Ask after the caravan master.", "next_id": "caravan", "spends_slot": true,
				 "forbids_flag": "asked_caravan", "forgone_flag": "never_asked_caravan",
				 "effects": {"flags": ["asked_caravan"]}},
				{"text": "Ask the innkeeper the day's news.", "next_id": "hub", "effects": {}},
				{"text": "Leave the city.", "next_id": "out", "requires_slots_spent": true, "effects": {}},
			],
		},
		{"id": "widow", "text": "She took the token.", "choices": [{"text": "Back.", "next_id": "hub", "effects": {}}]},
		{"id": "caravan", "text": "He had little to say.", "choices": [{"text": "Back.", "next_id": "hub", "effects": {}}]},
		{"id": "out", "text": "The road again.", "choices": []},
	]

func test_taking_an_opportunity_spends_a_slot():
	var engine := DialogueEngine.new()
	engine.slots = ["the first evening", "the next morning"]
	engine.load_tree(_hub_nodes(), "hub")
	assert_eq(engine.slot_index, 0)
	engine.choose(0) # visit the widow
	assert_eq(engine.slot_index, 1)

func test_a_free_choice_does_not_spend_a_slot():
	var engine := DialogueEngine.new()
	engine.slots = ["the first evening", "the next morning"]
	engine.load_tree(_hub_nodes(), "hub")
	# available_choices() order: widow, caravan, innkeeper, (exit hidden)
	engine.choose(2) # the innkeeper costs nothing
	assert_eq(engine.slot_index, 0)

func test_a_taken_opportunity_stops_being_offered():
	var engine := DialogueEngine.new()
	engine.slots = ["one", "two"]
	engine.load_tree(_hub_nodes(), "hub")
	var before := engine.available_choices().size()
	engine.choose(0)          # widow, sets visited_widow
	engine.choose(0)          # "Back." to the hub
	assert_eq(engine.available_choices().size(), before - 1,
		"the visited opportunity must be hidden by its forbids_flag")

func test_the_exit_is_hidden_until_the_slots_are_spent():
	var engine := DialogueEngine.new()
	engine.slots = ["one"]
	engine.load_tree(_hub_nodes(), "hub")
	for choice in engine.available_choices():
		assert_ne(choice["next_id"], "out", "the exit must not be offered while time remains")
	engine.choose(0) # spend the only slot
	engine.choose(0) # back to the hub
	var exits := 0
	for choice in engine.available_choices():
		if choice["next_id"] == "out":
			exits += 1
	assert_eq(exits, 1, "the exit must appear once the stay is spent")
```

- [ ] **Step 2: Run to verify it fails**

Expected: `test_taking_an_opportunity_spends_a_slot` fails with `[0] expected to equal [1]`; the exit test fails because `requires_slots_spent` is satisfied only after Task 1, but nothing advances the index yet.

- [ ] **Step 3: Advance the index**

In `choose()`, after the flags from `effects` are applied and before `current_node_id` is reassigned:

```gdscript
	if choice.get("spends_slot", false):
		slot_index += 1
```

- [ ] **Step 4: Run to verify it passes**

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add engine/dialogue/DialogueEngine.gd tests/unit/test_dialogue_engine.gd
git commit -m "feat: let a choice spend a slot of the stay"
```

---

### Task 3: Exhaustion writes the forgone flags

The point of the whole feature: declining is recorded as precisely as doing.

**Files:**
- Modify: `engine/dialogue/DialogueEngine.gd`
- Test: `tests/unit/test_dialogue_engine.gd`

**Interfaces:**
- Consumes: Tasks 1 and 2.
- Produces: on the transition that spends the final slot, every hub choice carrying a `forgone_flag` whose opportunity was not taken has that flag set.

- [ ] **Step 1: Write the failing test**

```gdscript
func test_spending_the_last_slot_records_every_untaken_opportunity():
	var engine := DialogueEngine.new()
	engine.slots = ["the only evening"]
	engine.load_tree(_hub_nodes(), "hub")
	engine.choose(0) # visit the widow, spending the only slot
	assert_true(engine.flags.get("visited_widow", false), "the taken one is recorded as taken")
	assert_true(engine.flags.get("never_asked_caravan", false), "the untaken one is recorded as declined")
	assert_false(engine.flags.get("never_visited_widow", false),
		"an opportunity that was taken must not also be recorded as forgone")

func test_forgone_flags_are_not_written_while_time_remains():
	var engine := DialogueEngine.new()
	engine.slots = ["one", "two"]
	engine.load_tree(_hub_nodes(), "hub")
	engine.choose(0)
	assert_false(engine.flags.get("never_asked_caravan", false),
		"there is still a slot left; nothing has been declined yet")

func test_which_opportunity_was_taken_decides_which_flags_are_written():
	# Same single slot as the test above, spent the other way round, so the pairing of
	# taken and declined is proven in both directions rather than once.
	var engine := DialogueEngine.new()
	engine.slots = ["one"]
	engine.load_tree(_hub_nodes(), "hub")
	engine.choose(1) # ask after the caravan master
	assert_true(engine.flags.get("never_visited_widow", false), "the widow was declined")
	assert_false(engine.flags.get("never_asked_caravan", false), "the caravan master was taken")
```

- [ ] **Step 2: Run to verify it fails**

Expected: the first and third fail — no forgone flag is ever written.

- [ ] **Step 3: Remember the hub, and write the flags on exhaustion**

Add state:

```gdscript
# The last stay hub the player stood on. Needed because taking an opportunity moves
# current_node_id into that opportunity's branch, so when the final slot is spent the
# hub is no longer current and its untaken choices could not otherwise be found.
var _hub_node_id: String = ""
```

In `choose()`, before the node moves, record the hub and detect exhaustion:

```gdscript
	if current_node().get("stay_hub", false):
		_hub_node_id = current_node_id
	var was_spent := slots_spent()
	if choice.get("spends_slot", false):
		slot_index += 1
	if slots_spent() and not was_spent:
		_record_forgone_opportunities()
```

And the helper:

```gdscript
# Called once, on the transition that exhausts the stay. An opportunity counts as
# taken if the flag its forbids_flag watches is set - the same flag that hides it
# from the hub - so taken and forgone can never both be recorded.
func _record_forgone_opportunities() -> void:
	var hub: Dictionary = _nodes_by_id.get(_hub_node_id, {})
	for choice in hub.get("choices", []):
		var forgone_flag = choice.get("forgone_flag", null)
		if forgone_flag == null:
			continue
		var taken_flag = choice.get("forbids_flag", null)
		if taken_flag != null and flags.get(taken_flag, false):
			continue
		flags[forgone_flag] = true
```

Note the ordering: this runs *after* `effects` flags are applied, so the opportunity
just taken already has its `forbids_flag` set and is correctly excluded.

- [ ] **Step 4: Run to verify it passes**

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add engine/dialogue/DialogueEngine.gd tests/unit/test_dialogue_engine.gd
git commit -m "feat: record every untaken opportunity when a stay is spent"
```

---

### Task 4: Persist the slot index

**Files:**
- Modify: `engine/save/GameState.gd`
- Test: `tests/unit/test_save_manager.gd`

**Interfaces:**
- Consumes: nothing.
- Produces: `GameState.slot_index: int`, round-tripped through `to_dict()` / `from_dict()`.

- [ ] **Step 1: Write the failing test**

Append to `tests/unit/test_save_manager.gd`:

```gdscript
func test_slot_index_round_trips():
	var state := GameState.new()
	state.slot_index = 2
	var restored := GameState.from_dict(state.to_dict())
	assert_eq(restored.slot_index, 2)

func test_a_save_written_before_slots_existed_loads_at_the_first_slot():
	# Every field in from_dict() is read with a default, which is what makes this
	# change backward-compatible - the first change to this save format.
	var restored := GameState.from_dict({"chapter_id": "chapter_00_prologue"})
	assert_eq(restored.slot_index, 0)
```

- [ ] **Step 2: Run to verify it fails**

Expected: FAIL — `slot_index` is not a property of `GameState`.

- [ ] **Step 3: Add the field**

In `engine/save/GameState.gd`: declare `var slot_index: int = 0`, add `"slot_index": slot_index` to `to_dict()`, and `state.slot_index = int(data.get("slot_index", 0))` to `from_dict()`. The explicit `int()` matters for the same reason `farrukh_wear_stage` casts: JSON parses every number as float.

- [ ] **Step 4: Run to verify it passes**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_save_manager.gd -gexit`

- [ ] **Step 5: Commit**

```bash
git add engine/save/GameState.gd tests/unit/test_save_manager.gd
git commit -m "feat: persist the stay's slot index"
```

---

### Task 5: Wire the chapter and show the slot

**Files:**
- Modify: `scenes/chapter_view/ChapterView.gd` (`load_chapter_by_id`, `_update_colophon`, `_save_and_finish`, `resume`)
- Test: `tests/unit/test_chapter_view.gd`

**Interfaces:**
- Consumes: Tasks 1 and 4.
- Produces: slots supplied from the manifest; the colophon showing the slot; `slot_index` saved and restored.

- [ ] **Step 1: Write the failing test**

```gdscript
func test_the_colophon_names_the_current_slot():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.place_name = "Nishapur"
	chapter_view.dialogue_engine.slots = ["the first evening", "the next morning"]
	chapter_view.dialogue_engine.load_tree([{"id": "n01", "text": "", "choices": []}], "n01")
	chapter_view._update_colophon()
	var colophon: Label = chapter_view.get_node("Folio/FolioMargin/Page/TextColumn/Colophon")
	assert_true(colophon.text.begins_with("Nishapur, the first evening"),
		"got: %s" % colophon.text)

func test_the_colophon_omits_the_slot_when_no_stay_is_declared():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.place_name = "Nishapur"
	chapter_view.dialogue_engine.load_tree([{"id": "n01", "text": "", "choices": []}], "n01")
	chapter_view._update_colophon()
	var colophon: Label = chapter_view.get_node("Folio/FolioMargin/Page/TextColumn/Colophon")
	assert_true(colophon.text.begins_with("Nishapur · "), "got: %s" % colophon.text)

func test_slots_are_taken_from_the_manifest_entry():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter_by_id("fixture_chapter_stay", "res://tests/fixtures/manifest_fixture.json")
	assert_eq(chapter_view.dialogue_engine.slots.size(), 2)
	assert_eq(str(chapter_view.dialogue_engine.slots[0]), "the first evening")
```

The third test needs a `fixture_chapter_stay` entry and its dialogue fixture; Task 7 creates them. Expect it to fail until then, and say so in the run notes rather than pretending otherwise.

- [ ] **Step 2: Run to verify it fails**

Expected: the two colophon tests fail; the manifest test fails on a missing fixture entry.

- [ ] **Step 3: Wire it**

In `load_chapter_by_id()`, beside the existing `place_name` line:

```gdscript
	var stay: Dictionary = entry.get("stay", {})
	dialogue_engine.slots = stay.get("slots", [])
	dialogue_engine.slot_index = 0
```

In `_update_colophon()`, fold the slot into the place name:

```gdscript
	if place_name != "":
		var slot_name := dialogue_engine.current_slot_name()
		parts.append(place_name if slot_name == "" else "%s, %s" % [place_name, slot_name])
```

In `_save_and_finish()`, add `state.slot_index = dialogue_engine.slot_index`. In
`resume()`, restore it alongside the flags:

```gdscript
	if state_data.has("slot_index"):
		dialogue_engine.slot_index = int(state_data["slot_index"])
```

Order matters in `resume()`: `load_chapter_by_id()` resets `slot_index` to 0, so the
restore must happen **after** that call, not before.

- [ ] **Step 4: Run to verify the colophon tests pass**

The manifest test still fails until Task 7. Note it and continue.

- [ ] **Step 5: Rendered layout check**

Run: `godot --path . -s tools/verify_folio_layout.gd`

Expected: exit 0. The colophon is now longer; confirm it has not overflowed.

- [ ] **Step 6: Commit**

```bash
git add scenes/chapter_view/ChapterView.gd tests/unit/test_chapter_view.gd
git commit -m "feat: supply slots from the manifest and name the slot in the colophon"
```

---

### Task 6: Validation

**Files:**
- Modify: `engine/dialogue/DialogueEngine.gd` (`validate_tree`)
- Test: `tests/unit/test_dialogue_engine.gd`

**Interfaces:**
- Consumes: nothing new.
- Produces: three additional error strings.

- [ ] **Step 1: Write the failing test**

```gdscript
func test_validate_tree_rejects_two_stay_hubs():
	var engine := DialogueEngine.new()
	var errors := engine.validate_tree([
		{"id": "a", "stay_hub": true, "text": "one", "choices": []},
		{"id": "b", "stay_hub": true, "text": "two", "choices": []},
	])
	assert_eq(errors.size(), 1)
	assert_string_contains(errors[0], "stay_hub")

func test_validate_tree_rejects_a_forgone_flag_with_no_forbids_flag():
	# Without forbids_flag there is no way to tell taken from untaken, so the
	# opportunity would be recorded as forgone even after being taken.
	var engine := DialogueEngine.new()
	var errors := engine.validate_tree([{
		"id": "a", "stay_hub": true, "text": "one",
		"choices": [{"text": "go", "next_id": "a", "forgone_flag": "never_went"}],
	}])
	assert_eq(errors.size(), 1)
	assert_string_contains(errors[0], "forgone_flag")

func test_validate_tree_rejects_spends_slot_outside_a_hub():
	var engine := DialogueEngine.new()
	var errors := engine.validate_tree([{
		"id": "a", "text": "one",
		"choices": [{"text": "go", "next_id": "a", "spends_slot": true}],
	}])
	assert_eq(errors.size(), 1)
	assert_string_contains(errors[0], "spends_slot")

func test_validate_tree_accepts_a_well_formed_hub():
	var engine := DialogueEngine.new()
	assert_eq(engine.validate_tree(_hub_nodes()), [])
```

- [ ] **Step 2: Run to verify it fails**

Expected: the first three fail with `[0] expected to equal [1]`.

- [ ] **Step 3: Add the checks**

In `validate_tree()`, count hubs across the pass and check each choice:

```gdscript
	var hub_count := 0
```

inside the node loop:

```gdscript
		var is_hub: bool = node.get("stay_hub", false)
		if is_hub:
			hub_count += 1
```

inside the choice loop:

```gdscript
			if choice.get("forgone_flag", null) != null and choice.get("forbids_flag", null) == null:
				errors.append("node '%s' has a choice with a forgone_flag but no forbids_flag, so taking it could not be told from declining it" % node_id)
			if choice.get("spends_slot", false) and not is_hub:
				errors.append("node '%s' has a choice with spends_slot but the node is not a stay_hub" % node_id)
```

and after the loop:

```gdscript
	if hub_count > 1:
		errors.append("chapter declares %d nodes with stay_hub; exactly one is allowed" % hub_count)
```

- [ ] **Step 4: Run to verify it passes**

- [ ] **Step 5: Commit**

```bash
git add engine/dialogue/DialogueEngine.gd tests/unit/test_dialogue_engine.gd
git commit -m "feat: validate stay hubs and slot-spending choices"
```

---

### Task 7: An end-to-end fixture stay

Proves the whole mechanism through `ChapterView` and the manifest, without touching shipped content. Real content is a separate task — the spec is explicit that retrofitting Nishapur is its own job.

**Files:**
- Create: `tests/fixtures/dialogue_fixture_stay.json`
- Modify: `tests/fixtures/manifest_fixture.json`
- Test: `tests/unit/test_chapter_view.gd`

**Interfaces:**
- Consumes: every prior task.
- Produces: `fixture_chapter_stay` in the fixture manifest.

- [ ] **Step 1: Create the dialogue fixture**

`tests/fixtures/dialogue_fixture_stay.json`, matching the repo's compact style:

```json
[
	{
		"id": "hub",
		"stay_hub": true,
		"text": "The city, and time enough for some of it.",
		"choices": [
			{"text": "Visit the widow.", "next_id": "widow", "spends_slot": true, "forbids_flag": "visited_widow", "forgone_flag": "never_visited_widow", "effects": {"flags": ["visited_widow"]}},
			{"text": "Ask after the caravan master.", "next_id": "caravan", "spends_slot": true, "forbids_flag": "asked_caravan", "forgone_flag": "never_asked_caravan", "effects": {"flags": ["asked_caravan"]}},
			{"text": "Sit with the dying scribe.", "next_id": "scribe", "spends_slot": true, "forbids_flag": "sat_with_scribe", "forgone_flag": "never_sat_with_scribe", "effects": {"flags": ["sat_with_scribe"]}},
			{"text": "Leave the city.", "next_id": "out", "requires_slots_spent": true, "effects": {}}
		]
	},
	{"id": "widow", "text": "She took the token without a word.", "choices": [{"text": "Back to the city.", "next_id": "hub", "effects": {}}]},
	{"id": "caravan", "text": "He had less to say than the rumour promised.", "choices": [{"text": "Back to the city.", "next_id": "hub", "effects": {}}]},
	{"id": "scribe", "text": "The scribe's hand had already stopped being his own.", "choices": [{"text": "Back to the city.", "next_id": "hub", "effects": {}}]},
	{"id": "out", "text": "The road again.", "choices": []}
]
```

**Three opportunities against two slots, deliberately.** With two of each, taking
both leaves nothing declined and the forgone-flag path would never be exercised
end to end. A third guarantees exactly one is always left undone.

- [ ] **Step 2: Add the manifest entry**

Add to `tests/fixtures/manifest_fixture.json`, editing the text directly rather than round-tripping the file:

```json
	"fixture_chapter_stay": {
		"dialogue_path": "res://tests/fixtures/dialogue_fixture_stay.json",
		"glossary_path": "res://tests/fixtures/glossary_fixture_a.json",
		"next_chapter_id": null,
		"place_name": "Fixture City",
		"stay": {"slots": ["the first evening", "the next morning"]}
	}
```

- [ ] **Step 3: Write the end-to-end test**

Append to `tests/unit/test_chapter_view.gd`:

```gdscript
func test_a_stay_can_be_spent_and_records_what_was_declined():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter_by_id("fixture_chapter_stay", "res://tests/fixtures/manifest_fixture.json")
	var colophon: Label = chapter_view.get_node("Folio/FolioMargin/Page/TextColumn/Colophon")
	assert_true(colophon.text.begins_with("Fixture City, the first evening"), "got: %s" % colophon.text)

	# First slot: three opportunities and no exit.
	assert_eq(chapter_view.dialogue_engine.available_choices().size(), 3)
	chapter_view._on_choice_pressed(0)   # visit the widow
	chapter_view._on_choice_pressed(0)   # back to the hub
	assert_true(colophon.text.begins_with("Fixture City, the next morning"), "got: %s" % colophon.text)

	# Second slot: the visited opportunity is gone, still no exit.
	assert_eq(chapter_view.dialogue_engine.available_choices().size(), 2)
	chapter_view._on_choice_pressed(0)   # ask after the caravan master, spending the last slot
	chapter_view._on_choice_pressed(0)   # back to the hub

	# Spent: only the exit remains.
	var choices := chapter_view.dialogue_engine.available_choices()
	assert_eq(choices.size(), 1)
	assert_eq(choices[0]["next_id"], "out")

	# And the one there was never time for is recorded as declined, while the two
	# that were taken are not.
	var flags: Dictionary = chapter_view.dialogue_engine.flags
	assert_true(flags.get("never_sat_with_scribe", false), "the scribe was never visited")
	assert_false(flags.get("never_visited_widow", false), "the widow was visited")
	assert_false(flags.get("never_asked_caravan", false), "the caravan master was asked")

func test_the_declined_opportunity_survives_a_save_and_reload():
	# The whole point of recording a declined opportunity is that a later chapter can
	# read it, which means it has to outlive the stay it happened in.
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter_by_id("fixture_chapter_stay", "res://tests/fixtures/manifest_fixture.json")
	chapter_view._on_choice_pressed(0)   # widow
	chapter_view._on_choice_pressed(0)   # back
	chapter_view._on_choice_pressed(0)   # caravan, exhausting the stay
	chapter_view._on_choice_pressed(0)   # back

	var state := GameState.new()
	state.dialogue_flags = chapter_view.dialogue_engine.flags
	state.slot_index = chapter_view.dialogue_engine.slot_index
	var restored := GameState.from_dict(state.to_dict())
	assert_true(restored.dialogue_flags.get("never_sat_with_scribe", false))
	assert_eq(restored.slot_index, 2)
```

- [ ] **Step 4: Run the full suite**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`

Expected: green apart from the 22 pre-existing failures and 1 risky. Task 5's manifest test now passes too.

- [ ] **Step 5: Re-measure and retighten the ratchet**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_consequence_metrics.gd -gexit`

The fixture stay lives in `tests/`, not `content/`, so it must **not** move the numbers. If it does, `_all_chapter_nodes()` is reading somewhere it should not. Leave the constants alone unless real content changed.

- [ ] **Step 6: Commit**

```bash
git add tests/fixtures/dialogue_fixture_stay.json tests/fixtures/manifest_fixture.json tests/unit/test_chapter_view.gd
git commit -m "test: prove a stay end to end through the manifest and ChapterView"
```

---

## Self-Review

**Spec coverage.** The model and its four choice keys → Tasks 1–3 and 7. Engine additions → Tasks 1–3, 6. Save format → Task 4. Visible surface → Task 5. Testing list → distributed. The spec's out-of-scope items — retrofitting Nishapur, and the other subsystems — correctly have no task.

**Addition beyond the spec.** `stay_hub` as an explicit node marker, because the spec never said how the engine identifies the hub, and it cannot be inferred once an opportunity has moved the current node into its branch. Recorded at the top of this plan and validated in Task 6.

**Deliberately not built.** No real city gets a stay. The plan proves the machinery on a fixture and stops, because the spec is explicit that Nishapur's converging branches need restructuring into returning ones, and doing that alongside the machinery would make a machinery bug and a content bug indistinguishable. First real hub is a follow-up task.

**Known ordering hazards, both called out inline.** `_record_forgone_opportunities()` must run *after* `effects` flags are applied, or the opportunity just taken is wrongly recorded as forgone. And `resume()` must restore `slot_index` *after* `load_chapter_by_id()`, which resets it to zero.

**Type consistency.** `slots: Array`, `slot_index: int`, `current_slot_name() -> String`, `slots_spent() -> bool` keep identical signatures from Task 1 onward. `spends_slot`, `forbids_flag`, `forgone_flag`, `requires_slots_spent` and `stay_hub` are spelled identically in the schema, the engine, the validator and the fixtures. Node paths in Task 5's tests match the folio tree as merged in `6173b5f`.
