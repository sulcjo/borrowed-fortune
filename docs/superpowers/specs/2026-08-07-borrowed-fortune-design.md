# Borrowed Fortune — Design Doc

**Status:** Approved for planning. **Date:** 2026-08-07
**Genre:** 2D narrative trade-sim / "immersive sim"-adjacent adventure, no combat.
**Engine:** Godot. **Art:** Persian-miniature-inspired, diegetically framed.

---

## 1. High Concept

You are **Farrukh ibn Hasan al-Nishapuri**, nineteen, in Ghazni, in the year 1035. Your father has just died, leaving a debt-choked, half-finished caravan venture and a household that can't cover what he owed. At his graveside, before the town, you swear to stand surety for his debt yourself — a real, binding Islamic legal act (**kafāla/ḍamān**), not required of you by law, chosen anyway. You inherit the debt, and with it a mystery: your father's ledger contains a payment instrument and a shipment manifest that don't match anything the shop ever carried, tied to money that smells of Sultan Mahmud's India campaigns and to a name whispered with real fear — a hidden network of Fatimid-directed missionaries the state has been crucifying people for belonging to.

The game is the road from Ghazni to Nishapur — and the frontier is failing as you travel it. Real history: the Battle of Nasa (1035) is already unsettling news when you set out; Merv falls to the Seljuks in 1037; Sarakhs, Herat, and Nishapur — your destination — all fall in 1038. You are walking toward a city that is, historically, about to stop being Ghaznavid at all. The empire's contingency and your father's contingency are the same shape. That's not a metaphor bolted on afterward — it's the actual history of this road in this decade.

No combat exists as a system. Violence, ruin, exile, and death are all real — always a consequence of a choice or bad luck, foreshadowed, never a minigame you pilot.

---

## 2. Setting & Timeline

**Window: 1035–1038**, chosen deliberately as the "collapsing frontier" window rather than the fully stable 998–1037 Ghaznavid road:

| Stop | Ghaznavid until | Historical note |
|---|---|---|
| Ghazni | throughout (dynasty survives in the east past 1040) | capital, safe home base |
| Teginabad (near Panjwai) | throughout | admin outpost, Ghaznavid heartland |
| Bost | throughout | Mahmud's winter palace complex, Lashkari Bazar |
| Farah | throughout | thin sourcing — treat as stable relay, invent lightly |
| Herat | 1038 | falls same year as Sarakhs/Nishapur |
| Pushang (Bushanj) | 1038 | falls with Herat, same province |
| Sarakhs | 1038 (Battle of Sarakhs) | frontier fortress, first to break |
| *Merv (branch)* | *1037* | falls **before** Sarakhs/Herat/Nishapur — a real backtrack off the direct line |
| Nishapur | 1038 | journey's end, falls the year you arrive |

Dandanaqan (1040) is the seal on a collapse already ~2/3 complete by 1038 — usable as an epilogue beat, not something the core game needs to dramatize directly.

**Trade corridors (keep distinct in any map/UI):** East via Kabul/Khyber (India ↔ Ghazni — spices, cotton, indigo, captives). North via Balkh (Ghazni ↔ Transoxiana — horses, relayed silk). **Southwest via Teginabad–Bost–Farah–Herat–Nishapur — this is the game's route.**

---

## 3. Route & Structure — Node-Chain Campaign

8 fixed stops in geographic order (Ghazni is home base / Chapter 0; the 7 stops after are Chapters 1–7, with an optional Merv branch off Sarakhs):

