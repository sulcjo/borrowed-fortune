# Trading Engine — Design Doc

**Status:** Approved for planning. **Date:** 2026-08-09
**Builds on:** `2026-08-07-borrowed-fortune-design.md` (the original spec's deferred "trade & haggle" commitment), Farah's `coin_spent_dirham_equivalent` effects key (Chapter 3, `v0.4-farah`) — the first, minimal instance of coin actually moving through play.

---

## 1. Purpose

Every chapter so far has treated coin as something Farrukh only loses (debts guaranteed, a bed haggled over in Farah). This is the standing "give the trade system real gameplay" commitment finally getting paid off — not as a full merchant-simulation economy (no goods inventory, no city-to-city price arbitrage), but as a real, repeatable **haggling mechanic**: multi-round, choice-driven negotiation where the player's reputation with a faction can open a better outcome, and where coin can finally flow both ways.

This spec covers the **engine layer only** — two small, additive changes — plus a **content-authoring pattern** that Chapter 4A and 4B (and any future chapter) will use to actually write haggle scenes. It does not itself add any chapter content.

**Explicitly out of scope** (confirmed with the user): a goods/inventory system, dynamic city-to-city pricing, numeric player-entered offers, and any randomized/dice-roll outcome — every haggle's result is deterministic content, authored the same way Farah's bed-price fork already was, just with more rounds and now a reputation-gated branch.

---

## 2. Engine Changes

### 2.1 `Ledger` gains symmetric income

`engine/ledger/Ledger.gd` currently has `spend_dirham_equivalent(amount: float) -> void`, which accumulates into `spent_dirham_equivalent` and is subtracted in `total_wealth_dirham_equivalent()`. Add the mirror:

```gdscript
func receive_dirham_equivalent(amount: float) -> void:
	spent_dirham_equivalent -= amount
```

No new field needed — the existing accumulator already generalizes in both directions (`total_wealth_dirham_equivalent()` doesn't change). `ChapterView._apply_effects()` gains a new effects key, `"coin_gained_dirham_equivalent"`, calling this method — the exact mirror of how `"coin_spent_dirham_equivalent"` already calls `spend_dirham_equivalent()`.

### 2.2 `DialogueEngine` choice-gating gains `requires_reputation`

Currently, `_choice_is_available()` only checks `requires_flag` against `DialogueEngine.flags` (a `Dictionary` `ChapterView` never has to touch directly — `choose()` populates it itself from each choice's `effects.flags`). Reputation is different: it lives in `ChapterView`'s separate `ReputationTracker`, and `DialogueEngine` currently knows nothing about it.

Add a new field, `reputation: Dictionary = {}`, to `DialogueEngine` — a plain `{faction_id: int}` snapshot, structurally identical to what `ReputationTracker.to_dict()` already returns. `ChapterView` is responsible for keeping it in sync: right after `_apply_effects()` applies a reputation delta (and once, right after loading a chapter), it assigns `dialogue_engine.reputation = reputation_tracker.to_dict()`. `DialogueEngine` itself never mutates this field and never imports `ReputationTracker` — it stays a `RefCounted` engine class with zero knowledge of where the numbers come from, same as `flags`.

A choice may now carry `"requires_reputation": {"faction_id": "trading_families", "min_score": 2}`. `_choice_is_available()` checks both gates — a choice with neither key is always available, same as today:

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

(The `int(...)` cast on `min_score` follows the project's standing hard rule — `min_score` arrives from JSON as a `float`.)

This is the only new gating primitive. It composes with `requires_flag` (a choice can require both) and is checked the same way `validate_tree()` already checks `requires_flag`-adjacent content — no change needed there, since `requires_reputation` doesn't affect graph reachability validation (a reputation-gated choice's `next_id` still must exist, same as any other choice).

---

## 3. Content-Authoring Pattern: the Haggle Scene

This is not new engine code — it's a template for how a haggle scene gets written as ordinary `DialogueEngine` nodes, for whoever authors Chapter 4A/4B's haggle content. A minimal worked example (faction and numbers illustrative, not final):

1. **Opening node** — seller states an asking price. Choices:
   - `"Offer a fair price."` → a **convergence node**: deal struck, effects `{"coin_spent_dirham_equivalent": <fair_price>}`, reputation usually neutral or slightly positive.
   - `"Lowball him."` → a **round-2 reaction node** (seller pushes back).
   - `"Walk away."` → a **walk-away node**: no purchase, effects usually empty or a small flavor reputation delta, converges to the scene after the haggle either way.
   - *(optional)* `"Remind him of your standing."`, gated `requires_reputation: {"faction_id": "<relevant faction>", "min_score": <N>}` → a **discount node**: deal struck at a better price than the fair option, available only to a player who's earned it.

2. **Round-2 reaction node** (reached only via lowball) — the seller reacts to being lowballed. Choices:
   - `"Back off to a fair price."` → the same convergence node as above (or an equivalent one), same effects.
   - `"Push further."` → either a **breakdown node** (negotiation fails — no purchase, a real reputation cost, this is the "walk-away risk" the haggle needs to actually carry) or a **grudging-deal node** (deal struck, but at a worse price than the fair option would have gotten, plus a reputation cost) — pick whichever the specific scene's narrative stakes call for; both are legitimate, and a scene can use either or offer the player a further choice between them.

This is 4-6 nodes per haggle scene (vs. Farah's 1-node, 2-choice version) — richer, still entirely inside the existing `DialogueEngine`/`ChapterView` machinery. Nothing about this pattern requires every haggle in the game to use all of it — a low-stakes haggle can stay as simple as Farah's; this template is for the ones a chapter wants to make matter.

---

## 4. Scope & Next Steps

Chapters 4A and 4B (Herat, the two Farah-fork variants — see project memory) will be the first real consumers of this pattern, each authoring their own haggle scenes and their own income moments (a paid delivery, a partial debt repayment, selling something) using `coin_gained_dirham_equivalent`. This spec ships engine-only; no chapter content, no manifest changes. Next step: `writing-plans` for this spec alone, followed by its own subagent-driven implementation, before either Chapter 4 variant's design begins.
