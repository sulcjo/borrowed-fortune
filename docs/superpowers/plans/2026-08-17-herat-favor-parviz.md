# Herat Favor — Parviz, the Other Courier — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show Rostam's second errand actually happening on the stay-entangled path of the plunder route, via a new minor character (Parviz) who reads as comfortable in this work rather than cautionary.

**Architecture:** Pure content change. Five new dialogue nodes inserted into the existing `chapter_04b_herat_favor.json` between `n16a_the_first_task` and the existing terminal `n17a_departure_bound`, plus one new NPC portrait-generation entry in a separate offline tool's config file. No engine code changes, no manifest changes, no new chapter.

**Tech Stack:** Godot 4.3 / GDScript dialogue-tree JSON content (`content/chapters/chapter_04b_herat_favor/herat_favor.json`); Python offline tool (`tools/pixellab/generate_portraits.py`) for the optional portrait asset.

**Spec:** `docs/superpowers/specs/2026-08-17-herat-favor-parviz-design.md`

## Global Constraints

- **No GUT test suite runs, no `tests/unit/*.gd` edits** — standing instruction from the user for this project, overriding this skill's default TDD test-writing steps. Verification substitutes: JSON validity check via `python3 -c "import json; json.load(open(...))"`, manual next_id chain tracing, and an `advisor()` consultation before the pass is considered done. This applies to every task below.
- Every new node's `effects` dict must exactly match what's specified per node — no extra keys, no omitted keys.
- No new boolean flag anywhere in this scene (per spec: nothing downstream would ever read one).
- Do not touch `n15b_pivot_away`, `n16b_the_veiled_threat`, `n17b_departure_free`, or any other node on the `chose_to_pivot_away` branch.
- Do not touch `chapter_05_plunder_ending`'s content or flags.
- Do not add a coin effect (`coin_spent_dirham_equivalent` / `coin_gained_dirham_equivalent`) anywhere in this scene.
- Do not add a new glossary term.

---

## Task 1: Add Parviz scene content to `chapter_04b_herat_favor.json`

**Files:**
- Modify: `content/chapters/chapter_04b_herat_favor/herat_favor.json`

**Interfaces:**
- Consumes: nothing new — the existing `n16a_the_first_task` node and `n17a_departure_bound` node, both already present in the file, are the only integration points.
- Produces: five new node ids for any future work to reference: `n16c_the_handoff`, `n16d_parviz_introduced`, `n16e_parviz_at_ease`, `n16f_asked_if_it_gets_easier`, `n16h_carrying_it_back`. `npc_portrait: "parviz"` is the string id Task 2's asset must match exactly.

- [ ] **Step 1: Retarget `n16a_the_first_task`'s existing choice**

Find this exact node in the file:

```json
	{
		"id": "n16a_the_first_task",
		"text": "Rostam gave him the particulars without ceremony - a name, a place, nothing that sounded any more dangerous than the delivery he'd just completed - and Farrukh understood, accepting it, that he had just become a slightly different kind of person than the one who'd walked into this quarter an hour ago, in a way no single moment of the conversation had quite let him refuse.",
		"npc_portrait": "rostam",
		"choices": [
			{
				"text": "Continue.",
				"next_id": "n17a_departure_bound",
				"effects": {}
			}
		]
	},
```

Change only the `next_id` value inside its `choices` array from `"n17a_departure_bound"` to `"n16c_the_handoff"`. Leave `text`, `npc_portrait`, and `effects` exactly as they are.

- [ ] **Step 2: Insert the five new nodes**

Insert the following five node objects into the array, positioned immediately before the existing `n17a_departure_bound` node (so the file reads `n16a` → new nodes → `n17a` → `n15b_pivot_away` in the same relative order the file already uses):

```json
	{
		"id": "n16c_the_handoff",
		"text": "The place Rostam had named turned out to be a narrow storeroom off a dyer's yard, chosen, Farrukh guessed, for the practical reason that nobody asked why a courier might smell of indigo rather than whatever he was actually carrying. Someone was already waiting when he arrived - unhurried, comfortable, the particular ease of a man who had done this exact wait often enough to stop finding it worth impatience over.",
		"choices": [
			{
				"text": "Continue.",
				"next_id": "n16d_parviz_introduced",
				"effects": {}
			}
		]
	},
	{
		"id": "n16d_parviz_introduced",
		"text": "\"You'll be Rostam's new one,\" the man said, not quite a question, already reaching to help with the wrapped bundle Farrukh was carrying as if the two of them had done this together before. He gave his name as Parviz, easily, the way a man gives a name he's never had reason to be careful with. Farrukh placed him at a year into this work, maybe two - not new to it, not worn down by it either, in a way that was somehow harder to read than either extreme would have been.",
		"npc_portrait": "parviz",
		"choices": [
			{
				"text": "Continue.",
				"next_id": "n16e_parviz_at_ease",
				"effects": {}
			}
		]
	},
	{
		"id": "n16e_parviz_at_ease",
		"text": "Parviz talked while they finished the handoff, unhurried, the way a man talks about any job he has long since stopped resenting - which street to avoid on which day, which official's palm needed how much grease and no more, the small unglamorous mechanics of moving things that weren't supposed to move. He did not lower his voice doing it, and did not seem to think he needed to. Farrukh, one errand into this himself, found the ease more unsettling than caution would have been.",
		"npc_portrait": "parviz",
		"choices": [
			{
				"text": "Ask him if it gets easier.",
				"next_id": "n16f_asked_if_it_gets_easier",
				"effects": {"reputation": {"hidden_network": 1}}
			},
			{
				"text": "Say as little as possible. This isn't a friendship.",
				"next_id": "n16h_carrying_it_back",
				"effects": {}
			}
		]
	},
	{
		"id": "n16f_asked_if_it_gets_easier",
		"text": "\"Easier?\" Parviz considered the word like it belonged to a language he'd half-forgotten. \"It stops being a question you ask yourself, is what it does. That's not nothing.\" He said it kindly, meaning it as reassurance, the way an older hand offers a younger one the only honest comfort available - and Farrukh understood, hearing it land exactly as kindly as intended, that the kindness was the part that should have worried him most.",
		"npc_portrait": "parviz",
		"choices": [
			{
				"text": "Continue.",
				"next_id": "n16h_carrying_it_back",
				"effects": {}
			}
		]
	},
	{
		"id": "n16h_carrying_it_back",
		"text": "The task itself took less time than the conversation around it had, and cost Farrukh nothing he could point to afterward - no coin, no danger, nothing a customs man or a qadi would ever have cause to notice. What he carried back out of that storeroom was smaller and harder to name: the specific, unhurried ease of a man a year or two further down the same road Farrukh had just started walking, and the plain fact that he could no longer be entirely certain that ease was something to fear rather than something to eventually feel himself.",
		"choices": [
			{
				"text": "Continue.",
				"next_id": "n17a_departure_bound",
				"effects": {}
			}
		]
	},
```

