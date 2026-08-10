# Chapter 7 (Sarakhs) Design

**Chapter id:** `chapter_07_sarakhs` — continuing past `chapter_05_plunder_ending` and `chapter_06_pushang`, both already claimed.

## Purpose

Continues the long main route from Chapter 6's terminal node (`n12_departure_pushang`, currently `next_chapter_id: null`). Historical grounding, verbatim from the master design spec: "Sarakhs - 'Gate of Khorasan,' fortress on the Tejen, first to break (Battle of Sarakhs, 1038)." The optional Merv branch mentioned alongside it in the master spec is explicitly **out of scope for this chapter** (confirmed with the user) — it deserves its own dedicated design pass later, not a squeezed-in detour here.

**Thematic focus:** unlike Pushang's administrative decline, Sarakhs is a fortress under active military tension — "the muster, in stone" rather than the muster's cost. **Returns to the one-central-NPC pattern** (confirmed with the user) after Pushang's atmospheric departure, but breaks from every prior confidant being a money-changer/broker: the NPC here, Bahram, is a ghulam officer holding the gate.

## Historical grounding (verified via dedicated research, not assumed)

Researched before writing this spec — primary source Bosworth's "The Early Ghaznavids" (Cambridge History of Iran vol. 4), the actual scholarly-consensus account, not a summary.

- **Ghulams** were the core of Ghaznavid military power — a standing corps of ~4,000, principally Turkic slave-soldiers, personally bound to the sultan, commanded by the *sālar-i ghulamān*. A real, citable example of upward mobility: Altun-Tash, a ghulam of Sebük-Tegin, rose to *hājib* and was installed as governor of Khwarazm — used here as camp legend, not claimed as something Farrukh witnesses directly.
- **Ghazis** were free volunteers, unpaid, fighting for a share of campaign spoils rather than a wage — a real, distinct, well-attested category the game hasn't used yet. Introduced as a new glossed term, contrasted directly with `ghulam` (already established, from Farah).
- **Iqta (land-grant military pay) is deliberately absent.** Bosworth states explicitly that Ghaznavid income from Indian plunder and Khorasani taxation let them pay troops in cash, "whereas the Büyids and *later the Saljuqs* had to resort to a system of land-grants or iqta's" — the systematized military iqta is a Seljuk-era (Nizam al-Mulk, 1070s+) institution. Attributing it to the Ghaznavid side here would be not just anachronistic but backwards, given the Seljuks are this game's frontier threat. The garrison is paid in cash carried out from Ghazni's treasury instead — and that supply line's fragility this far from the capital is the chapter's real point, a direct mirror to Farrukh's own precarious finances.
- **War elephants are deliberately absent.** A real, attested Ghaznavid institution (royal beasts, Indian keepers, used at Ghazni and with field armies — e.g. accompanying Mas'ud's 1040 column toward Dandanaqan), but not attested as stationed at a small frontier garrison, which is the wrong logistical shape for the institution. Left out rather than forced in.
- **No specific attested rank-title exists below the top tier** (*sālar-i ghulamān*, *hājib*) for a garrison gate-officer — Bahram's title stays a plain functional description ("a ghulam himself, one rank below whoever technically commanded the province"), not an invented specific term.
- **Real connective payoff:** the Battle of Nasa (1035) — already referenced in the Prologue as the rumor reaching Ghazni as Farrukh's father died — was a real Ghaznavid defeat under a real commander, Begtoghdi. Bahram references this directly, by name, giving the chapter's central relationship a concrete, historically real anchor rather than a generic "the frontier is scary" gesture. (Sarakhs's own subsequent history is richer than the single 1038 battle — Seljuk settlement in 1025, a punitive campaign in 1027-28, the 1035 defeat at Nasa, a 1037 ultimatum, the 1038 battle itself, then final collapse at nearby Dandanaqan in 1040 — but this chapter only needs the 1035 Nasa connection, since the story's present is 1035 and nothing later has happened yet.)
- Garrison size at Sarakhs specifically is not attested anywhere found — left as an open, unstated detail rather than invented as a specific number.

## Structure

Thirteen nodes, entry node `n01_sarakhs_arrival`, single terminal node `n11_departure_sarakhs`.

