# MOONSWILL
### Master Design Document — v4 FINAL
_Working title. Alt: The Sated Moon, Wechuge._
_Locked 2026-10-15. Single source of truth — never fork this file._

---

## 0. HOW TO USE THIS DOC
- This is the only version of the design. If something here conflicts
  with a conversation, this file wins until it is edited.
- `[OPEN]` marks an unresolved question. `[DEFERRED]` marks something
  deliberately out of v1.
- Appendices 17-19 are the load-bearing bits: read them before changing
  anything in §6.

---

## 1. LOGLINE
Chugs runs a tavern and brews beer that rewrites his customers' bodies.
He is a Skull-Dog — a canid who grew too strong and grew a skull for a
face. Once a month the moon makes him hungry enough to eat his
regulars. Every one he eats makes him fatter, in front of everyone.

## 2. GENRE & PILLARS
Cozy fantasy management sim. Turn-based JRPG combat. Tactical feast
set-piece. Relationship layer. Dark comedy.

1. **Everything is consensual.** Even when a partner orders for someone.
2. **Cozy surface, hungry depths.** Warm lamplight over a predator.
3. **The player is the monster.** Not a hero with a curse — a business.
4. **Transformation is a resource, not a cutscene.**
5. **No fail state, only consequences.** No death, no banishment.
6. **Chugs's own body is the evidence.** He sells transformation and is
   being transformed by his own appetite, in public, slowly.

## 3. CONTENT RATING
- Base: **PG-13**. Toggle unlocks **full NSFW**. No ceiling.
- **The toggle gates dialogue AND visuals.**
  - PG-13: clothes stay on.
  - NSFW: clothes tear at brew 3 where the transformation would tear them.
- Toggle is live-swappable mid-save. Effects exist in both modes; only
  presentation changes.
- **In:** TG / sex change, MPreg, futa, herm, hyper, lactation,
  oviposition, weight gain, inflation, feederism, belly audio, soft vore.
- **Out:** hard vore, scat, digestion detail.

---

## 4. PROTAGONIST — CHUGS
- Male Skull-Dog. Purple fur, thick mane, big tail, grey cargo shorts.
- Face is a bare canid skull — hollow sockets, fixed grin of sharp teeth.
- **Aware** of what he is, privately worried about discovery — of his
  trigger and of his power. Underplays everything on the surface.
- The skull cannot emote. He acts through posture, hands, tail, and
  increasingly his gut. Design body language first, faces never.
- Warm, wry, unbothered. Runs a genuinely good bar. Eats people.

## 5. LORE — SKULL-DOGS & THE WECHUGE
- A **Skull-Dog** is an anthro canid whose defining feature is a canid
  skull for a face. Not a mask. The result of becoming **too strong**.
- "Chugs" derives from **Wechuge**, a Cree / Plains Algonquian cannibal
  spirit of winter and hunger. Traditional Wechuge avoid their trigger
  if they can. **Ship an in-game codex entry crediting the concept.**
- Skull-Dogs are rare and usually avoided. Two who meet stick around,
  cautiously.
- **Hunger is species-wide. The trigger is individual.**
  - Chugs: the full moon.
  - Marrow: any food or drink she enjoys immensely.
- Chugs can suppress his trigger by skipping a feeding — at a cost (§6.6).

---

## 6. SYSTEMS

### 6.1 The three loops
- **L1 — Brew & Serve (night).** Patrons arrive with desires. Brews are
  beers with transformative effects. Requests run specific → vague →
  proxy → wildcard (§7.3). Effects stack across visits and mix.
- **L2 — Forage & Fight (day).** Classic JRPG overworld. Ingredients,
  skills, rare items, feral enemies.
- **L3 — The Full Moon.** The feast. A turn-based escape puzzle (§6.5).

### 6.2 The spine
L2 gathers INGREDIENTS → L1 makes TRANSFORMATIONS → TRANSFORMATIONS are
the currency of L3. A transformed patron is valuable both ways: keep
them and they compound; eat them and their change becomes power. Every
patron is an account you either keep or cash out.

### 6.3 Brewing
- Ingredients carry **tags**: [sweet] [bloom] [firm] [bitter] [heat]
  [wild] [bog] [tonic] [rich]...
- Effects are **derived from tag combinations** — combinatorial, not a
  lookup table. This is what makes L2 matter.
