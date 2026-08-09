# Story Review Fixes — Implementation Plan

> **For agentic workers:** this is a prose-correction pass over already-shipped, tagged content. No engine changes, no node ids change, no `next_id`/`next_chapter_id` routing changes, no `effects` blocks change. Every fix is a `text` field edit plus a covering regression test. Verified against source files directly (not against subagent summaries) before this plan was written.

**Goal:** fix the four pinned continuity bugs, the timeline date pattern, and two mechanical doc/prose typos found by the 2026-08-09 story review, without touching the branch structure, gating, or flags those findings sit inside.

**Architecture:** direct content edits across five `content/chapters/*/*.json` files plus one design doc. Each edit gets a `grep`-based regression test in the matching `tests/unit/test_*_dialogue_content.gd` file asserting the bad phrase is gone and/or the corrected phrase is present.

**Explicitly deferred, not part of this plan:**
- Finding 5 (no wealth/reputation UI display) — engine + `.tscn` change, needs its own design pass and can't be visually verified from this session. Separate branch.
- Mihran's unstated Zoroastrian identity, Teginabad's unidentified contraband, the Prologue mother's near-absence — additive worldbuilding decisions, not bugs. Surfaced to the user separately, not fixed here.
- The two flags set and never read (`stayed_uninvolved_at_farah`, `confirmed_the_name_at_farah`) — left alone; plausible Chapter 5 hooks.

## Global Constraints

- Godot 4.3 floor. `JSON.parse_string` deserializes numbers as float — n/a here, no numeric fields touched.
- No `{{term|gloss}}` glossary markers added or removed by any edit (would require a glossary-file change and would trip `test_glossary_terms_and_flag_names_are_unique_across_all_manifest_chapters` / the per-chapter glossary-coverage test otherwise).
- Every existing test must stay green. Verified beforehand: no test in this repo asserts full node text for any node this plan touches (only node ids, routing, and glossary-marker coverage) — see grep in session transcript.
- Commit per finding group, following this project's established granular-commit convention.

---

### Task 1: Fix finding ① — Ardashir referenced across the exclusive 4A/4B split

**File:** `content/chapters/chapter_04b_herat_favor/herat_favor.json`
**Test:** `tests/unit/test_herat_favor_dialogue_content.gd` (new test)

Four nodes name or imply Ardashir, a character this branch's Farrukh never meets:

- `n04a_the_debasement`: "two weeks of watching Ardashir-adjacent men weigh coin" → "two weeks of watching Herat's coin-weighers eye every payment with more suspicion than the mint's reputation should have required"
- `n05_the_far_edge_of_herat`: "why Ardashir's whole world ran on correspondence and reputation rather than ever setting foot somewhere like this himself" → "why the respectable sarrafs of this city ran everything on correspondence and reputation rather than ever setting foot somewhere like this themselves"
- `n09a_paid_as_agreed`: "the same way Ardashir had" → "the same way every careful sarraf on this road had"
- `n17a_departure_bound`: "a name and a city from Ardashir's side of this journey that he'd never get to hear" → "a name and a city from a road he hadn't taken, one he'd never get to hear the rest of"

- [ ] Add test asserting no node in `herat_favor.json` contains the substring `"Ardashir"`.
- [ ] Apply the four text edits above.
- [ ] Run `tests/unit/test_herat_favor_dialogue_content.gd`, confirm pass.
- [ ] Commit: `fix: remove cross-branch Ardashir references from Chapter 4B`

### Task 2: Fix finding ② — 4A's aftermath narrates the gated outcome on the default path

**File:** `content/chapters/chapter_04a_herat/herat.json`
**Test:** `tests/unit/test_herat_dialogue_content.gd` (new test)

`n20_aftermath` and `n21_departure_herat` both currently only make sense after `n19b_the_full_truth` (naming "Buyid," "missionary," "a name from Rayy"). Most players reach them via the default `n19a_the_partial_truth`, which never mentions those specifics. Rewrite both nodes to be true on either path, echoing `n19a`'s own vocabulary ("trouble," "passed down further than anyone meant it to travel") instead of asserting the gated specifics.

- `n20_aftermath`: replace "had never so much as mentioned Rayy at the dinner table, had never once used a word like Buyid or missionary in Farrukh's hearing" → "had never so much as mentioned Rayy at the dinner table, had never once hinted at the shape of the trouble he was leaving behind him"
- `n21_departure_herat`: replace "carrying a name from Rayy that had stopped being merely mysterious and started being dangerous, in roughly the proportion Ardashir had warned him it would" → "carrying more of Rayy's trouble than he'd arrived with, dangerous in roughly the proportion Ardashir had warned him it would be"

- [ ] Add test asserting neither `n20_aftermath` nor `n21_departure_herat` contains `"Buyid"` or `"missionary"`.
- [ ] Apply the two text edits above.
- [ ] Run `tests/unit/test_herat_dialogue_content.gd`, confirm pass.
- [ ] Commit: `fix: make Chapter 4A's aftermath true on both reputation-gate outcomes`

### Task 3: Fix finding ③ — 4B states the gated Rayy backstory as free fact, and overclaims what Bost established

**File:** `content/chapters/chapter_04b_herat_favor/herat_favor.json`
**Test:** `tests/unit/test_herat_favor_dialogue_content.gd` (new test)

