# Chapter 6 (Pushang) Design

**Chapter id:** `chapter_06_pushang` — not `chapter_05`, since that id is already claimed by the plunder-branch ending chapter shipped earlier this session. In the master design spec's original, un-forked 8-stop numbering, Pushang was "Chapter 5"; Chapter 4 later split into 4A/4B and Chapter 5 became the plunder branch's ending, so every long-route stop from here on shifts up by one.

## Purpose

Continues the long main route from Chapter 4A's terminal node (`n21_departure_herat`, currently `next_chapter_id: null`). Historical grounding, verbatim from the master design spec (`docs/superpowers/specs/2026-08-07-borrowed-fortune-design.md`): "Pushang (Bushanj) - small walled waystation, 'half the size of Herat' (Ibn Hawqal). A minor, grittier stop between two big cities." Falls in 1038, the same year and province as Herat — the story's present is 1035, so this is the same kind of dramatic-irony foreshadowing the game has used throughout.

**Thematic focus (confirmed with the user): the failing frontier, made concrete** — not another beat in the Rayy-network mystery, which just had its payoff (partial or full) in Chapter 4A. Pushang shows the empire's contingency at a smaller, grittier scale: a town under real strain from the same muster that was only atmospheric texture in Herat.

**Structural break from every prior chapter (confirmed with the user): no single central NPC.** Every stop before this one centered on one money-changer/broker figure (Mihran, Umm-Kavus, Ardashir, Tahir, Rostam). Pushang is deliberately atmospheric/collective instead — a mosaic of brief, unnamed encounters plus one mechanical spine, matching "half the size of Herat" structurally as well as thematically.

