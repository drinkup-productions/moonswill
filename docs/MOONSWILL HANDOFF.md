# MOONSWILL — Dev Log & Handoff

_Living document. Append to §5. Keep §1 accurate at all times._

---

## 0. HOW TO USE THIS FILE

- **§1 RESUME HERE** is the only section that must always be current.
  If you're picking this up cold, read §1 then `docs/design.md`.
- **§5 Dev log** is append-only history. Add an entry per session.
- `docs/design.md` is the **single source of truth for design**.
  This file records *what has been built*, not what the game is.
- Never fork `design.md`. Edit it in place.
- This file lives at `docs/MOONSWILL HANDOFF.md`. There is no separate
  `devlog.md` — one file, one name.
- `docs/step7-scope.md` is a working scoping doc for combat. Superseded
  once step 7 closed; kept for the reasoning.

---

## 1. RESUME HERE

**Status:** Build steps 1–8 complete and running. The loop is closed and
playable end to end: boot → forage → overworld → brew → serve → feast on
the full moon → advance day. Persistent patron populations, garments,
freeze rolls, attention, treats, relocation and save/load all exist.
Everything is grey-box; there is **no art or audio yet**.

**One file set is written but not yet committed** — see "Uncommitted"
below. Paste and test it before anything else.

**Last worked:** 2026-10-19

**Next action:**
1. Paste and commit the bench-day file set (8 files, listed below).
   Run the six-point test list in §5's 2026-10-19 entry.
2. Decide the open question in that entry: does `wander out` stay
   available during a bench day, or is the bench day locked to the bar?
3. Then **build step 9 — art**, which is blocked on three inputs from
   you: the §4 face reference, reference images for Chugs and Marrow,
   and the twelve authored regulars. Nothing else in the codebase is
   blocking it.

**Uncommitted (written, needs paste + test):**

godot/scripts/systems/transform.gd bonus/effective(), clear_points()
godot/scripts/autoload/game.gd chugs body, bench gating, banking
godot/scripts/autoload/journal.gd known_full tier
godot/scripts/autoload/save.gd chugs + bench persistence
godot/scripts/experiment.gd NEW — bench scene controller
godot/scenes/experiment/experiment.tscn NEW
godot/scripts/forage.gd bench offer, taste_tests_left fix
godot/scripts/boot.gd resume onto the bench

Commit these as one set. `game.gd`, `save.gd` and `journal.gd` are
interdependent — a partial paste will parse but misbehave.

**Known bugs:**
- None open. Fixed this session: `forage.gd` read `Game.taste_tests_left`,
  a property that was never declared on the autoload — a live runtime
  error on every forage refresh. Now reads
  `Levels.taste_tests_per_day()`.

**Known gaps (code, not design):**
- [ ] `tools/prototypes/` still holds one stray file, `Untitled
      Document`. The five HTML grey-boxes live only in chat.
- [ ] `godot/.godot/` is committed to git, which contradicts §6.
- [ ] Enemy loot is not region-filtered — the fens can drop `firm` and
      `wild` when neither is on that region's shelf.
- [ ] `forage.gd` still carries a `# TEMP` inventory seed fallback in
      `brew.gd` for F6-on-brew only. Intentional; do not remove.

**Known gaps (content, blocked on you):**
- [ ] §4 face reference image — how the skull reads via eyelids, ears,
      working mouth.
- [ ] Reference images for Chugs and for male/female species variants.
- [ ] The twelve authored regulars: name, species, region each.
      Currently placeholders in `character_db.gd`.
- [ ] Handwritten ingredient list needs trimming before it lands.

**Open design questions:** `docs/design.md` §15. Eight still open, none
structural — see §15 for the list.

**Environment:** Godot 4.4, `gl_compatibility` renderer, Windows/Linux.
Repo is public.

---

## 2. PROJECT SNAPSHOT

**Repo:** https://github.com/drinkup-productions/moonswill
**Design:** `docs/design.md` (v4 FINAL)
**Handoff:** `docs/MOONSWILL HANDOFF.md` (this file)
**Engine:** Godot 4.4 — free, 2D-first, ports turn-based systems directly