1. **Ghazni** (Prologue/home) — the death, the vow, the reckoning, departure.
2. **Teginabad** (admin seat: nearby Panjwai) — first stop past the capital; Ghaznavid bureaucracy, first taste of the debt following you.
3. **Bost** — Mahmud's winter palace complex at Lashkari Bazar (170×100m South Palace, painted-guardsman murals, attached bazaar street). Wealth and plunder made visible.
4. **Farah** — thinnest-sourced stop; a gritty, quiet desert relay. Good for a smaller, breather chapter.
5. **Herat** — provincial capital, oasis on the Hari Rud, one of six Ghaznavid mints. Falls in 1038 — the pressure should be audible here.
6. **Pushang (Bushanj)** — small walled waystation, "half the size of Herat" (Ibn Hawqal). A minor, grittier stop between two big cities.
7. **Sarakhs** — "Gate of Khorasan," fortress on the Tejen, first to break (Battle of Sarakhs, 1038).
   - *Optional branch:* **Merv** — off the direct line, a real detour, but fell in 1037 — the clearest "this already happened here" stop in the game.
8. **Nishapur** — journey's end. Provincial capital, turquoise market, falls the year you arrive. Tus (Ferdowsi's home, ~75km off) is reachable as a late coda.

Each stop is a self-contained chapter: bazaar/dialogue/mystery beats, one meaningful trade decision that carries forward, short "on the road" vignettes between stops (weather, encounters, checkpoints, the abstracted-danger system below). State — coin, goods, debts, reputation per faction, clues, relationships — persists across the whole chain.

**Scope note:** 8 chapters + 1 optional branch is a real, finishable solo-dev scope — larger than a tight vertical slice, smaller than an open-ended saga.

---

## 4. Protagonist & Story Spine