- Three-brew escalation on a patron: 1 subtle, 2 noticeable, 3 tears
  clothing (NSFW). The patron's own concealment problem, mirroring
  Chugs's.
- Brewing occupies a vat and a chunk of the day.
- Vat holds 3 ingredients (4 at level 4).

### 6.4 Taste Test
- Unlocked by a **level-up** or by **discovering a new ingredient**.
- Costs **one full day** — the foraging day. That is the price.
- Chugs drinks the test brews; their effects are revealed.
- **Chugs reverts to his exact state at the start of the test**,
  including any weight gained. No risk to him.
- Patron-applied effects are NOT covered and remain permanent.
- [OPEN] Reveals *which* attributes change, not the *magnitude*.
- At level 5, a second taste test per day.

### 6.5 The Feast — turn-based escape puzzle
- **Format: planning → commit → simultaneous resolution.**
  Into the Breach, not Pac-Man.
- The bar floor plan is the one the player has been running all month.
- Each patron has an **escape route** to the nearest exit, drawn on the
  planning screen, with a **turns-to-escape forecast**.
- **Turn limit: the night.** 12 turns baseline.
- **Lose condition: all fleeing patrons escape.** Night advances, Chugs
  is hungry and weaker. Not a game over — a bad month.
- Willing patrons do not run. They are the floor.

**Three ways transformation pays off:**
1. **Slow them.** Speed 3 → 1 across transformation tiers.
2. **Block routes.** Patrons collide. A huge patron in a doorway jams
   everyone behind them — trap a table with one body.
3. **Deny exits.** At high tiers a patron can't fit a narrow door and
   must reroute, turning a 2-turn escape into a 6-turn one.

**Other rules:**
- Chugs's **weight reduces his action points** (6 → 2 at maximum).
- Escaped patrons lose the night and blame the drink. No attention cost.
- Eaten patrons: **body resets. Affinity and kinks persist.**
- Willing patrons stack themselves toward immobility to be eaten first.
- **Marrow** does not hunt. If lovers and present, she slows Chugs via
  enticement, costing action points to pass.
- [DEFERRED] Optional 5-second real-time scramble on the final turn.

### 6.6 Attention
- One meter, town-level. Rises with eating and Chugs's visible weight;
  rises when a patron is eaten repeatedly and notices.
- **Falls when the player skips a feeding.**
  - Cost: weaker when foraging, diminished ability to refuse treats.
  - Self-balancing: skip → refuse fewer treats → fatter → attention up.
- **Max attention → the bar walks to a new region.** No death, no
  banishment, ever.

### 6.7 The Walking Bar
- The bar **walks**. Baba Yaga's-hut style — a cozy tavern that stands
  up on four furry clawed legs and strides to a new region.
- Relocation is a **scene**, not a menu. **This is the marketing image.**
- Triggered by max attention, or by a player-initiated move once per
  in-game month if a region is unlocked.
- Moving unlocks new ingredients and stronger brew combinations.
- Returning to a previous region: some NPCs forget him, others retain
  unlocked kinks and feederism toward him.

### 6.8 Regions
- Each species has a **home region**.
- Structure: **campaign spine + sandbox.** You can stay, but
  progression eventually demands moving.
- [OPEN] Region count and names.

### 6.9 Transformation
- Attributes: chest, hips, belly, height, muscle, weight, hair, skin,
  voice, genitals, sex, plus species flavor (tail, scales, horns).
- Deltas stack. Opposing effects interact rather than cancel.
- On patrons: permanent until the feast resets the body.
- On Chugs, from patron treats: **permanent** until reversed by a
  specific item or action.
- On Chugs, from taste tests: temporary.

**Stages.** Raw points bucket into six stages (0-5). One full vat is
about one stage, which is what makes §6.3's three-brew escalation fall
out of the maths instead of being special-cased. Art and mechanics both
read a stage, never raw points.

**Crossing a stage is an event.** A reaction fires the first time an
axis crosses upward — see §6.17. Repeated small doses do not re-trigger.

**The slice runs one axis: bulk** (belly/weight). It is the only axis
with combat semantics and the only one Chugs shares with enemies, so a
single ladder and a single art set serve both. Further axes are
additive, and cost overlays rather than new bodies.

