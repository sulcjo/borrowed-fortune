# Delayed Consequences Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let a decision made in one city change how a later city reads, without adding nodes.

**Architecture:** A node gains an optional `text_variants` array, selected by the same `requires_flag` / `requires_reputation` conditions choices already use. `DialogueEngine` resolves it; `ChapterView` asks for resolved text instead of raw text. Then an authoring pass wires the 24 flags that are currently set and never read.

**Tech Stack:** Godot 4.3, GDScript, GUT (vendored at `addons/gut/`).

**Spec:** `docs/superpowers/specs/2026-08-21-delayed-consequences-design.md`

## Global Constraints

- **Godot 4.3**, binary on PATH at `/home/sulcjo/.local/bin/godot`.
- **Full suite:** `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`
- **Single file:** `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/<file>.gd -gexit`
- **Rendered layout check** (needs a display, not headless): `godot --path . -s tools/verify_folio_layout.gd` — must still exit 0, since variant prose is longer or shorter than base and must not break the folio.
- **Class cache:** `class_name` registration lives in gitignored `.godot/global_script_class_cache.cfg`. This plan adds no new `class_name`, so no priming is needed. If a fresh worktree cannot resolve existing classes, see the README's "Running the tests" section.
- **Known-failing baseline: 22 failing tests and 1 risky**, all pre-existing content-navigation staleness. Measure before starting and compare against that number, never against zero.
- **Content changes are exempt from GUT maintenance** by standing project rule — but that exemption does not cover the per-thread tests this plan adds, which are the mechanism keeping the threads alive.
- `text` stays mandatory on every node and is the unconditional reading. All 229 nodes already have non-empty text.

---

### Task 1: Extract the condition predicate

Pure refactor, no behaviour change. Choices and text variants must apply identical rules; two implementations would drift.

**Files:**
- Modify: `engine/dialogue/DialogueEngine.gd:64-75` (`_choice_is_available`)
- Test: `tests/unit/test_dialogue_engine.gd`

**Interfaces:**
- Consumes: nothing.
- Produces: `DialogueEngine._conditions_met(condition_holder: Dictionary) -> bool`, honouring `requires_flag` and `requires_reputation`.

- [ ] **Step 1: Write the failing test**

Append to `tests/unit/test_dialogue_engine.gd`:

```gdscript
func test_conditions_met_accepts_a_holder_with_no_conditions():
	var engine := DialogueEngine.new()
	assert_true(engine._conditions_met({}))

func test_conditions_met_honours_requires_flag():
	var engine := DialogueEngine.new()
	assert_false(engine._conditions_met({"requires_flag": "spoke_now"}))
	engine.flags["spoke_now"] = true
	assert_true(engine._conditions_met({"requires_flag": "spoke_now"}))

func test_conditions_met_honours_requires_reputation():
	var engine := DialogueEngine.new()
	var holder := {"requires_reputation": {"faction_id": "officials", "min_score": 2}}
	assert_false(engine._conditions_met(holder))
	engine.reputation["officials"] = 2
	assert_true(engine._conditions_met(holder))

func test_conditions_met_requires_both_when_both_are_present():
	var engine := DialogueEngine.new()
	var holder := {
		"requires_flag": "spoke_now",
		"requires_reputation": {"faction_id": "officials", "min_score": 2},
	}
	engine.flags["spoke_now"] = true
	assert_false(engine._conditions_met(holder), "reputation still unmet")
	engine.reputation["officials"] = 2
	assert_true(engine._conditions_met(holder))
```

- [ ] **Step 2: Run to verify it fails**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_dialogue_engine.gd -gexit`

Expected: the four new tests error — `_conditions_met` does not exist. GUT reports these as Risky ("Did not assert") rather than Failed, because the script error aborts before the first assert.

- [ ] **Step 3: Extract the predicate**

In `engine/dialogue/DialogueEngine.gd`, replace `_choice_is_available()` with:

```gdscript
func _choice_is_available(choice: Dictionary) -> bool:
	return _conditions_met(choice)

