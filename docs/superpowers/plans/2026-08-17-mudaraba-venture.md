# Mihran's Venture — Wiring Up the Mudaraba Mechanic — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire the previously-dormant `MudarabaPartnership.gd` class into live gameplay — Mihran offers Farrukh a mudarib role in Bost, Pushang resolves it as a real, engine-computed settlement.

**Architecture:** One new effects key (`mudaraba_settlement`) handled in `ChapterView._apply_effects()`, which constructs a real `MudarabaPartnership` and calls its existing `.settle()` method — no new persistent state, no cross-chapter object serialization. Two chapter-content edits (Bost, Pushang) that offer and resolve the venture using that key.

**Tech Stack:** Godot 4.3 / GDScript (`scenes/chapter_view/ChapterView.gd`, `engine/ledger/MudarabaPartnership.gd`); GUT test framework (`tests/unit/test_chapter_view.gd`); JSON dialogue-tree content (`content/chapters/chapter_02_bost/bost.json`, `content/chapters/chapter_06_pushang/pushang.json`, `content/glossary/bost_terms.json`).

**Spec:** `docs/superpowers/specs/2026-08-17-mudaraba-venture-design.md`

## Global Constraints

- Only `agent_result` from `MudarabaPartnership.settle()` ever touches Farrukh's ledger. `financier_result` is narrative-only and must never be applied anywhere.
- The engine-code task (Task 1) gets real GUT tests, written TDD-first, per the user's explicit confirmation. Tasks 2 and 3 (chapter content) get NO GUT tests and NO edits to any `tests/unit/*.gd` file — standing project instruction. Verification for Tasks 2/3 is JSON validity + manual `next_id` tracing + `advisor()`.
- Do not touch `Suftaja.gd`, `Ledger.gd`, `Coin.gd`, `Debt.gd`, or `ReputationTracker.gd`.
- Do not change `n09_the_palace_glimpsed`, `n10_departure_bost`, or `n12_departure_pushang` — all three must remain byte-identical to their current content.
- No new UI, no player-tuned numeric input — venture terms are fixed story constants.
- No coin effect on accepting the offer at Bost — Farrukh contributes labor only, not capital.

---

## Task 1: Wire `mudaraba_settlement` into `ChapterView._apply_effects()`

**Files:**
- Modify: `scenes/chapter_view/ChapterView.gd:154-174` (the `_apply_effects` function)
- Test: `tests/unit/test_chapter_view.gd`

**Interfaces:**
- Consumes: `MudarabaPartnership.new(financier_name: String, agent_name: String, capital_dirham_equivalent: float, agent_profit_share: float)` and its `.settle(outcome_value_dirham_equivalent: float, agent_was_negligent: bool) -> Dictionary` method (both already exist in `engine/ledger/MudarabaPartnership.gd`, unchanged by this task), returning `{"financier_result": float, "agent_result": float}`. Also consumes the existing `ledger.receive_dirham_equivalent(amount: float)` and `ledger.spend_dirham_equivalent(amount: float)` methods on `Ledger` (already exist, unchanged).
- Produces: the `mudaraba_settlement` effects-dict key, consumed by Task 3's content.

- [ ] **Step 1: Write the three failing tests**

Add these three test functions to `tests/unit/test_chapter_view.gd`, near the existing `test_apply_effects_with_coin_spent_dirham_equivalent_spends_from_the_ledger` / `test_apply_effects_with_debt_repaid_pays_down_the_matching_debt_and_spends_from_the_ledger` tests (same file, same `add_child_autofree(ChapterViewScene.instantiate())` pattern):

