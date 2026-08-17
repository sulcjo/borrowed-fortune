# Mihran's Venture — Wiring Up the Mudaraba Mechanic

**Status:** approved, pending implementation plan.

## Goal

This is the "merchant ventures" north-star item, scoped down through direct conversation with the user from a broad "merchant ventures" idea to something concretely buildable in one pass.

**Confirmed with the user:**
- `Ledger`, `Coin`, `Debt`, and `ReputationTracker` are already fully wired into live gameplay — the dormant pieces are narrower than "merchant ventures" sounded: just `MudarabaPartnership.gd` and `Suftaja.gd`, both tested in isolation (`tests/unit/test_mudaraba_and_suftaja.gd`) but never instantiated by any chapter or by `ChapterView.gd`. This pass wires up `MudarabaPartnership` specifically; `Suftaja.gd` stays as-is (the suftaja *concept* is already dramatized narratively in Bost, without instantiating the class — that's a separate, already-shipped decision from an earlier pass, not something this spec touches).
- Real stakes, delayed resolution: Farrukh enters the arrangement in one city and learns the outcome in a later one — this is the only option that actually exercises `MudarabaPartnership` as a live mechanic rather than narrative flavor, and it fits this session's established "delayed consequences" pattern (the seal, the declined charge, etc.).
- Farrukh takes the **agent/mudarib** role, not financier — matches his situation (spending down an inheritance all game, not accumulating capital to invest) and the historical protection this role gets (no personal loss for honest failure).
- **Mihran (Bost) offers it; resolves at Pushang.** Mihran is already this game's "explains real finance" voice (the suftaja/letters-of-credit scene). Pushang already dramatizes the exact kind of frontier trouble (garrison requisitions, the muster) that can plausibly eat a venture's margin — the resolution ties into an existing thematic throughline instead of inventing a new one.
- **Outcome: a loss, but Farrukh owes nothing for it.** Per `MudarabaPartnership.settle()`'s own existing logic, an honest (non-negligent) loss falls entirely on the financier. This is the one outcome that actually *demonstrates* mudaraba's distinctive fairness feature by living it, rather than a profit that would just feel like a bonus. It mirrors Farrukh's own requisition scene at Pushang's gate a few nodes earlier.
- **Test scope, confirmed explicitly:** the standing "no GUT tests for content changes" instruction does not extend to this pass's engine-code change. `ChapterView._apply_effects()`'s new branch gets real GUT tests, matching this project's existing engine-layer convention (`MudarabaPartnership.gd` already has its own test file). The Bost/Pushang dialogue content stays test-free, as with every other content pass this session.

## The content

### Bost: the offer

Bost's `n07_the_offer` forks into `n08a_pressed`/`n08b_patient` (the suftaja-mystery name reveal), both of which currently choice straight to `n09_the_palace_glimpsed` with `effects: {}`. Retarget both of those choices' `next_id` from `"n09_the_palace_glimpsed"` to `"n08c_mihrans_proposition"`. Neither node's `text` changes.

**New node `n08c_mihrans_proposition`** (`npc_portrait: "mihran"`), reached identically regardless of which name-reveal path was taken — the venture offer doesn't depend on that choice:

> Mihran set the last of Farrukh's coin aside and, in the same unhurried voice he'd used for everything else that afternoon, mentioned he had a merchant contact bound for Herat who could use a second pair of hands he trusted - someone to mind a share of the goods the rest of the way, for a cut of whatever they sold for. "{{mudaraba|Mudaraba}}," he said, when Farrukh asked what to call it. "His capital, your carrying. If it turns a profit, you take a share of it. If it doesn't - and roads like this one don't always let it - the loss is his to carry, not yours, provided you haven't been careless with what he trusted you to carry. That's the whole of the arrangement. Older than either of our fathers, and it still works exactly that plainly."

Choices:
- `"Take the arrangement."` → `n09_the_palace_glimpsed`, effects `{"flags": ["entered_mihrans_venture"]}`
- `"Decline. You have enough to carry."` → `n09_the_palace_glimpsed`, effects `{}` — matches this game's established "declining costs nothing" precedent.

Both converge on the existing `n09_the_palace_glimpsed`, unchanged.

### New glossary term

`content/glossary/bost_terms.json` gets one new entry, alongside the existing `sarraf`/`jizya` (checked directly: no other chapter's glossary defines `mudaraba` — confirmed via grep across `content/glossary/`, avoiding the exact collision class that bit an earlier pass this session with "amana"):

```json
"mudaraba": {
  "headword": "Mudaraba",
  "definition": "A profit-sharing partnership between an investor's capital and an agent's labor - profit is split by an agreed ratio, but ordinary loss falls on the capital alone; the agent forfeits only his effort, unless he acted negligently."
}
```

### Pushang: the resolution

Pushang's `n11_after_the_requisition` currently has one choice, `"Continue." → n12_departure_pushang, effects: {}`. Change its `choices` array to two entries, matching this game's established gated-choice-plus-ungated-fallback pattern:

```json
"choices": [
  {"text": "See if any word has reached you about the venture.", "requires_flag": "entered_mihrans_venture", "next_id": "n11b_word_of_the_venture", "effects": {}},
  {"text": "There's nothing left to do here but move on.", "next_id": "n12_departure_pushang", "effects": {}}
]
```

The two choices need genuinely distinct wording, not identical `"Continue."` labels, because of how `DialogueEngine` actually evaluates gated choices. `DialogueEngine.gd`'s `_choice_is_available()` (backing `available_choices()`) only checks `requires_flag` against the current flag state for choices that *have* one; a choice with no `requires_flag` at all passes that check unconditionally and is always included, regardless of what any other choice's flag is set to. There is no mutual-exclusivity mechanism anywhere in the engine that suppresses an ungated choice just because a gated sibling also qualifies. That means when `entered_mihrans_venture` IS set, the player sees **both** choices at once, on the same screen: the gated one and the ungated fallback. If both read `"Continue."`, the player would be looking at two identical, indistinguishable buttons with different destinations — confusing regardless of which one they pick.

This is a different pattern from `plunder_ending.json`'s `n02_which_road_he_walks`, which offers two *gated* choices (`requires_flag: "chose_to_stay_entangled"` and `requires_flag: "chose_to_pivot_away"`) with no ungated fallback at all. Those two flags are set exclusively by the two options of `n14_the_choice` in `chapter_04b_herat_favor` - the only place either flag is ever set - and `chapter_04b_herat_favor` is the only path in the manifest that leads into `chapter_05_plunder_ending` at all (`chapter_04a_herat` routes to `chapter_06_pushang` instead, bypassing both `n14_the_choice` and `chapter_05_plunder_ending` entirely). Every playthrough that reaches `plunder_ending.json` has therefore necessarily passed through `n14_the_choice` and set exactly one of the two flags, so exactly one of `n02_which_road_he_walks`'s two choices is ever available - genuinely mutually exclusive, with nothing rendering both simultaneously. That true exclusivity is why identical `"Continue."` labels are safe there and are not safe here.

**New node `n11b_word_of_the_venture`** (no `npc_portrait` — Mihran isn't on-page; this is Farrukh alone with news that reached him):

> Word reached him before he'd cleared the town's edge - a courier, paid in advance out of Mihran's own pocket for exactly this, already waiting with an answer by the time Farrukh thought to ask after it. The venture had run afoul of a requisition of its own, somewhere on the road past Herat - past the point where Farrukh's own carrying of it had ended and it had passed into other hands to carry onward - the frontier's arithmetic at work again, the same necessity he had just witnessed at the gate, now exacting its price from the venture's capital. The loss was real. It was also, plainly and without any hedging in the telling, not his to make good: he had watched what he was given as carefully as anyone could have asked, and a man who watches carefully doesn't owe for a garrison's arithmetic.

One choice: `"Continue."` → `n12_departure_pushang`, effects:

```json
{
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
```

`n12_departure_pushang` itself is unchanged.

## Engine change

`scenes/chapter_view/ChapterView.gd`'s `_apply_effects(effects: Dictionary)` (currently lines 154-174) ends with:

```gdscript
	if effects.has("coin_spent_dirham_equivalent"):
		ledger.spend_dirham_equivalent(effects["coin_spent_dirham_equivalent"])
	if effects.has("coin_gained_dirham_equivalent"):
		ledger.receive_dirham_equivalent(effects["coin_gained_dirham_equivalent"])
```

Add a new block immediately after those two, following the same style (typed dictionary extraction, direct ledger calls):

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

`financier_result` (the other key in `settle()`'s return dict) is narrative-only — what Mihran's contact got — and is never read or applied; only `agent_result` ever touches Farrukh's own ledger. When `agent_result` is exactly `0.0` (this scene's actual case), neither branch fires and the ledger is untouched, which is the correct behavior, not a gap — `MudarabaPartnership.settle()` already runs and computes that zero for real; the engine doesn't need to do anything further with it.

With this scene's numbers (`capital: 40.0`, `outcome: 28.0`, `profit_share: 0.5`, `negligent: false`): profit is `28.0 - 40.0 = -12.0` (a loss), and since `agent_was_negligent` is `false`, `settle()`'s existing logic returns `{"financier_result": 28.0, "agent_result": 0.0}` — the mechanic runs for real, at play time, and correctly computes "Farrukh owes nothing," rather than the content merely asserting that in prose.

## Testing

Per the user's explicit confirmation, this pass's split is:

**Engine code (`ChapterView._apply_effects()`'s new branch) gets real GUT tests, written TDD-first**, covering (at minimum):
- A losing, non-negligent settlement (this scene's actual case) applies `agent_result: 0.0` — ledger wealth unchanged.
- A profitable settlement applies a positive `agent_result` correctly to the ledger, verifying the handler is correct generically, not just for the one scenario this content happens to use.
- A negligent-loss settlement applies a negative `agent_result` (a ledger deduction) — sanity coverage for a branch no current content exercises, confirming the handler doesn't silently clamp to zero.

**Bost/Pushang dialogue content stays test-free**, per the standing project instruction — verified instead by manual `next_id`/reachability tracing and an `advisor()` consultation, same as every other content pass this session. `python3 -c "import json; json.load(open(...))"` confirms both edited chapter files still parse.

## What this pass does not do

- Does not touch `Suftaja.gd` or add any new suftaja-redemption content — that class stays exactly as dormant as it is today; the suftaja concept's existing narrative treatment in Bost (without instantiating the class) is a separate, already-shipped decision this spec doesn't revisit.
- Does not add a UI for choosing investment amount, risk level, or any other player-tuned numeric input — the venture's terms are fixed story constants, same as every other economic effect in this game.
- Does not touch `Ledger.gd`, `Coin.gd`, `Debt.gd`, or `ReputationTracker.gd` — all already live and unaffected by this change.
- Does not change `n09_the_palace_glimpsed`, `n10_departure_bost`, or `n12_departure_pushang` — all three stay byte-identical to before.
- Does not add a negligent-outcome path anywhere in actual content — the negligent branch is covered only by the engine test suite, as a correctness guarantee for future content, not something this pass's own scene uses.
