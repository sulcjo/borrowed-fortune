# Chapter 1: Teginabad — Design Doc

**Status:** Approved for planning. **Date:** 2026-08-08
**Builds on:** `2026-08-07-borrowed-fortune-design.md` (setting/systems), the shipped Prologue (`v0.1-prologue`, tag on master).

---

## 1. High Concept

Chapter 1 is the first stop past Ghazni: **Teginabad**, a real Ghaznavid administrative/customs outpost near Panjwai. The caravan is stopped at the toll post by **Sa'id ibn Yaqub al-Teginabadi**, an *amid* (customs officer), whose scrutiny of the goods pays off the mystery planted in the Prologue (the suftaja from Rayy, the unsigned letter). This is the first chapter with a **real fork** — a choice with genuinely different, persistent consequences (reputation and flags), not a reconverging one like both Prologue forks.

Per explicit direction: this chapter should teach real politics (Ghaznavid tax-farming pressure, the frontier crisis pressing down through the bureaucracy), real religious practice (prayer structuring the day, an authentic *adhan*/*zuhr* beat), real customs (the legitimate *'ushr* tax versus the corrupt "expedited passage" fee layered on top of it), and real interiority (Farrukh's internal reckoning with grief, the debt, and the Floating Man idea from the Prologue, tested against an actual decision rather than left abstract).

**No new trade/economy mechanics this chapter** (confirmed with the user — trading is deferred to a later, bigger bazaar stop). The fork's cost is felt narratively and in reputation, not modeled as a Ledger transaction.

---

## 2. Cast

**Sa'id ibn Yaqub al-Teginabadi** — young for his rank, threadbare cuffs on otherwise good cloth. Not a villain: a functionary under real pressure, converting every traveler into a quota he owes upward, ultimately to a court nervous about the frontier (ties directly to the Nasa/Oghuz unrest thread already planted in the Prologue). Devout in an ordinary, unperformed way — breaks off customs business for *zuhr* without comment. His attitude toward Farrukh shifts based on the fork (see below).

---

## 3. Chapter Structure — 11 nodes, one real fork

1. `n01_teginabad_arrival` — arrival, sensory contrast with Ghazni
2. `n02_the_official` — Sa'id introduced
3. `n03_politics` — tax-farming pressure, frontier crisis pushing down through the bureaucracy (Nasa callback)
4. `n04_the_demand` — the manifest discrepancy (Rayy suftaja) surfaces; the legitimate *'ushr* is explicitly distinguished from what comes next
5. `n05_prayer_interlude` — *adhan*, *zuhr*, Sa'id steps away; Farrukh's interiority (grief, the Floating Man idea tested against a real decision)
6. `n06_the_choice` — **the fork**
   - **A. "Pay for expedited passage."** → `n07a_bribe`. Effects: flags `["bribed_teginabad_official"]`, reputation `{"townsfolk": -1, "trading_families": -1, "ghaznavid_officials": 1}`
   - **B. "Let the inspection happen."** → `n07b_inspection`. Effects: flags `["honest_at_teginabad"]`, reputation `{"ghaznavid_officials": 2}`
7. `n07a_bribe` — aftermath narration (bribe path) → `n08`
8. `n07b_inspection` — aftermath narration (honest path); the inspectors find something. Two choices:
   - "Say nothing. Let him wonder." → `n08` (always available)
   - "Tell him what you read in the unsigned letter back in Ghazni." → `n07b_letter_callback`, **gated on `requires_flag: "read_unsigned_letter"`** (the Prologue's own choice, paid off one chapter later) — effects: flags `["revealed_letter_to_said"]`, reputation `{"ghaznavid_officials": 1}`
9. `n07b_letter_callback` — the payoff scene, Sa'id's brief recognition → `n08`
10. `n08_guide_transition` — the Ghazni-hired guide's contract ends here (already implied by the Prologue's last line); practical arrangement for the Bost leg
11. `n09_departure_teginabad` — closing/foreshadowing, terminal node (`choices: []`)

Both fork paths converge on `n08` for the next scene, but carry forward genuinely different, persistent state — this is what makes it a *real* fork per the earlier design discussion, without requiring the entire remainder of the chapter to diverge.

---

## 4. Full Node Text

> **n01_teginabad_arrival**
> Teginabad was not a city pretending to be one. It was a wall, a gate, and the men who stood in it — a fortress squatting on patterned brick where the Ghazni road narrowed toward the desert crossing beyond. After the capital's crowded lanes, the outpost felt like a held breath. Farrukh's caravan guide reined in a full bowshot before the gate, the way a man slows before knocking on a door he isn't sure will open.

> **n02_the_official**
> A man came out to meet them before they'd finished dismounting — young for the {{amid|amid}} he claimed, his robe good cloth gone thin at the cuffs, the particular tiredness of someone paid to want more from travelers than they wished to give. He named himself Sa'id ibn Yaqub, amid of the Teginabad customs post, and asked, with the practiced patience of a man who has asked it a thousand times, to see the manifest.

> **n03_politics**
> He did not ask unkindly. That, Farrukh would learn, was almost worse — Sa'id had the manner of a man doing arithmetic in his head at all times, converting every traveler into a quota he owed someone above him, and that someone into a quota owed to Ghazni, and Ghazni, lately, into a court nervous about a frontier that kept sending back worse news than it sent revenue. "They tell us collect what Nasa isn't sending anymore," he said, not quite to Farrukh, checking a seal against a wax impression in his own ledger. "As if a customs post can tax a rumor."

> **n04_the_demand**
> He found the discrepancy the way men who have found a thousand discrepancies find them — without surprise, only a faint, professional interest. The {{ushr|'ushr}} was already logged and paid; that was never in question. This was a different matter: a weight of silk logged as originating from a house in Rayy that no merchant road from Ghazni to Teginabad had any business touching. "Interesting bill of lading, this," Sa'id said, not looking up. "I'll need to open the crates."

> **n05_prayer_interlude**
> The call to {{zuhr|midday prayer}} rose from the post's small mosque before Farrukh could answer him — the {{adhan|adhan}}, unhurried, indifferent to customs disputes. Sa'id closed his ledger at the sound the way another man might close a door. "God's business first," he said, and went, leaving Farrukh standing in the yard with the crates still sealed and the whole caravan's fate apparently subordinate to the sun's position in the sky.
>
> Farrukh did not pray, not then — grief had made his prayers thin and mechanical since Ghazni, words without the man behind them believing they reached anywhere — but he found himself doing the other thing the old letter-writer had given him instead: counting what in this moment was borrowed and what, if anything, was his. The crates were not his — his father's, or his father's creditors', depending on which qadi you asked, though none had asked. The debt was his, by his own mouth, at a graveside, to no one's compulsion. Perhaps that was the one contingent thing a man got to choose for himself: not what he was given, but what he agreed to carry.

> **n06_the_choice**
> Sa'id returned unhurried, prayer's calm still on him, and made Farrukh an offer with the same flat patience he'd made every other statement: the inspection could happen, properly, crate by crate, manifest against goods — a process that would take the rest of the day and might, Sa'id did not pretend otherwise, turn up exactly the kind of irregularity that got shipments impounded and merchants questioned by men less patient than himself. Or the post's fee for "expedited passage" could be settled now, quietly, and the caravan could be through the gate before the sun moved another hand's width.

> **n07a_bribe**
> Farrukh paid it. He told himself, counting the coins into Sa'id's palm, that this was arithmetic and nothing else — the same arithmetic Sa'id himself was always doing, obligation converted to obligation, all the way up to a Sultan who'd never see a dirham of it and all the way down to a father's debt Farrukh was still, by his own word, carrying. It did not feel like arithmetic. It felt like the first small dishonesty of the man he might become on this road, and he could not yet tell if that was a cost or simply a toll, the same as any other.

> **n07b_inspection**
> Farrukh let him look. Sa'id's men worked through the crates with the bored thoroughness of soldiers who had done this a hundred times and expected the hundred-and-first to be exactly as dull — until one of them went still over an unmarked bolt of cloth, wrapped inside it something that was plainly not cloth at all, and Sa'id crouched to look himself, and did not immediately say what he saw.

> **n07b_letter_callback**
> "There was a second paper," Farrukh said, before he'd decided to say it — the same way he'd once stepped forward at a grave. "Unsigned. My father's clerk wouldn't finish reading it aloud." Sa'id looked up at him for a long moment, weighing something that had nothing to do with customs law. "Then you already know more than I do," he said, "which is not usually true of the men I stop at this gate." He did not write anything further in his ledger that day.

> **n08_guide_transition**
> The caravan guide who'd brought them from Ghazni collected his fee at the gate and turned back the way they'd come — his contract, like the road behind them, ended at Teginabad. Farrukh spent what remained of the afternoon doing the ordinary, unglamorous work of the road: asking after a caravan master bound for Bost who'd take on a smaller party, haggling nothing, since there was nothing left in him to haggle with, and simply agreeing to the first honest face that offered a fair arrangement — a decision he suspected his father would have made faster, and better, and made anyway.

> **n09_departure_teginabad**
> They left Teginabad in the last honest light of the day, patterned brick walls behind them, Sa'id already a receding figure who would forget Farrukh's face by nightfall and remember, if he remembered anything, only the shipment's strange manifest. The road to Bost ran through country that still, for one more year, called itself Ghaznavid without irony. Farrukh did not know yet how short a lease that word had left. He knew only that the debt was still his, the letter's secret still unresolved, and that somewhere ahead, his father's actual road — not the one Nasuh's ledger recorded, but the one the man had actually walked — was still waiting to be found.

---

## 5. New Glossary Terms (`content/glossary/teginabad_terms.json`)

| Term | Headword | Definition |
|---|---|---|
| `amid` | Amid | A Ghaznavid administrative title for a mid-level civil or financial official — used here for the officer overseeing a customs post. |
| `ushr` | 'Ushr | A customs tithe on goods entering or crossing Muslim territory — roughly 5% for Muslim traders, up to double for non-Muslim or foreign ones — collected at frontier posts like this one. |
| `zuhr` | Zuhr | One of the five daily prayers, performed after the sun passes its zenith at midday. |
| `adhan` | Adhan | The Islamic call to prayer, sounded aloud to mark each of the five daily prayer times. |

(`ostad` is referenced in `n05` in plain prose, deliberately not re-glossed — it's a callback to a term the Prologue already taught, not a new one.)

---

## 6. Engine Changes Required

Two small, real engine changes — not just content authoring:

**6.1 `MarginGlossary.load_entries()` must merge, not replace.** Currently `_entries = entries` — loading Chapter 1's glossary would silently erase every Prologue term from the persistent Margin. Fix: merge key-by-key. Needs a regression test proving two sequential `load_entries()` calls with disjoint term sets leave both present.

**6.2 A minimal chapter-transition mechanism.** Chapter 1's existence forces a real decision here (this is also where Finding K from the Prologue's final review — hardcoded `chapter_id` — stops being deferrable). Proposed minimal version:
- A small manifest, `content/chapters/manifest.json`, mapping `chapter_id → {dialogue_path, glossary_path, next_chapter_id}`.
- `ChapterView` gains `load_chapter_by_id(chapter_id: String)`, which resolves the manifest entry and calls the existing `load_chapter(dialogue_path, glossary_path)` unchanged (Chapter 0's tests keep working against the existing method), then records `next_chapter_id` and sets `chapter_id` from the manifest (replacing the hardcoded value).
- `_save_and_finish()` is extended: after saving, if `next_chapter_id` is not null, immediately call `load_chapter_by_id(next_chapter_id)` — the game flows Prologue → Teginabad in one sitting without a menu.
- `Main.gd` calls `load_chapter_by_id("chapter_00_prologue")` instead of hardcoding both paths directly.

**Explicitly NOT in scope:** reading a save file back in on boot. Closing and reopening the game still always restarts at the Prologue. Real save/resume remains deferred, same as the Prologue's final review concluded — Chapter 1 only closes the "hardcoded chapter_id" gap, not the "no load path" one.

---

## 7. Scope & Next Steps

Comparable size to the Prologue's content layer (11 nodes vs. 14), plus two small, well-scoped engine additions. No new trade mechanics, no save/resume. Next step: `writing-plans` to turn this into a task-by-task implementation plan, following the same TDD/subagent-driven-development pattern as the Prologue.