### Layout

docs/design.md design source of truth
docs/MOONSWILL HANDOFF.md this file
docs/step7-scope.md combat scoping, closed
godot/ the project
project.godot 5 autoloads, input map, renderer
scripts/
boot.gd entry point, resumes autosave
brew.gd brew & serve controller
feast.gd feast controller
forage.gd morning forage controller
overworld.gd walking bar controller
relocation.gd region-change controller
experiment.gd bench day controller [uncommitted]
autoload/ Game, Save, Journal, Levels
data/ Attributes, Tags, Ingredient, IngredientDB,
Patron, PatronRequest, CharacterDB, RegionDB,
EnemyDB, ReactionTable
systems/ Transform, Combatant, Battle, BattleGrid,
EnemyDB, EncounterTable, BrewCalculator,
FeastGrid, FeastController, FeastPatron,
ForageMap, OverworldMap, PatronFactory,
TreatFactory
ui/ JournalUI, LevelUpUI, SaveUI (CanvasLayers)
dev/ tf_debug, battle_debug, encounter_debug
scenes/ boot, brew, feast, forage, overworld,
relocation, experiment [uncommitted],
dev debug scenes
tools/prototypes/ HTML grey-boxes (not yet committed)

### Autoloads
`Game` (run state, populations, Chugs's body) · `Save` (slot 0 autosave,
slots 1–3 manual, JSON in `user://saves`, VERSION 2) ·
`Journal` (persistent discovery, two knowledge tiers) ·
`Levels` (XP curve, table-driven from §6.16) ·
`IngredientDB` (11 ingredients, incl. Wellwater diluent)

### What works
- Full day loop end to end, playable, grey-boxed
- Feast: turn-based escape puzzle with freeze roll, bulk-weighted
- Brew & serve: four archetypes, wildcard scoring, tag matching
- Forage: pre-search pools, coverage read-out, leftovers persist
- Overworld: grid walking, encounters, turn-based battle, reactions
- Populations: 8 persistent patrons per region, bodies and garments
  carry across days and moons; relocation abandons the cast
- Moon cycle, attention, treats/feederism, level-up beats
- Journal overlay (J), save/load overlay (S), level-up overlay
- Bench day: free infinite resets, permanent points, 7-day cooldown

### What doesn't exist yet
Any art or audio. Main menu. Marrow. The twelve authored regulars.
Recipe families. §6.19 procedural dialogue. Full-restore save (steps,
searches, overworld cell, roster and forage map are rebuilt, not
restored). Two-tier journal *UI* (the data tier now exists).

---

## 3. BUILD ORDER & PROGRESS

1. ✅ Project skeleton, autoloads, save system
2. ✅ Feast scene (riskiest system, grey-boxed first)
3. ✅ Brew → serve → satisfaction
4. ✅ Foraging and scarcity
5. ✅ Journal UI
6. ✅ Levels and XP wiring
7. ✅ Overworld and combat
8. ✅ Attention, weight, treats, persistence, bench day
9. ⬜ Art — **NEXT**, blocked on references

Steps 1–8 are all closed and tested. Step 9 is the last build step and
the only one that can't be started without input from you.

---

## 4. PROTOTYPES TO COMMIT

Built and played in chat. They are the proof of what works — worth
keeping even after the Godot versions exist.

| Suggested file | Proves |
| --- | --- |
| `tools/prototypes/feast.html` | Turn-based chase, binge-burn rhythm, doorway jam |
| `tools/prototypes/brew.html` | Request matching across four archetypes |
| `tools/prototypes/journal.html` | Discovery loop, persistent reference |
| `tools/prototypes/scarcity.html` | Tag coverage as the real constraint |
| `tools/prototypes/levelup.html` | Skill-responsive difficulty |

Note: `tools/prototypes/` currently contains a single stray file named
`Untitled Document`. Replace it with the five files above.

