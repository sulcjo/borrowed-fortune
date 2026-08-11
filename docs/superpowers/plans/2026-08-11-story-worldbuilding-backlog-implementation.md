# Story Worldbuilding Backlog Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close out finding 7 (the low-severity worldbuilding backlog) from the 2026-08-09 full-campaign story review - five small, independent content/doc edits.

**Architecture:** Four tasks, genuinely independent of each other - different files, no shared state, no ordering requirement. Grouped by file rather than by finding: Task 1 touches `bost.json` (2 findings), Task 2 touches `farah.json` + its test, Task 3 touches `prologue.json` (2 findings), Task 4 is a docs-only fix. Any task can run before or after any other.

**Tech Stack:** Godot 4.3 / GDScript / JSON content. No engine or scene changes at all in this plan.

## Global Constraints

- Godot 4.3 floor.
- GUT headless test discipline: prime once per fresh worktree (`godot --headless --path . --editor --quit` - a SIGSEGV on this first run is expected and harmless, confirmed repeatedly this session), then `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`. Never re-run priming twice in the same worktree.
- Commit per task.
- No reviewer subagent dispatch, task-level or final - standing project override. Controller self-verifies every diff and test run directly.
- Baseline before this plan: 270 tests (269 passing + 1 pre-existing harmless "risky" zero-assertion test, unrelated to this content - do not attempt to fix it).
- No new flags, no new glossary terms, no engine or scene changes anywhere in this plan - every task is a content or doc prose edit, optionally paired with a content-presence test.

---

## Task 1: Bost - Mihran's identity and the Sa'id callback

**Files:**
- Modify: `content/chapters/chapter_02_bost/bost.json`
- Test: `tests/unit/test_bost_dialogue_content.gd` (add to existing file)

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: nothing later depends on this.

- [ ] **Step 1: Write the failing tests in `tests/unit/test_bost_dialogue_content.gd`**

