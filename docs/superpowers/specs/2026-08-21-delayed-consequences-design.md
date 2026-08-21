# Delayed consequences — conditional text for cross-city payoffs

Date: 2026-08-21
Status: design approved, ready for implementation planning

## Why

The game records far more player decision than it ever consults. Measured against
`6173b5f`, across all 229 authored nodes:

| Measure | Value |
|---|---|
| Nodes offering **no decision** (0 or 1 choice) | **175 / 229 (76%)** |
| Nodes with 2 choices | 45 (20%) |
| Nodes with 3 or more choices | 9 (4%) |
| Choices gated on a flag | **14** |
| Choices gated on reputation | **1** |
| Distinct flags **set** by choices | 43 |
| Distinct flags **ever read** | **12** |

**31 of 43 flags are set and never read.** `bribed_teginabad_official`,
`honest_at_teginabad`, `earned_mihrans_trust`, `owes_tahir_a_favor`,
`chose_umm_kavus_channel` — the player decides, the engine records, nothing ever
consults it. Of those 31, **24 have chapters downstream** and so can be paid off;
the remaining 7 are set by ending choices in Nishapur and the plunder ending and
have nothing after them by construction.

Those 24 are the cheapest narrative material in the repository. The decision, its
prose, and its flag already exist and cost nothing further. Only the consequence
needs writing.