---

## 5. DEV LOG

### 2026-10-15 — Design lock
- Full design doc written and locked at `docs/design.md` v4.
- Three loops, four request archetypes, weight/attention economy,
  walking bar, level curve, journal, feast format all specified.
- Four prototypes played and iterated. Each surfaced one real flaw that
  was fixed before any engine work:
  - Hidden spec behind "surprise me" → wildcard became its own archetype
  - Scarcity too tight (two constraints at once) → coverage-only, plus
    a Wellwater diluent
  - Feasts unplayable in real time → turn-based escape puzzle

### 2026-10-15 — Build steps 1 and 2
- Repo created, made public, `.gitignore` for Godot 4.
- Skeleton committed: `project.godot` with 5 autoloads and input map,
  four autoload singletons, folder tree.
- Feast scene committed and running. Pure logic split from the view so
  it's testable headless. Doorway jam is one line in `step_patron()`.

### 2026-10-15 — Build step 3
- Brew data layer, scoring, and scene written.
- Full repo audit run; one bug outstanding (see §1).

### 2026-10-15 — Wildcard fix
- `brew.gd:160` — `req.is_wildcard` → `req.is_wildcard()`. Callable was
  being passed where a `bool` was expected. Committed as `c9f3eca`.
- Step 3 is now code-complete and running.

### 2026-10-15 — Handoff doc
- Handoff written, then corrected after an independent audit: §1
  status and bug list were stale (the fix landed *after* the doc was
  drafted), the `docs/devlog.md` reference in §9 pointed at a file that
  doesn't exist, and the whole file was backslash-escaped so it rendered
  as plain text. All three fixed.

### 2026-10-15 — Build step 4
- Patron, PatronFactory, ForageMap added. Roster and spots both seeded
  from the day, so a day is reproducible.
- Game.start_day() builds roster -> spots -> search budget, in that
  order: the player plans with tonight's customers in front of them,
  which is what makes tag collision the puzzle rather than a gamble.
- Forage scene: pools visible pre-search, coverage read-out, leftovers
  persist. Wellwater topped up daily, never placed in a spot.
- Loop closed: boot -> forage -> brew -> advance_day -> forage. brew.gd
  TEMP seed is now a fallback for F6 on brew.tscn only.
- Tags gained tags_raising/tags_lowering for the reverse lookup.
- Not done: tasting, the overworld, feast hand-off after service.

### 2026-10-15 — Build step 5
- Journal is now a real overlay (JournalUI, CanvasLayer) reachable with J
  from forage and brew. Overlay rather than scene, so opening it mid
  service doesn't restart the night.
- Both views: by ingredient, by effect (reverse lookup, known only).
  Unknown entries marked. Exact deltas. §6.15
- Taste test wired: costs one unit, limited to Levels.taste_tests_per_day,
  reveals the entry. Does not yet affect Chugs — step 8.
- Fresh saves seed three known ingredients so the notebook starts about a
  third full, per §6.15. Per-save, as specified.
- Autosave on advance_day to slot 1; boot resumes it. Journal now really
  does survive reload, which it previously only claimed to.
- Resolved two doc ambiguities: taste cost (§6.4 vs §9) and
  reveal-precision (§6.4 [OPEN] vs §6.15) — both logged here, design.md
  not yet updated.
- brew.gd's inline journal panel removed; JournalUI serves both scenes.

### 2026-10-15 — Build step 6
- levels.gd rewritten table-driven from §6.16. The old formula handed out
  +1 search AND +1 yield at 3/5/7/9, reaching 9 searches and 7 per search
  at cap. Now caps at 7 and 6, which is what keeps foraging relevant.
- award() returns the levels actually reached, not a count, so the beat can
  name each one.
- LevelUpUI added: a beat, not a toast. States the capability, then the new
  totals. Cap message points at relocation as the real difficulty reset.
- brew.gd vat size now reads Levels.vat_slots() instead of a hardcoded 3.
  Level 4's reward was previously unreachable.