### 6.10 Weight
- Persistent. Decreases **only** through overworld exertion.
- **Spiral:** fat → slow → fewer trips → fatter.
- Fat = resilience through **damage resistance and heavier attacks,
  not a larger HP pool.** A fixed pool plus rising resistance avoids
  double-dipping; a tank build is legitimate and slow.
- Three costly outs: exertion, slimming brews, refusing treats.
- **Belly capacity is a resource.** Brews and treats compete for space.
- Concealment: loose clothing masks one stage. Level 7 masks two.
- One rare overworld item resets a stage — the spiral's escape valve.

### 6.11 Treats / Feederism
- Certain patrons bring Chugs food. Mostly bovine, some canid, some human.
- Prompt during service: **Accept** (weight up, Affinity up) or
  **Decline** (Affinity down).
- Escalation: higher Affinity → richer, more frequent, sometimes spiked
  with Chugs's own brews. Symmetry: he is a customer too.
- At high Affinity a feeder becomes a named relationship with an arc.
- The dark joke: they are fattening the thing that eats them.

### 6.12 Patrons as resources
Transformation produces goods. Lactating bovine → milk. Lizard-folk →
shed scales and eggs. Canid and felinid → shed fur. A transformed
regular is an ingredient source, not just a payer.

### 6.13 Progression & Saves
- **Everything persists.** Multiple manual save slots.
- **No campaign ending. Runs endless.**
- Player power comes from eating, scaled to the patron's transformation.
- See §6.16 for the level system.

### 6.14 Foraging & scarcity
**Principle: quantity is abundant, tag coverage is the constraint.**
Two simultaneous constraints read as arithmetic, not decision-making.

- 5 searches at level 1, 4 ingredients each, 4-5 patrons.
- Spot pools are **visible before you spend a search.** Planning, not
  gambling. The collision between two patrons who want the same tag is
  the puzzle.
- **Wellwater** — pantry staple, no tags, unlimited.
  1. Anti-stuck valve: you can always brew.
  2. Diluent: fills a vat slot without side effects, making a
     one-effect brew a legitimate precise answer on strict requests.
- Leftovers carry to the next day.

### 6.15 Chugs's Journal
- A persistent, diegetic notebook. Chugs's own knowledge.
- **Survives closing time, relocation, and save/reload.** The one thing
  that carries when the bar walks.
- Two views: **by ingredient** (effect of each) and **by effect**
  (reverse lookup — what raises and lowers each attribute).
- Unknown entries marked. Roughly two-thirds blank on a fresh save.
- Discovery: **serving** (free, incidental) or **tasting** (targeted,
  costs one unit, serves nobody).
- Exact deltas, not qualitative — counter-planning needs precision.
- Per-save, so a fresh save means fresh discovery.

**Design note:** a complete journal does not trivialise brewing, because
it splits knowledge from availability. The journal says what you need;
scarcity decides whether you can get it.

### 6.16 Experience & Levels
- End of day: XP paid on **total satisfaction**, floored so a bad night
  still progresses.
- **No XP from eating.** Leveling is purely a brewing measure.
- XP buys levels. Levels buy **capability**, not just quantity.
- Curve: tight at level 1, comfortable by level 3. Cap 10.

| Level | Reward |
|---|---|
| 1 → 3 | +1 search / +1 yield, alternating |
| 4 | 4th vat slot |
| 5 | Second taste test per day |
| 6 | +1 search |
| 7 | Hide one extra weight stage |
| 8 | +1 yield |
| 9 | Feast: +1 action point |
| 10 | New recipe family unlocked |

**Design note — the difficulty reset:** leveling alone would soften the
game permanently. The walking bar resets it: relocation brings a new
region, unfamiliar ingredients, harder requests, unknown species. The
player's level carries; the challenge resets. Loop is
**level → relocate → new squeeze → level**. The bar walking is
load-bearing for pacing, not just plot.

**Design note — reward quality, not volume:** XP on satisfaction means a
player serving three patrons brilliantly out-levels one serving six
badly. Do not add XP for volume.

### 6.17 Reactions
What a character *does* when their body changes. Reactions are the
counterplay to transformation, and the reason a fight is not solved by
"fatten it" every single time.

- Keyed by **reaction profile**, not species. Two individuals of one
  type can react differently, for no extra art.