Do not modify `n17a_departure_bound` itself in any way — it stays exactly as it already is, including its `next_chapter_id`.

- [ ] **Step 3: Validate JSON**

Run: `python3 -c "import json; json.load(open('content/chapters/chapter_04b_herat_favor/herat_favor.json'))" && echo OK`
Expected: `OK` with no exception.

- [ ] **Step 4: Manually trace both branches**

Confirm by reading the file: `n16a_the_first_task` → `n16c_the_handoff` → `n16d_parviz_introduced` → `n16e_parviz_at_ease` → (either `n16f_asked_if_it_gets_easier` → `n16h_carrying_it_back`, or directly → `n16h_carrying_it_back`) → `n17a_departure_bound`. Confirm no node id collides with any existing id in the file (in particular `n16b_the_veiled_threat`, which belongs to the unrelated pivot-away branch and must not be touched or reused).

- [ ] **Step 5: advisor() consultation**

Call `advisor()` before proceeding. Address anything it flags (tonal leaks, unintended reachability issues, orphaned effects) before moving to Task 2.

- [ ] **Step 6: Commit**

```bash
git add content/chapters/chapter_04b_herat_favor/herat_favor.json
git commit -m "content: show Rostam's second errand happening, via Parviz

Fills the thinnest stretch of the plunder route's stay-entangled path -
n16a_the_first_task previously jumped straight to departure without ever
showing the errand it described. Five new nodes show the delivery itself
and introduce Parviz, a courier further into this work than Farrukh,
who reads as comfortable rather than cautionary - deliberately not a
warning sign, per the approved design spec.

No new flag (nothing downstream reads one), no coin effect, pivot-away
branch untouched. Implements docs/superpowers/specs/2026-08-17-herat-favor-parviz-design.md."
```

---

## Task 2: Add Parviz's portrait entry to the pixellab config

**Files:**
- Modify: `tools/pixellab/npcs.json`

**Interfaces:**
- Consumes: the `npc_portrait: "parviz"` string id produced by Task 1 — this task's `id` field must match it exactly.
- Produces: nothing consumed by later tasks. This task is independently reviewable/skippable — the game runs correctly without it (missing portraits clear gracefully, per `tests/unit/test_chapter_view_portraits.gd`'s existing `test_npc_portrait_with_unknown_id_clears_without_erroring` test).

- [ ] **Step 1: Read the current file to confirm exact format**

Run: `python3 -c "import json; print(json.dumps(json.load(open('tools/pixellab/npcs.json'))['npcs'][:2], indent=2))"`
Expected output shows entries shaped like `{"id": "nasuh", "description": "..."}`.

- [ ] **Step 2: Add the new entry**

Add this object to the `npcs` array (any position — order doesn't matter to the generator):

```json
{"id": "parviz", "description": "a young courier in road-worn but decent clothes, relaxed unguarded posture, faint easy smile, waist-up portrait bust"}
```

- [ ] **Step 3: Validate JSON**

Run: `python3 -c "import json; json.load(open('tools/pixellab/npcs.json'))" && echo OK`
Expected: `OK` with no exception.

- [ ] **Step 4: Commit the config entry**

```bash
git add tools/pixellab/npcs.json
git commit -m "chore: add Parviz to the pixellab portrait generation config"
```

- [ ] **Step 5: Generate the portrait (requires user's own credentials)**

This step cannot be run by an agent in this worktree — there is no `.env` with pixellab API credentials here. Tell the user:

> "Parviz's config entry is in place. To generate the actual portrait PNG, run `python tools/pixellab/generate_portraits.py` (see `tools/pixellab/README.md` for the exact invocation and required `.env` setup) from an environment with valid pixellab credentials. The game works correctly without this — the portrait will simply be absent until it's generated — so this can happen whenever you're ready, no urgency."

Do not attempt to fabricate credentials, skip this step silently, or mark it complete without the user's own action.

---

## Self-Review Notes

- **Spec coverage:** every bullet in the spec's "The content" and "Portrait asset" sections maps to a step above. The "Testing" section's manual-verification list is fully covered by Task 1 Steps 3-5. The "What this pass does not do" list is covered by Global Constraints.
- **Placeholder scan:** no TBD/TODO; all node text is final prose, not a description of prose.
- **Type/id consistency:** `npc_portrait: "parviz"` (Task 1, three nodes) matches `"id": "parviz"` (Task 2) exactly. All five new node ids are referenced consistently across their own `next_id` chain with no typos introduced during the self-review pass.