Add these two functions to the existing file (it already has a `_load_nodes()` helper at the top - reuse it, don't duplicate it):

```gdscript
func test_mihran_has_a_small_unstated_zoroastrian_cue():
	var nodes := _load_nodes()
	var by_id: Dictionary = {}
	for node in nodes:
		by_id[node["id"]] = node
	var sarraf_text: String = by_id["n02_seeking_the_sarraf"]["text"]
	assert_true(sarraf_text.contains("a small clay lamp burning steadily"), "Mihran's shop should carry a legible-but-unspoken sacred-fire cue")

func test_bost_arrival_names_saeed_by_name_not_just_teginabad_generically():
	var nodes := _load_nodes()
	var by_id: Dictionary = {}
	for node in nodes:
		by_id[node["id"]] = node
	var arrival_text: String = by_id["n01_bost_arrival"]["text"]
	assert_true(arrival_text.contains("Sa'id ibn Yaqub"), "the Teginabad comparison should name Sa'id specifically, not stay generic")
```

- [ ] **Step 2: Run the tests to verify they fail**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected: both new tests FAIL - neither phrase exists in the current content yet.

- [ ] **Step 3: Edit `content/chapters/chapter_02_bost/bost.json`**

Current line 4 (node `n01_bost_arrival`'s `text` field):

```json
		"text": "After Teginabad's flat customs-wall discipline, Bost announced Ghaznavid wealth a different way - not with a gate and a ledger, but with a skyline. Across the canal-fed green, low domes and a long red-brick palace face caught the last sun: the sultan's winter residence, Lashkari Bazar, more garrison-town than palace grounds, more market than either. Farrukh had no business inside those walls and no wish to acquire any. His business was smaller, and stranger: a piece of paper from a house in Rayy that his father's accounts should never have mentioned.",
```

Replace with:

```json
		"text": "After Teginabad's flat customs-wall discipline - and the particular tired patience of the amid who'd measured him there, Sa'id ibn Yaqub, closing his ledger over a question he'd chosen not to press further - Bost announced Ghaznavid wealth a different way - not with a gate and a ledger, but with a skyline. Across the canal-fed green, low domes and a long red-brick palace face caught the last sun: the sultan's winter residence, Lashkari Bazar, more garrison-town than palace grounds, more market than either. Farrukh had no business inside those walls and no wish to acquire any. His business was smaller, and stranger: a piece of paper from a house in Rayy that his father's accounts should never have mentioned.",
```

Current line 9 (node `n02_seeking_the_sarraf`'s `text` field):

```json
		"text": "Every winter-quartered army needs men who can turn one kingdom's coin into another's, and Bost had no shortage of them. Farrukh found the one the caravan drivers trusted on reputation alone - a narrow shopfront off the bazaar's spine, scales hung by the door, a {{sarraf|sarraf}} named Mihran who weighed silver for a living and, by the look of the room, had done it long enough to stop being impressed by anyone's coin.",
```

Replace with:

```json
		"text": "Every winter-quartered army needs men who can turn one kingdom's coin into another's, and Bost had no shortage of them. Farrukh found the one the caravan drivers trusted on reputation alone - a narrow shopfront off the bazaar's spine, scales hung by the door, a small clay lamp burning steadily beside the account-books that Farrukh noticed but did not ask about, and a {{sarraf|sarraf}} named Mihran who weighed silver for a living and, by the look of the room, had done it long enough to stop being impressed by anyone's coin.",
```

Only the `text` fields change - node ids, choices, effects, and the `npc_portrait` key on `n02_seeking_the_sarraf` are untouched.

- [ ] **Step 4: Run the tests to verify they pass**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected: both new tests pass, and every pre-existing test still passes too. This task adds 2 tests regardless of what order the other independent tasks in this plan run in (baseline 270, +2 from wherever the count stood before this task).

- [ ] **Step 5: Commit**

```bash
git add content/chapters/chapter_02_bost/bost.json tests/unit/test_bost_dialogue_content.gd
git commit -m "content: give Mihran a Zoroastrian cue and name Sa'id in Bost's arrival"
```

---

## Task 2: Farah - remove the 2 dead flags

**Files:**
- Modify: `content/chapters/chapter_03_farah/farah.json`
- Modify: `tests/unit/test_farah_dialogue_content.gd`

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: nothing later depends on this.

- [ ] **Step 1: Confirm the current failing state**

There's no new test to write first here - this task *removes* dead code and updates the one existing test that currently locks in the flag being removed. Run the suite once to confirm the starting baseline before touching anything:

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected: 270 tests, 269 passing (the usual 1 pre-existing risky test), all green - this is your baseline, not a failure to fix.

- [ ] **Step 2: Edit `content/chapters/chapter_03_farah/farah.json`**

Current line 22 (node `n04_the_choice_at_the_checkpoint`'s "Say nothing" choice):

```json
			{"text": "Say nothing. It isn't your caravan to risk.", "next_id": "n05b_uninvolved", "effects": {"flags": ["stayed_uninvolved_at_farah"], "reputation": {"ghaznavid_officials": 1}}}
```

Replace with:

```json
			{"text": "Say nothing. It isn't your caravan to risk.", "next_id": "n05b_uninvolved", "effects": {"reputation": {"ghaznavid_officials": 1}}}
```

Current line 104 (node `n13x_the_name_already_known`'s single choice):

```json
		"choices": [{"text": "Continue.", "next_id": "n14_the_choice", "effects": {"flags": ["confirmed_the_name_at_farah"]}}]
```

Replace with:

```json
		"choices": [{"text": "Continue.", "next_id": "n14_the_choice", "effects": {}}]
```

`confirmed_the_name_at_farah` has zero existing test references anywhere (confirmed by grep across the whole `tests/` tree before writing this plan) - only `stayed_uninvolved_at_farah` needs an accompanying test fix, in the next step.

- [ ] **Step 3: Update the existing test in `tests/unit/test_farah_dialogue_content.gd`**

Current function:

```gdscript
func test_the_checkpoint_forks_other_branch_sets_its_own_flag_and_reputation():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_farah_arrival")
	for i in range(3):
		engine.choose(0)
	var uninvolved_effects := engine.choose(1) # "Say nothing. It isn't your caravan to risk."
	assert_eq(uninvolved_effects["flags"], ["stayed_uninvolved_at_farah"])
	assert_eq(int(uninvolved_effects["reputation"]["ghaznavid_officials"]), 1)
```

Replace with:

```gdscript
func test_the_checkpoint_forks_other_branch_sets_its_own_reputation():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_farah_arrival")
	for i in range(3):
		engine.choose(0)
	var uninvolved_effects := engine.choose(1) # "Say nothing. It isn't your caravan to risk."
	assert_false(uninvolved_effects.has("flags"), "stayed_uninvolved_at_farah was removed - it was never read anywhere in content/")
	assert_eq(int(uninvolved_effects["reputation"]["ghaznavid_officials"]), 1)
```

The function is renamed (dropped "_sets_its_own_flag_") since it no longer sets one - the rest of the test body is unchanged except the one assertion.

- [ ] **Step 4: Run the tests to verify they pass**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected: the renamed test passes, and every pre-existing test still passes too. Test count is unchanged (272 before this task if Task 1 already ran, else 270 - this task neither adds nor removes a test, it only edits one in place).

- [ ] **Step 5: Commit**

```bash
git add content/chapters/chapter_03_farah/farah.json tests/unit/test_farah_dialogue_content.gd
git commit -m "content: remove Farah's 2 dead flags (never read anywhere in content/)"
```

---

## Task 3: Prologue - a real scene beat for Farrukh's mother

**Files:**
- Modify: `content/chapters/chapter_00_prologue/prologue.json`
- Test: `tests/unit/test_prologue_dialogue_content.gd` (add to existing file)

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: nothing later depends on this.

- [ ] **Step 1: Write the failing tests in `tests/unit/test_prologue_dialogue_content.gd`**

Add these two functions to the existing file (it already has a `_load_nodes()` helper and a `by_id` pattern in `test_the_spoken_debt_count_matches_the_actual_ledger` - follow the same style):

```gdscript
func test_the_grave_scene_names_his_mother_specifically():
	var nodes := _load_nodes()
	var by_id: Dictionary = {}
	for node in nodes:
		by_id[node["id"]] = node
	var grave_text: String = by_id["n04_grave_question"]["text"]
	assert_true(grave_text.contains("not his mother, not the clerks"), "the ledger list should name her specifically, not just \"the widow\"")
	assert_false(grave_text.contains("not the widow, not the clerks"), "the old, impersonal phrasing must not reappear")

func test_the_taziya_gives_his_mother_an_actual_scene_beat():
	var nodes := _load_nodes()
	var by_id: Dictionary = {}
	for node in nodes:
		by_id[node["id"]] = node
	var taziya_text: String = by_id["n07_prayer_taziya"]["text"]
	assert_true(taziya_text.contains("His mother sat through all three days"), "the mourning chapter should give her a real, specific character moment")
	assert_true(taziya_text.contains("{{taziya|ta'ziya}}"), "the existing taziya glossed term must survive the edit")
	assert_true(taziya_text.contains("{{rahimahu_llah|rahimahu llah}}"), "the existing rahimahu_llah glossed term must survive the edit")
```

- [ ] **Step 2: Run the tests to verify they fail**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected: both new tests FAIL - the first on both assertions (current text still says "not the widow"), the second on its first assertion (the two glossed-term assertions already pass against the current text, since those terms already exist - only the new sentence is missing).

- [ ] **Step 3: Edit `content/chapters/chapter_00_prologue/prologue.json`**

Current line 19 (node `n04_grave_question`'s `text` field) - only the "not the widow" clause changes, nothing else in this long sentence:

```json
		"text": "At the grave they said the {{janaza|janaza}} standing, no bowing, near-silent - and it was there, in front of half the merchants of the western bazaar, that the trouble surfaced into the open air. The imam did not begin. He turned, instead, to the men close by, and asked, plainly, the question the Prophet himself was remembered to have asked before he would pray over a man: is he in debt? Someone answered before Farrukh could. Yes. Considerably. To two houses, maybe three. Nobody was certain how much, because nobody - not the widow, not the clerks, not the dead man's own partner - had yet opened the ledger. The imam did not move to pray.",
```

Replace with:

```json
		"text": "At the grave they said the {{janaza|janaza}} standing, no bowing, near-silent - and it was there, in front of half the merchants of the western bazaar, that the trouble surfaced into the open air. The imam did not begin. He turned, instead, to the men close by, and asked, plainly, the question the Prophet himself was remembered to have asked before he would pray over a man: is he in debt? Someone answered before Farrukh could. Yes. Considerably. To two houses, maybe three. Nobody was certain how much, because nobody - not his mother, not the clerks, not the dead man's own partner - had yet opened the ledger. The imam did not move to pray.",
```

Current line 50 (node `n07_prayer_taziya`'s `text` field):

```json
		"text": "The imam prayed. Grief afterward observed its three days of {{taziya|ta'ziya}} - visitors, murmured {{rahimahu_llah|rahimahu llah}}, trays of food from neighbors Farrukh could not later remember thanking.",
```

Replace with:

```json
		"text": "The imam prayed. Grief afterward observed its three days of {{taziya|ta'ziya}} - visitors, murmured {{rahimahu_llah|rahimahu llah}}, trays of food from neighbors Farrukh could not later remember thanking. His mother sat through all three days at the head of the room, taking each condolence with a stillness Farrukh recognized as his own, inherited from somewhere he'd never thought to ask - and once, on the second evening, when the room had briefly emptied, reached over and gripped his wrist hard enough to hurt, said nothing, and let go.",
```

Only these two `text` fields change - node ids, choices, and effects (including `n07`'s incoming choice's `vowed_kafala` flag and reputation effects on the preceding node) are untouched.

- [ ] **Step 4: Run the tests to verify they pass**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected: both new tests pass, the pre-existing `test_the_spoken_debt_count_matches_the_actual_ledger` test still passes unchanged (it only checks the "To two houses, maybe three." substring, which this edit doesn't touch), and every other pre-existing test still passes too (272 tests before this task if Tasks 1-2 already ran, else 270; +2 new either way).

- [ ] **Step 5: Commit**

```bash
git add content/chapters/chapter_00_prologue/prologue.json tests/unit/test_prologue_dialogue_content.gd
git commit -m "content: give Farrukh's mother a real presence in the Prologue's funeral chapter"
```

---

## Task 4: Fix the Chapter 4B design doc's term mismatch

**Files:**
- Modify: `docs/superpowers/specs/2026-08-09-chapter-4b-herat-design.md`

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: nothing later depends on this.

- [ ] **Step 1: Confirm the current mismatch**

```bash
grep -n "ghanima" docs/superpowers/specs/2026-08-09-chapter-4b-herat-design.md
```

Expected: one hit, on line 26 - confirms the target line hasn't moved since this plan was written.

- [ ] **Step 2: Edit the doc**

Line 26, current (only the "deals in resold **ghanima**" clause changes, the rest of the paragraph is untouched):

```markdown
**Rostam** — deals in resold **ghanima** out of a quarter of Herat the respectable bazaar trade doesn't use, on the far side of the same underground channels Ardashir's world (Chapter 4A) touches only by correspondence. Genuinely capable, genuinely dangerous, and entirely uninterested in whatever cause originally justified the network he exploits — to him it's cover and leverage, nothing more. Not performatively menacing; his danger surfaces mostly in what he says carelessly, assuming Farrukh is already too implicated to matter. Knows exactly how much a courier who "asks too many questions" or "decides the money isn't worth it" has cost him before, and isn't shy about saying so once payment is settled.
```

Replace with:

```markdown
**Rostam** — deals in resold goods that never saw a customs manifest, out of a quarter of Herat the respectable bazaar trade doesn't use, on the far side of the same underground channels Ardashir's world (Chapter 4A) touches only by correspondence. Genuinely capable, genuinely dangerous, and entirely uninterested in whatever cause originally justified the network he exploits — to him it's cover and leverage, nothing more. Not performatively menacing; his danger surfaces mostly in what he says carelessly, assuming Farrukh is already too implicated to matter. Knows exactly how much a courier who "asks too many questions" or "decides the money isn't worth it" has cost him before, and isn't shy about saying so once payment is settled.
```

- [ ] **Step 3: Verify the fix**

```bash
grep -c "ghanima" docs/superpowers/specs/2026-08-09-chapter-4b-herat-design.md
```

Expected: `0`.

This is a docs-only change with no test coverage - `docs/superpowers/plans/2026-08-09-chapter-4b-herat-favor-implementation.md` was already re-checked during the design spec's own writing and confirmed to never use the word "ghanima" at all, so there's nothing else to touch.

- [ ] **Step 4: Commit**

```bash
git add docs/superpowers/specs/2026-08-09-chapter-4b-herat-design.md
git commit -m "docs: fix Chapter 4B design spec's term mismatch (ghanima -> what actually shipped)"
```

---

## Self-Review Notes

- **Spec coverage:** all 5 backlog items map to a task - items 1+2 (Mihran, Sa'id) → Task 1; item 3 (dead flags) → Task 2; item 4 (mother) → Task 3; item 5 (docs) → Task 4.
- **Placeholder scan:** none found - every step has literal, complete before/after text or code.
- **Type consistency:** N/A - no new functions, classes, or shared interfaces are introduced anywhere in this plan; every task is a self-contained content/doc edit plus, where relevant, a content-presence test using the existing `_load_nodes()`/`by_id` pattern already established in `test_bost_dialogue_content.gd` and `test_prologue_dialogue_content.gd`.
- **Independence confirmed:** all four tasks touch entirely disjoint files (`bost.json`+its test, `farah.json`+its test, `prologue.json`+its test, one doc file) - any task can be done in any order, or by four different subagents without conflict, unlike the main-menu/journey-map passes' genuinely sequential tasks.
- **Test-count arithmetic:** 270 baseline. Task 1: +2. Task 2: +0, edits one existing test in place. Task 3: +2. Task 4: +0, no GUT test. Total added across the whole plan: +4, regardless of task order. Final total after all four tasks: 274.
