# Chapter 2: Bost — Design Doc

**Status:** Approved for planning. **Date:** 2026-08-08
**Builds on:** `2026-08-07-borrowed-fortune-design.md` (setting/systems), `2026-08-08-chapter-1-teginabad-design.md` (chapter-manifest pattern), shipped Chapters 0-1 (`v0.1-prologue`, `v0.2-teginabad`).

---

## 1. High Concept

Chapter 2 is Bost — Mahmud of Ghazni's real winter palace complex, Lashkari Bazar. Farrukh seeks out a *sarraf* (moneychanger) to make sense of the mysterious Rayy suftaja from his father's papers. The moneychanger, **Mihran**, is a Zoroastrian — a real, historically grounded minority position (jizya-paying, understandably cautious about anything that could draw official attention) — which gives his hesitation genuine stakes rather than generic caginess. He also knew Farrukh's father personally, giving this chapter its emotional beat alongside its mystery progress. This is the chapter's second real fork (after Teginabad's bribe/honest split): how much Farrukh presses a frightened, vulnerable man for information.

**Disclosed spec deviation:** the original design spec's one-line description of Bost was "wealth and plunder made visible" — implying an early direct confrontation with the India-campaign plunder economy. That confrontation is deliberately deferred past this chapter (confirmed with the user): the palace appears only as a glimpse at the end, atmosphere and foreshadowing, not a scene. This is a conscious revision, not an oversight.

**Forward-looking note (not part of this chapter's scope):** the user has confirmed that the Ledger's buy/sell/haggle trade mechanics — built in the Prologue, never exercised by any chapter's content since — should get real implementation somewhere in the game, once more of the story structure exists. This is NOT this chapter's job (Bost stays narrative-only, same as Teginabad). Whoever plans the chapter that finally introduces real trading (per the original design spec, likely a bigger bazaar stop such as Herat or Nishapur) should treat this as a standing commitment, not a permanently shelved idea.

---

## 2. Cast

**Mihran** — a moneychanger in Bost's bazaar, trusted by the caravan trade on reputation. Zoroastrian, a real and still-present minority in this era's Khorasan (per the original design spec's philosophy research: fading but not extinct communities, jizya-paying, existing under real legal/social pressure). Knew Farrukh's father as a regular, honest client over several years. Genuinely afraid of a specific second mark on the suftaja — not performative caution, real risk calculus for a man in his position.

---

## 3. Chapter Structure — 11 nodes, one real fork

1. `n01_bost_arrival` — arrival, Lashkari Bazar glimpsed across the canal-fed green
2. `n02_seeking_the_sarraf` — Farrukh finds Mihran's shop
3. `n03_mihran_examines` — Mihran reads the suftaja, goes quiet
4. `n04_the_second_mark` — the Rayy house's seal is recognized; a second, more troubling mark is not
5. `n05_ibn_hasan` — Mihran recognizes Farrukh as his father's son; a personal, humanizing aside
6. `n06_the_danger` — Mihran explains what the second mark could cost him (jizya, official attention)
7. `n07_the_offer` — **the fork**
   - **A. "Ask him plainly."** → `n08a_pressed`. Effects: flags `["pressed_mihran_for_the_name"]`, reputation `{"trading_families": -1, "townsfolk": -1}`
   - **B. "Don't make him say it."** → `n08b_patient`. Effects: flags `["earned_mihrans_trust"]`, reputation `{"trading_families": 2}`
8. `n08a_pressed` — gets a real name/city, but Mihran closes off, warns Farrukh off → `n09`
   `n08b_patient` — gets a vaguer clue (a metaphor pointing toward "follow the channels"), genuine trust → `n09`
9. `n09_the_palace_glimpsed` — Lashkari Bazar's painted guardsmen seen from outside; Farrukh deliberately doesn't finish the thought about what the wealth cost (the deferred plunder theme, held at arm's length on purpose)
10. `n10_departure_bost` — terminal node (`choices: []`), transition toward Farah

Both fork paths converge on `n09` for the next scene, carrying forward different persistent state — same structural pattern as Teginabad's fork.

---

## 4. Full Node Text

> **n01_bost_arrival**
> After Teginabad's flat customs-wall discipline, Bost announced Ghaznavid wealth a different way - not with a gate and a ledger, but with a skyline. Across the canal-fed green, low domes and a long red-brick palace face caught the last sun: the sultan's winter residence, Lashkari Bazar, more garrison-town than palace grounds, more market than either. Farrukh had no business inside those walls and no wish to acquire any. His business was smaller, and stranger: a piece of paper from a house in Rayy that his father's accounts should never have mentioned.

> **n02_seeking_the_sarraf**
> Every winter-quartered army needs men who can turn one kingdom's coin into another's, and Bost had no shortage of them. Farrukh found the one the caravan drivers trusted on reputation alone - a narrow shopfront off the bazaar's spine, scales hung by the door, a {{sarraf|sarraf}} named Mihran who weighed silver for a living and, by the look of the room, had done it long enough to stop being impressed by anyone's coin.

> **n03_mihran_examines**
> Mihran took the suftaja without much interest until he actually read it, and then went quiet in a way Farrukh was beginning to recognize - the particular stillness of a man deciding how much of what he'd noticed was safe to say aloud.

> **n04_the_second_mark**
> "This seal I know," he said finally, turning the paper toward the light. "The house in Rayy - a real house, good credit, before -" he stopped himself. "Before some things changed there. But this" - he touched a second mark beneath the first, smaller, easy to miss - "this I have seen exactly twice in eleven years, and both times I wished I hadn't."

> **n05_ibn_hasan**
> He set the paper down without being asked and looked at Farrukh properly for the first time. "Ibn Hasan," he said - not a question. "You have his hands. He came through here four, five years running, always the same honest weight, never once tried to pass me clipped silver like half these road-merchants do. I am sorry for him. Whatever this is" - he touched the paper again, carefully, as if it might be warm - "he did not deserve to carry it alone. Whether he understood he was carrying it at all, I couldn't say."

> **n06_the_danger**
> Farrukh asked what the second mark meant. Mihran's hand actually moved to cover it, an old instinct. "A name goes with it," he said. "I could give you the name. I could also tell you that I pay the {{jizya|jizya}} every year specifically so that men in robes with questions never have reason to visit my shop - and a name like this one is exactly the kind of thing that brings them anyway, whether I meant to say it or not."

> **n07_the_offer**
> He looked at Farrukh, weighing something that had nothing to do with silver. "I will tell you, if you ask me plainly," he said. "But I would rather you didn't have to."

> **n08a_pressed**
> Farrukh asked. Mihran told him - a name, a city, nothing more, delivered in the flat voice of a man crossing a line he'd hoped to avoid - then wrapped the suftaja back into its cloth with hands that were, for the first time since Farrukh had walked in, not entirely steady. "Don't come back here," he said, not unkindly. "Not because of the debt. Because of this." Farrukh had his lead. He had also, he suspected, spent something he could not get back.

> **n08b_patient**
> Farrukh didn't ask. Mihran seemed to relax by a fraction he probably didn't notice himself. "I'll tell you this much for nothing," he said. "Whoever sent that second mark moves money the way water moves through Bost's canals - underground, on purpose, surfacing only where someone built a channel for it to surface. Follow the channels, not the water. You'll find your name eventually, and it will still be true when you do." It was less than a name. It felt, somehow, like more.

> **n09_the_palace_glimpsed**
> Farrukh left Mihran's shop as the winter light went copper over Lashkari Bazar's long brick face, close enough now to make out painted guardsmen on the palace's outer wall - a hundred still figures keeping a watch that had never once been real. He thought of what it must have cost, all of it - the paint, the brick, the canals, the garrison that ate a season's wages just by existing - and did not let himself finish the thought all the way to where it wanted to go. That accounting was for another day, on another road. Tonight there was only Farah ahead, and a channel somewhere with his father's name written on it in water.

> **n10_departure_bost**
> He set out before the palace's watch-fires were lit, the caravan small now, the guide new, the road west running straight into a dark that Nasa's riders had already told him was not as empty as it used to be.

---

## 5. New Glossary Terms (`content/glossary/bost_terms.json`)

| Term | Headword | Definition |
|---|---|---|
| `sarraf` | Sarraf | A moneychanger - weighed and verified coin for a cut, and often served as an informal banker for traveling merchants. |
| `jizya` | Jizya | A per-capita tax levied on non-Muslim subjects (dhimmi) under Islamic rule, in exchange for protection and exemption from military service. |

(`suftaja` is referenced in plain prose, deliberately not re-glossed - it was already taught in the Prologue and persists in The Margin via the existing merge fix.)

---

## 6. Engine Changes Required

**None.** This chapter reuses the chapter-manifest mechanism, `DialogueEngine`, `MarginGlossary`, and `ChapterView` exactly as they exist after Chapter 1 - including the auto-transition recursion guard and the validated node-graph loading. This is a content-only chapter plus one manifest update (adding `chapter_02_bost` and pointing `chapter_01_teginabad`'s `next_chapter_id` at it).

---

## 7. Scope & Next Steps

Comparable size to Chapters 0-1 (11 nodes), no new engine work, one real fork. Next step: `writing-plans` to turn this into a task-by-task implementation plan, following the same TDD/subagent-driven-development pattern as the previous two chapters.