**Correction found during implementation: 19 of the 24, not all 24.** Five are set
by a node offering only `"Continue."`, so they are set on every playthrough and a
variant gated on one would fire always — which is just editing the base text with
extra ceremony. Those five are `vowed_kafala` and `carries_own_ledger` (both on the
Prologue's mandatory spine, so genuinely unconditional) and `began_his_own_ledger`,
`knows_the_second_marks_name`, `owes_tahir_a_favor` (single-choice nodes inside
Farah's optional branches, so they may still vary in practice — worth checking per
flag before writing one off). A flag is only useful as a variant condition if some
playthrough does not set it.

## The constraint this removes

A node's `text` is fixed. There is no conditional prose, so "Mihran's man
recognises you" can only be expressed by routing to a *different node* through a
gated choice. That makes the cheapest-feeling payoff — one sentence landing
differently because of something four chapters back — the most expensive to
author, and pushes every consequence toward a whole branch. The result is a graph
that grows without becoming more decidable.

## Scope

**In scope**

- `engine/dialogue/DialogueEngine.gd` — resolve conditional text; extend validation.
- `content/chapters/*/*.json` — an optional `text_variants` key on nodes.
- `scenes/chapter_view/ChapterView.gd` — one line, to ask for resolved text.
- An authoring pass wiring the 24 payable flags.

**Out of scope**

- **Cutscene variance.** Five of the seven terminal flags record which ending the
  player chose, and varying the outro on them is attractive. It is not cheap:
  cutscene panels are `{image_path, caption}`, a different schema, and
  `Cutscene.gd` receives only a `content_path` export with no access to dialogue
  flags. Passing game state into cutscenes is separate work.
- **The other three subsystems** identified alongside this one: recurring
  characters (generalising Yusuf), road situations (turning the nine one-node road
  beats into 3–6 node situations), and time/actions in cities (generalising the
  two-day Nishapur). Each needs its own spec. Time/actions is the only one that
  requires new engine code beyond this.
- **Deleting the 7 terminal flags.** They are a meaningful authorial record of
  which ending was reached and cost nothing to keep.

## Decisions and their provenance

1. **Conditional text added to the engine**, over gated-choices-only, over
   mechanical-only consequences, over a both-with-a-rule hybrid. Chosen because it
   makes the common case cheap: the same beat reads differently with no new nodes,
   so consequence density rises without node count rising.
2. **First matching variant wins**, over "most conditions satisfied". Predictable
   from reading the file, at the cost that a mis-ordered array silently shadows a
   later variant.
3. **Node-count targets rejected as the metric.** An earlier framing proposed
   229 → 650–750 nodes. Volume is not the goal and would actively pull toward
   padding, since the cheapest way to reach 700 is 470 more single-choice nodes —
   exactly what the codebase already over-produces. The decision metrics below
   replace it.

## Schema

A node gains an optional `text_variants` array. Every existing node is untouched
and keeps working.

```json
{
  "id": "n09_the_officers_demand",
  "text": "An officer at the gate — young, tired, working from a list that clearly hadn't gotten shorter all week — looked over Farrukh's manifest … naming a sum.",
  "text_variants": [
    { "requires_flag": "bribed_teginabad_official",
      "text": "An officer at the gate named a sum, and something in how he named it said he already knew you were a man who paid." },
    { "requires_flag": "honest_at_teginabad",
      "text": "An officer at the gate named a sum, then hesitated — your manifest was in better order than most that crossed his table." }
  ],
  "choices": [ "…unchanged…" ]
}
```

Same beat, same four choices, no new nodes — Teginabad reaching four chapters
forward into Pushang.

A variant may carry `requires_flag`, `requires_reputation`, or both; when both are
present both must hold. These are the same two conditions choices already support,
so authors learn no new vocabulary.

## Selection semantics

- Variants are tested in array order; the first whose conditions hold supplies the
  text.
- No variant matching falls back to the node's own `text`, which is therefore the
  unconditional reading and must always be present. All 229 existing nodes already
  carry non-empty text (verified), so having `validate_tree()` require it is a
  zero-cost tightening rather than a migration.
- Author-ordered priority means the most specific variant goes first. The validator
  cannot detect a mis-ordered array, so ordering is a review concern.
- Resolution is pure: same flags plus same reputation always yields the same text.

## Engine surface

```gdscript
# Returns the current node's text with any matching variant applied.
func current_text() -> String

# Extracted from _choice_is_available() so choices and text variants apply
# identical rules rather than two implementations drifting apart.
func _conditions_met(condition_holder: Dictionary) -> bool
```

`_choice_is_available()` becomes a call to `_conditions_met()`, so the existing
gating behaviour is unchanged by construction and its tests keep passing.

`validate_tree()` gains two checks, in the style of the existing ones:

- a variant missing a non-empty `text`
- a variant with a malformed `requires_reputation` (the same shape check already
  applied to choices)

Gloss tokens inside variant text must be parsed too — `validate_tree()` already
rejects unparsed `{{…}}` in a node's `text` and must apply the same check to every
variant, or a typo in a variant would reach the screen as literal braces.

## Renderer

`ChapterView._render_current_node()` changes one line, from
`node.get("text", "")` to `dialogue_engine.current_text()`. Gloss marking and
margin notes already derive from the node's raw text; they must derive from the
**resolved** text instead, or a variant's glossed terms would not appear in the
margin.

## Authoring pass

The 24 payable flags, with the chapter that sets each. Payoff sites are proposals
to settle per thread during implementation, not fixed assignments.

| Set in | Flags |
|---|---|
| Prologue | `vowed_kafala`, `spoke_now`, `waited`, `carries_own_ledger`, `avoided_unsigned_letter` |
| Teginabad | `bribed_teginabad_official`, `honest_at_teginabad`, `haggled_at_teginabad`, `heeded_the_desert_warning`, `revealed_letter_to_said` |
| Bost | `earned_mihrans_trust`, `learned_of_two_mints_dispute` |
| Farah | `began_his_own_ledger`, `chose_tahirs_price`, `chose_umm_kavus_channel`, `knows_the_second_marks_name`, `owes_tahir_a_favor` |
| Herat | `asked_about_the_mints_delay`, `full_network_reveal`, `partial_network_reveal`, `hid_the_rayy_paper_more_carefully` |
| Pushang | `asked_about_the_khutba` |
| Sarakhs | `accepted_the_charge_for_payment`, `learned_of_arranged_ghulam_marriages` |

The Prologue's five are the highest-value starting point: set earliest, so they can
echo anywhere downstream, and they encode the vow the whole game hangs on.

Ordering principle for the pass: prefer payoffs that reach **across a city
boundary**. A flag consumed in the chapter that set it is local colour and does not
build the quality this work is for.

## Testing

Engine and scene code both get tests; the standing project rule exempts only
*content* changes.

**New unit tests** (`tests/unit/test_dialogue_engine.gd`)

- no variants → base text
- one variant, flag held → variant text
- one variant, flag absent → base text
- two variants both matching → the earlier one wins
- reputation variant below threshold → base text; at threshold → variant text
- variant with both conditions, only one held → base text
- `validate_tree()` rejects a variant with no text
- `validate_tree()` rejects a variant with malformed `requires_reputation`
- `validate_tree()` rejects an unparsed gloss token inside a variant

**Renderer test** (`tests/unit/test_chapter_view.gd`)

- a node whose variant is active renders the variant's prose
- a glossed term appearing **only** in a variant still produces a margin note

**Content tests, one per authored thread.** Conditional text is invisible in the
graph — the node list no longer shows that Teginabad affects Pushang — so each
thread needs a test asserting that setting the flag changes the text at the payoff
site. Without this the threads rot silently. This is the single most important test
category in the spec.

## Metrics

Tracked in place of node count:

| Metric | Now | Target |
|---|---|---|
| Flags set but never read | 31 | ≤ 10 |
| Choices gated on flag or reputation | 15 | 40+ |
| Nodes offering no decision | 76% | < 60% |

Node count is reported as a byproduct, never as a goal.

## Risks

- **Consequence becomes invisible in the graph.** You can no longer see from the
  node list that one city affects another. Mitigated only by the per-thread content
  tests; if those are skipped, this spec makes the content *less* maintainable, not
  more.
- **It does not reduce the 76% figure.** Conditional text makes the game more
  responsive without making it more decidable. Leaning on it exclusively produces a
  game that reacts richly and still rarely asks the player anything. The road
  situations and time/actions work remain necessary; this spec does not substitute
  for them.
- **Ordering is a silent failure mode.** A mis-ordered `text_variants` array
  shadows later entries and no validator can catch it.
- **Variant prose drifts from base prose.** When a beat is later rewritten, its
  variants are easy to forget. The per-thread tests catch removal but not staleness
  of tone.

## Verification

1. Full suite green apart from the 22 pre-existing content-navigation failures and
   1 risky test that predate this work.
2. `godot --path . -s tools/verify_folio_layout.gd` still exits 0 — variant text is
   longer or shorter than base and must not break the folio.
3. For each authored thread, play both sides and confirm the payoff site reads
   differently.
4. Re-measure the three metrics above and record them in the implementation plan.