`n13_the_weight_of_knowing` currently asserts, unconditionally: (a) that Mihran "first named" the network in Bost — but Bost's Mihran never uses the word "network" and, on the patient path (`n08b_patient`), never gives a name at all; (b) the Buyid/crucifixion backstory as settled fact — the same content 4A gates behind `trading_families >= 4`. Rewrite as Farrukh's own developing suspicion, not confirmed history, and stop overclaiming Bost's content.

Replace the node's text:
> "Farrukh walked out of the quarter with his coin and without whatever the last courier had lost, turning over the particular arithmetic of a man who'd just been complimented for his own self-preservation. Whatever Mihran in Bost had been unwilling to say outright, whatever this network actually was beneath the trouble it had caused - Rostam was proof it had survived long enough to grow a second, uglier layer: men who weren't part of whatever cause it once served, just men who'd found a profitable way to stand in its shadow, trading on other people's old convictions and other people's continuing silence."

- [ ] Add test asserting `n13_the_weight_of_knowing` does not contain `"Mihran had first named"`, `"crucified"`, or `"nine years ago"`.
- [ ] Apply the text edit above.
- [ ] Run `tests/unit/test_herat_favor_dialogue_content.gd`, confirm pass.
- [ ] Commit: `fix: stop Chapter 4B from stating 4A's gated backstory as settled fact`

### Task 4: Fix finding ④ — Farah's clean-path reveal resolves the wrong mystery

**File:** `content/chapters/chapter_03_farah/farah.json`
**Test:** `tests/unit/test_farah_dialogue_content.gd` (new test)

`n17a_the_name_given_cleanly` currently re-confirms the *main* house seal ("the same house whose seal Mihran had first recognized") while still setting `knows_the_second_marks_name = true`. It must resolve the actual second mark — the one Mihran refused to fully explain — to make the flag honest, while staying just as bare/context-free as it is today (preserving the "needs Chapter 4A for the full picture" shape).

Replace:
> "The answer came back written in a hand Farrukh didn't recognize, on paper that had clearly traveled further than Farah: a name, a city - not the house Mihran had already placed, but the owner of the second mark itself, the one Mihran said he'd seen twice in eleven years and wished he hadn't - and nothing else, no explanation, no warning, exactly the transaction it had been sold as. Farrukh had what he'd paid for and nothing he hadn't. It felt, oddly, like the cleanest thing to happen to him since his father's death, which was its own kind of unsettling."

- [ ] Add test asserting `n17a_the_name_given_cleanly` does not contain `"the same house whose seal Mihran had first recognized"` and does contain `"second mark"`.
- [ ] Apply the text edit above.
- [ ] Run `tests/unit/test_farah_dialogue_content.gd`, confirm pass.
- [ ] Commit: `fix: correct Farah's clean-path reveal to resolve the second mark, not the main seal`

### Task 5: Fix the timeline — anchor every date to 1035, not 1038

**Files:** `content/chapters/chapter_00_prologue/prologue.json`, `content/chapters/chapter_03_farah/farah.json`, `content/chapters/chapter_04a_herat/herat.json`, `content/chapters/chapter_04b_herat_favor/herat_favor.json`
**Tests:** new tests in each chapter's content test file

- Prologue `n04_grave_question`: "To three houses, maybe four." → "To two houses, maybe three." (matches the actual ledger: 2 creditor-houses + a wage debt, set in `n06_vow`'s effects)
- Farah `n16b_tahirs_price`: "a veteran of a campaign three years gone" → "a veteran of a campaign ten years gone" (Somnath, 1025; story present, 1035)
- Farah `n18b_the_favor_owed`: "the spoils of a war three years cold" → "the spoils of a war ten years cold"
- 4A `n04a_the_1020_muster`: "near twenty years gone now" → "fifteen years gone now" (1020 muster; 1035 present)
- 4A `n19b_the_full_truth`: "Nine years ago," → "Six years ago," (Rayy fell / Majd al-Dawla deposed, 1029; 1035 present)
- 4B `n13_the_weight_of_knowing`: covered by Task 3's rewrite — drop the "nine years ago" clause entirely rather than restate a number, since this node no longer asserts the history as confirmed fact.

- [ ] Add/extend tests asserting each corrected phrase is present and each wrong phrase is absent.
- [ ] Apply all five text edits above (Task 3 already removes the sixth).
- [ ] Run the full suite, confirm pass.
- [ ] Commit: `fix: anchor every "years ago/gone" reference to the story's 1035 present`

### Task 6: Mechanical fixes — demonym and doc/impl mismatch

**Files:** `content/chapters/chapter_04a_herat/herat.json`, `content/chapters/chapter_04b_herat_favor/herat_favor.json`, `docs/superpowers/specs/2026-08-09-chapter-4b-herat-design.md`

- [ ] `herat.json` `n01_herat_arrival`: "a Heratigan by birth" → "a Herati by birth"
- [ ] `herat_favor.json` `n03a_the_mint_at_work`: "every Heratigan seemed proud" → "every Herati seemed proud"
- [ ] Design doc line 148: correct the claim that `ghanima` and `dai` appear in plain prose — only `sarraf` actually does in the shipped content.
- [ ] Add test asserting neither content file contains `"Heratigan"`.
- [ ] Commit: `fix: correct demonym and design-doc term claim`

### Verification

- [ ] Run full GUT suite (`godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`), confirm all green, note new total.
- [ ] Dispatch an independent code-reviewer subagent over the full diff before merging.
