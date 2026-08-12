# Bost — Currency Mechanics (The Light Coin) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add two new dialogue nodes to Bost dramatizing coin debasement and mint-distrust, per `docs/superpowers/specs/2026-08-12-bost-currency-mechanics-design.md`.

**Architecture:** Two new content nodes inserted between two existing, unchanged nodes (`n02b_the_ordinary_business` and `n02c_mihran_on_letters_of_credit`) by retargeting `n02b`'s existing choices' `next_id` values. No new NPC, no new glossary term, no engine changes.

**Tech Stack:** Godot 4.3 / GDScript, GUT (headless).

## Global Constraints

- Godot 4.3.
- Test baseline confirmed on `master` just before this plan was written: **296 tests, 295 passing + 1 pre-existing harmless "risky" zero-assertion test** (`test_every_glossed_term_id_exists_in_the_merv_glossary`, unrelated — do not attempt to fix it). After this change: **298** (two new dialogue-content tests added, none removed), 297 passing + the same 1 pre-existing risky test.
- Neither new choice carries any `coin_spent_dirham_equivalent`, `coin_gained_dirham_equivalent`, or `reputation` effect — flavor-only, per the spec. Do not add any numeric effect to either new node; this is a deliberate design choice, not an oversight.
- Do not add or reuse the `sikka` glossary term anywhere — it is already glossed in `content/glossary/herat_favor_terms.json` and this project enforces glossary-term-id uniqueness project-wide. Express the political-legitimacy idea in plain prose only, exactly as drafted in Step 1 below — do not add `{{}}` markup around it.
- **Standing override for this project, given directly by the user this session, non-negotiable: the controller must never run this project's GUT test suite, under any circumstances.** The implementer subagent doing this task should still run tests normally as part of verifying their own work — that requirement is unchanged. The controller verifies the result via `git diff` review only, never by re-running any test command.
- Standing project override: **no reviewer subagent dispatch at any stage** — the controller self-verifies every diff (`git diff`) directly instead.
- Isolation: `git worktree add -b bost-currency-mechanics .worktrees/bost-currency-mechanics master` from the repo root — not the generic `EnterWorktree` tool.
- `master`'s `.godot/global_script_class_cache.cfg` is already primed from earlier work this session; this plan introduces no new `class_name` file, so a fresh worktree should not need re-priming.

---

## File Structure

| File | Purpose |
|---|---|
| `content/chapters/chapter_02_bost/bost.json` | Modify — retarget 2 existing choices, add 2 new nodes |
| `tests/unit/test_bost_dialogue_content.gd` | Modify — fix 2 landing-node assertions, add 2 new test functions, bump 2 hop-counts |

---

### Task 1: Add the two new nodes and fix all affected tests

**Files:**
- Modify: `content/chapters/chapter_02_bost/bost.json`
- Modify: `tests/unit/test_bost_dialogue_content.gd`

**Interfaces:** None — this task is fully self-contained, nothing later depends on it.

- [ ] **Step 1: Retarget `n02b`'s choices and insert the two new nodes**

In `content/chapters/chapter_02_bost/bost.json`, find `n02b_the_ordinary_business`. Its current choices are:

```json
[
	{"text": "Thorough. Weigh every coin.", "next_id": "n02c_mihran_on_letters_of_credit", "effects": {"coin_spent_dirham_equivalent": 2.0}},
	{"text": "Quick is fine. I trust you.", "next_id": "n02c_mihran_on_letters_of_credit", "effects": {"coin_spent_dirham_equivalent": 1.0, "reputation": {"trading_families": 1}}}
]
```

Change **only** the `next_id` in both (leave `text` and `effects` on both exactly as they are) to:

```json
[
	{"text": "Thorough. Weigh every coin.", "next_id": "n02d_the_light_coin", "effects": {"coin_spent_dirham_equivalent": 2.0}},
	{"text": "Quick is fine. I trust you.", "next_id": "n02d_the_light_coin", "effects": {"coin_spent_dirham_equivalent": 1.0, "reputation": {"trading_families": 1}}}
]
```