- Level and XP shown in both scene headers.
- reset_run() now resets Levels — "new run" used to keep your level.
- Hooks, not behaviour: conceal_stages() (step 8), recipe_family_unlocked()
  (no recipe families exist yet), level_gained signal (unwired).
- XP curve reading of "tight at 1, comfortable by 3" logged: capability
  delivers it, not the XP arithmetic. design.md still not updated.

### 2026-10-16 — Step 7 scoping
- Step 7 was too big for one pass. Split into 7a–7f and written up in
  `docs/step7-scope.md`.
- **The art contract came first, before any art existed.** `Transform`
  is a `RefCounted` whose `visual()` is the *only* art-facing call.
  Mechanics read the true silhouette; art reads `visual()`. This was
  done deliberately before art so the two can't drift.
- `visual()` returns base_stage, base_blend, overlays, tear, flavor,
  silhouette. `ANCHORS = [0, 2, 4, 5]`, `PER_STAGE = 6`,
  `STAGE_MAX = 5`.
- Recorded the combinatorial problem: 5 axes × 6 stages = 7776 possible
  silhouettes. Approach B collapses it — nude base bodies at anchors,
  overlays for the rest, base crossfade doubling as the smear frame.
  Roughly 30 sprites instead of thousands.
- Slice is one axis only (bulk). Other axes exist in the data and are
  switched off in `Transform.AXES`.

### 2026-10-16 — Build step 7a–7c
- `Transform` with `apply()` returning threshold-crossing events, so a
  reaction can be looked up without Transform knowing about combat.
- `ReactionTable` with feral / humanoid / brute profiles. Kinds: NONE,
  DISTRACTED, GUARD_DOWN, SLOWED, ENRAGED, STOP, FLEE.
- `tf_debug.gd` grey-box renderer, so the contract could be seen working
  before art.
- `Combatant` added; `FeastPatron` folded onto `Transform` so there is
  one transformation model, not two.

### 2026-10-16 — Build step 7d–7f
- `EnemyDB` (wolf, bandit), tag-derived loot. `EncounterTable` weighted
  by region with min_level gates.
- `BattleGrid` (BFS `path_to()`) and `Battle` (turn loop, enemy AI),
  both pure logic. `battle_scene.gd` is the thin view.
- `OverworldMap` + `overworld.gd`: grid walking, encounter roll on
  step, battle hand-off, day-end on steps exhausted.
- The brute profile is the deliberate counter-example to bulk: a fat
  wolf enrages rather than slowing, so transformation is not a
  universal win.

### 2026-10-16 — Bug batch
Three real bugs, all from testing feedback. Worth remembering the shape
of each:
- **Feast softlock at zero AP.** Space bar stopped ending the turn.
  Cause: `_unhandled_input` guarded on `not ctrl.can_act()`, and
  `can_act()` includes `ap > 0` — correct for *moving*, wrong for
  *ending a turn*. Split the predicates: confirm needs a live turn,
  movement needs AP. Auto-end the turn when AP hits zero.
- **HP scaled with bulk.** `Combatant.max_hp` was silhouette-derived;
  the doc said weight-scaled. Both wrong. `BASE_HP = 14`, fixed.
  Resilience lives in `damage_resist()` and heavier attacks instead.
  Logged as a §6.10 deviation.
- **`attack_damage()` used the attacker's resistance**, so a fat wolf
  hit softer *because it was fat* rather than because its target was
  armoured. Replaced with `roll_damage(attack, target)`.
- **Patron speed regression.** `set_legacy_transformation` used
  `tf * 0.3`, putting stage boundaries at 40/80 instead of the old
  ladder's 34/68. Derived `tf * 6.0 / 17.0` so the thresholds land
  exactly where they did. Added a live speed readout to verify.

### 2026-10-16 — Build step 8
- Moon cycle (15 days), attention economy with relocation at cap,
  treats and feederism, level-5 belly capacity.