# Shared by choices and text variants so both apply exactly one rule set.
func _conditions_met(condition_holder: Dictionary) -> bool:
	var requires_flag = condition_holder.get("requires_flag", null)
	if requires_flag != null and not flags.get(requires_flag, false):
		return false
	var requires_reputation = condition_holder.get("requires_reputation", null)
	if requires_reputation != null:
		var faction_id: String = requires_reputation["faction_id"]
		var min_score: int = int(requires_reputation["min_score"])
		if reputation.get(faction_id, 0) < min_score:
			return false
	return true
```

- [ ] **Step 4: Run to verify it passes**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_dialogue_engine.gd -gexit`

Expected: PASS — 24 tests. The 20 pre-existing tests are the proof this refactor changed no behaviour.

- [ ] **Step 5: Commit**

```bash
git add engine/dialogue/DialogueEngine.gd tests/unit/test_dialogue_engine.gd
git commit -m "refactor: extract _conditions_met from _choice_is_available"
```

---

### Task 2: Resolve conditional node text

**Files:**
- Modify: `engine/dialogue/DialogueEngine.gd`
- Test: `tests/unit/test_dialogue_engine.gd`

**Interfaces:**
- Consumes: `_conditions_met()` from Task 1.
- Produces: `DialogueEngine.current_text() -> String` — the current node's `text`, or the first matching entry in its `text_variants`.

- [ ] **Step 1: Write the failing test**

Append to `tests/unit/test_dialogue_engine.gd`:

```gdscript
func _variant_nodes() -> Array:
	return [{
		"id": "n1",
		"text": "An officer named a sum.",
		"text_variants": [
			{"requires_flag": "bribed_before", "text": "An officer named a sum; he knew you paid."},
			{"requires_reputation": {"faction_id": "officials", "min_score": 2},
			 "text": "An officer named a sum, and named it politely."},
		],
		"choices": [{"text": "Pay.", "next_id": "n1", "effects": {}}],
	}]

func test_current_text_returns_the_base_text_when_a_node_has_no_variants():
	var engine := DialogueEngine.new()
	engine.load_tree(_sample_nodes(), "n1")
	assert_eq(engine.current_text(), "Opening beat.")

func test_current_text_returns_the_base_text_when_no_variant_matches():
	var engine := DialogueEngine.new()
	engine.load_tree(_variant_nodes(), "n1")
	assert_eq(engine.current_text(), "An officer named a sum.")

func test_current_text_returns_a_flag_variant_when_its_flag_is_held():
	var engine := DialogueEngine.new()
	engine.load_tree(_variant_nodes(), "n1")
	engine.flags["bribed_before"] = true
	assert_eq(engine.current_text(), "An officer named a sum; he knew you paid.")

func test_current_text_returns_a_reputation_variant_at_the_threshold():
	var engine := DialogueEngine.new()
	engine.load_tree(_variant_nodes(), "n1")
	engine.reputation["officials"] = 2
	assert_eq(engine.current_text(), "An officer named a sum, and named it politely.")

func test_current_text_ignores_a_reputation_variant_below_the_threshold():
	var engine := DialogueEngine.new()
	engine.load_tree(_variant_nodes(), "n1")
	engine.reputation["officials"] = 1
	assert_eq(engine.current_text(), "An officer named a sum.")

func test_current_text_takes_the_first_matching_variant_when_several_match():
	# Documents the ordering rule: array order is priority, most specific first.
	var engine := DialogueEngine.new()
	engine.load_tree(_variant_nodes(), "n1")
	engine.flags["bribed_before"] = true
	engine.reputation["officials"] = 5
	assert_eq(engine.current_text(), "An officer named a sum; he knew you paid.",
		"the earlier variant must win")

func test_current_text_is_empty_for_an_unknown_node():
	var engine := DialogueEngine.new()
	assert_eq(engine.current_text(), "")
```