- Fires once per threshold, only on an upward crossing (§6.9).
- Kinds: none, distracted, guard down, slowed, enraged, stop, flee.
  - *distracted* — loses turns
  - *guard down* — resistance halved
  - *slowed* — speed reduced
  - *enraged* — hits harder and moves faster
  - *stop* — stops fighting and enjoys it
  - *flee* — leaves
- **Profile is rolled per individual at spawn.** The same bandit can be
  a pushover or a problem, and the player cannot tell until they try.

Slice profiles:

| Profile | On bulk | Reads as |
|---|---|---|
| feral | slowed, then stop | §8's "fatten a wolf so it can't close" |
| humanoid | distracted, then guard down | stops to enjoy it; §7.1 species reads |
| brute | **enraged** | the counter-example: bulking him is a mistake |

**Design note — reactions are the interesting half.** Hindering a feral
creature with weight is a strategy. Making a person stop and stare at
themselves is the joke, and it is why the axis is worth having at all.

Bespoke dialogue and animation per reaction are a later pass. The
system ships grey-box, with the reaction named in the battle log.
---

## 7. NPCS

### 7.1 Species
Species is a *read*, not a *rule*. Break it on roughly a third of
individuals. The moment the player stops trusting the shorthand is the
moment brewing gets interesting.

| Species | Wants | Anchor | Loop role |
|---|---|---|---|
| Human | Weight, height, muscle — subtle. Shyer about asking. | Vanilla, exhibitionism | The norm. Main attention source. |
| Felinid | Sleekness, flexibility, tail, grace | Grooming, pet play, heat, vanity | High-variance picky requests |
| Canid | Size, muscle, stamina, "bigger" | Knots, rut, pack loyalty, gluttony | Near-kin. They sense he's off. |
| Equine | Height, bulk, endowment, stamina | Size difference, virility | Big-ticket customers |
| Lizard-folk | Warmth-driven bulk, tail, scales | Oviposition, basking, cold-blood | Wants to be fat for warmth — Chugs's mirror |
| Bovine | Chest, hips, bulk, milk | Lactation, feederism, WG | The feeders. Load-bearing species. |

Canids are **near-kin**, not kin. Wolves are the most popular fursona
species in the fandom, so Chugs's silhouette is the safest possible lead.

### 7.2 Marrow (female Skull-Dog)
- Travels. Appears occasionally. Taller, leaner, greyer, starving.
- Trigger: food or drink she enjoys immensely — a powder keg in a bar
  full of brews she'd love.
- Kind: **wildcard.** "Surprise me" means exactly that.
- Starts wary. Slow burn to close, then lovers.
- **Does not participate in the hunt.** If lovers and present, she
  distracts Chugs instead.
- She is the only one who gets to interrupt the monster's dinner.
- [OPEN] Does she eat Chugs's patrons? Do they share?

### 7.3 Request archetypes
Four kinds. Each signals its own rules on the patron card.

| Archetype | Question | Judged on |
|---|---|---|
| Specific | Hit this exact mark | Target match, strict on side effects |
| Vague | Infer the mark | Target match, forgiving tolerance |
| Proxy | Hit a mark belonging to a third party | Target match + recipient reaction |
| Wildcard | No mark at all | Boldness, focus, single direction |

**Rule: if a patron has a hidden target, the request must signal that a
target exists.** Never hide a spec behind a promise of no spec.

Wildcards: no target. Score = magnitude window + penalty for touching
more than 3 attributes + penalty for mixed directions + penalty for
net-zero change. Rare — roughly 1 in 6. Reserve for patrons whose trust
matters.

---

## 8. OVERWORLD & COMBAT
- Anthro cast. Enemies are **feral** (wolves, bears, and worse) **or
  humanoid** — bandits, rivals, people with a grudge.
- Turn-based. Enemies drop ingredients. Enemies are ingredient nodes
  with a fight attached.
- **Brews are usable on enemies** to force transformations — fatten a
  wolf so it can't close, or make a bandit stop and look at himself.
  Ending a fight with no blows struck is legitimate if the player has
  the stock. Otherwise they fight.
- Enemies **carry their own brews**, rolled into their inventory at the
  start of a battle, and will use them on Chugs. Same component, same
  rules; direction is the only difference.
- Chugs's attacks: **Punch, Claw, Belly Slam.** Weight raises Belly
  Slam's damage and its cost. Fat is power that is slow.
- **Fights are a sandbox, not a wall.** Generous turn limits, low
  lethality, room to try things and watch what happens. They exist so
  the player can experiment, and to yield ingredients.
