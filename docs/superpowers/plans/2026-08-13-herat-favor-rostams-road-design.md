# Herat Favor — Rostam's Own Road Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add two new dialogue nodes to Herat Favor (Chapter 4B) giving Rostam a real backstory beat with genuine `hidden_network` reputation stakes, per `docs/superpowers/specs/2026-08-13-herat-favor-rostams-road-design.md`.

**Architecture:** Two new content nodes inserted between two existing, unchanged nodes (`n12_rostams_boast` and `n13_the_weight_of_knowing`) by retargeting `n12`'s single existing choice's `next_id`. No new NPC, no new glossary term, no engine changes. Unlike most of this session's recent installments, this one **does** carry a real reputation effect (no exhaustive-path calibration exists for this chapter's `hidden_network` faction, unlike Chapter 4A's `trading_families` gate) — so two full-playthrough cumulative totals in `test_chapter_view.gd` need updating.

**Tech Stack:** Godot 4.3 / GDScript, GUT (headless).

## Global Constraints

- Godot 4.3.
- Test baseline confirmed on `master` just before this plan was written: **312 tests, 311 passing + 1 pre-existing harmless "risky" zero-assertion test** (`test_every_glossed_term_id_exists_in_the_merv_glossary`, unrelated — do not attempt to fix it). After this change: **314** (two new dialogue-content tests added, none removed), 313 passing + the same 1 pre-existing risky test.
- Neither new node may reveal, hint at, or overclaim anything about the Rayy/Buyid/da'i backstory (the words "Buyid," "crucified," or any specific date claim about it) — that mystery stays exclusive to Chapter 4A's gated reveal. This chapter has a dedicated test (`test_the_weight_of_knowing_hedges_rather_than_asserts_the_gated_backstory`) guarding `n13`'s own text against this; the new nodes must hold to the same standard even though that specific test only checks `n13`.
- Do not add a coin effect anywhere in this pass — only `hidden_network` reputation, on exactly one of the two new choices.
- Do not add a new glossary term.
- **Standing override for this project, given directly by the user this session, non-negotiable: the controller must never run this project's GUT test suite, under any circumstances.** The implementer subagent doing this task should still run tests normally as part of verifying their own work — that requirement is unchanged. The controller verifies the result via `git diff` review only, never by re-running any test command.
- Standing project override: **no reviewer subagent dispatch at any stage** — the controller self-verifies every diff (`git diff`) directly instead.
- Isolation: `git worktree add -b herat-favor-rostams-road .worktrees/herat-favor-rostams-road master` from the repo root — not the generic `EnterWorktree` tool.
- `master`'s `.godot/global_script_class_cache.cfg` is already primed from earlier work this session; this plan introduces no new `class_name` file, so a fresh worktree should not need re-priming.

---

## File Structure

| File | Purpose |
|---|---|
| `content/chapters/chapter_04b_herat_favor/herat_favor.json` | Modify — retarget 1 existing choice, add 2 new nodes |
| `tests/unit/test_herat_favor_dialogue_content.gd` | Modify — bump 2 hop-counts, add 2 new test functions |
| `tests/unit/test_chapter_view.gd` | Modify — update 2 full-playthrough `hidden_network` total assertions |

---

### Task 1: Add the two new nodes and fix all affected tests

**Files:**
- Modify: `content/chapters/chapter_04b_herat_favor/herat_favor.json`
- Modify: `tests/unit/test_herat_favor_dialogue_content.gd`
- Modify: `tests/unit/test_chapter_view.gd`

**Interfaces:** None — this task is fully self-contained, nothing later depends on it.

- [ ] **Step 1: Retarget `n12`'s choice and insert the two new nodes**

In `content/chapters/chapter_04b_herat_favor/herat_favor.json`, find `n12_rostams_boast`. Its current single choice is:

```json
"choices": [{"text": "Continue.", "next_id": "n13_the_weight_of_knowing", "effects": {}}]
```

Change only the `next_id` to:

```json
"choices": [{"text": "Continue.", "next_id": "n12b_rostams_own_road", "effects": {}}]
```

Do not change `n12`'s own `text` or anything else about it.

