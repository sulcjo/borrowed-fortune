# Road situations — the country between the cities

Date: 2026-08-25
Status: implemented. The Pushang road landed first (PR #23); the remaining eight
followed in one pass, and the flag contract below was corrected in the process.

## Why

The delayed-consequences spec named four subsystems and scoped three of them out,
road situations among them: "turning the nine one-node road beats into 3–6 node
situations." This is that spec, and the Pushang → Sarakhs road is its first
instance.

Every city in this game is a place where people have leverage over Farrukh. A
sarraf can refuse him a rate, a garrison officer can hold his caravan at a gate, a
broker can decline to find a name. He is always, in a city, dealing with someone who
can do something to him. That is what makes the cities work, and it is also their
one limitation: every moral choice inside a wall is entangled with a practical one,
and the player can never be sure which of the two they answered.

The road removes the entanglement. Between towns Farrukh meets people who cannot
pay him, cannot report him, cannot be looked up later, and will never see him again.
Nobody is keeping score but him. That is the question the road asks and the city
cannot.

Twelve terminal departure nodes carry all nine of these roads today, at 40–202 words
each, and none of them asks anything.

## What a road situation is

Three to six nodes, inserted between the departing chapter's last city node and its
terminal departure node, whose prose and routing are left as authored. Every node is
a real decision, so the subsystem adds nodes without adding page-turns: the ratchet's
no-decision count is unmoved by construction, and only the denominator grows.

The road is not a hazard system. Nothing on it threatens Farrukh physically; the
danger is moral throughout. This is a personal myth, not an adventure, and an
ambush would answer a question the game is not asking.

### The four-beat shape, as built

| beat | what it does |
|---|---|
| **read the ground** | The road is empty of people and full of traces. The player is asked to interpret them, not to react to them. |
| **the strangers** | The people those traces belonged to. No leverage in either direction. |
| **what they ask** | The cost of having stopped: they want something a stranger can refuse without consequence. |
| **the question** | What Farrukh says about who he passed, to an authority entitled to ask. Deliberately *not* arrival: see decision 5. |

## Decisions and their provenance

1. **Inference, rewarded — not a skill check.** The first beat shows a cistern drawn
   lower than a caravan leaves it with the rope still wet, brush cut low and green at
   the cut, a fire pressed flat and covered rather than scattered, and tracks leaving
   the track — one set small — for ground where the walking is worse and the view of it
   from the road is worse with it. Reading these as people rather than as a patrol sets
   `read_the_roads_signs`.

   The reward is **a choice the other reading never sees**: at the next beat, a player
   who read the road correctly may draw the water *before* the eldest of the family has
   to ask for it. Nothing is avoided by being right — the encounter is identical either
   way, and the ungated generous choice remains available to everyone. What correct
   inference buys is the chance to spare someone the asking.

   This is deliberate. Sparing the asking is already the game's recurring courtesy, seen
   from the receiving end: the Teginabad provisioner who "didn't wait for sympathy, and
   went back to tying off the last of his order before he could offer any"; Umm-Kavus,
   who "had learned not to make them say it aloud before she'd fed them." The road is
   the first place Farrukh is on the giving end of it, and he only gets there by paying
   attention.

2. **Displaced, not deserters.** An earlier draft made the strangers hashar levies who
   had walked away from the Pushang muster, which put a state-crime decision at the gate
   beat. Rejected: it raises the voltage past what this story runs at. The family's
   seed-grain was taken *lawfully*, with a mark in a clerk's book and a repayment nobody
   expects, and they are walking to a brother. Naming them to the riders exposes them to
   questioning and another requisition, not to execution. The choice is as hard and the
   register is right.

3. **`place_label`, a per-node place name.** The manifest names one place per chapter.
   A colophon reading "Pushang" while Farrukh is a day's ride outside it is simply
   wrong, and the road nodes live in `pushang.json`. A node may now name its own place;
   nodes without the key read from the manifest exactly as before.

   Chosen over the two alternatives. A **road chapter** (`chapter_06b_road_to_sarakhs`)
   would be the cleanest structure, but `_load_place_texture()` loads
   `assets/backgrounds/<chapter_id>.png` and the asset guard requires one per chapter —
   so every road would need generated art, and each would become a journey-map waypoint
   decision: nine backgrounds and nine map entries by the end. Doing **nothing** and
   letting the colophon say "Pushang" was the cheap option and is a small lie the rest
   of this codebase would not accept. Five lines of engine code is the smaller cost.

4. **One road first, then the rest in one pass.** Merv was built as the hub model
   before hubs were repeated; the Pushang road was the same move. It held up, so the
   remaining eight were written against it directly.

   Writing eight at once surfaced one thing building one had hidden - see decision 7.

5. **The road must end before the next city does.** The fourth beat was first written at
   Sarakhs's own gate, with a clerk and a board. That put arrival one node before the
   chapter's closing coda, which says "Sarakhs lay ahead" - and a chapter before
   `sarakhs.json` opens by arriving there. Farrukh would have reached the city twice.

   Moved onto the last stretch: a mounted pair off the garrison's own strength, working
   the one piece of road their commander can be expected to hold, which this chapter has
   already established as the limit of what Sarakhs patrols. The confrontation stays
   live, the coda stays true, and the question is if anything harder to answer from
   open ground, with two bored riders already half turned to be gone, than it would
   have been across a clerk's table.

   **A road situation ends while the road is still the road.** That is the rule the other
   eight inherit.

6. **The terminal departure node keeps its text and its routing.** It carries
   `next_chapter_id` and the chapter's last word, so the road is inserted before it and
   chapter routing, the journey map, and every test asserting where a chapter ends are
   unaffected. It does take a `place_label`: the coda is spoken from the road, after the
   last city node, so a colophon reading "Pushang" there is wrong in exactly the way the
   key exists to fix. Labelling it changes neither its prose nor where it goes.

## Schema

One optional key on a node:

```json
{ "id": "n11d_the_stretch_nobody_watches", "place_label": "The Sarakhs road" }
```

`DialogueEngine.current_place_label()` returns it or `""`.
`ChapterView._update_colophon()` prefers it over the manifest's `place_name`, and
falls back when it is absent. Slots belong to a stay and a road never declares one,
so a labelled node is never composed with a slot name. `validate_tree()` rejects a
`place_label` that is present but not a non-empty String — an empty one would read
as "this node names its own place" while naming none, blanking the colophon instead
of falling back.

## Flags

### The contract, corrected

Four flags per road. Three of the four are read **inside the road itself**, which is
what makes the subsystem affordable at nine roads rather than one:

| flag | set by | read by |
|---|---|---|
| inference | beat 1's correct reading | the gated choice at beat 2 |
| grace | beat 2's gated choice only | a `text_variants` on beat 3 |
| helped | **both** generous choices at beat 2 | a `text_variants` on beat 4 |
| downstream | beat 4's disclosing choice | one assigned node in a later chapter |

Only the last consumes external budget, so nine roads need nine payoff sites rather
than thirty-odd - which matters, because free spine nodes are genuinely scarce: when
this pass began Sarakhs had three and Merv had two.

The first draft of the eight capped each road at two flags, to protect exactly that
budget. Three of the four writers independently reported the same problem, and the
splice validator then made it concrete: under a two-flag cap, beat 2's gated choice
set **no flags at all**, so the inference reward - the whole signature of the
subsystem - was recorded nowhere. The player was rewarded in prose and the engine
never knew. That is the precise defect `test_consequence_metrics.gd` exists to catch,
and it is worth stating plainly: a reward that is not recorded is not a mechanic.

The grace and helped variants are also where the road earns its keep dramatically.
The helped variant of beat 4 is the load-bearing one: a man who stopped now has
something to not-mention, so the disclosure costs him something a man who drove past
never risked. Same question, different price, no extra nodes.

### The Pushang road, as originally built

Five flags, all read in the same change, so `MAX_DEAD_PAYABLE_FLAGS` stays at 4.

| flag | set by | read at |
|---|---|---|
| `read_the_roads_signs` | reading the traces correctly | gates the pre-emptive choice at the next beat |
| `shared_on_the_road` | either generous choice | sarakhs `n10_after_the_gate` |
| `offered_before_they_asked` | the gated choice only | nishapur `n03d_the_ledgers_last_entry` |
| `carrying_word_to_sarakhs` | taking the errand | sarakhs `n10b_the_road_forks` |
| `named_them_to_the_riders` | answering the patrol fully | sarakhs `n07_a_quiet_request` |

Every payoff sits on a node that dominates every terminal in its chapter, so it
fires for a player who set the flag rather than merely satisfying the static
counter. `n07_a_quiet_request` is the one worth naming: it is Bahram deciding
whether a stranger's discretion is worth a favour he has no standing to ask for,
a day after Farrukh told two riders off this same garrison exactly who he passed.

`n05_bahram_the_gatekeeper` and `n06_what_nasa_taught_him` already carry variants
and were avoided: variants are first-match-wins, so a second one on the same node
can be silently shadowed.

## Decision 7 - what building eight at once taught

- **Each road must own a distinct clue medium.** Eight roads written in parallel will
  otherwise all reach for tracks and a cistern, because that is what the model road
  used. The media were assigned before writing: sound and absence, stone and wind,
  livestock, paper and writing, field and harvest, shrine and grave, abandoned goods,
  bread and ovens. Assign the medium, not the incident, and the roads differentiate
  themselves.
- **The strangers must not duplicate the next chapter's own scene.** Farah opens with
  soldiers holding a Nasa family off the road, so the Bost road was explicitly barred
  from mounted soldiers detaining anyone and given a road-warden with a charcoal tally
  instead. Check the destination chapter's first two nodes before choosing beat 4's
  authority.
- **Beat 4's authority is a relay post, a warden, a transport clerk or a patrol working
  its own stretch** - never the destination's gate. That is decision 5, and it is the
  rule most easily broken by accident, because arriving is the natural way to end a
  journey and the wrong way to end a road.
- **One branch of Farah gets no road.** `n19b_departure_farah_plunder` leads into
  herat_favor, whose opening already carries the unease of a road with a stranger's
  bundle in the pack, and on into the plunder ending, which opens with a road chapter
  of its own. A road there would be the third road beat in a row.

## Out of scope

- **A road on Farah's plunder exit**, for the reason above.
- **Road chapters, backgrounds, journey-map waypoints.** Reconsider if a road ever
  needs to be more than a handful of nodes.
- **Hazards, weather, travel time, provisioning.** Time and actions is a separate
  subsystem with its own spec still unwritten; the road must not grow a shadow copy
  of it.