```gdscript
func test_apply_effects_with_mudaraba_settlement_applies_a_positive_profit_share():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view._apply_effects({
		"mudaraba_settlement": {
			"financier_name": "Test Financier",
			"agent_name": "Farrukh",
			"capital_dirham_equivalent": 40.0,
			"agent_profit_share": 0.5,
			"outcome_value_dirham_equivalent": 60.0,
			"agent_was_negligent": false
		}
	})
	# profit = 60.0 - 40.0 = 20.0; agent_share = 20.0 * 0.5 = 10.0
	assert_almost_eq(chapter_view.ledger.total_wealth_dirham_equivalent(), 10.0, 0.0001)

func test_apply_effects_with_mudaraba_settlement_applies_zero_result_on_an_honest_loss():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view._apply_effects({
		"mudaraba_settlement": {
			"financier_name": "Mihran's contact",
			"agent_name": "Farrukh",
			"capital_dirham_equivalent": 40.0,
			"agent_profit_share": 0.5,
			"outcome_value_dirham_equivalent": 28.0,
			"agent_was_negligent": false
		}
	})
	# profit = 28.0 - 40.0 = -12.0 (loss), not negligent -> agent owes nothing
	assert_almost_eq(chapter_view.ledger.total_wealth_dirham_equivalent(), 0.0, 0.0001)

func test_apply_effects_with_mudaraba_settlement_applies_a_negative_result_on_a_negligent_loss():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view._apply_effects({
		"mudaraba_settlement": {
			"financier_name": "Test Financier",
			"agent_name": "Farrukh",
			"capital_dirham_equivalent": 40.0,
			"agent_profit_share": 0.5,
			"outcome_value_dirham_equivalent": 28.0,
			"agent_was_negligent": true
		}
	})
	# profit = 28.0 - 40.0 = -12.0; negligent -> agent bears the full loss
	assert_almost_eq(chapter_view.ledger.total_wealth_dirham_equivalent(), -12.0, 0.0001)
```

Note on the RED phase for the second test: since `_apply_effects()` currently has no handling for the `mudaraba_settlement` key at all, calling it is a silent no-op today — wealth stays at its default `0.0`, which happens to equal this test's expected value. This specific test cannot show a meaningful failure before implementation (a missing code path and a "net zero effect" look identical from the outside) — that's expected and fine; it still becomes real regression coverage once Step 3's implementation lands, guarding against a future change that accidentally applies a nonzero effect on an honest loss. The first and third tests DO show real, meaningful failures pre-implementation (see Step 2) and are what actually drives the implementation.

- [ ] **Step 2: Run the tests to verify the expected (partial) failure**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`

Expected: `test_apply_effects_with_mudaraba_settlement_applies_a_positive_profit_share` FAILS (`0.0` != `10.0`), `test_apply_effects_with_mudaraba_settlement_applies_a_negative_result_on_a_negligent_loss` FAILS (`0.0` != `-12.0`), `test_apply_effects_with_mudaraba_settlement_applies_zero_result_on_an_honest_loss` PASSES (vacuously, per the note above — this is expected, not a problem). All other existing tests still pass.

- [ ] **Step 3: Implement the minimal code**

In `scenes/chapter_view/ChapterView.gd`, find the end of `_apply_effects`:

```gdscript
	if effects.has("coin_spent_dirham_equivalent"):
		ledger.spend_dirham_equivalent(effects["coin_spent_dirham_equivalent"])
	if effects.has("coin_gained_dirham_equivalent"):
		ledger.receive_dirham_equivalent(effects["coin_gained_dirham_equivalent"])
```

Add immediately after those two blocks, inside the same function:

```gdscript
	if effects.has("mudaraba_settlement"):
		var venture: Dictionary = effects["mudaraba_settlement"]
		var partnership := MudarabaPartnership.new(
			venture["financier_name"],
			venture["agent_name"],
			venture["capital_dirham_equivalent"],
			venture["agent_profit_share"]
		)
		var result := partnership.settle(venture["outcome_value_dirham_equivalent"], venture["agent_was_negligent"])
		var agent_result: float = result["agent_result"]
		if agent_result > 0.0:
			ledger.receive_dirham_equivalent(agent_result)
		elif agent_result < 0.0:
			ledger.spend_dirham_equivalent(-agent_result)
```

- [ ] **Step 4: Run the full suite to verify all three pass and nothing else broke**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`
Expected: all three new tests PASS, and the full suite's total test count is unchanged apart from these 3 new tests, with zero failures.

- [ ] **Step 5: Commit**