Then insert these two new node objects into the file (place them right after `n12_rostams_boast` for readability, before `n13_the_weight_of_knowing`):

```json
{
	"id": "n12b_rostams_own_road",
	"text": "Something about the boast, or perhaps just the wine, loosened something in Rostam that his usual unhurried caution otherwise kept shut. \"You want to know how a man ends up doing what I do?\" he said, not quite a question, not quite needing an answer. \"One delivery, years back, for coin I needed badly enough not to ask too many questions about. Told myself it was the one time. Man tells himself a lot of things, the first time.\" He didn't finish the thought any further than that, and didn't need to - Farrukh understood, with a chill that had nothing to do with the room's temperature, that he was listening to a version of the exact lie he'd just heard Rostam not-quite tell about the last courier, except this one had happened to Rostam himself, years before either of them had met.",
	"npc_portrait": "rostam",
	"choices": [
		{"text": "Tell him you understand more than he thinks.", "next_id": "n12c_a_moment_of_recognition", "effects": {"reputation": {"hidden_network": 1}}},
		{"text": "Say nothing. It's not your place.", "next_id": "n13_the_weight_of_knowing", "effects": {}}
	]
},
{
	"id": "n12c_a_moment_of_recognition",
	"text": "Rostam looked at him for a moment too long to be entirely comfortable, then allowed himself something that wasn't quite a smile. \"Maybe you do,\" he said, and for just that moment, the practiced unhurriedness slipped enough to look almost like relief - the particular relief of a man who has spent a long time being seen only as dangerous, briefly seen as something closer to human instead.",
	"npc_portrait": "rostam",
	"choices": [{"text": "Continue.", "next_id": "n13_the_weight_of_knowing", "effects": {}}]
},
```

Both new nodes carry `"npc_portrait": "rostam"` — confirmed via direct grep to be the exact string every other Rostam-scene node in this chapter uses. Do not change `n13_the_weight_of_knowing`'s own `text` or anything else in the file.

- [ ] **Step 2: Bump the two affected hop-count loops**

In `tests/unit/test_herat_favor_dialogue_content.gd`, in both `test_the_stay_entangled_path_is_walkable_and_sets_its_flags_and_reputation()` and `test_the_pivot_away_path_is_walkable_and_sets_its_flags_and_reputation()`, change:

```gdscript
	for i in range(12):
```

to:

```gdscript
	for i in range(14):
```

in both functions. This is a **+2** change (not +1) — confirmed by hand-tracing the full chain in the spec: `n12`'s single-choice path used to reach `n13` in 1 press; it now reaches `n13` via `n12b` and `n12c` in 3 presses (taking "understand," index 0, at `n12b`), a net addition of 2. Both functions still land on `n14_the_choice` immediately after the loop — verify this with Step 4 below rather than trusting the arithmetic alone.

**Do not touch** `test_choosing_rostam_directly_skips_the_sideroad()`, `test_choosing_the_mint_visits_the_sideroad_then_converges()` (both stop at `n05`), any of the four `test_the_payment_negotiations_*` tests (all use `range(7)` to reach `n08`, well before this insertion point), `test_the_full_tree_is_walkable_from_start_to_end_via_first_choices()` (uncapped loop), `test_no_node_mentions_ardashir_or_the_non_standard_demonym()`, or `test_the_weight_of_knowing_hedges_rather_than_asserts_the_gated_backstory()` — the spec confirms all of these are unaffected.

- [ ] **Step 3: Add two new test functions for the new nodes**

Add these two new functions to `tests/unit/test_herat_favor_dialogue_content.gd` (place them after `test_the_payment_negotiations_passive_path_has_no_reputation_effect()`, before `test_the_stay_entangled_path_is_walkable_and_sets_its_flags_and_reputation()`):