Then insert these two new node objects into the file (position in the array doesn't matter functionally, but place them right after `n02b_the_ordinary_business` for readability, before `n02c_mihran_on_letters_of_credit`):

```json
{
	"id": "n02d_the_light_coin",
	"text": "Mihran's hands stopped on one coin before it reached the rest. He turned it once in the lamp-light, weighed it apart from the others, and set it down instead of adding it to the stack. \"Someone's had a knife at the edge of this,\" he said, not looking up - clipped, the silver shaved thin enough to matter, however carefully the theft had been dressed up as ordinary wear. His thumb found the stamp next. \"And I haven't taken coin from this mint in two years - not since the man whose name is on it stopped being anyone's idea of an authority worth trusting. Whoever's face gets struck into new coin is making a promise, same as any paper. Some promises age worse than others.\"",
	"npc_portrait": "mihran",
	"choices": [
		{"text": "Ask what happened to the mint's authority.", "next_id": "n02e_the_mint_in_question", "effects": {"flags": ["learned_of_two_mints_dispute"]}},
		{"text": "Let it go. It's his problem now.", "next_id": "n02c_mihran_on_letters_of_credit", "effects": {}}
	]
},
{
	"id": "n02e_the_mint_in_question",
	"text": "\"Two amirs, both claiming the same stretch of road, each striking coin with his own name on it,\" Mihran said, setting the light coin aside for melting rather than spending. \"Merchants don't wait for anyone to settle that properly. We decide for ourselves whose promise to trust with our own scales. It settles itself, eventually - one name stops appearing on new coin, and everyone quietly agrees to remember why.\" He shrugged, already reaching for the next coin in the stack. \"Nothing personal in it, when I don't take his either.\"",
	"npc_portrait": "mihran",
	"choices": [
		{"text": "Continue.", "next_id": "n02c_mihran_on_letters_of_credit", "effects": {}}
	]
},
```

Do not change `n02c_mihran_on_letters_of_credit`'s own `text` or anything else in the file.

- [ ] **Step 2: Fix the two existing tests' landing-node assertions**

In `tests/unit/test_bost_dialogue_content.gd`, in `test_the_ordinary_business_choices_have_the_right_effects()`, change:

```gdscript
	assert_eq(engine.current_node()["id"], "n02c_mihran_on_letters_of_credit")
	assert_eq(engine.current_node()["npc_portrait"], "mihran")
```

(the pair immediately after `thorough_effects := engine.choose(0)`) to:

```gdscript
	assert_eq(engine.current_node()["id"], "n02d_the_light_coin")
	assert_eq(engine.current_node()["npc_portrait"], "mihran")
```

In `test_taking_the_quick_option_spends_less_and_gains_reputation()`, change:

```gdscript
	assert_eq(engine.current_node()["id"], "n02c_mihran_on_letters_of_credit")
```

(the line immediately after `quick_effects := engine.choose(1)`) to:

```gdscript
	assert_eq(engine.current_node()["id"], "n02d_the_light_coin")
```

Nothing else in either test changes — the effects assertions on the Thorough/Quick choices themselves are unrelated to this fix and stay exactly as they are.

- [ ] **Step 3: Add two new test functions for the new nodes**

Add these two new functions to `tests/unit/test_bost_dialogue_content.gd` (place them after `test_taking_the_quick_option_spends_less_and_gains_reputation()`):

```gdscript
func test_asking_about_the_mint_sets_a_flag_and_reaches_the_letters_of_credit_scene():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_bost_arrival")
	for i in range(2):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n02b_the_ordinary_business")
	engine.choose(0) # "Thorough. Weigh every coin."
	assert_eq(engine.current_node()["id"], "n02d_the_light_coin")
	var effects := engine.choose(0) # "Ask what happened to the mint's authority."
	assert_eq(effects["flags"], ["learned_of_two_mints_dispute"])
	assert_eq(engine.current_node()["id"], "n02e_the_mint_in_question")
	engine.choose(0) # "Continue."
	assert_eq(engine.current_node()["id"], "n02c_mihran_on_letters_of_credit")
	assert_true(engine.flags.get("learned_of_two_mints_dispute", false))

func test_letting_the_light_coin_go_reaches_the_letters_of_credit_scene_directly():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_bost_arrival")
	for i in range(2):
		engine.choose(0)
	assert_eq(engine.current_node()["id"], "n02b_the_ordinary_business")
	engine.choose(0) # "Thorough. Weigh every coin."
	assert_eq(engine.current_node()["id"], "n02d_the_light_coin")
	var effects := engine.choose(1) # "Let it go. It's his problem now."
	assert_eq(effects, {})
	assert_eq(engine.current_node()["id"], "n02c_mihran_on_letters_of_credit")
	assert_false(engine.flags.get("learned_of_two_mints_dispute", false))
```

- [ ] **Step 4: Bump the two hop-count loops**

In both `test_the_pressed_path_is_walkable_and_sets_its_flag_and_reputation()` and `test_the_patient_path_is_walkable_and_converges_on_the_same_node()`, change:

```gdscript
	for i in range(8):
		engine.choose(0)
```

to:

```gdscript
	for i in range(10):
		engine.choose(0)
```

in both functions. This is a **+2** change (not +1) — confirmed by hand-tracing the full chain in the spec: `n02b`'s index-0 path used to reach `n02c` in 1 press; it now reaches `n02c` via `n02d` and `n02e` in 3 presses, a net addition of 2. Both functions still land on `n07_the_offer` immediately after the loop — verify this with Step 5 below rather than trusting the arithmetic alone.

- [ ] **Step 5: Run the affected test file**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=tests/unit/test_bost_dialogue_content.gd -gexit
```

Expected: all tests pass, 0 failures. If either hop-count-bumped test fails on the `assert_eq(engine.current_node()["id"], "n07_the_offer")` line, the actual node reached there will tell you whether the count needs adjusting — trust that output over the arithmetic in this plan if they disagree, and report back what the real count needed to be.

- [ ] **Step 6: Run the full suite**

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Expected: 298 tests total (296 + 2 new), 297 passing + the 1 pre-existing risky test, no failures.

- [ ] **Step 7: Commit**

```bash
git add content/chapters/chapter_02_bost/bost.json tests/unit/test_bost_dialogue_content.gd
git commit -m "content: add coin debasement and mint-distrust scene to Bost"
```

---

## Self-Review

**Spec coverage:** the two new nodes and their exact text/wiring → Step 1, verbatim from the spec. The two existing tests' landing-node fix → Step 2. The two new dialogue-content tests → Step 3. The hop-count fix, with its exact +2 arithmetic reasoning preserved → Step 4. ✓ Nothing else in the spec requires a task — no glossary change, no NPC, no coin/reputation effect anywhere.

**Placeholder scan:** none.

**Type/signature consistency:** node ids (`n02d_the_light_coin`, `n02e_the_mint_in_question`) and the flag name (`learned_of_two_mints_dispute`) match exactly between the content JSON and the test code. No new function or signature is introduced anywhere.

**Task granularity check:** one task. The content addition and its test fixes are inseparable — a reviewer could not sensibly approve one without the other, since the new nodes don't exist without their own tests, and the existing tests don't pass without the retargeting.