```bash
git add scenes/chapter_view/ChapterView.gd tests/unit/test_chapter_view.gd
git commit -m "feat: wire MudarabaPartnership into ChapterView via a new effects key

Adds mudaraba_settlement handling to _apply_effects() - constructs a real
MudarabaPartnership and calls its existing settle() method at runtime.
Only agent_result ever touches the ledger; financier_result is narrative-
only. Covers profit, honest-loss, and negligent-loss cases.

Implements the engine-change section of
docs/superpowers/specs/2026-08-17-mudaraba-venture-design.md."
```

---

## Task 2: Bost — Mihran's venture offer

**Files:**
- Modify: `content/chapters/chapter_02_bost/bost.json`
- Modify: `content/glossary/bost_terms.json`

**Interfaces:**
- Consumes: nothing from Task 1 — this task only sets a boolean flag, no coin effect, no `mudaraba_settlement` key. It has no dependency on Task 1's engine code and could technically run in either order, but is sequenced after it for a clean narrative build order.
- Produces: flag `entered_mihrans_venture`, consumed by Task 3.

- [ ] **Step 1: Retarget the two name-reveal choices**

In `content/chapters/chapter_02_bost/bost.json`, find:

```json
	{
		"id": "n08a_pressed",
		"text": "Farrukh asked. Mihran told him - \"Mansur,\" and a city, Nishapur, delivered in the flat voice of a man crossing a line he'd hoped to avoid - then wrapped the suftaja back into its cloth with hands that were, for the first time since Farrukh had walked in, not entirely steady. \"It's probably not even his own name,\" he added, as if that made the giving of it safer. \"Don't come back here,\" he said, not unkindly. \"Not because of the debt. Because of this.\" Farrukh had his lead. He had also, he suspected, spent something he could not get back.",
		"npc_portrait": "mihran",
		"choices": [{"text": "Continue.", "next_id": "n09_the_palace_glimpsed", "effects": {}}]
	},
	{
		"id": "n08b_patient",
		"text": "Farrukh didn't ask. Mihran seemed to relax by a fraction he probably didn't notice himself. \"I'll tell you this much for nothing,\" he said. \"Whoever sent that second mark moves money the way water moves through Bost's canals - underground, on purpose, surfacing only where someone built a channel for it to surface. Follow the channels, not the water. You'll find your name eventually, and it will still be true when you do.\" It was less than a name. It felt, somehow, like more.",
		"npc_portrait": "mihran",
		"choices": [{"text": "Continue.", "next_id": "n09_the_palace_glimpsed", "effects": {}}]
	},
```

Change both nodes' `next_id` from `"n09_the_palace_glimpsed"` to `"n08c_mihrans_proposition"`. Nothing else on either node changes.

> **Deviation note (recorded during implementation):** this instruction was overridden by a controller ruling while this task was actually carried out. Only `n08b_patient`'s `next_id` was retargeted to `"n08c_mihrans_proposition"`; `n08a_pressed` was left pointing at `"n09_the_palace_glimpsed"`, unchanged. Reason: `n08a_pressed`'s own text ends with Mihran saying "Don't come back here... Not because of the debt. Because of this" — immediately following that line with Mihran offering Farrukh a trust-based venture arrangement would contradict what he'd just said. Retargeting only `n08b_patient` avoids that narrative contradiction while still making the venture offer reachable on the patient path. A future reader of this plan should not "fix" the shipped content back to match the original instruction above — the shipped, two-path-asymmetric result is the intended one.

- [ ] **Step 2: Insert the new node**

Insert this new node object immediately before the existing `n09_the_palace_glimpsed` node:

```json
	{
		"id": "n08c_mihrans_proposition",
		"text": "Mihran set the last of Farrukh's coin aside and, in the same unhurried voice he'd used for everything else that afternoon, mentioned he had a merchant contact bound for Herat who could use a second pair of hands he trusted - someone to mind a share of the goods the rest of the way, for a cut of whatever they sold for. \"{{mudaraba|Mudaraba}},\" he said, when Farrukh asked what to call it. \"His capital, your carrying. If it turns a profit, you take a share of it. If it doesn't - and roads like this one don't always let it - the loss is his to carry, not yours, provided you haven't been careless with what he trusted you to carry. That's the whole of the arrangement. Older than either of our fathers, and it still works exactly that plainly.\"",
		"npc_portrait": "mihran",
		"choices": [
			{"text": "Take the arrangement.", "next_id": "n09_the_palace_glimpsed", "effects": {"flags": ["entered_mihrans_venture"]}},
			{"text": "Decline. You have enough to carry.", "next_id": "n09_the_palace_glimpsed", "effects": {}}
		]
	},
```