- [ ] **Step 2: Run to verify it fails**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_dialogue_engine.gd -gexit`

Expected: the seven new tests error — `current_text` does not exist.

- [ ] **Step 3: Implement resolution**

In `engine/dialogue/DialogueEngine.gd`, after `current_node()`:

```gdscript
# The current node's prose, with the first matching variant applied. Variants let a
# decision taken cities earlier change how a beat reads without duplicating the node.
func current_text() -> String:
	var node := current_node()
	for variant in node.get("text_variants", []):
		if _conditions_met(variant):
			return str(variant.get("text", ""))
	return str(node.get("text", ""))
```

- [ ] **Step 4: Run to verify it passes**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_dialogue_engine.gd -gexit`

Expected: PASS — 31 tests.

- [ ] **Step 5: Commit**

```bash
git add engine/dialogue/DialogueEngine.gd tests/unit/test_dialogue_engine.gd
git commit -m "feat: resolve conditional node text via text_variants"
```

---

### Task 3: Validate variants

`validate_tree()` runs under an `assert` in `load_tree()`, so a malformed variant should be caught at load rather than silently rendering wrong.

**Files:**
- Modify: `engine/dialogue/DialogueEngine.gd:17-37` (`validate_tree`)
- Test: `tests/unit/test_dialogue_engine.gd`

**Interfaces:**
- Consumes: nothing new.
- Produces: three additional error strings from `validate_tree()`.

- [ ] **Step 1: Write the failing test**

Append to `tests/unit/test_dialogue_engine.gd`. These call `validate_tree()` directly rather than `load_tree()`, because `load_tree()` asserts and would abort the test run:

```gdscript
func test_validate_tree_rejects_a_variant_with_no_text():
	var engine := DialogueEngine.new()
	var errors := engine.validate_tree([{
		"id": "n1", "text": "Base.",
		"text_variants": [{"requires_flag": "f"}],
		"choices": [],
	}])
	assert_eq(errors.size(), 1)
	assert_true(errors[0].contains("n1"), "the error must name the node")

func test_validate_tree_rejects_a_variant_with_malformed_requires_reputation():
	var engine := DialogueEngine.new()
	var errors := engine.validate_tree([{
		"id": "n1", "text": "Base.",
		"text_variants": [{"requires_reputation": {"faction_id": "officials"}, "text": "V."}],
		"choices": [],
	}])
	assert_eq(errors.size(), 1)

func test_validate_tree_rejects_an_unparsed_gloss_token_inside_a_variant():
	# A typo in a variant would otherwise reach the screen as literal braces; the
	# base text is already checked for this and variants must be too.
	var engine := DialogueEngine.new()
	var errors := engine.validate_tree([{
		"id": "n1", "text": "Base.",
		"text_variants": [{"requires_flag": "f", "text": "A {{dallal|dallal}} and a {{broken"}],
		"choices": [],
	}])
	assert_eq(errors.size(), 1)

func test_validate_tree_accepts_well_formed_variants():
	var engine := DialogueEngine.new()
	var errors := engine.validate_tree([{
		"id": "n1", "text": "Base.",
		"text_variants": [
			{"requires_flag": "f", "text": "Variant."},
			{"requires_reputation": {"faction_id": "officials", "min_score": 2}, "text": "Other."},
		],
		"choices": [],
	}])
	assert_eq(errors, [])
```

- [ ] **Step 2: Run to verify it fails**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_dialogue_engine.gd -gexit`

Expected: the first three fail with `[0] expected to equal [1]` — no variant validation exists yet, so `errors` is empty. The fourth passes already.

- [ ] **Step 3: Add the checks**

In `validate_tree()`, inside the per-node loop, after the existing residual-bbcode check on the node's own text:

```gdscript
		for variant in node.get("text_variants", []):
			var variant_text = variant.get("text", null)
			if not (variant_text is String) or str(variant_text).strip_edges().is_empty():
				errors.append("node '%s' has a text_variant with no text" % node_id)
				continue
			if GlossedTextParser.parse_to_bbcode(variant_text).contains("{{"):
				errors.append("node '%s' has a text_variant with an unparsed gloss token" % node_id)
			var variant_reputation = variant.get("requires_reputation", null)
			if variant_reputation != null and not (variant_reputation is Dictionary and variant_reputation.get("faction_id") is String and (variant_reputation.get("min_score") is float or variant_reputation.get("min_score") is int)):
				errors.append("node '%s' has a text_variant with a malformed requires_reputation (needs a String faction_id and a numeric min_score)" % node_id)
