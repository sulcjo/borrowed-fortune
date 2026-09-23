# Recurring characters — people the road gives back

Date: 2026-09-23
Status: implemented

## Why

The delayed-consequences spec named four subsystems. Three are built: conditional
text, road situations, and stays. This is the fourth, and the last.

It was listed as "recurring characters (generalising Yusuf)". Measured before any of
this work, that framing was wrong in a way worth recording: **Yusuf was the only person
in the game who appeared in more than one chapter.** Fifteen other people had portraits,
and every one of them lived in a single chapter and was never seen again. There was no
pattern to generalise. This work creates recurrence; it does not extend it.

The road situations made the opposite choice on purpose - their strangers are met once
and never again, because that is what makes a stranger's claim on you unenforced. The
two subsystems are meant to sit together. On the road nobody can find you afterwards.
These are the people who can.

## The rejected version

PR #11 already had the obvious design and turned it down, and its reasoning holds: add
five to seven more characters "following the Yusuf pattern" and you add roughly
eighteen single-choice cameo nodes, which is precisely the padding
`test_consequence_metrics.gd` exists to stop. It also rejected a per-person
relationship counter: `ReputationTracker` would accept `"yusuf"` as a key without a
line of code, but reputation feeds the colophon, and a person is not a faction.

What made Yusuf worth having was never that he came back. It was that every time he
came back he asked something, and remembered what you had said the last time.

## The contract

A recurring character is declared in `content/characters/recurring.json` - portrait,
role, and one appearance node per chapter - and `test_recurring_characters.gd` holds
every declared character to four rules:

1. **At least two appearances, in at least two chapters.**
2. **Every appearance is a decision**: two or more choices, never a cameo.
3. **Every appearance after the first remembers an earlier one**: at least one of its
   `text_variants` is keyed on a flag an earlier appearance's choices set.
4. **One face throughout**: every appearance carries the declared portrait, or, while a
   portrait is pending, none of them does. A face in one chapter and none in the next
   reads as two different people.

And one rule across the whole game: **anyone whose portrait appears in two or more
chapters must be declared**, so recurrence cannot be added around the contract instead
of through it.

No engine code. Everything a recurring character needs already existed: flags,
`text_variants`, and the rule that both choices at a beat rejoin the same next node. The
subsystem is the declaration and the contract, not a mechanism - which is the same
conclusion PR #11 reached, now written down as something checkable.

Yusuf passes the contract without his content changing a word. That is the test of
whether the contract describes what was actually good about him.

## The three

Chosen by what their *situation* lets them do, not by who was available. Most people in
this game cannot plausibly reappear: a sarraf keeps his shop, a widow keeps her
caravanserai. The candidates were the ones whose circumstances travel.

| character | role | appearances |
|---|---|---|
| **Sa'id ibn Yaqub** | the state, which is always at the gate before you | Teginabad (existing) -> Herat assay office -> Nishapur gate |
| **Parviz** | the man a year further down the road you have just stepped onto | herat_favor (existing) -> the plunder ending, bound path |
| **Hamza** | the one traveller going exactly where you are going, for a reason you do not share | Farah -> leaving Pushang -> the khaneqah |

### Sa'id ibn Yaqub

The strongest candidate by a distance, because he already had cross-chapter reach
without a second appearance: `bribed_teginabad_official` and `honest_at_teginabad` were
read at Pushang, `revealed_letter_to_said` at Farah, and he was named in Bost and Farah.
He is also the only person whose *institution* travels. The frontier is contracting and
men like him are posted and reposted west.

His return never re-asks bribe-or-inspection. It asks what that answer turned into. At
the Herat assay office, a bribe paid at Teginabad went upward with the quarter's silver
and is plausibly being restruck lighter in the very room he now sits in, so Farrukh has
"paid it twice". An honest inspection is remembered as "nothing is not a thing I can
enter". At Nishapur's gate he asks the ending's own question in a clerk's vocabulary:
which column, men arriving or men returning?

### Parviz

Only reachable on the bound path, where Farrukh said yes to Rostam and every player has
met him. He returns just before `n05a_the_lie_he_might_tell` - the choice between
believing it was only ever one more errand and admitting what he has become - because
he is that question's living answer: the man it stopped being a question for.

He offers a small packet going Farrukh's way, unassigned by anyone. It does not re-ask
"does it get easier"; it tests whether Farrukh now says yes the way Parviz does. Carrying
it makes "one more errand" literally true at the next node, which is what makes the lie
tempting: it is accurate. Neither payoff makes the choice for the player.

### Hamza

The only new person, and new on purpose: nobody existing is walking to Nishapur to hear
the teacher, and the ending needed somebody who was. He is devout, young, a little funny,
and owns almost nothing, which is the one thing a failing state cannot tax. He never
lectures. He declines things.

Every one of his choices sits on the axis the final choice sits on - hold to the self, or
let go of insisting on it - with the self-side kept reasonable each time so none of them
preaches. Farah: whether to write your name on the ledger's first leaf. Pushang: whether
you would mind owning as little as he does. The khaneqah: whether to sit with him by the
sandals at the door or go up to the lamp. That last one is read at
`n08_the_last_reckoning`, the beat immediately before the ending.

He walks the direct road west through Jam, not the Sarakhs track. That keeps him out of
the Sarakhs road's footprint clue, and explains how a man on foot reaches Nishapur first.

**His portrait is pending.** He is registered in `tools/pixellab/npcs.json`, but the
generation step needs the pixellab credentials, which a safety hook kept this session
from reading. Per rule 4 his appearances carry no portrait until the art exists; the
game already renders portrait-less nodes cleanly. To finish him:

```
python3 tools/pixellab/generate_portraits.py        # generates only what is missing
```

then set `"npc_portrait": "hamza"` on his three appearance nodes and `"portrait": "hamza"`
in the declaration. The contract test will fail until both are done together, which is
intended.

## Placement rules that fell out of building it

- **Insert on the spine, repoint only the named predecessors.** Every appearance sits on
  a node every route through its chapter passes, and only the predecessor's choices are
  repointed, so nothing else in the chapter moves.
- **The last appearance's flags must be read somewhere, or set none.** Sa'id's Nishapur
  gate sets nothing, because nothing comes after it that could read it. Hamza's khaneqah
  sets two, read one node later. Anything else is dead state the ratchet would catch.
- **A character met once on one branch is fine.** Hamza's Farah appearance is on both
  branches, but the plunder branch never reaches Pushang or Nishapur, so plunder players
  meet him once. Yusuf's Sarakhs farewell has the same shape.
- **Every insertion shifts every test that counts presses.** Fourteen did, across four
  files, none because a route was wrong. They were moved to `Nav.expect_reaches`, which
  is the third time this project has paid that cost: the Pushang stay, the roads, and now
  this.

## Metrics

nodes 267 -> 273 · no-decision **159**, unchanged, since every new node is a decision ·
flags set 109 -> 119 · read 100 -> 110 · gated conditions 109 -> 124 · payable dead flags 4

## Out of scope

- **More characters.** The declaration makes the next one cheap; four is enough to prove
  the contract, and the next should be chosen by whose situation travels.
- **Road strangers recurring.** Deliberately never. Their being unfindable is the point.
- **A relationship counter.** Rejected in PR #11, and nothing here needed one.