- Reactions (§6.17) are the counterplay — see the brute profile.
- Defeat = knocked out, **lose half of gathered inventory.** Never fatal.
- Enemy transformations **do not persist** between encounters. Win or
  lose, bodies reset. Loot is unaffected either way.
- Only Chugs's weight, and the weight lost to exertion, leaves a fight.

## 9. TIME
- Day = forage / brew / taste test / prep. Night = service.
- One moon = one run. Full moon = the feast.
- Time is the currency. You can never do everything.

## 10. ART DIRECTION
- **Hybrid, concept look preserved.** All characters cel-shaded, bold
  outlines, flat shading, warm palette — matching the reference concept.
- Overworld: same rendering, locked camera, tile-grid layout. Retro in
  *structure*, not pixel density.
- Pixel art reserved for UI, icons, inventory.
- **6 weight stages per outfit.** Largest recurring art cost. Budget it.
- Do not pixel the characters — it fights the concept's line quality.
- Generated art for now; commission if funds permit. A 6-stage weight
  system across outfits is where a human artist will beat generation.

## 11. AUDIO
- Tavern: warm acoustic, clinking, low murmur.
- Overworld: bright adventure.
- Full moon: single held drone; low wet chime on each swallow; door
  creak on each escape.
- Belly audio: yes.
- [OPEN] Composer or library.

## 12. TECH
- **Godot 4.** Free, 2D-first, strong 2D pipeline, easy Windows/Linux
  export, turn-based systems port directly.
- Windows + Linux. Android possible much later.
- English only for now.
- Solo dev, with Venice as design and prototyping partner.
- Repo: public GitHub, `docs/design.md` is this file.

## 13. SCOPE — VERTICAL SLICE
One lunar week, 3 customers, 1 zone, 2 enemy types, 1 transformation
axis, 1 taste test, 1 feast, PG-13 only.
**If the week isn't fun, the year won't be.**

**Build order:**
1. Project skeleton, autoloads, save system
2. Feast scene (riskiest system, grey-box in engine)
3. Brew → serve → satisfaction
4. Foraging and scarcity
5. Journal
6. Levels and XP
7. Overworld and combat
8. Attention, weight, treats
9. Art

## 14. PROTOTYPES (all playable, all grey-boxed)
| File | Proves |
|---|---|
| `feast.html` | Turn-based chase; binge-burn rhythm; doorway jam |
| `brew.html` | Request matching across four archetypes |
| `journal.html` | Discovery loop; persistent reference |
| `levelup.html` | Skill-responsive difficulty |

Keep these. They are the proof of what works.

## 15. OPEN QUESTIONS

### Resolved 2026-10-15 — combat scope
| # | Question | Answer |
|---|---|---|
| 1 | Do enemy transformations persist between encounters? | No. Reset at the next encounter, win or lose. |
| 2 | Does a transformed enemy drop different loot? | No. Same loot. |
| 3 | Can an encounter be resolved by transformation alone? | Yes, if the player has the stock. Otherwise they fight. |
| 4 | Where do enemies get brews? | Rolled into their inventory at battle start. |
| 5 | Does drinking consume belly capacity? | No. Only Chugs's weight, and exertion loss, persists. |
| 6 | Does Chugs's weight do anything in combat? | Raises Belly Slam damage and its AP cost. |
| 7 | Does the NSFW toggle apply to enemies? | Yes. Battles are paced to allow experimentation. |
| 8 | Which axis is the slice's single axis? | Bulk. More axes are additive later. |

### Still open
1. Does the journal record **combos**, or only single ingredients?
2. Does Chugs ever *forget* an ingredient? (Lean: no.)
3. Region count and names.
4. Audio: composer or library.
5. One-line pitch.
6. Bar customization?
7. Named recurring cast size?
8. Do transformed patrons produce goods on a timer or on demand?