```

- [ ] **Step 4: Run to verify it passes**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_dialogue_engine.gd -gexit`

Expected: PASS — 35 tests.

- [ ] **Step 5: Commit**

```bash
git add engine/dialogue/DialogueEngine.gd tests/unit/test_dialogue_engine.gd
git commit -m "feat: validate text_variants at load"
```

---

### Task 4: Render resolved text

Two things read the node's raw text and both must switch, or a term glossed only inside a variant never reaches the margin.

**Files:**
- Modify: `scenes/chapter_view/ChapterView.gd` (`_render_current_node`, `_update_gloss_notes`)
- Test: `tests/unit/test_chapter_view.gd`

**Interfaces:**
- Consumes: `DialogueEngine.current_text()` from Task 2.
- Produces: nothing new.

- [ ] **Step 1: Write the failing test**

Append to `tests/unit/test_chapter_view.gd`:

```gdscript
func test_narration_renders_the_active_text_variant():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.dialogue_engine.load_tree([{
		"id": "n01",
		"text": "He named a sum.",
		"text_variants": [{"requires_flag": "bribed_before", "text": "He named a sum; he knew you paid."}],
		"choices": [],
	}], "n01")
	chapter_view.dialogue_engine.flags["bribed_before"] = true
	chapter_view._render_current_node()
	var narration: RichTextLabel = chapter_view.get_node("Folio/FolioMargin/Page/TextColumn/HeadBlock/NarrationLabel")
	assert_true(narration.text.contains("he knew you paid"))
	assert_false(narration.text.contains("He named a sum."), "the base reading must be replaced, not appended")

func test_a_term_glossed_only_inside_a_variant_still_gets_a_margin_note():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.margin_glossary.load_entries({
		"dallal": {"headword": "Dallal", "definition": "A broker."},
	})
	chapter_view.dialogue_engine.load_tree([{
		"id": "n01",
		"text": "He named a sum.",
		"text_variants": [{"requires_flag": "met_the_broker", "text": "The {{dallal|dallal}} named it for him."}],
		"choices": [],
	}], "n01")
	chapter_view.dialogue_engine.flags["met_the_broker"] = true
	chapter_view._render_current_node()
	var gloss_notes: VBoxContainer = chapter_view.get_node("Folio/FolioMargin/Page/MarginColumn/GlossNotes")
	assert_eq(gloss_notes.get_child_count(), 1, "the variant's glossed term needs a margin note")

func test_no_margin_note_for_a_term_in_an_inactive_variant():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.margin_glossary.load_entries({
		"dallal": {"headword": "Dallal", "definition": "A broker."},
	})
	chapter_view.dialogue_engine.load_tree([{
		"id": "n01",
		"text": "He named a sum.",
		"text_variants": [{"requires_flag": "met_the_broker", "text": "The {{dallal|dallal}} named it."}],
		"choices": [],
	}], "n01")
	chapter_view._render_current_node()
	var gloss_notes: VBoxContainer = chapter_view.get_node("Folio/FolioMargin/Page/MarginColumn/GlossNotes")
	assert_eq(gloss_notes.get_child_count(), 0)
```

- [ ] **Step 2: Run to verify it fails**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_chapter_view.gd -gexit`

Expected: the first two fail — narration still shows the base text and no margin note appears. The third passes already.

- [ ] **Step 3: Switch both readers to resolved text**

In `_render_current_node()`, replace the narration assignment:

```gdscript
	narration_label.text = GlossedTextParser.parse_to_marked_bbcode(
		dialogue_engine.current_text(), ThemeConstants.RUBRIC_RED
	)