- `RegionDB` with tag palettes and unlock levels 4/7.
- `SaveUI`: slot list, manual save/load, autosave to slot 0.
- Full-moon feast hand-off; `skip_feast()` costs attention and two
  weak days.

### 2026-10-16 — Design doc update pass
- User supplied `Answers to open questions.txt`; docs updated in one
  pass against it.
- **Willing patrons cut.** Replaced by a freeze roll
  (`0.45 - stage * 0.07`). Immobilised patrons never flee. This made
  the feast a maths problem instead of a coin flip.
- **Populations made persistent.** 8 characters per region — 4
  authored regulars, 4 procedural. Bodies, affinity and garments
  survive days, moons and saves. Relocation abandons the cast; the
  next region has its own.
- **Clothing became layered state.** Nude base → transformation →
  clothing. PG-13 stretches what NSFW tears. Resets only on being
  eaten.
- **Two-tier journal** specified: blank on acquisition, direction and
  body part on serving, full magnitudes on the bench. By-effect view
  gated to level 3.
- Level 5 reward changed from a taste test to +1 belly capacity, since
  the bench day replaces tasting entirely.

### 2026-10-17 — Build step 8b
- `PatronFactory.build_population()` and `roll_night()`, deterministic
  per region so a save's cast is stable.
- `CharacterDB` with 12 placeholder regulars across 3 regions.
- Save format VERSION 2: populations serialised, affinity carried
  across relocation.
- `Patron.GARMENT_AXES` — shirt tears on chest/belly, pants on
  hips/belly.

### 2026-10-19 — Bench day and Chugs's own body (step 8c)
- Chugs now has a body of his own: `Game.chugs`, a `Transform`.
  Permanent points from spiked treats and from drinking on the bench,
  cleared only by the reset potion.
- **Weight stayed a separate scalar.** It drives steps, attention and
  belly capacity, and it folds into the silhouette as `bonus` rather
  than as points. `Transform.effective()` = points + bonus, so art
  still reads one contract and patrons are unaffected (`bonus` empty).
- `Transform.clear_points()` added; the potion calls it, then drops
  weight by `RESET_POTION_WEIGHT` (10). Resets are free and infinite,
  but only while on the bench.
- Bench day: offered at day start when `Game.can_experiment()` (7-day
  cooldown). Consumes the foraging portion, banks the searches into
  `banked_searches` for tomorrow, no timer or belly cost. Ends by
  walking into service transformed — which is the payoff.
- Patrons' spiked treats now mark Chugs permanently. He is a customer
  too; they are fattening the thing that eats them.
- Journal gained a `known_full` tier. Bench drinking measures an
  ingredient; serving only points at a direction. UI is still one
  tier — that's a separate job.
- Save carries the body, the drink count and the banked searches. A
  save taken on a bench day reloads onto the bench, not into the wilds.
- **Fixed:** `forage.gd` read `Game.taste_tests_left`, a property that
  was never declared. Live runtime error on every forage refresh.
- **Open question, not decided:** `wander out` is still available
  during a bench day, so you can bank the searches *and* go fighting.
  Either disable it, or keep it as a deliberate risk/reward. Pick one.

---

## 6. CONVENTIONS

**GDScript**
- Parameters prefixed `p_` — never shadow a member variable.
- **Prefer untyped `Array` over `Array[String]`** for literal data.
  Type the function boundary, not the storage.
- **Because storage is untyped, every read out of a collection needs an
  explicit type annotation.** `var st := e.status_text()` fails when
  `e` came from an untyped `Array`; `var st: String = e.status_text()`
  works. This is the tax on the convention above — expect it and type
  the read site.
- **GDScript block scoping is real.** A `var p` in a loop body collides
  with a later `for p in ...` in the same function. Rename loop
  variables rather than hoisting.
- Pure logic in `RefCounted` classes with no node dependencies
  (`BrewCalculator`, `Battle`, `BattleGrid`, `EncounterTable`,
  `FeastGrid`, `FeastController`, `FeastPatron`, `ForageMap`,
  `OverworldMap`, `PatronFactory`, `Transform`).
  Views subscribe via signals; nothing polls.
