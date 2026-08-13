# Nishapur — Word to Nasuh (Debt Repayment) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire a new `"debt_repaid"` effects key into the engine, then use it to build a real debt-repayment beat in Nishapur, per `docs/superpowers/specs/2026-08-13-nishapur-debt-repaid-design.md`.

**Architecture:** Task 1 adds the engine mechanism (new effects key, `ChapterView._apply_effects()` wiring, its own unit test) using the already-existing, already-tested `Ledger.pay_debt()`. Task 2 depends on Task 1's effects key and builds the actual content (two new nodes in Nishapur, retargeting one existing choice) plus its own test fixes.

**Tech Stack:** Godot 4.3 / GDScript, GUT (headless).

## Global Constraints

- Godot 4.3.
- Test baseline confirmed on `master` just before this plan was written: **302 tests, 301 passing + 1 pre-existing harmless "risky" zero-assertion test** (`test_every_glossed_term_id_exists_in_the_merv_glossary`, unrelated — do not attempt to fix it). After this change: **305** (3 new tests added across both tasks, none removed), 304 passing + the same 1 pre-existing risky test.
- `Ledger.pay_debt(debt: Debt, amount: float)` and `Ledger.guarantee_debt_via_kafala(creditor_name, amount)` already exist in `engine/ledger/Ledger.gd` and are already unit-tested in `tests/unit/test_ledger.gd` — do not modify either of them, and do not add new tests to `test_ledger.gd`. This plan only adds a new *caller* of `pay_debt()` from `ChapterView._apply_effects()`.
- The two larger debts (Ibrahim al-Sarraf's 340.0, Rukn ibn Faramarz's 210.0) are not touched anywhere in this plan — only Nasuh's 60.0 debt gets a `debt_repaid` effect, and only a partial 20.0 of it.
- **Standing override for this project, given directly by the user this session, non-negotiable: the controller must never run this project's GUT test suite, under any circumstances.** The implementer subagent doing this task should still run tests normally as part of verifying their own work — that requirement is unchanged. The controller verifies the result via `git diff` review only, never by re-running any test command.
- Standing project override: **no reviewer subagent dispatch at any stage** — the controller self-verifies every diff (`git diff`) directly instead.
- Isolation: `git worktree add -b nishapur-debt-repaid .worktrees/nishapur-debt-repaid master` from the repo root — not the generic `EnterWorktree` tool.
- `master`'s `.godot/global_script_class_cache.cfg` is already primed from earlier work this session; this plan introduces no new `class_name` file, so a fresh worktree should not need re-priming.

---

## File Structure

| File | Purpose |
|---|---|
| `scenes/chapter_view/ChapterView.gd` | Modify (Task 1) — add `debt_repaid` handling to `_apply_effects()` |
| `tests/unit/test_chapter_view.gd` | Modify (Task 1) — add 1 new engine-level test; Modify (Task 2) — fix 1 full-playthrough wealth assertion, add 1 new debt-total assertion |
| `content/chapters/chapter_08_nishapur/nishapur.json` | Modify (Task 2) — retarget 1 existing choice, add 2 new nodes |
| `tests/unit/test_nishapur_dialogue_content.gd` | Modify (Task 2) — bump 4 hop-counts, add 2 new test functions |

---

### Task 1: Wire the `debt_repaid` effects key into the engine

**Files:**
- Modify: `scenes/chapter_view/ChapterView.gd`
- Modify: `tests/unit/test_chapter_view.gd`

**Interfaces:**
- Produces: a new effects key, `"debt_repaid"`, consumed by `_apply_effects()`. Shape: `{"creditor_name": <String, must exactly match an existing Debt.creditor_name>, "amount_dirham_equivalent": <float>}`. Task 2 depends on this exact shape.

- [ ] **Step 1: Add the `debt_repaid` handling to `_apply_effects()`**

In `scenes/chapter_view/ChapterView.gd`, find `_apply_effects()`:

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

Insert a new block after the `for debt_data in effects.get("debts", [])` loop and before the `coin_spent_dirham_equivalent` check:

```gdscript
	if effects.has("debt_repaid"):
		var repayment: Dictionary = effects["debt_repaid"]
		var matched_debt: Debt = null
		for debt in ledger.debts:
			if debt.creditor_name == repayment["creditor_name"]:
				matched_debt = debt
				break
		assert(matched_debt != null, "debt_repaid effect references unknown creditor '%s'" % repayment["creditor_name"])
		ledger.pay_debt(matched_debt, repayment["amount_dirham_equivalent"])
		ledger.spend_dirham_equivalent(repayment["amount_dirham_equivalent"])
```

The full function afterward should read, in order: reputation loop, debts loop, the new debt_repaid block, coin_spent check, coin_gained check.

- [ ] **Step 2: Add the new engine-level test**

In `tests/unit/test_chapter_view.gd`, add this new test function immediately after `test_apply_effects_with_coin_gained_dirham_equivalent_receives_into_the_ledger()`:

```gdscript
func test_apply_effects_with_debt_repaid_pays_down_the_matching_debt_and_spends_from_the_ledger():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.ledger.guarantee_debt_via_kafala("Nasuh's own back wages, unpaid four months", 60.0)
	chapter_view._apply_effects({"debt_repaid": {"creditor_name": "Nasuh's own back wages, unpaid four months", "amount_dirham_equivalent": 20.0}})
	assert_almost_eq(chapter_view.ledger.total_debt_owed(), 40.0, 0.0001)
	assert_almost_eq(chapter_view.ledger.total_wealth_dirham_equivalent(), -20.0, 0.0001)
```

- [ ] **Step 3: Run the affected test file**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=tests/unit/test_chapter_view.gd -gexit
```

Expected: all tests pass, 0 failures.

- [ ] **Step 4: Commit**

```bash
git add scenes/chapter_view/ChapterView.gd tests/unit/test_chapter_view.gd
git commit -m "engine: wire a debt_repaid effects key into ChapterView._apply_effects"
```

---

### Task 2: Build the Nishapur content using the new effects key

**Files:**
- Modify: `content/chapters/chapter_08_nishapur/nishapur.json`
- Modify: `tests/unit/test_nishapur_dialogue_content.gd`
- Modify: `tests/unit/test_chapter_view.gd`

**Interfaces:**
- Consumes: the `"debt_repaid"` effects key from Task 1, exact shape `{"creditor_name": String, "amount_dirham_equivalent": float}`.

- [ ] **Step 1: Retarget `n03`'s choice and insert the two new nodes**

In `content/chapters/chapter_08_nishapur/nishapur.json`, find `n03_the_turquoise_and_the_ledger`. Its current single choice is:

```json
"choices": [{"text": "Continue.", "next_id": "n04_the_choice_before_the_khaneqah", "effects": {}}]
```

Change only the `next_id` to:

```json
"choices": [{"text": "Continue.", "next_id": "n03b_word_to_nasuh", "effects": {}}]
```

Do not change `n03`'s own `text` or anything else about it.

Then insert these two new node objects into the file (place them right after `n03_the_turquoise_and_the_ledger` for readability, before `n04_the_choice_before_the_khaneqah`):

```json
{
	"id": "n03b_word_to_nasuh",
	"text": "Nishapur's bazaar kept a courier trade as old as the turquoise itself - men who carried nothing but folded paper and other men's trust between cities that never saw each other's coin change hands. Farrukh thought, watching one such courier haggle over a fee to Marw, of his father's suftaja, and then, less expectedly, of Nasuh - four months unpaid, still minding whatever was left of a dead man's shop, because nobody had told him not to. It would cost something to send even a little of it home. He had, by his own accounting, not very much left to send.",
	"choices": [
		{"text": "Send what you can spare toward Nasuh's wages.", "next_id": "n03c_what_was_sent", "effects": {"debt_repaid": {"creditor_name": "Nasuh's own back wages, unpaid four months", "amount_dirham_equivalent": 20.0}}},
		{"text": "There's nothing to spare. Let it wait.", "next_id": "n04_the_choice_before_the_khaneqah", "effects": {}}
	]
},
{
	"id": "n03c_what_was_sent",
	"text": "Twenty dirham, folded into a letter he wrote three times before he was satisfied with it, went west that same afternoon with a courier he paid extra to remember his name. It was not four months of wages. It was not even half. But it was more than a promise, which was the one thing his father's own ledger had apparently never quite managed to be.",
	"choices": [{"text": "Continue.", "next_id": "n04_the_choice_before_the_khaneqah", "effects": {}}]
},
```

Do not change `n04_the_choice_before_the_khaneqah`'s own `text` or anything else in the file — including its own "There was, first, a smaller matter to settle, or not" line, which continues to refer only to Bahram's family token, not this new scene.

- [ ] **Step 2: Bump the four hop-count loops**

In `tests/unit/test_nishapur_dialogue_content.gd`, in both `test_the_family_sideroad_is_hidden_without_the_token_flag()` and `test_the_family_sideroad_is_visible_and_taken_with_the_token_flag()`, change:

```gdscript
	for i in range(3):
```

to:

```gdscript
	for i in range(5):
```

In both `test_the_endures_choice_reaches_its_terminal_and_sets_its_flag()` and `test_the_dissolved_choice_reaches_its_terminal_and_sets_its_flag()`, change:

```gdscript
	for i in range(7):
```

to:

```gdscript
	for i in range(9):
```

This is a **+2** change in both cases (not +1) — confirmed by hand-tracing the full chain in the spec: `n03`'s single-choice path used to reach `n04` in 1 press; it now reaches `n04` via `n03b` and `n03c` in 3 presses (taking "Send," index 0, at `n03b`), a net addition of 2. Verify with Step 4 below rather than trusting the arithmetic alone — if any test fails on its post-loop landing-node assertion, trust the actual output over this plan's arithmetic, adjust the count to whatever actually reaches the expected node, and report exactly what you found and changed.

Do not change `test_the_full_tree_is_walkable_from_start_to_end_via_first_choices()` — it uses an uncapped `while` loop and needs no fixed-count adjustment.

- [ ] **Step 3: Add two new test functions for the new nodes**

Add these two new functions to `tests/unit/test_nishapur_dialogue_content.gd` (place them after `test_the_family_sideroad_is_visible_and_taken_with_the_token_flag()`, before `test_the_endures_choice_reaches_its_terminal_and_sets_its_flag()`):

```gdscript
func test_sending_coin_to_nasuh_repays_part_of_his_debt_and_reaches_n04():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_nishapur_arrival")
	for i in range(3):
		engine.choose(0) # n01 -> n02 -> n03 -> n03b
	assert_eq(engine.current_node()["id"], "n03b_word_to_nasuh")
	var effects := engine.choose(0) # "Send what you can spare toward Nasuh's wages."
	assert_eq(effects["debt_repaid"], {"creditor_name": "Nasuh's own back wages, unpaid four months", "amount_dirham_equivalent": 20.0})
	assert_eq(engine.current_node()["id"], "n03c_what_was_sent")
	engine.choose(0) # "Continue."
	assert_eq(engine.current_node()["id"], "n04_the_choice_before_the_khaneqah")

func test_letting_nasuhs_wages_wait_reaches_n04_directly():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_nishapur_arrival")
	for i in range(3):
		engine.choose(0) # n01 -> n02 -> n03 -> n03b
	assert_eq(engine.current_node()["id"], "n03b_word_to_nasuh")
	var effects := engine.choose(1) # "There's nothing to spare. Let it wait."
	assert_eq(effects, {})
	assert_eq(engine.current_node()["id"], "n04_the_choice_before_the_khaneqah")
```

- [ ] **Step 4: Fix the one affected full-playthrough test in `test_chapter_view.gd`**

In `tests/unit/test_chapter_view.gd`, inside `test_a_full_playthrough_via_the_mystery_branch_carries_prologue_flags_through_farah()`, change:

```gdscript
	assert_almost_eq(chapter_view.ledger.total_wealth_dirham_equivalent(), -83.0, 0.0001, "unchanged since Chapter 6 - neither Chapter 7 nor Chapter 8 has any coin effect on this path")
```

to:

```gdscript
	assert_almost_eq(chapter_view.ledger.total_wealth_dirham_equivalent(), -103.0, 0.0001, "Chapter 8's word-to-Nasuh scene (index 0, 'Send what you can spare') adds a 20.0 debt_repaid spend on this path")
	assert_almost_eq(chapter_view.ledger.total_debt_owed(), 590.0, 0.0001, "Nasuh's 60.0 debt drops to 40.0 after the 20.0 repayment; the other two debts (340.0 + 210.0) are untouched")
```

**Do not touch** any other assertion in this test, or either of the other two full-playthrough tests (`test_a_full_playthrough_via_the_plunder_branch...`, `test_a_full_playthrough_via_the_pivot_away_path...`) — neither reaches Chapter 8, confirmed by direct reading (both terminate at Chapter 5).

- [ ] **Step 5: Run the affected test files**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=tests/unit/test_nishapur_dialogue_content.gd -gexit
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=tests/unit/test_chapter_view.gd -gexit
```

Expected: all tests in both files pass, 0 failures.

- [ ] **Step 6: Run the full suite**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected: 305 tests total (302 + 3 new across both tasks), 304 passing + the 1 pre-existing risky test, no failures.

- [ ] **Step 7: Commit**

```bash
git add content/chapters/chapter_08_nishapur/nishapur.json tests/unit/test_nishapur_dialogue_content.gd tests/unit/test_chapter_view.gd
git commit -m "content: add the word-to-Nasuh debt-repayment scene to Nishapur"
```

---

## Self-Review

**Spec coverage:** the engine wiring and its own test → Task 1, verbatim from the spec's code block. The two new content nodes and their exact text/wiring → Task 2 Step 1, verbatim from the spec. The hop-count fix → Task 2 Step 2, with the exact +2 arithmetic reasoning preserved. The two new dialogue-content tests → Task 2 Step 3. The one affected full-playthrough test, plus the new debt-total assertion → Task 2 Step 4, with the other two full-playthrough tests explicitly called out as unaffected. ✓ Nothing else in the spec requires a task.

**Placeholder scan:** none.

**Type/signature consistency:** the effects key (`debt_repaid`) and its shape (`creditor_name`, `amount_dirham_equivalent`) match exactly between Task 1's engine code, Task 2's content JSON, and both tasks' test code. The creditor name string (`"Nasuh's own back wages, unpaid four months"`) matches exactly what the Prologue's `n06_vow` already established — this is load-bearing: `_apply_effects()`'s lookup is a plain string match, and any typo would trip the new `assert()` at runtime. Node ids (`n03b_word_to_nasuh`, `n03c_what_was_sent`) match exactly between the content JSON and the test code.

**Task granularity check:** two tasks, split because they are independently reviewable — Task 1's engine correctness (does `debt_repaid` correctly find and reduce the right debt, does it spend the right amount) is a different concern from Task 2's content correctness (does the prose read well, does it wire into the right nodes), and Task 2 cannot start until Task 1's exact effects-key shape exists to consume.