**Farrukh ibn Hasan al-Nishapuri** — ism *Farrukh* ("fortunate," real pre-Islamic-origin Persian name, used ironically), no kunya yet (unmarried, no son), nisba *al-Nishapuri* (his family's roots are in Nishapur — going there is also, quietly, going home). His father, addressed his whole adult life only as **Khwaja Abu Farrukh** ("father of Farrukh"), died owing three or four trading houses money nobody had yet added up.

**The spine, one thread, three layers:**
1. **Personal** — what really happened to his father, and why the ledger doesn't add up.
2. **Political/economic** — the money is tangled with goods moving out of Mahmud's India campaigns; profiting from that machinery is not a neutral background fact the game lets slide.
3. **Conspiratorial** — a **Fatimid-directed Ismaili cell** (hierarchical, Cairo-funded, its own agenda) is entangled in the same deal — dangerous to know about at all, in a state that crucified Ismailis at Rayy in 1029.

**The inciting mechanic — kafāla, not law:** Classical Islamic inheritance law (all four Sunni madhhabs, including the Hanafi school dominant in this Khorasan setting) caps heir liability at the estate's value — Farrukh could legally have walked away the moment the estate was exhausted. He didn't: at the grave, in front of witnesses, he voluntarily guaranteed the debt himself (**kafāla**/**ḍamān** — a real, binding Islamic suretyship instrument, not a narrative abstraction). The whole game runs on the gap between what the law released him from and what his own word didn't.

**A real trap worth building into the mechanics:** under Hanafi doctrine, the debt-encumbered portion of an estate never fully vests in the heir — if Farrukh starts selling his father's shop inventory before creditors are addressed, *he personally* becomes liable for what he disposed of, on top of the kafāla vow. Early-game economic decisions should carry this teeth.

---

## 5. Cast — Real Historical Figures, Correctly Placed

| Figure | Dates/reign | Where reachable | Use |
|---|---|---|---|
| Sultan Mas'ud I | r. 1030–1040 (killed Jan 1041) | Ghazni / Herat (mustered there 1020 as a prince) | inherits the collapse; distant authority figure |
| Abu Nasr Mishkan | chancery head c. 1011–1039/40 | Ghazni | central bureaucrat; access to debt/state records |
| Abu'l-Fadl Bayhaqi | c. 995–1077 | Ghazni | chancery secretary, later the era's great historian — could plausibly be the one "recording" this very story |
| Hasanak-e Vazir | vizier 1024/25–1030, executed c. 1031–32 | Ghazni (rumor/backstory) | fallen-patron court-purge drama, cautionary tale |
| **Al-Biruni** | 973–1048 | Ghazni | polymath, brought "in chains" after 1017 Khwarazm conquest, writing *Kitab al-Hind*; known locally as the man who once out-argued Ibn Sina (that debate was actually c. 997–998, before this window — use as reputation, not a scene) |
| **Abu Sa'id Abu'l-Khayr** | 967–1048/49 | genuinely on/near-route: born near Sarakhs, resident in Nishapur | best on-route Sufi figure — early mysticism of poverty/self-effacement, *not* a formal order (those are 12th-13th c.) |
| **Ferdowsi** | c. 940–1019/1020 | Tus, ~75km from Nishapur | reachable near the route's end as a very old man (or recently dead, if timed at the later end); *Shahnameh* completed ~1010, dedicated to Mahmud — its "wheel of fortune topples every throne" theme is the game's thesis restated as epic poetry |
| **Ibn Sina (Avicenna)** | 980–1037 | **never physically on-route** — Bukhara/Khwarazm/Gurgan/Rey/Hamadan, all west/north of this road | present only as rumor, reputation, letters, and eventually news of his 1037 death — landing in the same 1–2 years Ghaznavid Khorasan itself falls apart. Deliver his "Floating Man" idea and "contingent existence" vocabulary secondhand, through traveling scholars, not a meeting. |
| Nasir-i Khusraw | b. 1004 | regional native, minor cameo only | his real Ismaili conversion is dated c. 1045 — **five years after this game ends**; use only as a not-yet-converted courtier, never as the network's leader |
| Tughril, Chaghri, Musa (Seljuq leaders) | Nasa 1035 / Dandanaqan 1040 | frontier, faction-level | antagonist faction, not personal NPCs |
| Majd al-Dawla | last Buyid of Rayy, deposed 1029 | off-route, held captive in Ghazni | rumor/captive-in-Ghazni NPC, ties to the Rayy suftaja discovered in the prologue |

---

## 6. Systems

**Ledger (economy):** Buy/sell/haggle grounded in real instruments:
- **Mudāraba/qirāḍ** — silent-capital partner + traveling-agent partner; capital losses fall on the financier alone *unless the agent was negligent* — the exact shape of Farrukh's father's failed venture, and a mechanic Farrukh can use himself with future partners.
- **Suftaja** — a proto-bill-of-exchange; move value between cities without carrying coin through dangerous country. Interest is forbidden, so the banker's margin hides in the exchange spread — model as a hidden conversion cost, not a visible interest rate.
- Coins (gold **dinar**, silver **dirham**) are weighed and purity-checked, not just counted — a haggling/appraisal layer, not a fixed price list.
- **Zakat** (2.5%/year on capital held above a threshold) and **'ushr** (customs tithe, ~5% Muslim / up to double non-Muslim) as real, predictable costs; ad hoc gate/pass tolls as an unpredictable, bribery-shaped cost on top.

**Reputation:** Tracked per faction independently (Ghaznavid officials, trading families/creditors, the hidden Fatimid-directed network, ordinary townsfolk) rather than one global morality meter — each gates its own dialogue, prices, and doors.

**Clue tracking:** Pieces of what actually happened to the father accumulate stop by stop; order and completeness affect later dialogue and the ending.

**Danger:** Abstracted, stat/dice-resolved, always foreshadowed (bandits, checkpoints, the collapsing frontier itself). Never a piloted combat system. Rare desperate moments may let the player threaten or strike someone, resolved the same narrative way.

**Slavery — handled deliberately, not as background color:** The largest actual commodity moving on this road in this period was enslaved people from Mahmud's campaigns. Decision: **refusable, at a real cost.** The player can decline to deal in it, but it costs something real — money, a relationship, a door that closes. It is never allowed to sit as neutral goods-list flavor.

---

## 7. The Margin — In-Game Encyclopedia System

Since the game is already framed as a manuscript retelling compiled generations after the events (see Art Direction), the glossary is **diegetic**: the copyist/editor's own marginal notes, explaining unfamiliar terms to their own later audience.

- Any term, place, or custom appearing for the first time in narration/dialogue is marked (underline / small marginal ornament). Selecting it opens a short entry: headword, a tight 2–4 sentence definition, sometimes a line of the copyist's own editorializing uncertainty.
- Entries persist in a browsable menu ("The Margin"), cross-referenced.
- Also the honest place to flag the game's own stylization (e.g., an entry on the illustrations noting they're painted in a *later* manuscript style than the period they depict).
- Implementation: a dictionary keyed by term, entries as content-layer data — fits the engine/content split cleanly, no special engine work beyond a lookup + tooltip/panel UI.
- Section 11 below is the seed vocabulary for this system.

---

## 8. Art Direction

The popular "Persian miniature" look (jewel tones, gold-ground skies, flat perspective, dense arabesque borders) is a **Timurid/Safavid convention, c. 1400–1600** — 400+ years after this story, and it postdates the paper/pigment technology and script (nasta'liq) that look requires.

**Solve — make the anachronism diegetic:** frame the game as a manuscript retelling made generations after the events it depicts — exactly how every surviving Shahnameh manuscript actually works (the *Shahnameh* text is from ~1010; its earliest surviving illustrated copy is the 1330s Great Mongol/Demotte Shahnameh, painted ~300 years later). This licenses the full jewel-tone/gold-ground grammar for the **presentational layer** — menus, chapter/map screens, cutscene interludes, save illuminations — as an honest later retelling, not a claim of period accuracy.

For the **depicted in-world layer** (costume, architecture, props), use the genuine 1000–1040 record instead:
- Lashkari Bazar frescoes — Turkic palace guards, frontal torso/profile feet, red/gold/black (closer to Sogdian-Buddhist mural convention than to any later miniature)
- Patterned unglazed brick (Gonbad-e Qabus, 1006–7) rather than tilework
- Stucco, Khurasani inlaid bronze, Sasanian-derived hunt/roundel imagery
- **Kufic or early naskh** lettering for any in-world text/signage — never nasta'liq (formalized ~350 years later)
- **Qaba** (front-closing coat) as the default merchant/craftsman garment, plainer/undecorated versus the ornamented court version documented at Lashkari Bazar

**Avoid entirely** (all confirmed anachronistic for this window): Ghazni's star-patterned minarets (Mas'ud III, 1099–1115), Herat's tiled Great Mosque (Ghurid, begun 1200), Ribat-i Sharaf caravanserai (Seljuk, 1150s), any Kashan-style figural lustre/mina'i ceramics (earliest dated piece 1179), tea, coffee, tobacco/qalyan (all centuries too early), organized Sufi orders/tariqas as institutions (12th–13th c. development — individual respected Sufis and small lodges are fine, "brotherhoods" are not).

---

## 9. Engine & Architecture

**Godot**, engine/content split modeled on the studio's existing project *vigil* (a terminal game with tested, pure engine code and all story content in a separate layer):
- **Engine layer** (generic, tested): ledger/economy math, dialogue system, reputation tracking, save/load state, The Margin lookup system.
- **Content layer** (data-driven): every stop, character, dialogue tree, gloss entry, and story beat as content files the engine reads.
- Static/illustrative art (the chosen style needs little animation) plays to Godot's 2D strengths without needing its 3D/physics systems.

---

## 10. Prologue (Chapter 0 — Ghazni)

Full scene text:

> Farrukh ibn Hasan al-Nishapuri had lived nineteen years without once hearing his father's own name spoken aloud. To the bazaar, to the mosque, to the tax-farmer's clerks, the man who raised him was **Khwaja Abu Farrukh** — "master, father of Farrukh" — and that was enough of a name for a man to die under.
>
> It was a bad season to be caught grieving. Riders had come through the Chahar Su market three weeks running with the same unsettling murmur — Turkmen horsemen loose again on the Khorasan frontier, a garrison broken somewhere near **Nasa**, word passed caravan to caravan faster than any courier the Sultan employed. Farrukh had barely marked it. His father's cough had turned to fever on the same week the news arrived, as if the sickness in the empire's far edge had found its way, by some private road, into one merchant's chest in Ghazni.
>
> He died on a Thursday. His body was washed that same afternoon by his brother and two men from the mosque — **ghusl**, three times over, the last water scented with camphor — and wrapped before evening in plain white cloth, three lengths of it, unmarked, unadorned. Farrukh had expected — he did not know what he had expected. Not this. Not a shroud identical, thread for thread, to the one they'd have wrapped a beggar in behind the grain market. **Kafan** made no distinction. That was the point of it, someone told him gently. He did not feel comforted.
>
> At the grave they said the **janāza** standing, no bowing, near-silent — and it was there, in front of half the merchants of the western bazaar, that the trouble surfaced into the open air. The imam did not begin. He turned, instead, to the men close by, and asked, plainly, the question the Prophet himself was remembered to have asked before he would pray over a man: *is he in debt?*
>
> Someone answered before Farrukh could. Yes. Considerably. To three houses, maybe four. Nobody was certain how much, because nobody — not the widow, not the clerks, not the dead man's own partner — had yet opened the ledger.
>
> The imam did not move to pray. A dead man owing money was not, strictly, buried without someone living answering for it — and for a breath that felt much longer, nobody among the assembled **tājirs** stepped forward to be that someone.
>
> Farrukh stepped forward instead.
>
> He said the words before he had decided to say them, the way a man's hand moves before his mind has finished arguing with it: that he would stand for his father's debt himself — all of it, whatever it proved to be — **damān**, his word as guarantee, in front of every man there to remember it. It was not required of him. No qāḍī, no creditor, no verse of the Book would have compelled a son to answer for a father's failed venture beyond whatever the estate itself could cover — a fact he did not yet know, and that would have changed nothing if he had. He said it because the alternative was standing silent while his father was refused a grave.
>
> The imam prayed. Grief afterward observed its three days of **taʿziya** — visitors, murmured *raḥimahu llāh*, trays of food from neighbors Farrukh could not later remember thanking.
>
> It was on the second of those three days that Nasuh — his father's old clerk, a quiet, ink-stained man who had kept the shop's accounts for eleven years — finally opened the ledger in front of him, and went very still reading it.
>
> The debts were real, and worse than the bazaar's rumor. But it was not the sums that troubled Nasuh. It was a **suftaja** from a banking house in Rayy that Farrukh's father had never mentioned owning, promising a payment against goods that, by the manifest, did not match anything the shop had ever carried west — and a second paper, unsigned, in a hand Nasuh did not recognize, that used a word for the shipment's origin that made the old clerk fold it shut before Farrukh could finish reading it.
>
> "Some accounts," Nasuh said, "are better settled on the road than argued over in this house."
>
> That night, an old friend of his father's — a traveling letter-writer who called himself nothing grander than **ostād**, though he had read further than most qāḍīs — sat with Farrukh outside the shuttered shop and offered the only comfort that didn't feel like a lie. They say the physicians in the west — Bukhara, Hamadan, wherever the man has run to now, the Sultan's men still asking after him — argue that a man stripped of every sense, every last touch of his own skin, would still know one thing for certain: that he is. That the self isn't the body at all. "Whatever's under that shroud," the old man said, "was never the whole of your father. Only what could be borrowed. The rest went somewhere law and ledgers don't reach."
>
> Farrukh did not know if he believed it. He packed the shop's remaining goods into two mules' worth of load, hired a caravan guide who knew the road past Teginabad, and set out from Ghazni's western gate before the week's mourning was fully spent — toward Nishapur, toward whatever his father had actually been carrying, and toward a frontier that the riders from Nasa said was already starting to come apart.

**Marginal gloss entries seeded by this scene** (see Section 11 for the full reference; these are the ones the Prologue specifically unlocks): Khwaja, kunya, Nasa, ghusl, kafan, janāza, tājir, damān/kafāla, taʿziya, raḥimahu llāh, suftaja, ostād.

---

## 11. Vocabulary & Customs Reference (seed content for The Margin)

### Honorifics
| Term | Gloss | Note |
|---|---|---|
| **Khwaja** | "Sir/master/my lord" — respectful address for a learned or notable man | Period-attested exactly (the court historian of Sultan Mas'ud is styled *Khwaja Abu'l-Fadl Bayhaqi*). **Not** a merchant-specific title yet — that develops from the 14th–15th c. Pair with *tājir/bāzargān* if occupation must be explicit. |
| **Ostād** | Master craftsman / teacher / scholar | Pre-Islamic Iranian guild root; safe, cross-trade. |
| **Shaikh** | Elder, notable | Safe for an older respected man. |
| **Sāheb** | "Sir," lit. possessor/master | General polite filler address. |
| **Sayyid** | Descendant of the Prophet (through Hasan/Husain) | *Not* generic — don't hand to a random NPC without intending a lineage claim. |

### Naming
Structure: **kunya + ism + nasab + nisba (+ laqab)**. Kunya ("Abu-/Umm- + child's name") is taken from the *firstborn son*, so unmarried/childless men have no kunya. Nisba marks origin/hometown (*al-Nishapuri*, *al-Bayhaqi*). Real exemplar: *Khwaja Abu'l-Fadl Muhammad ibn Husain Bayhaqi*.

### Death & Debt (core plot vocabulary)
| Term | Gloss |
|---|---|
| **Innā li-llāhi wa-innā ilayhi rājiʿūn** | "We belong to God and to Him we return" — the formula spoken on hearing of a death |
| **Ghusl** | Ritual washing of the body before burial |
| **Kafan** | Burial shroud — plain white, unadorned regardless of wealth |
| **Janāza** | The standing, near-silent funeral prayer |
| **Taʿziya** | The customary three-day condolence period |
| **Marḥūm** | "The late [one]" — how the dead are referred to afterward |
| **Yatīm** | Orphan — Qur'anically loaded, describes Farrukh's new status |
| **Dayn** | Debt |
| **Damān / Kafāla** | Formal, voluntary, binding suretyship for another's debt — the game's inciting mechanic |
| **Suftaja** | Proto-bill-of-exchange between cities |
| **Muḍāraba / Qirāḍ** | Capital-partner + labor-partner investment contract |
| **Wakīl** | Agent/proxy empowered to act on another's behalf |
| **Amīn** | Trustee/custodian; also "trustworthy" — as much a reputation as a role |

### Trade & Money
**Tājir** (merchant, Arabic) / **Bāzargān** (merchant, Persian) · **Bāzār** (market) · **Dirham** (silver coin) / **Dīnār** (gold coin) · **Kārvānsarā(y)** (caravanserai) · **Dallāl** (broker) · **Sarrāf** (moneychanger) · **Muḥtasib** (market inspector) · **Zakāt** (2.5%/year wealth tax) · **'Ushr** (customs tithe)

### Kinship
**Pedar** (father) · **Mādar** (mother) · **Barādar** (brother) · **Khāhar** (sister) · **Pesar** (son) · **Dokhtar** (daughter) · **Zan** (wife) · **Shohar** (husband) · **Farzand** (child, gender-neutral) · **Pīr** (elder/wise man — *not* yet the fixed "Sufi master" sense, that's later)

### Hospitality & Daily Life
**Mehmān** (guest) · **Mehmān-navāzī** (hospitality) · **Sofreh** (the cloth spread for a meal) · **Nān** (bread) · **Āsh** (stew, cuts across class lines) · **Māst** (yogurt) · **Panīr** (cheese) · **Sharbat** (chilled fruit/herb syrup — *the* hospitality drink; **no tea or coffee yet**, both centuries too early) · **Qabā** (front-closing coat, the default merchant garment) · **Dastār** (turban)

### Blessings & Commercial Piety (Arabic, spoken inside Persian speech)
**Bismillāh** (opens a sale, invokes *barakah*/blessing) · **Inshā'Allāh** (hedges a future promise — a caravan's arrival, a debt's due date) · **Al-ḥamdu lillāh** (closes a completed deal) · **Māshā'Allāh** (wards off envy at good fortune) · **Astaghfiru llāh** (muttered after an oath or bad news)

---

## 12. Historical Research Notes — Corrections & Creative-License Flags

Compiled from two research passes (route/politics/philosophy/art/economy, then vocabulary/funeral-inheritance/daily-life/religion). Keep these visible to whoever writes content — they are easy mistakes to make by default:

- **Bost ≠ Teginabad/"Kandahar."** Two distinct sites ~100km apart. Route order: Ghazni → Teginabad → Bost → Farah → Herat.
- **Ghazni's star-patterned minarets are Mas'ud III's (1099–1115)** — a century too late; don't depict them.
- **Herat's tiled Great Mosque is Ghurid (begun 1200)**, over two earlier Ghaznavid mosques lost to earthquake/fire. The period building is plainer and now lost. Drop the "12,000 shops / 6,000 bathhouses" figure — later literary exaggeration.
- **Ribat-i Sharaf caravanserai near Sarakhs is Seljuk (1150s)** — anachronistic.
- **Ibn Sina never physically visits this road.** Use rumor/letters/reported death (1037) only.
- **Nasir-i Khusraw's Ismaili conversion is c. 1045** — after this game's window. Minor cameo only, never the network's leader.
- **"Khwaja" is a general notable/scholar honorific here, not yet merchant-specific.** Pair with *tājir/bāzargān* if occupation must be explicit in dialogue.
- **No tea, no coffee, no tobacco/qalyan.** All centuries too early; al-Biruni himself (this era, this court) describes tea only as an exotic Chinese/Tibetan curiosity.
- **No organized Sufi orders/ṭarīqas as institutions** (12th–13th c. development). Individual respected Sufi figures and small lodges (*khānqāh*) are fine — Abu Sa'id Abu'l-Khayr is a genuinely period-accurate figure to use.
- **No formal merchant guilds** (futuwwa/ahi/esnaf are later Anatolian/Ottoman developments). Use kinship/coreligionist trading-house networks, the *muḥtasib*, and a temporary-authority caravan leader instead.
- **Andarun/biruni household terminology is best documented for 19th-c. Qajar households** — plausible by cultural continuity for 1000–1040, not directly attested. Use the spatial concept (private family quarters vs. public-facing space) loosely; don't present the vocabulary as verified-period.
- **Nasir Khusraw's own travel writing (*Safarnama*) describes the mid-1040s–50s, compiled 1088** — a decade-plus after this game's window. Anything sourced to it is "true shortly after," not exactly contemporary; use with light adjustment.
- **The "20 million dinar" Somnath figure and the sandalwood-doors legend are later-inflated tradition**, not contemporary record — usable narratively, flagged as legend if it comes up in dialogue.
- **Slavery is the single largest real commodity on this exact road in this period.** Section 6 records the design decision (refusable, at a real cost) — do not let it default to background color in any actual content pass.
- **The diegetic "manuscript retelling" frame is required, not optional**, to justify the Persian-miniature art style at all — it is a genuine ~400-year anachronism otherwise. Keep this framing visible in menus/credits/a codex entry, not just implied.

---

## 13. Scope & Next Steps

8 chapters (Ghazni prologue + 7 route stops) + 1 optional branch (Merv) is the committed scope — a real, finishable solo project, not a vertical slice and not an open-ended saga.

**Open items for the implementation plan:**
- Godot project scaffolding (engine/content split, per Section 9)
- Ledger/economy math as tested engine code (mudaraba, suftaja, zakat/'ushr, purity-checking)
- Reputation system (per-faction, not global)
- The Margin (glossary lookup + UI)
- Dialogue system
- Save/load state
- Content for Chapters 1–7 (currently only the Prologue is written)
- Art asset pipeline for the two-layer style (in-world material culture vs. manuscript-frame presentational layer)

This document is the spec. Next step is `writing-plans` to turn Section 13's open items into a phased implementation plan.