```

The `var node := dialogue_engine.current_node()` line above it may now be unused —
delete it if so.

In `_update_gloss_notes()`, replace the raw-text lookup:

```gdscript
	var raw_text: String = dialogue_engine.current_text()
```

- [ ] **Step 4: Run to verify it passes**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_chapter_view.gd -gexit`

Expected: PASS, including the pre-existing gloss and narration tests.

- [ ] **Step 5: Check the rendered layout still holds**

Run: `godot --path . -s tools/verify_folio_layout.gd`

Expected: exit 0. Needs a display. Variant prose differs in length from base prose and the folio must absorb that.

- [ ] **Step 6: Commit**

```bash
git add scenes/chapter_view/ChapterView.gd tests/unit/test_chapter_view.gd
git commit -m "feat: render resolved variant text, glosses included"
```

---

### Task 5: The first thread, and the recipe

One thread end to end, to fix the pattern before repeating it 23 times. Teginabad's bribe-or-honesty reaching Pushang's gate officer, four chapters later.

**Files:**
- Modify: `content/chapters/chapter_06_pushang/pushang.json` (node `n09_the_officers_demand`)
- Test: `tests/unit/test_pushang_dialogue_content.gd`

**Interfaces:**
- Consumes: `bribed_teginabad_official` and `honest_at_teginabad`, both set in `chapter_01_teginabad`.
- Produces: the authoring recipe every later thread follows.

- [ ] **Step 1: Confirm the flags and the payoff node**

```bash
grep -n 'bribed_teginabad_official\|honest_at_teginabad' content/chapters/chapter_01_teginabad/teginabad.json
grep -n 'n09_the_officers_demand' content/chapters/chapter_06_pushang/pushang.json
```

Expected: both flags set by choices in Teginabad; the node id present in Pushang. If either has moved, find the current equivalent before writing prose.

- [ ] **Step 2: Write the failing content test**

Append to `tests/unit/test_pushang_dialogue_content.gd`:

```gdscript
func test_the_gate_officer_reads_differently_if_farrukh_bribed_at_teginabad():
	# _load_nodes() is the file's existing helper, returning the parsed chapter array.
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n09_the_officers_demand")
	var neutral := engine.current_text()

	engine.flags["bribed_teginabad_official"] = true
	var bribed := engine.current_text()
	assert_ne(bribed, neutral, "the bribe at Teginabad must change this beat")

	engine.flags.erase("bribed_teginabad_official")
	engine.flags["honest_at_teginabad"] = true
	var honest := engine.current_text()
	assert_ne(honest, neutral, "the honest declaration at Teginabad must change this beat")
	assert_ne(honest, bribed, "the two histories must not read the same")
```

Every `test_<chapter>_dialogue_content.gd` file already defines `_load_nodes()`,
which opens its own chapter JSON and returns the parsed array — verified in
`test_pushang_dialogue_content.gd:3`. Reuse it; do not add a second loader.

