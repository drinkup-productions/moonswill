# STEP 7 SCOPE — Overworld & Combat
_Companion to docs/design.md. Scope only; design.md stays the source of truth._

## 0. THE POINT OF THIS DOC
Step 7 is where art and systems collide. The risk is not combat — it is
building a transformation system whose output art cannot render. So the
order is inverted: **contract first, combat second, overworld third.**

## 1. PRINCIPLE: COMBAT IS A TOY, NOT A WALL
Battles are not the challenge. They are where the player experiments with
transformations and finds items. Forgiving turn limits, low lethality,
room to try things and watch what happens. Failure costs inventory, not
progress (§8).

## 2. SCOPE BOUNDARY
Per §13 the slice is 1 zone, 2 enemy types, 1 transformation axis.

In:
- Transform component, stage ladders, art descriptor
- Reaction system (per individual, not per type)
- Grey-box debug renderer
- Combatant stats derived from transformation
- 2 enemy types, one encounter table, one zone
- Turn-based combat reusing the feast's shape
- Defeat penalty: half gathered inventory, never fatal

Out:
- More zones (needs the region system, §6.8)
- More than 2 enemy types, or more than 1 axis
- NSFW art — §13 says the slice is PG-13 only
- Wandering NPCs, weather, day/night, equipment, buffs

## 3. THE ART CONTRACT (built first, at 7a)
One rule: **art reads `Transform.visual()` and nothing else.**

`visual()` returns:
```gdscript
{
    "species": "bandit",
    "base_stage": 1,          # anchor index art draws
    "base_blend": 0.5,        # crossfade toward the next anchor — the smear
    "overlays": [{"axis": "belly", "stage": 3}],
    "tear": 1,                # 0 intact, 1 straining, 2 open
    "flavor": {"tail": true},
    "silhouette": 3,          # true — mechanics read this
    "visible_silhouette": 2,  # after concealment — art reads this
    "axes": {...},
    "visible_axes": {...},
}
```

Art draws `base[base_stage]` crossfaded toward `base[base_stage + 1]` by
`base_blend`, with `overlays` layered on top. Mechanics use
`silhouette()`; art uses `visible_*`.

## 4. THE STAGE LADDER
One full vat is about one stage, which reproduces §6.3's escalation
without special-casing it.

| Stage | Points | Look | Gameplay |
|---|---|---|---|
| 0 | 0-5 | baseline | full speed |
| 1 | 6-11 | softer, fuller | full speed |
| 2 | 12-17 | clearly heavier | speed -1 |
| 3 | 18-23 | clothing strains | speed -1, cannot fit narrow gaps |
| 4 | 24-29 | clothing open | speed 1 |
| 5 | 30+ | immobile | speed 0 |

Stage 3 is the tear point because §3 already says clothing tears "at brew
3 where the transformation would tear them."

## 5. ART APPROACH: ANCHORS + OVERLAYS
Chosen over the alternatives because it scales. Five axes at six stages
is $$6^5 = 7776$$ silhouettes; collapsing to one number per axis is not
enough on its own.

- **Anchors** are base bodies at key stages (0, 2, 4, 5). Between them
  the base crossfades — the smear. Four bodies per character.
- **Overlays** are per-axis layers for nuance. Adding an axis later costs
  overlays, never a new body set.

Slice cost, one axis, PG-13:

| Subject | Anchors | Overlays | Total |
|---|---|---|---|
| Chugs | 4 | 6 | 10 |
| Enemy A | 4 | 6 | 10 |
| Enemy B | 4 | 6 | 10 |
| **Total** | | | **30** |

More than approach A's 18, paid now to avoid a rewrite when axis two and
three arrive.

**Manifest, so art lands additively:**
`godot/assets/characters/<id>/stages.json`
```json
{ "id": "bandit", "mode": "pg13",
  "anchors": ["a0.png", "a2.png", "a4.png", "a5.png"],
  "overlays": { "belly": ["b1.png", "b2.png", "b3.png", "b4.png", "b5.png"] } }
```
`CharacterArt.texture_for()` falls back to a grey-box rect when a texture
is missing, so characters can land one at a time.

## 6. REACTIONS
A reaction is what a character does when an axis crosses a threshold.
Keyed by **reaction profile**, not species, so two individuals of one type
can behave differently for zero extra art.

Kinds: NONE, DISTRACTED, GUARD_DOWN, SLOWED, ENRAGED, STOP, FLEE.

Profiles in the slice:
- **feral** (wolf, bear) — bulk slows, then stops. §8's "fatten a wolf so
  it can't close."
- **humanoid** (bandit) — chest or hips at 4 makes them stop and enjoy it;
  belly distracts; muscle enrages.
- **brute** (bandit variant) — **bulk enrages**. The counter-example:
  transforming is not automatically a win.

Reactions fire only on upward crossings, so small repeated applications do
not re-trigger.

## 7. COMBAT MODEL
Turn-based, AP-based, same shape as the feast — §16 says the feast "reuses
combat engine," so this is the engine the feast is meant to share.

- Chugs's attacks: Punch, Claw, Belly Slam. Weight raises Belly Slam
  damage and its cost — fat is power that is slow.
- Using a brew on an enemy applies its deltas to that enemy's Transform.
- Enemies carry their own brews, randomly spawned at battle start.
- Enemies can use items on Chugs. Same component, same path; direction is
  the only difference.
- An encounter can be won by transformation alone if the player has the
  stock. Otherwise they fight.
- Defeat: knocked out, lose half gathered inventory, never fatal.

**Do not unify with `FeastController` yet.** Extract shared parts
(Transform, Combatant stats, turn skeleton), get combat working, then fold
`FeastPatron` onto `Transform`.

## 8. WHAT PERSISTS OUT OF A BATTLE
Only Chugs's weight, and weight lost from the exertion of fighting.
Enemy transformations reset at the next encounter, win or lose. Loot is
the same whether or not the enemy was transformed. Drinking does not
consume belly capacity in combat.

## 9. SUB-STEPS
| # | Sub-step | Effort |
|---|---|---|
| 7a | Transform, ladders, descriptor, reactions, serialization | 1 |
| 7b | Grey-box debug renderer | 0.5 |
| 7c | Combatant, derived stats; fold FeastPatron onto Transform | 1 |
| 7d | Enemy data, 2 types, encounter table | 1 |
| 7e | Combat scene: turn loop, move, strike, item, AI, reactions | 2.5 |
| 7f | Overworld: 1 zone, tile grid, locked camera, encounters, loot | 2 |
| 7g | Art manifest + fallback loader | 0.5 |
| | **Total** | **~8.5** |

**Stop after 7b.** Confirm the descriptor is what art needs before
building anything that depends on it.

## 10. RISKS
| Risk | Mitigation |
|---|---|
| Art explosion | One axis; anchors + overlays; 30 sprites |
| Transformation trivialises combat | Brute profile enrages on bulk |
| Reactions become unmaintainable | Profiles are data; per-individual |
| Breaking the working feast | Extract first, unify last |
| Overworld becomes a second game | One zone, locked camera, no NPCs |
| NSFW doubling art | Slice is PG-13; manifest reserves the slot |

## 11. REQUIRED design.md EDITS
1. §8 — enemies may be feral **or humanoid**; name Chugs's attacks; note
   enemy-carried brews; note combat is a sandbox.
2. New §6.17 — Reactions. Kinds, profiles, per-individual keying.
3. §15 — mark questions 1-8 answered, with the answers.
4. §6.9 — cross-reference reactions.