```gdscript
func test_understanding_rostam_gains_reputation_and_reaches_the_weight_of_knowing():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival_the_favor")
	for i in range(12):
		engine.choose(0) # reach n12b via the sideroad + insist-on-price defaults, then the boast
	assert_eq(engine.current_node()["id"], "n12b_rostams_own_road")
	var effects := engine.choose(0) # "Tell him you understand more than he thinks."
	assert_eq(int(effects["reputation"]["hidden_network"]), 1)
	assert_eq(engine.current_node()["id"], "n12c_a_moment_of_recognition")
	engine.choose(0) # "Continue."
	assert_eq(engine.current_node()["id"], "n13_the_weight_of_knowing")

func test_saying_nothing_to_rostam_reaches_the_weight_of_knowing_directly():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_herat_arrival_the_favor")
	for i in range(12):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n12b_rostams_own_road")
	var effects := engine.choose(1) # "Say nothing. It's not your place."
	assert_eq(effects, {})
	assert_eq(engine.current_node()["id"], "n13_the_weight_of_knowing")
```

Note these two new tests walk only 12 presses (not 14) before making their own choice — that count is unaffected by Step 2's change, since it stops at `n12b` itself, which is unchanged at 12 presses from `n01` (the same count that used to reach `n13` directly, before this insertion existed).

- [ ] **Step 4: Update the two affected full-playthrough tests in `test_chapter_view.gd`**

In `tests/unit/test_chapter_view.gd`, inside `test_a_full_playthrough_via_the_plunder_branch_reaches_its_own_terminal_node()`, change:

```gdscript
	assert_eq(chapter_view.reputation_tracker.get_reputation("hidden_network"), 2, "unchanged since Chapter 4B - Chapter 5 has no reputation effects at all")
```

to:

```gdscript
	assert_eq(chapter_view.reputation_tracker.get_reputation("hidden_network"), 3, "n09a_paid_as_agreed (+1) + n12b_rostams_own_road's understand option (+1) + n14_the_choice's stay-entangled option (+1) = 3")
```

Inside `test_a_full_playthrough_via_the_pivot_away_path_reaches_its_own_terminal_node()`, change:

```gdscript
	assert_eq(chapter_view.reputation_tracker.get_reputation("hidden_network"), 0, "n09a_paid_as_agreed (+1) + n14_the_choice's pivot-away option (-1) = 0")
```

to:

```gdscript
	assert_eq(chapter_view.reputation_tracker.get_reputation("hidden_network"), 1, "n09a_paid_as_agreed (+1) + n12b_rostams_own_road's understand option (+1) + n14_the_choice's pivot-away option (-1) = 1")
```

**Do not touch** any other assertion in either test, or any other test in this file — no other full-playthrough test reaches Chapter 4B (the mystery-branch test goes through Chapter 4A instead, confirmed by this file's own existing structure).

- [ ] **Step 5: Run the affected test files**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=tests/unit/test_herat_favor_dialogue_content.gd -gexit
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=tests/unit/test_chapter_view.gd -gexit
```

Expected: all tests in both files pass, 0 failures.

- [ ] **Step 6: Run the full suite**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected: 314 tests total (312 + 2 new), 313 passing + the 1 pre-existing risky test, no failures.

- [ ] **Step 7: Commit**

```bash
git add content/chapters/chapter_04b_herat_favor/herat_favor.json tests/unit/test_herat_favor_dialogue_content.gd tests/unit/test_chapter_view.gd
git commit -m "content: add Rostam's own-road backstory scene to Herat Favor"
```

---

## Self-Review

**Spec coverage:** the two new nodes and their exact text/wiring → Step 1, verbatim from the spec. The hop-count fix → Step 2, with the exact +2 arithmetic reasoning preserved. The two new dialogue-content tests → Step 3. The two full-playthrough reputation-total updates, with the exact new arithmetic (3 and 1) preserved → Step 4. ✓ Nothing else in the spec requires a task — no NPC beyond the already-present Rostam, no glossary term, no coin effect anywhere.

**Placeholder scan:** none.

**Type/signature consistency:** node ids (`n12b_rostams_own_road`, `n12c_a_moment_of_recognition`) match exactly between the content JSON and the test code. The reputation math (`1+1+1=3`, `1+1-1=1`) is verified arithmetic, not assumed.

**Task granularity check:** one task. The content addition and its test fixes (both the dialogue-content hop-counts and the full-playthrough totals) are inseparable — a reviewer could not sensibly approve one without the others, since the new nodes don't exist without their own tests, and neither the existing dialogue-content tests nor the full-playthrough tests pass without every piece of this fix landing together.