Do not modify `n09_the_palace_glimpsed` or `n10_departure_bost` in any way.

- [ ] **Step 3: Add the glossary term**

In `content/glossary/bost_terms.json`, add a `mudaraba` entry alongside the existing `sarraf`/`jizya` entries:

```json
	"mudaraba": {
		"headword": "Mudaraba",
		"definition": "A profit-sharing partnership between an investor's capital and an agent's labor - profit is split by an agreed ratio, but ordinary loss falls on the capital alone; the agent forfeits only his effort, unless he acted negligently."
	}
```

- [ ] **Step 4: Validate JSON**

Run: `python3 -c "import json; json.load(open('content/chapters/chapter_02_bost/bost.json'))" && echo OK`
Run: `python3 -c "import json; json.load(open('content/glossary/bost_terms.json'))" && echo OK`
Expected: `OK` for both, no exception.

- [ ] **Step 5: Manually trace both paths**

Confirm by reading the file: `n07_the_offer` → (`n08a_pressed` or `n08b_patient`) → `n08c_mihrans_proposition` (n08b_patient only — see the deviation note at Step 1) → (either choice) → `n09_the_palace_glimpsed` → `n10_departure_bost`. Confirm `n08c_mihrans_proposition` does not collide with any existing node id in the file.

- [ ] **Step 6: advisor() consultation**

Call `advisor()` before proceeding. Address anything it flags before moving to Task 3.

- [ ] **Step 7: Commit**

```bash
git add content/chapters/chapter_02_bost/bost.json content/glossary/bost_terms.json
git commit -m "content: give Mihran a mudaraba offer for Farrukh in Bost

Both name-reveal paths (n08a_pressed, n08b_patient) now converge on a new
node, n08c_mihrans_proposition, before continuing to the existing
n09_the_palace_glimpsed - Mihran offers Farrukh a mudarib role in a small
venture, explained in his own voice. Accepting sets
entered_mihrans_venture; declining costs nothing, matching this game's
established precedent for declined offers.

Adds a mudaraba glossary term. Implements the Bost half of
docs/superpowers/specs/2026-08-17-mudaraba-venture-design.md."
```

---

## Task 3: Pushang — the venture's resolution

**Files:**
- Modify: `content/chapters/chapter_06_pushang/pushang.json`

**Interfaces:**
- Consumes: flag `entered_mihrans_venture` (Task 2) and the `mudaraba_settlement` effects key (Task 1) — both must already exist for this task's content to have any live effect, though the JSON itself is valid without them.
- Produces: nothing consumed by later tasks — this is the final task in the plan.

- [ ] **Step 1: Retarget `n11_after_the_requisition`'s choice**

In `content/chapters/chapter_06_pushang/pushang.json`, find:

```json
	{
		"id": "n11_after_the_requisition",
		"text": "Whatever it had cost him, Farrukh left the garrison gate with the same caravan he'd arrived with, which was more than the town's own watch, thinned past pairs, could apparently say for itself these days. A frontier failing was not, he was beginning to understand, one dramatic collapse - it was a hundred small requisitions like this one, in a hundred towns like this one, each individually reasonable, each one shaving a little more off whatever the word 'ordinary' had meant here a year ago.",
		"choices": [
			{"text": "Continue.", "next_id": "n12_departure_pushang", "effects": {}}
		]
	},
```

Change its `choices` array to:

```json
		"choices": [
			{"text": "Continue.", "requires_flag": "entered_mihrans_venture", "next_id": "n11b_word_of_the_venture", "effects": {}},
			{"text": "Continue.", "next_id": "n12_departure_pushang", "effects": {}}
		]
```

The node's own `text` does not change.

- [ ] **Step 2: Insert the resolution node**

Insert this new node immediately before the existing `n12_departure_pushang` node:

```json
	{
		"id": "n11b_word_of_the_venture",
		"text": "Word reached him before he'd cleared the town's edge - a courier, paid in advance out of Mihran's own pocket for exactly this, so the news didn't have to wait for Farrukh to ask after it himself. The venture had run afoul of a requisition of its own, somewhere back along the road - the same arithmetic Farrukh had just paid his way through at this very gate. The loss was real. It was also, plainly and without any hedging in the telling, not his to make good: he had watched what he was given as carefully as anyone could have asked, and a man who watches carefully doesn't owe for a garrison's arithmetic.",
		"choices": [
			{
				"text": "Continue.",
				"next_id": "n12_departure_pushang",
				"effects": {
					"mudaraba_settlement": {
						"financier_name": "Mihran's contact",
						"agent_name": "Farrukh",
						"capital_dirham_equivalent": 40.0,
						"agent_profit_share": 0.5,
						"outcome_value_dirham_equivalent": 28.0,
						"agent_was_negligent": false
					},
					"reputation": {"trading_families": 1}
				}
			}
		]
	},
```

Do not modify `n12_departure_pushang` in any way.

- [ ] **Step 3: Validate JSON**

Run: `python3 -c "import json; json.load(open('content/chapters/chapter_06_pushang/pushang.json'))" && echo OK`
Expected: `OK`, no exception.

- [ ] **Step 4: Manually trace both branches**

Confirm by reading the file: with `entered_mihrans_venture` set, `n11_after_the_requisition` → `n11b_word_of_the_venture` → `n12_departure_pushang`. Without it, `n11_after_the_requisition` → `n12_departure_pushang` directly (the second, ungated choice). Confirm `n11b_word_of_the_venture` does not collide with any existing node id in the file, and that `n12_departure_pushang`'s own text is unchanged.

- [ ] **Step 5: advisor() consultation**

Call `advisor()` before proceeding. Ask it specifically to verify the arithmetic in the `mudaraba_settlement` effects dict matches what Task 1's engine code will compute (capital `40.0`, outcome `28.0`, profit share `0.5`, not negligent → `agent_result: 0.0`), and to check this resolution doesn't contradict anything else already established about Pushang's requisition scene. Address anything it flags.

- [ ] **Step 6: Commit**

```bash
git add content/chapters/chapter_06_pushang/pushang.json
git commit -m "content: resolve Mihran's venture at Pushang - a loss Farrukh doesn't owe

Gated on entered_mihrans_venture (set in Bost). The venture ran into
frontier trouble of its own - a requisition, mirroring Farrukh's own gate
scene a few nodes earlier - and the loss falls on the financier, not on
Farrukh, per mudaraba's own real fairness logic. Applies a real
mudaraba_settlement effect (wired up in Task 1) rather than asserting the
outcome in prose alone.

Implements the Pushang half of
docs/superpowers/specs/2026-08-17-mudaraba-venture-design.md."
```

---

## Self-Review Notes

- **Spec coverage:** every section of the spec maps to a task — "Bost: the offer" → Task 2 Steps 1-2; "New glossary term" → Task 2 Step 3; "Pushang: the resolution" → Task 3 Steps 1-2; "Engine change" → Task 1 Step 3; "Testing" → Task 1 Steps 1-2/4 (engine) and Task 2/3 Steps for manual JSON validation + advisor (content). "What this pass does not do" is covered by Global Constraints.
- **Placeholder scan:** no TBD/TODO; all node text and code is final, not a description of what it should contain.
- **Type/id consistency:** `mudaraba_settlement`'s dict keys (`financier_name`, `agent_name`, `capital_dirham_equivalent`, `agent_profit_share`, `outcome_value_dirham_equivalent`, `agent_was_negligent`) are identical, spelled the same way, in Task 1's test code, Task 1's implementation, and Task 3's content. `entered_mihrans_venture` is spelled identically in Task 2 (set) and Task 3 (`requires_flag`). Numeric constants (`40.0`, `0.5`, `28.0`, `false` → `agent_result: 0.0`) match between Task 1's second test and Task 3's actual content effect, so the live behavior in-game will match what Task 1 already proved correct in isolation.