- [ ] **Step 3: Run to verify it fails**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_pushang_dialogue_content.gd -gexit`

Expected: FAIL on the first `assert_ne` — with no variants, all three readings are identical.

- [ ] **Step 4: Author the variants**

Add to `n09_the_officers_demand` in `content/chapters/chapter_06_pushang/pushang.json`, keeping its `text` and all four choices unchanged:

```json
"text_variants": [
  { "requires_flag": "bribed_teginabad_official",
    "text": "An officer at the gate - young, tired, working from a list that clearly hadn't gotten shorter all week - looked over Farrukh's manifest with the flat professional interest of a man collecting for a muster that needed feeding regardless of whose caravan happened to be passing through. \"For the garrison,\" he said, naming a sum; and then, without looking up, a second figure, smaller, the way a man names a price he has been told this particular merchant will meet." },
  { "requires_flag": "honest_at_teginabad",
    "text": "An officer at the gate - young, tired, working from a list that clearly hadn't gotten shorter all week - looked over Farrukh's manifest and found it, unusually, in order: every bale where the writing said it would be. \"For the garrison,\" he said, naming a sum, and named it once, in the tone of a man who has decided not to bother." }
]
```

Prose notes for whoever writes the remaining threads: keep the beat, the speaker
and the choices identical — a variant changes what the moment *means*, never what
happens next. Keep any glossed term that appears in the base text, or the margin
note silently disappears on that path.

- [ ] **Step 5: Run to verify it passes**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_pushang_dialogue_content.gd -gexit`

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add content/chapters/chapter_06_pushang/pushang.json tests/unit/test_pushang_dialogue_content.gd
git commit -m "content: let Teginabad's bribe or honesty reach Pushang's gate"
```

---

### Task 6: Wire the Prologue's five flags

The highest-value group: set earliest, so they can echo anywhere, and they encode the vow the whole game hangs on. Five threads, each following Task 5's recipe exactly.

**Files:**
- Modify: chapter JSON at each chosen payoff site
- Test: the corresponding `tests/unit/test_<chapter>_dialogue_content.gd`

**Interfaces:**
- Consumes: `vowed_kafala`, `spoke_now`, `waited`, `carries_own_ledger`, `avoided_unsigned_letter` — all set in `chapter_00_prologue`.
- Produces: nothing new.

- [ ] **Step 1: Pick one payoff site per flag and write it down**

Read the candidate chapters before choosing, and prefer a site at least one city away. Record the choice as a comment in the commit message, not in the JSON.

Suggested pairings, to be confirmed against the actual prose:

| Flag | Candidate payoff |
|---|---|
| `vowed_kafala` | Bost, where the debt is first tested against a creditor |
| `spoke_now` / `waited` | Farah, where Farrukh's standing with the family is weighed |
| `carries_own_ledger` | Herat, where the ledger is read by someone else |
| `avoided_unsigned_letter` | Sarakhs or Nishapur, where the letter's absence matters |

- [ ] **Step 2: For each flag, repeat Task 5's Steps 2 to 6**

Write the failing content test first, confirm it fails because all readings are
identical, author the variant, confirm it passes, commit that thread alone. One
commit per thread keeps a bad variant revertible without touching the others.

- [ ] **Step 3: Run the full suite**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`

Expected: green apart from the 22 pre-existing failures and 1 risky.

---

### Task 7: Ratchet the metrics

Locks in progress and makes regression visible. Without this, dead flags can quietly accumulate again.

**Files:**
- Create: `tests/unit/test_consequence_metrics.gd`
- Test: itself

**Interfaces:**
- Consumes: all chapter JSON.
- Produces: nothing.

- [ ] **Step 1: Write the test**

Create `tests/unit/test_consequence_metrics.gd`:

```gdscript
extends GutTest

# A ratchet, not a target. These bounds may only be tightened as threads are
# authored - never loosened to make a change pass. Measured on 6173b5f before any
# delayed-consequences work: 43 flags set, 12 read, 31 dead, 15 gated choices.
#
# Update the constants downward (dead) and upward (gated) as part of the commit that
# earns it, so the numbers in git always describe the content in git.
const MAX_DEAD_FLAGS := 31
const MIN_GATED_CONDITIONS := 15

func _all_chapter_nodes() -> Array:
	var nodes: Array = []
	var chapters := DirAccess.open("res://content/chapters")
	assert_not_null(chapters, "cannot open res://content/chapters")
	for chapter in chapters.get_directories():
		var dir := DirAccess.open("res://content/chapters/%s" % chapter)
		for file_name in dir.get_files():
			if not file_name.ends_with(".json"):
				continue
			var path := "res://content/chapters/%s/%s" % [chapter, file_name]
			var file := FileAccess.open(path, FileAccess.READ)
			var parsed = JSON.parse_string(file.get_as_text())
			file.close()
			if parsed is Array:
				nodes.append_array(parsed)
	return nodes

func _measure() -> Dictionary:
	var set_flags := {}
	var read_flags := {}
	var gated := 0
	for node in _all_chapter_nodes():
		# Variants are readers too - that is the whole point of this work.
		for variant in node.get("text_variants", []):
			if variant.has("requires_flag"):
				read_flags[variant["requires_flag"]] = true
				gated += 1
			if variant.has("requires_reputation"):
				gated += 1
		for choice in node.get("choices", []):
			if choice.has("requires_flag"):
				read_flags[choice["requires_flag"]] = true
				gated += 1
			if choice.has("requires_reputation"):
				gated += 1
			for flag_name in choice.get("effects", {}).get("flags", []):
				set_flags[flag_name] = true
	var dead := 0
	for flag_name in set_flags:
		if not read_flags.has(flag_name):
			dead += 1
	return {"set": set_flags.size(), "read": read_flags.size(), "dead": dead, "gated": gated}

func test_dead_flags_do_not_increase():
	var m := _measure()
	assert_lte(m["dead"], MAX_DEAD_FLAGS,
		"%d flags are set and never read; the ratchet allows at most %d. Wire one up or justify raising this." % [m["dead"], MAX_DEAD_FLAGS])

func test_gated_conditions_do_not_decrease():
	var m := _measure()
	assert_gte(m["gated"], MIN_GATED_CONDITIONS,
		"only %d gated conditions remain; the ratchet requires at least %d" % [m["gated"], MIN_GATED_CONDITIONS])

func test_measurement_reports_the_current_numbers():
	# Not an assertion about quality - it prints the figures so a run shows progress.
	var m := _measure()
	gut.p("flags set=%d read=%d dead=%d | gated conditions=%d" % [m["set"], m["read"], m["dead"], m["gated"]])
	assert_gt(m["set"], 0, "no flags found at all - has the content layout moved?")
```

- [ ] **Step 2: Run it**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_consequence_metrics.gd -gexit`

Expected: PASS. The printed line should show `dead` at 31 minus however many threads Tasks 5 and 6 wired, and `gated` correspondingly higher.

- [ ] **Step 3: Tighten the constants to what was actually earned**

Set `MAX_DEAD_FLAGS` to the measured `dead` and `MIN_GATED_CONDITIONS` to the measured `gated`, then re-run. This is the step that makes it a ratchet rather than a decoration.

- [ ] **Step 4: Commit**

```bash
git add tests/unit/test_consequence_metrics.gd
git commit -m "test: ratchet dead flags and gated conditions"
```

---

## Self-Review

**Spec coverage.** Schema → Task 2. Selection semantics → Task 2 (the first-match test documents the rule). Engine surface → Tasks 1–3. Renderer → Task 4. Authoring pass → Tasks 5–6. Metrics → Task 7. Testing → distributed across every task. The spec's out-of-scope items (cutscene variance, the other three subsystems, deleting the 7 terminal flags) correctly have no task.

**Partial coverage, stated plainly.** The spec lists 24 payable flags; this plan authors 6 of them (Task 5's one plus Task 6's five). The remaining 18 are deliberately left: the recipe is fixed by Task 5 and repeating it is mechanical, but 18 more threads is a content programme rather than a task list, and each needs a judgement about where its payoff belongs. Task 7's ratchet is what keeps them from being forgotten — every future thread tightens it.

**Ordering risk not solved.** A mis-ordered `text_variants` array silently shadows later entries, and no task fixes that because no validator can detect it. Task 2's first-match test at least documents the rule so a reviewer knows to check ordering.

**Type consistency.** `_conditions_met(Dictionary) -> bool` and `current_text() -> String` keep identical signatures from their defining task onward. `text_variants` is the same key throughout, always an array of dictionaries carrying `text` plus optional `requires_flag` / `requires_reputation`. Node paths in Task 4's tests match the folio tree as merged in `6173b5f`.