## 16. DECISION LOG
| Date | Decision | Why |
|---|---|---|
| 10-15 | PG-13 base, NSFW toggle | Broad reach, no compromise |
| 10-15 | Toggle gates dialogue + visuals | One game, two presentations |
| 10-15 | Attention is the fail axis | Failure without a game over |
| 10-15 | Eating resets body, not affinity | Relationships persist |
| 10-15 | Max attention = relocate, not death | Soft reboot, keeps the player |
| 10-15 | Weight permanent, exertion-only loss | Makes the clock real |
| 10-15 | Weight is a tradeoff, not a penalty | Fat is a build choice |
| 10-15 | Chugs = Skull-Dog, name from Wechuge | Mythic spine |
| 10-15 | Transformations hinder escape | Dosing is the feast strategy |
| 10-15 | Taste test is risk-free for Chugs | Free discovery, gated by a day |
| 10-15 | Patron treats are permanent on Chugs | He's a customer too |
| 10-15 | Hybrid art, concept look locked | Concept art is the game's look |
| 10-15 | No campaign ending; runs endless | Ship the loop first |
| 10-15 | The bar physically walks to regions | Whimsy, and a scene not a menu |
| 10-15 | Marrow distracts, doesn't compete | Her arc is about him |
| 10-15 | Attention and suspicion merged | One meter until it earns two |
| 10-15 | Feast is turn-based, reuses combat engine | Legible payoff, 1/4 the work |
| 10-15 | Lose condition = weak month | Failure without a game over |
| 10-15 | Real-time chase deferred | Revisit only if the feel is missed |
| 10-15 | Wildcard is a distinct archetype | Fixes the hidden-spec bug |
| 10-15 | Requests must signal their own rules | Never graded invisibly |
| 10-15 | One constraint only: tag coverage | Two constraints read as arithmetic |
| 10-15 | Wellwater diluent, unlimited | Anti-stuck valve and precision tool |
| 10-15 | Spot contents visible pre-search | Turns a gamble into a plan |
| 10-15 | Journal persists across relocations | Knowledge is the progression axis |
| 10-15 | Journal is per-save, starts blank | Preserves replay discovery |
| 10-15 | Taste test costs stock, serving is free | Targeted learning has a price |
| 10-15 | XP on satisfaction, levels grant capability | Scarcity early, mastery late |
| 10-15 | Level cap 10, bonuses capped | Foraging must stay relevant |
| 10-15 | Relocation is the difficulty reset | Leveling alone softens the game |
| 10-15 | **No XP from eating** | Leveling is a brewing measure |
| 10-15 | Enemy TF resets between encounters | Fights are experiments, not investments |
| 10-15 | Transformed enemies drop the same loot | Loot is not a second progression axis |
| 10-15 | Enemies carry their own brews | Symmetry: he is a customer too |
| 10-15 | Reactions keyed per individual | Variety at zero art cost |
| 10-15 | Brute profile enrages on bulk | Transformation must not be a universal win |
| 10-15 | Chugs's attacks: Punch, Claw, Belly Slam | Weight is power that is slow |
| 10-15 | HP fixed; weight gives resistance not HP | Avoid double-dipping |
| 10-15 | Humanoid enemies allowed | Bandits read as people, not monsters |
| 10-15 | Combat is a sandbox, not a wall | The game is brewing; fights feed it |
| 10-15 | Slice axis is bulk, one only | Only axis with combat meaning, shared with enemies |
| 10-15 | Reactions ship grey-box, dialogue later | Art and VO are a later pass |

## 17. APPENDIX — KINK → MECHANIC MAP
| Concept | System |
|---|---|
| Weight gain / inflation | §6.10 |
| Expansion (BE / hips / belly) | §6.9 |
| Feederism | §6.11 |
| TF / TG | §6.3 |
| Heat / rut | §9 |
| Oviposition | Lizard-folk rare effect; eggs become ingredients |
| Lactation | Bovine; milk becomes an ingredient |
| Size difference | Late-game, capped by weight stage |
| Pet play / collars | Affinity gear and gifts |
| Hyper | Rare top-tier effects |
| Soft vore | §6.5 |

## 18. APPENDIX — CORE RHYTHM
The intended skill expression, in one line:

> **Binge on the full moon → burn it off foraging → arrive at the next
> moon lean enough to hunt.**

A player who skips the burn arrives fat, slow, and catches nothing. This
rhythm emerged from four independent decisions and is the spine of the
moment-to-moment game. **Protect it.**

## 19. APPENDIX — DIFFICULTY SHAPE
> **Tight → comfortable → relocate → tight again.**

Scarcity teaches. Levels reward. Relocation re-tightens. The player's
knowledge and level carry across; the challenge does not. This is the
pacing spine. **Protect it.**
