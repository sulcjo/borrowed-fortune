# Wealth/Reputation UI Plan

**Goal:** fix the story review's systemic choice-balance finding (finding 5) at its root — surface `Ledger` wealth/debt and `ReputationTracker` standing, which are computed correctly throughout the game but never shown anywhere, so a "harder" choice's real stakes are visible instead of invisible.

**Design decision (confirmed with user):** an always-visible corner readout, not a toggle/peek panel — a toggle only helps if the player remembers to open it before every choice, which doesn't actually fix the diagnosed problem (stakes invisible *at the moment of choosing*).

**Spoiler safety (self-resolved, no code needed):** `ReputationTracker.to_dict()` (`engine/reputation/ReputationTracker.gd:15`) returns `_scores.duplicate()`, which only contains faction ids that have actually been adjusted via `adjust_reputation()`. A faction the player hasn't encountered yet (e.g. `hidden_network`, introduced only in Chapter 4B) is simply absent from the dict — iterating it for display is already spoiler-safe by construction, no filtering logic required.

**Framing:** `Ledger.total_wealth_dirham_equivalent()` is a running net accumulator (`-spent_dirham_equivalent`, since the game has no starting purse/coin objects), not an absolute "how much money do I have" balance — it reads negative most of the game. Label it "Coin" rather than "Purse" to avoid implying an absolute balance. Faction ids are shown via GDScript's built-in `String.capitalize()` (`"trading_families"` → `"Trading Families"`), no new label table needed.

**Known limitation, stated plainly:** this is the one engine+`.tscn` change in this project's history with no existing visual precedent to match (no theme resources exist anywhere in the repo). It cannot be visually verified from this headless session — only that the label's `.text` binds the right values, via GUT tests reading the node directly, the same pattern `test_chapter_view.gd` already uses for `NarrationLabel`.

## Task 1: Add the StatusReadout node and wire it up

**Files:**
- Modify: `scenes/chapter_view/ChapterView.tscn`
- Modify: `scenes/chapter_view/ChapterView.gd`
- Modify: `tests/unit/test_chapter_view.gd`

**Scene change:** add a `StatusReadout` `Label` as a sibling of `NarrationLabel`, anchored top-wide like it, occupying the 16px-tall gap currently unused above it:

```
[node name="StatusReadout" type="Label" parent="."]
layout_mode = 1
anchors_preset = 10
anchor_right = 1.0
offset_left = 16.0
offset_top = 16.0
offset_right = -16.0
offset_bottom = 40.0
theme_override_font_sizes/font_size = 14
theme_override_colors/font_color = Color(0.55, 0.55, 0.55, 1)
horizontal_alignment = 2
```

Shift `NarrationLabel`'s `offset_top` from `16.0` to `48.0` so the two don't overlap (16 top margin + 24px readout band + 8px gap = 48).

**Script change** (`ChapterView.gd`):
- `@onready var status_readout: Label = $StatusReadout`
- New method, called at the top of `_render_current_node()` (alongside the existing `dialogue_engine.reputation = reputation_tracker.to_dict()` sync line):

```gdscript
func _update_status_readout() -> void:
	var parts: Array[String] = ["Coin: %.1f dirham" % ledger.total_wealth_dirham_equivalent()]
	var debt := ledger.total_debt_owed()
	if debt > 0.0:
		parts.append("Debt owed: %.1f dirham" % debt)
	for faction_id in reputation_tracker.to_dict():
		parts.append("%s: %+d" % [String(faction_id).capitalize(), reputation_tracker.get_reputation(faction_id)])
	status_readout.text = " · ".join(parts)
```

**Tests** (append to `test_chapter_view.gd`, following its existing `add_child_autofree(ChapterViewScene.instantiate())` pattern):
- Loading the Prologue shows `"Coin: 0.0 dirham"` and no debt/reputation segments before any choice is made.
- After the Prologue's `n06_vow` (guarantees 3 debts, adjusts `trading_families`/`townsfolk`), the readout shows the summed debt (340+210+60=610.0) and both reputation deltas, formatted with an explicit sign (`+2`, `+1`).
- A faction never touched in a short playthrough (e.g. `hidden_network` during the Prologue) never appears in the readout text — the spoiler-safety property, asserted directly rather than just inferred from `to_dict()`'s behavior.
- Spending coin (Teginabad's bribe, or any `coin_spent_dirham_equivalent` effect) is reflected as a negative `Coin:` value.

## Verification

- [ ] Run the full GUT suite, confirm all green including the new tests.
- [ ] Report plainly that the visual rendering (corner placement, muted color, no overlap) was not seen rendered — only that the bound values are correct.