1. **Opening** (`n01_sarakhs_arrival`) — the fortress as "the muster, in stone," contrasted explicitly with Herat's and Pushang's more distant worry.
2. **Optional sideroad** (`n02_the_choice_at_the_yard` offers it; `n03a_the_ghulams_road`, `n04a_the_treasurys_long_reach` are its two nodes) — matches the established sideroad convergence pattern (Chapter 4A/4B's mint detour): both choices reach `n05_bahram_the_gatekeeper` either way. The sideroad carries the "functioning of the military" content the user specifically asked for — ghulam recruitment/career-path legend, then the cash-pay fragility point and the new `ghazi` term — genuinely skippable, not required to understand anything downstream.
3. **Meeting Bahram** (`n05_bahram_the_gatekeeper`, `n06_what_nasa_taught_him`) — introduces the chapter's one confidant, then the Nasa/Begtoghdi connective beat establishing him as a clear-eyed realist, not falsely confident.
4. **The charge** (`n07_a_quiet_request`, `n08_the_commanders_charge`) — Bahram asks Farrukh to carry a personal token home, unofficially, echoing the Prologue's kafala vow: nobody requires this. Three choices, a real trade-off, and — unlike Pushang's requisition — no mechanical penalty for declining, since this is a personal favor, not a state obligation:

   | Choice | Coin | Reputation | Flags |
   |---|---|---|---|
   | Take it, ask for nothing | none | `ghaznavid_officials` +1 | `carries_the_commanders_token` |
   | Take it, but for a fair price | +12.0 | none | `carries_the_commanders_token`, `accepted_the_charge_for_payment` |
   | Decline | none | none | `declined_the_commanders_charge` |

   `carries_the_commanders_token` is a **deliberate forward-hook** for Chapter 8 (Nishapur, the eventual finale) — delivering it there is a real payoff to plant now, not a dead flag.

5. **Convergence and departure** (`n10_after_the_gate`, `n11_departure_sarakhs`) — the gate reframed as "a promise, made by an empire to itself," then departure toward Nishapur. `next_chapter_id: null` (current end of the long route — nothing past Sarakhs is built yet).

**Timeline discipline, caught during drafting and fixed before writing this doc:** an early draft of the closing node implied two years had passed since the Prologue ("a debt two years too old"). No time-skip has been signaled anywhere in this game — the story's present is still 1035. Corrected before it became the exact class of error the story review already spent a full pass fixing elsewhere.

## Node-by-node content

```
n01_sarakhs_arrival:
"Sarakhs called itself the Gate of Khorasan, and for once the name was not a merchant's flourish - the fortress sat squarely across the road on the Tejen's near bank, walls thick enough that Farrukh understood, without being told, that everything east of this river had already decided this was the line worth holding. Herat had worried about a muster. Pushang had worried about what the muster cost. Sarakhs simply was the muster, in stone."
-> "Continue." -> n02_the_choice_at_the_yard

n02_the_choice_at_the_yard:
"His caravan guide had business inside the walls that would take the better part of an hour, which left Farrukh time enough to see something of the place before finding whoever actually ran it."
-> "Linger in the garrison's outer yard." -> n03a_the_ghulams_road
-> "Go straight to whoever commands this gate." -> n05_bahram_the_gatekeeper

n03a_the_ghulams_road:
"The yard was busy with the specific, unhurried competence of men who had done this exact drilling for years rather than weeks - {{ghulam|ghulams}}, mostly, Turkic-born and bought young, trained from boyhood into the one trade the empire actually trusted with its own survival. An old one, resting between drills, told Farrukh without much prompting that men like him weren't soldiers by accident of birth the way a levied farmer was - they were raised to it, owned by it in a way that cut both directions, and the lucky ones climbed further than any free man's son from a shop like Farrukh's ever would. He named, with the particular relish of a story told many times before, one of Sebuk-Tegin's own ghulams who'd ended up governing an entire province on the empire's far side. Farrukh did not know whether to envy that or not."
-> "Continue." -> n04a_the_treasurys_long_reach

n04a_the_treasurys_long_reach:
"Not every man swinging a blade at this wall was paid the same way, or paid at all. The {{ghazi|ghazis}} camped at the yard's ragged edge fought for their own reasons and their own share of whatever the fighting produced, volunteers rather than soldiers, and nobody at the gate seemed to expect loyalty from them beyond the length of a single campaign. The ghulams, by contrast, drew real coin - minted in Ghazni, carried the whole distance out here by the same kind of caravans Farrukh himself was part of, which meant, the old soldier said without much comfort in it, that a bad season on the road back home was every bit as dangerous to this garrison as a bad season at the wall. Farrukh understood, not for the first time, that an empire this size ran on exactly the kind of fragile arithmetic his own father's ledger had."
-> "Continue." -> n05_bahram_the_gatekeeper

n05_bahram_the_gatekeeper:
"The man actually holding this gate, Farrukh was told, was a ghulam himself, one rank below whoever technically commanded the province - a soldier named Bahram, older than most of the men drilling in his yard, who looked over Farrukh's manifest with the flat, practiced patience of someone who had processed a great many travelers and expected to process a great many more before this posting, whatever it turned out to be, was finished."
-> "Continue." -> n06_what_nasa_taught_him

n06_what_nasa_taught_him:
"Bahram didn't need Farrukh to explain why he was nervous about the road behind him. \"Nasa,\" he said, when Farrukh mentioned the riders' rumors that had reached Ghazni before his father's death. \"Begtoghdi had men enough, on paper. It didn't matter.\" He said it the way a man states an old wound rather than an open one - not asking for sympathy, just establishing, plainly, that he'd already done the arithmetic Farrukh was still working through."
-> "Continue." -> n07_a_quiet_request

n07_a_quiet_request:
"He handed the manifest back, business concluded, and then didn't quite let Farrukh go - the particular hesitation of a man deciding whether a stranger passing through was worth a favor he had no official standing to ask for."
-> "Continue." -> n08_the_commanders_charge

n08_the_commanders_charge:
"\"I have a token,\" Bahram said finally. \"Small. Nothing a customs man would even blink at. It goes to my wife's people, west of here, if - \" he didn't finish the sentence, and didn't need to. \"Nobody requires this of you. I'm asking a stranger because a stranger is exactly what I need - someone this gate won't remember once you're through it.\""
-> "Take it. Ask for nothing in return." [flags: carries_the_commanders_token, reputation: ghaznavid_officials +1] -> n09a_accepted_freely
-> "Take it, but only for a fair price." [flags: carries_the_commanders_token, accepted_the_charge_for_payment; coin_gained_dirham_equivalent: 12.0] -> n09b_accepted_for_coin
-> "Decline. You already carry enough." [flags: declined_the_commanders_charge] -> n09c_declined_plainly

n09a_accepted_freely:
"Farrukh took the token without naming a price, the same reflex, he understood even as it happened, that had put him at his father's grave promising a debt nobody made him promise. Bahram's relief was almost imperceptible - a man filing away, the way Ardashir once had, that this particular stranger didn't need managing, or paying, to be trusted."
-> "Continue." -> n10_after_the_gate

n09b_accepted_for_coin:
"Farrukh named a price, and Bahram paid it without complaint or particular warmth - a transaction rather than a trust, which suited them both well enough. The token weighed exactly the same in his pack either way. What it meant to carry it, Farrukh suspected, did not."
-> "Continue." -> n10_after_the_gate

n09c_declined_plainly:
"Farrukh said no, as gently as refusing a dying man's request could be said, and told him the truth of it: he already carried one man's unfinished business the entire length of this road, and didn't trust himself to add a second without dropping one or the other somewhere between here and Nishapur. Bahram took the refusal exactly as evenly as he'd taken everything else, and did not ask again."
-> "Continue." -> n10_after_the_gate

n10_after_the_gate:
"Whatever he carried or didn't, out of Sarakhs, Farrukh understood the Gate of Khorasan for what it actually was: not a wall so much as a promise, made by an empire to itself, that this was the line past which the frontier's failure would finally have to stop being somebody else's problem. He did not know, walking away from it, how many more seasons that promise had left in it."
-> "Continue." -> n11_departure_sarakhs

n11_departure_sarakhs (terminal, next_chapter_id: null):
"He left Sarakhs behind him and Nishapur somewhere ahead, ordinary and unremarkable and the wrong side of that unspoken promise regardless. Whatever Bahram's token was worth, wherever it ended up, the road west went on carrying it - and him - toward whatever waited at the end of a debt he still hadn't finished understanding, let alone repaying."
```

## New glossary term (`content/glossary/sarakhs_terms.json`)

| id | headword | definition |
|---|---|---|
| `ghazi` | Ghazi | A volunteer frontier fighter, fighting for a share of whatever the campaign produces rather than a soldier's regular wage - unlike the ghulam, bound and paid by the state, a ghazi answers to no roster and owes his loyalty only as long as the campaign does. |

`ghulam` is reused as plain prose, not re-glossed — already taught in Chapter 3 (Farah) and persists in The Margin via the existing merge fix, same treatment `sarraf` got in Chapter 4B.

## Wiring

- New manifest entry: `chapter_07_sarakhs` → `{dialogue_path: "res://content/chapters/chapter_07_sarakhs/sarakhs.json", glossary_path: "res://content/glossary/sarakhs_terms.json", next_chapter_id: null}`.
- Change `content/chapters/chapter_06_pushang/pushang.json`'s terminal node `n12_departure_pushang`'s `next_chapter_id` from `null` to `"chapter_07_sarakhs"` — the node-level value, not just the manifest.
- `tests/unit/test_pushang_dialogue_content.gd` has `test_the_terminal_node_has_a_null_next_chapter_id`, asserting `n12_departure_pushang`'s `next_chapter_id` is `null` — must be strengthened to assert the new value.
- **Grep `tests/` for the literal string `n12_departure_pushang` before calling this wiring done, not just one remembered test name.** Chapter 6's own wiring task ran this exact grep and found 5 raw hits against 2 named ones, checked all three extras, found nothing missed — the discipline worked. Chapter 5's wiring task, one chapter earlier, did not run it broadly enough and missed a second full-playthrough test. Keep running it broadly every time.

## Global constraints (unchanged from every prior chapter)

Godot 4.3 floor. `JSON.parse_string` deserializes numbers as float — cast to `int` before comparing/assigning `int`-typed reputation values. No combat (Sarakhs is tense but nothing here depicts fighting). No religious/ritual framing of the hidden network — n/a, this chapter never mentions it. `ghazi`'s definition stays economic/structural (plunder-share vs. state wage), not framed primarily as religious warfare, consistent with the game's established critical-materialist lens on the plunder economy (Bost, Farah's Somnath legend). Commit per task.