**No new true fork.** This is a linear stop like Teginabad and Bost were, not a branch point like Farah — a fixed sequence of short beats with one real choice point (the requisition), converging back to a single path forward. Ends with `next_chapter_id: null` (the long route's current end, same as every other most-recently-built chapter has done).

## Historical/linguistic grounding (verified, not guessed)

Researched before writing this spec rather than assumed — see citations in the plan/implementation notes below if needed later.

- **Zoroastrian communities** genuinely persisted in 11th-century Khorasan (Nishapur, near this route, had a major Sasanian-era fire temple and a historically strong Zoroastrian presence). The respectful in-group term is **Behdin** ("follower of the Good Religion," from Sasanian/Pahlavi *wehdēn*) — used here in preference to the outsider terms *Majus* (Qur'anic/Arabic) or *Gabr* (New Persian, documented as having acquired pejorative weight). The chapter does not claim a specific documented Zoroastrian community at Pushang itself, only regional plausibility.
- **Nestorian Christian communities** were real in Khorasan/Central Asia at this date — Merv was a Church of the East metropolitan see confirmed active through at least 1018/19, though already "in decline" by the 11th century. **Tarsa** (from Middle Persian *tarsāg*, "God-fearing") is the everyday New Persian vernacular term; **Nasrani** is the Qur'anic/Arabic formal-register term for the same community. Used together deliberately, to dramatize the register split.
- **Linguistic landscape:** New Persian was the Ghaznavid court's administrative/literary language despite the dynasty's Turkic slave-soldier origin; the primary source for this exact reign (Bayhaqi's chancery history) documents Turkish spoken in military/court circles; Arabic remained the register of law and scholarship. A real, citable, non-invented detail: Sultan Mas'ud I (the reigning sultan, right now, in-game) is documented as competent in Arabic poetry *and* Persian chancery prose — genuinely trilingual across all three registers this chapter dramatizes.
- **Requisition terminology:** no well-attested Ghaznavid-specific term exists for wartime/frontier requisitioning (as distinct from ordinary taxes like kharaj/jizya/zakat/ushr) — terms like *ʿawāriḍ* are Ilkhanid-period-onward, not confirmed for this era. The chapter deliberately uses plain functional prose ("for the garrison," under the officer's authority) rather than inventing a fake technical term, consistent with this project's established practice of flagging invented/uncertain content rather than asserting it as fact.

## Structure

Fifteen nodes, id `chapter_06_pushang`, entry node `n01_pushang_arrival`.

1. **Opening** (`n01_pushang_arrival`, `n02_the_towns_face`) — the town's smallness against Herat, the muster's visible cost here.
2. **Vignette A** (`n03_the_behdin_shopkeeper`, `n04_closing_early`) — a shopkeeper who names her own faith before anyone else can name it for her. One small flavor choice (acknowledge her situation vs. say nothing), `+1 townsfolk` or none.
3. **Vignette B** (`n05_the_tarsa_merchant`, `n06_two_names_one_people`) — a cloth merchant the bazaar calls *Tarsa* and an officer's clerk calls *Nasrani* within the same minute, over the same unmoved man — the register-contrast beat.
4. **The garrison** (`n07_the_garrison_gate`, `n08_the_sultans_three_tongues`) — ambient Turkic/Persian/Arabic code-switching at the gate, then the guide's aside about Sultan Mas'ud's own real, attested trilingual competence.
5. **The requisition** (`n09_the_officers_demand`) — the chapter's one real choice point, four options, real and distinct stakes (no dominated choice — each has a trade-off, see table below):

   | Choice | Coin | Reputation |
   |---|---|---|
   | Pay what he asks | −12.0 | `ghaznavid_officials` +1 |
   | Haggle it down | −6.0 | none |
   | Refuse outright | 0 | `ghaznavid_officials` −2 |
   | Offer something quieter, off the list | −10.0 | `trading_families` +1, `ghaznavid_officials` −1 |

   Haggling is cheaper than paying in full but builds no standing; paying in full costs more but builds official standing; refusing is free but damages it; bribing costs less than paying in full but trades official standing for mercantile standing instead of gaining it outright — a real, distinct trade-off, not a strictly dominated option next to either paying or haggling.

6. **Convergence and departure** (`n11_after_the_requisition`, `n12_departure_pushang`) — the chapter's thesis stated plainly ("a frontier failing was not one dramatic collapse... it was a hundred small requisitions like this one"), then departure toward Sarakhs.

**Deliberately outcome-agnostic about Chapter 4A:** `n12_departure_pushang`'s closing line references "a name I understand better or worse depending on how the road behind him had gone" — vague on purpose, never naming Buyid/missionary specifics or anything else exclusive to 4A's gated full-truth reveal. This directly applies the lesson from this session's story-review fix pass: an aftermath/departure node reached from multiple possible prior states must stay true on all of them, not assume the gated outcome.

## Node-by-node content

```
n01_pushang_arrival:
"Pushang announced itself the way a lesser cousin does at a family gathering - present, unmistakably related to the city he'd just left, and unmistakably smaller. Half of Herat's walls, the guide said, before they'd even reached the gate, and Farrukh understood the comparison wasn't unkind so much as exact: the same brick, the same canal-fed green fighting the same patient desert, all of it simply built to a more modest scale, for a town that had never needed to be more than what it was."
-> "Continue." -> n02_the_towns_face

n02_the_towns_face:
"It did not take long to see what the muster had cost a town this size more visibly than it had cost Herat. Stalls stood shuttered at an hour a bazaar should still have been loud. A watch that should have paced the wall in pairs paced it alone, when it paced at all. Whatever news had reached Herat as rumor had reached Pushang, evidently, as arithmetic - fewer men left to spare for anything but the wall itself, and fewer excuses left for pretending otherwise."
-> "Continue." -> n03_the_behdin_shopkeeper

n03_the_behdin_shopkeeper:
"One shop on the bazaar's short spine was still doing business, kept by a woman old enough to have buried a husband and young enough not to have expected to yet, who introduced herself as {{behdin|Behdin}} without being asked - a habit, she said, of a lifetime spent making sure strangers heard it from her before they heard some other word for it from someone else."
-> "Continue." -> n04_closing_early

n04_closing_early:
"She was closing early, she told him, weighing his coin with the same unhurried care Mihran and Ardashir both would have recognized - not because business was bad, though it was, but because a woman alone in a half-emptied garrison town had learned which hours were worth being visible in and which weren't."
-> "Tell her you're sorry to hear it." [flags: none, reputation: townsfolk +1] -> n05_the_tarsa_merchant
-> "Say nothing. It isn't your business to comment on." [no effects] -> n05_the_tarsa_merchant

n05_the_tarsa_merchant:
"Farther down, past the mostly-shuttered stalls, a cloth merchant Farrukh's guide identified under his breath as {{tarsa|Tarsa}} was doing the opposite of closing - laying out goods with the specific, deliberate visibility of a man who had decided that vanishing from view, in a town this nervous, would draw more suspicion than staying exactly where everyone could see him."
-> "Continue." -> n06_two_names_one_people

n06_two_names_one_people:
"An officer's clerk, passing to record the day's arrivals, called the same man {{nasrani|Nasrani}} without a flicker of unkindness in it - the word simply belonging to a different register than the one the bazaar used, the way a qadi's ruling and a neighbor's gossip could describe the identical fact in languages that never quite touched. Farrukh understood, watching the two words pass within a minute of each other over the same unmoved man, that he had just been handed a small lesson about how many different vocabularies a single life in this empire actually required."
-> "Continue." -> n07_the_garrison_gate

n07_the_garrison_gate:
"The garrison gate ran on a different register again. Farrukh caught commands passing between officers in clipped Turkic he didn't follow, watched a Persian-lettered order change hands as if it were the only language administration had ever been conducted in, and noticed, tucked at the bottom of that same order, a line of Arabic script that a qadi would recognize before any soldier did."
-> "Continue." -> n08_the_sultans_three_tongues

n08_the_sultans_three_tongues:
"His guide, watching him watch it, said it was no different at the top than it was at this gate - that the Sultan himself, men said, could turn a line of Arabic verse as easily as he dictated a Persian rescript, and gave his orders to the men who actually swung the swords in the tongue those men had been born to. Three languages for one empire, none of them optional, and Farrukh understood, not for the first time on this road, how much of governing a place this size was simply the discipline of being understood by everyone whose obedience you actually needed."
-> "Continue." -> n09_the_officers_demand

n09_the_officers_demand:
"An officer at the gate - young, tired, working from a list that clearly hadn't gotten shorter all week - looked over Farrukh's manifest with the flat professional interest of a man collecting for a muster that needed feeding regardless of whose caravan happened to be passing through. \"For the garrison,\" he said, naming a sum, in the tone of a man reciting an order rather than making a request."
-> "Pay what he asks." [coin_spent_dirham_equivalent: 12.0, reputation: ghaznavid_officials +1] -> n10a_complied
-> "Argue him down to something smaller." [coin_spent_dirham_equivalent: 6.0] -> n10b_haggled
-> "Refuse outright." [reputation: ghaznavid_officials -2] -> n10c_refused
-> "Offer him something quieter, off the list." [coin_spent_dirham_equivalent: 10.0, reputation: trading_families +1, ghaznavid_officials -1] -> n10d_bribed

n10a_complied:
"Farrukh paid what was asked, and the officer marked his manifest with the small, satisfied economy of a man who had one fewer name left on a list that wasn't shrinking fast enough. It was not robbery, exactly - the garrison's need was real enough, and the muster wasn't his invention - but it did not feel like ordinary trade either, and Farrukh found he had no better word ready for whatever sat in between the two."
-> "Continue." -> n11_after_the_requisition

n10b_haggled:
"Farrukh talked the sum down the way he'd talked down every other price on this road, and the officer let him, with the particular weariness of a man who had heard every argument a caravan merchant could make and had stopped finding any of them worth resisting for more than a minute. He got a smaller number. He did not get the sense that the smaller number had cost the man in front of him anything at all."
-> "Continue." -> n11_after_the_requisition

n10c_refused:
"Farrukh said no, as plainly as he could manage, and watched the officer's tiredness curdle into something closer to genuine irritation - not violence, nothing that reached for a weapon, only the particular friction of a man whose list had just gotten one name longer to explain to whoever he answered to. They held his caravan at the gate longer than the transaction should have taken, checking papers that had already been checked, before finally, without apology, waving him through anyway."
-> "Continue." -> n11_after_the_requisition

n10d_bribed:
"Farrukh offered something smaller and considerably less official, and the officer took it with the practiced discretion of a man who had done this exact quiet transaction before and would do it again before the week was out - the list, technically, staying exactly as long as it had been, the coin simply never having existed as far as anyone above him would ever be told. It cost less than the official sum and considerably more than the haggled one, and Farrukh understood, walking away, that he had just paid specifically for the privilege of nobody official ever knowing he'd paid at all."
-> "Continue." -> n11_after_the_requisition

n11_after_the_requisition:
"Whatever it had cost him, Farrukh left the garrison gate with the same caravan he'd arrived with, which was more than the town's own watch, thinned past pairs, could apparently say for itself these days. A frontier failing was not, he was beginning to understand, one dramatic collapse - it was a hundred small requisitions like this one, in a hundred towns like this one, each individually reasonable, each one shaving a little more off whatever the word 'ordinary' had meant here a year ago."
-> "Continue." -> n12_departure_pushang

n12_departure_pushang (terminal, next_chapter_id: null):
"He left Pushang smaller than he'd found any city on this road, carrying whatever he'd carried out of Herat - a debt at his back, a name he understood better or worse depending on how the road behind him had gone, and now this too: a clearer sense of what an empire actually spent, day to day, simply to keep failing more slowly than it might have. Sarakhs lay ahead, and past it, however the road let him reach it, Nishapur."
```

## New glossary terms (`content/glossary/pushang_terms.json`)

| id | headword | definition |
|---|---|---|
| `behdin` | Behdin | "Follower of the Good Religion" - the Zoroastrian community's own term for itself, from the Middle Persian for the faith that predated Islam in Iran and Central Asia. Used in preference to outsider terms like Majus or Gabr, which carry more distance and, in Gabr's case, real pejorative weight. |
| `tarsa` | Tarsa | From Middle Persian *tarsāg*, "God-fearing" - the everyday New Persian word for a Christian, used in ordinary speech both before and long after the Islamic conquest. |
| `nasrani` | Nasrani | The Qur'anic and Arabic term for a Christian, used in more formal, legal, or administrative registers - the same people the bazaar might call Tarsa. |

## Wiring

- New manifest entry: `chapter_06_pushang` → `{dialogue_path: "res://content/chapters/chapter_06_pushang/pushang.json", glossary_path: "res://content/glossary/pushang_terms.json", next_chapter_id: null}`.
- Change `content/chapters/chapter_04a_herat/herat.json`'s terminal node `n21_departure_herat`'s `next_chapter_id` from `null` to `"chapter_06_pushang"` — the node-level value, not just the manifest.
- `tests/unit/test_herat_dialogue_content.gd` has `test_the_terminal_node_has_a_null_next_chapter_id`, currently asserting `n21_departure_herat`'s `next_chapter_id` is `null` — must be strengthened to assert the new value, per this project's established "grep for the OLD value, never delete, strengthen" lesson.
- **Grep `tests/` for the literal string `n21_departure_herat`, not just for one known test function name, before calling this wiring done.** Chapter 5's own wiring task just demonstrated exactly this failure mode: its plan named one full-playthrough test in `test_chapter_view.gd` and missed a second, structurally identical one (`test_a_full_playthrough_via_the_pivot_away_path_reaches_its_own_terminal_node`) that asserted the same stale final state through a different path. `test_chapter_view.gd`'s mystery-branch full-playthrough test (reaches `chapter_04a_herat` today) is the known one to update; search broadly for any others before assuming there's only one.

## Global constraints (unchanged from every prior chapter)

Godot 4.3 floor. `JSON.parse_string` deserializes numbers as float — cast to `int` before comparing/assigning `int`-typed reputation values. No combat (the refusal outcome stays administrative friction, never violence). No religious/ritual framing of the hidden network — n/a here, this chapter never mentions the network at all, by design. Commit per task.