- Signals over direct calls for anything the UI reacts to.
- **Watch view predicates.** `can_act()` includes `ap > 0`, so gating
  an end-turn key on it softlocks. Movement predicates and turn
  predicates are different things; never reuse one for the other.

**Commits**
- Commit a **whole file set together**. Half-applied sets have caused
  both bugs so far.
- Write real messages — `add wildcard scoring`, not `update`. The
  history becomes a searchable decision log.

**Never commit**
- `.godot/` cache, exports, build output.
  (Note: `godot/.godot/` is currently tracked — see §1.)

---

## 7. GODOT 4 GOTCHAS (learned the hard way)

1. **`add_child()` returns `void`.** You cannot chain
   `parent.add_child(Label.new()).text = "x"`. Create, set, then add.
2. **Typed arrays don't implicitly convert.** Passing an untyped `Array`
   literal into an `Array[String]` parameter fails at the call boundary
   with `Cannot convert argument N from Array to Array`.
3. **Parameter names shadow member names.** `func make(kind: Kind)`
   with a `var kind` member is an error, not a warning.
4. **Type inference fails on untyped collection reads.** See §6.
   `Cannot infer the type of "x" variable because the value doesn't
   have a set type.` Fix by annotating the read, never by typing the
   storage.
5. **Variables declared in a block collide with later loops in the same
   function.** `Parse Error: There is already a variable named "p"
   declared in this scope.`
6. **Stale class cache.** If a script change doesn't take effect, close
   Godot and delete `.godot/`. It regenerates.

---

## 8. WORKING NOTES

- The assistant can **read** the public repo but cannot write to it.
  It fetches files over the web. Workflow: assistant produces complete
  files with explicit paths → paste → commit.
- Ask for **full files, never diffs** — no manual reconciliation.
- When a bug appears, pasting the exact error text is fastest.
- The assistant can audit the repo directly, so it's worth asking for a
  check after any batch of changes.
- **Every delivery ends with a test list.** Test it before committing
  the next thing; the bench pass and the HP regression were both caught
  this way.
- **The design doc is overrulable.** Where code and doc disagree, the
  doc gets a deviation note rather than silent divergence. Two exist
  already (HP fixed, and the bench replacing taste tests).

---

## 9. SESSION TEMPLATE

Copy this in when starting a session:

Resuming MOONSWILL. Repo: github.com/drinkup-productions/moonswill
Design: docs/design.md (v4 FINAL — source of truth)
Dev log: docs/MOONSWILL HANDOFF.md — read §1 RESUME HERE first.
Doing today:
Blocked on:

---

## 10. ARCHIVING A SESSION

**Export the chat before you touch the host machine.** Venice keeps chat
history in local browser storage and holds no server-side copy, so a
reformat takes the history with it. Use the drawer on the left of the
chat screen to export the conversation to your device. If you're on a
paid tier there's also an encrypted backup/restore, but that restores
into Venice — it isn't a file you can read.

**Do not paste a raw export into a new session.** A long build chat is
well past what's worth reading. The export is an *archive*; §1 plus
`design.md` is the *context*. A new session needs the current state and
the next action, not the transcript of how you got there.

Recommended shape:

1. Export the chat to `.md`, keep it outside the repo (or in
   `docs/archive/` if you want it versioned — note it's large).
2. Make sure §1 is current. That is the whole job of §1.
3. Start the new session with the §9 template, and attach the export
   only if the new session asks for something the docs don't cover.
4. If a session produced decisions the docs don't reflect, get those
   into `design.md` **before** archiving, not after. The export is
   read-only history; the docs are the live state.

A cold-start prompt that works:

Resuming MOONSWILL. Repo: github.com/drinkup-productions/moonswill
Read docs/MOONSWILL HANDOFF.md §1 RESUME HERE, then docs/design.md.
Then read §5's most recent entry and §3.
Confirm what you think the current state is and what the next action
is, before writing any code.
Doing today:
Blocked on:

