# Story Worldbuilding Backlog Design

**Status:** approved, pending implementation plan.

## Goal

Close out finding 7 (the low-severity worldbuilding backlog) from the
2026-08-09 full-campaign story review - the only item from that review
still open. Findings 1-6 (critical/high/medium bugs) were fixed and
merged weeks ago; finding 7 was deliberately left alone at the time as
"worldbuilding additions, not bugs." The user has now greenlit acting on
all five of its items. This is five small, independent content/doc edits,
not one cohesive feature - no new flags, no new glossary terms, no engine
changes, nothing that touches `engine/**` or `scenes/**` at all.

**Already resolved, out of scope:** the same review's "Heratigan"
non-standard demonym finding - confirmed via direct grep against the
current codebase, zero occurrences in any live content file. Nothing to
do here.

## 1. Mihran's Zoroastrian identity (`chapter_02_bost/bost.json`)

Mihran, Bost's sarraf, already carries an implicit non-Muslim signal - he
tells Farrukh "I pay the {{jizya|jizya}} every year specifically so that
men in robes with questions never have reason to visit my shop." The gap
isn't the absence of any signal, it's that *which* minority community is
never specified. Khorasani sarrafs of this exact period were very often
Zoroastrian in genre fiction, and a small, legible-without-being-stated
detail fits the tone of everything else in his scene.

Node `n02_seeking_the_sarraf`, current text:

> Every winter-quartered army needs men who can turn one kingdom's coin
> into another's, and Bost had no shortage of them. Farrukh found the one
> the caravan drivers trusted on reputation alone - a narrow shopfront
> off the bazaar's spine, scales hung by the door, a {{sarraf|sarraf}}
> named Mihran who weighed silver for a living and, by the look of the
> room, had done it long enough to stop being impressed by anyone's coin.

New text (one clause inserted before the sarraf/Mihran clause):

> Every winter-quartered army needs men who can turn one kingdom's coin
> into another's, and Bost had no shortage of them. Farrukh found the one
> the caravan drivers trusted on reputation alone - a narrow shopfront off
> the bazaar's spine, scales hung by the door, a small clay lamp burning
> steadily beside the account-books that Farrukh noticed but did not ask
> about, and a {{sarraf|sarraf}} named Mihran who weighed silver for a
> living and, by the look of the room, had done it long enough to stop
> being impressed by anyone's coin.

No new glossed term - "a small clay lamp burning steadily" reads as a
sacred-fire cue to an attentive reader without ever using the word
"Zoroastrian" or requiring a glossary entry, matching how the jizya line
already implies dhimmi status without spelling out "non-Muslim."

## 2. Sa'id ibn Yaqub callback (`chapter_02_bost/bost.json`)

Sa'id, Teginabad's customs officer, never recurs anywhere in the campaign
after Chapter 1 - a real dead end in him specifically, distinct from the
campaign's intentionally-unresolved central "second mark" mystery (see
[[borrowed_fortune_replay_required_mystery_is_intentional]], already
confirmed working as designed). The fix is the smallest possible touch: a
passing, specific mention by name in the very next chapter, where the
narration already draws a Teginabad comparison generically.

Node `n01_bost_arrival`, current text:

> After Teginabad's flat customs-wall discipline, Bost announced
> Ghaznavid wealth a different way - not with a gate and a ledger, but
> with a skyline. Across the canal-fed green, low domes and a long
> red-brick palace face caught the last sun: the sultan's winter
> residence, Lashkari Bazar, more garrison-town than palace grounds, more
> market than either. Farrukh had no business inside those walls and no
> wish to acquire any. His business was smaller, and stranger: a piece of
> paper from a house in Rayy that his father's accounts should never have
> mentioned.

New text (the opening clause names Sa'id instead of staying generic):

> After Teginabad's flat customs-wall discipline - and the particular
> tired patience of the amid who'd measured him there, Sa'id ibn Yaqub,
> closing his ledger over a question he'd chosen not to press further -
> Bost announced Ghaznavid wealth a different way - not with a gate and a
> ledger, but with a skyline. Across the canal-fed green, low domes and a
> long red-brick palace face caught the last sun: the sultan's winter
> residence, Lashkari Bazar, more garrison-town than palace grounds, more
> market than either. Farrukh had no business inside those walls and no
> wish to acquire any. His business was smaller, and stranger: a piece of
> paper from a house in Rayy that his father's accounts should never have
> mentioned.

Note: Farah's existing `n04_the_choice_at_the_checkpoint` already contains
a rhetorical Sa'id namedrop ("the same open invitation Sa'id's men had
offered back in Teginabad") for comparing checkpoint behavior - that
stays untouched. This new mention is a different, personal beat (Farrukh
recalling the man himself, not comparing tactics), so the two don't read
as redundant.

## 3. Farah's 2 dead flags (`chapter_03_farah/farah.json`)

`stayed_uninvolved_at_farah` and `confirmed_the_name_at_farah` are each
set exactly once and never read anywhere in `content/` (confirmed via
grep across the whole tree - no `requires_flag` references either).
Removing them is simplest and safest: no risk of touching already-shipped
downstream chapters (4A/4B), and no observable behavior changes since
nothing ever checked them.

Node `n04_the_choice_at_the_checkpoint`, the "Say nothing" choice:

```json
{"text": "Say nothing. It isn't your caravan to risk.", "next_id": "n05b_uninvolved", "effects": {"flags": ["stayed_uninvolved_at_farah"], "reputation": {"ghaznavid_officials": 1}}}
```

becomes:

```json
{"text": "Say nothing. It isn't your caravan to risk.", "next_id": "n05b_uninvolved", "effects": {"reputation": {"ghaznavid_officials": 1}}}
```

Node `n13x_the_name_already_known`, its single choice:

```json
{"text": "Continue.", "next_id": "n14_the_choice", "effects": {"flags": ["confirmed_the_name_at_farah"]}}
```

becomes:

```json
{"text": "Continue.", "next_id": "n14_the_choice", "effects": {}}
```

`tests/unit/test_farah_dialogue_content.gd:68` currently asserts
`assert_eq(uninvolved_effects["flags"], ["stayed_uninvolved_at_farah"])` -
this must change to assert the `"flags"` key is simply absent from the
returned effects dict (`assert_false(uninvolved_effects.has("flags"))`),
alongside the content edit in the same task.

## 4. Farrukh's mother (`chapter_00_prologue/prologue.json`)

She's alive and present at the funeral - the existing single "the widow"
mention in the grave scene already implies this - she just has no actual
character moment anywhere in the chapter that carries all of the story's
emotional weight through the father's death alone. Two touches: make the
existing grave-scene mention personal instead of generic, and give her a
real beat during the three days of mourning that follow.

Node `n04_grave_question`, one clause changes ("not the widow" → "not his
mother"), rest of the node unchanged:

> ...Nobody was certain how much, because nobody - not his mother, not the
> clerks, not the dead man's own partner - had yet opened the ledger...

Node `n07_prayer_taziya`, current text:

> The imam prayed. Grief afterward observed its three days of
> {{taziya|ta'ziya}} - visitors, murmured {{rahimahu_llah|rahimahu llah}},
> trays of food from neighbors Farrukh could not later remember thanking.

New text (one sentence added, both existing glossed terms kept intact):

> The imam prayed. Grief afterward observed its three days of
> {{taziya|ta'ziya}} - visitors, murmured {{rahimahu_llah|rahimahu llah}},
> trays of food from neighbors Farrukh could not later remember thanking.
> His mother sat through all three days at the head of the room, taking
> each condolence with a stillness Farrukh recognized as his own,
> inherited from somewhere he'd never thought to ask - and once, on the
> second evening, when the room had briefly emptied, reached over and
> gripped his wrist hard enough to hurt, said nothing, and let go.

`tests/unit/test_prologue_glossary_content.gd` only checks that specific
term ids (including `taziya`, `rahimahu_llah`) are present somewhere in
the chapter's glossed content - both stay exactly where they already are,
so this test is unaffected.

## 5. Chapter 4B doc/implementation term mismatch

Only one concrete mismatch actually exists - re-verified directly against
both doc files rather than trusting the original review's memory record,
which also mentioned a "dai" term that doesn't appear anywhere in either
file under any spelling checked. The real mismatch:
`docs/superpowers/specs/2026-08-09-chapter-4b-herat-design.md` line 26
says Rostam "deals in resold **ghanima**," but the shipped
`chapter_04b_herat_favor/herat_favor.json` never uses that word anywhere
- only "sarraf"/"sarrafs" (matching what actually shipped). The same doc's
own line 12, two lines earlier, already avoids the term ("goods that came
west with Mahmud's armies and never saw a customs manifest") - the fix
just makes line 26 consistent with line 12 and with what shipped.

Line 26, current:

> **Rostam** — deals in resold **ghanima** out of a quarter of Herat the
> respectable bazaar trade doesn't use, on the far side of the same
> underground channels Ardashir's world (Chapter 4A) touches only by
> correspondence. [...]

New:

> **Rostam** — deals in resold goods that never saw a customs manifest,
> out of a quarter of Herat the respectable bazaar trade doesn't use, on
> the far side of the same underground channels Ardashir's world (Chapter
> 4A) touches only by correspondence. [...]

Historical planning doc only - no test coverage, no implementation file
references this line, nothing else to update.

## Testing

- Items 1, 2, 4, 5 are pure prose edits with no new flags or glossed
  terms - no new tests needed, and no existing test asserts the exact
  strings being changed (confirmed directly: `test_bost_dialogue_content.gd`
  only uses `n01_bost_arrival` as a tree-load starting id, never asserts
  its text; `test_herat_favor_dialogue_content.gd`'s one Mihran-related
  assertion is a negative check on a different, unrelated phrase and stays
  true; `test_prologue_glossary_content.gd` only checks term-id presence).
- Item 3 (the dead-flag removal) requires updating
  `test_farah_dialogue_content.gd:68`'s assertion in the same task, or the
  suite goes red - this is a real, necessary accompanying change, not
  optional.

## What this pass does not do

- Does not touch the campaign's intentionally-unresolved central mystery
  (the "second mark") - confirmed separately as working as designed, not
  part of this backlog.
- Does not expand Sa'id's own Teginabad scene, add a new NPC, or add any
  new flag/reputation effect - the callback is a single narration clause
  in an already-existing node.
- Does not add new glossary terms or portraits for anything touched here.
- Does not touch `docs/superpowers/plans/2026-08-09-chapter-4b-herat-favor-implementation.md`
  - re-checked directly, it never uses the word "ghanima" at all, so
  there's nothing in it to fix.
