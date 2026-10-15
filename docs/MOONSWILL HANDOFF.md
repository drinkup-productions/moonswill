\# MOONSWILL — Dev Log & Handoff

\_Living document. Append to §5. Keep §1 accurate at all times.\_

\---

\#\# 0\. HOW TO USE THIS FILE

\- \*\*§1 RESUME HERE\*\* is the only section that must always be current.  
  If you're picking this up cold, read §1 then \`docs/design.md\`.  
\- \*\*§5 Dev log\*\* is append-only history. Add an entry per session.  
\- \`docs/design.md\` is the \*\*single source of truth for design\*\*.  
  This file records \*what has been built\*, not what the game is.  
\- Never fork \`design.md\`. Edit it in place.

\---

\#\# 1\. RESUME HERE

\*\*Status:\*\* Build steps 1 and 2 complete and running. Step 3 code-complete,  
blocked on one one-line bug. Not yet playable end to end.

\*\*Last worked:\*\* 2026-10-15

\*\*Next action:\*\*  
1\. Fix the known bug below, commit, run \`godot/scenes/brew/brew.tscn\`  
   with F6 in the Godot editor.  
2\. Then start \*\*build step 4 — the forage scene\*\* (see §3).

\*\*Known bugs:\*\*  
\- \[ \] \`godot/scripts/brew.gd\`, in \`\_brew()\`:  
      \`BrewCalculator.band\_line(sc, req.is\_wildcard)\` is missing the  
      parentheses. It passes a Callable where a \`bool\` is expected.  
      Fix: \`req.is\_wildcard()\`.

\*\*Known gaps:\*\*  
\- \[ \] The five HTML grey-box prototypes exist only in chat, not in the  
      repo. They should be saved into \`tools/prototypes/\` — see §4.  
\- \[ \] \`feast\_patron.gd\` has not been line-audited (low risk; the scene  
      runs and \`feast\_controller.gd\` calls into it cleanly).

\*\*Open design questions:\*\* see \`docs/design.md\` §15. Nothing structural.

\*\*Environment:\*\* Godot 4.4, \`gl\_compatibility\` renderer, Windows/Linux.  
Repo is public.

\---

\#\# 2\. PROJECT SNAPSHOT

\*\*Repo:\*\* https\://github.com/drinkup-productions/moonswill  
\*\*Design:\*\* \`docs/design.md\` (v4 FINAL)  
\*\*Engine:\*\* Godot 4.4 — free, 2D-first, ports turn-based systems directly

\#\#\# Layout  
docs/design.md design source of truth  
godot/ the project  
project.godot 5 autoloads, input map, renderer  
scripts/  
boot.gd entry point  
brew.gd brew & serve scene controller  
feast.gd feast scene controller  
autoload/ Game, Save, Journal, Levels  
data/ Attributes, Tags, Ingredient, IngredientDB, PatronRequest  
systems/ BrewCalculator, FeastGrid, FeastController, FeastPatron  
data/feast\_layouts.gd bar floor plans  
scenes/ boot, brew, feast, overworld (empty)  
tools/prototypes/ HTML grey-boxes (not yet committed)  
\#\#\# Autoloads  
\`Game\` (run state) · \`Save\` (3 slots, JSON in \`user://saves\`) ·  
\`Journal\` (persistent discovery) · \`Levels\` (XP curve) ·  
\`IngredientDB\` (11 ingredients, incl. Wellwater diluent)

\#\#\# What works  
\- Boot scene runs, autoloads validate  
\- Feast scene: playable turn-based escape puzzle, grey-boxed  
\- Brew scene: builds, one bug away from running

\#\#\# What doesn't exist yet  
Foraging, overworld, combat, attention, weight, treats, journal UI in  
game, regions, the walking bar, any art or audio.

\---

\#\# 3\. BUILD ORDER & PROGRESS

1\. ✅ Project skeleton, autoloads, save system  
2\. ✅ Feast scene (riskiest system, grey-boxed first)  
3\. 🟡 Brew → serve → satisfaction — \*code complete, 1 bug\*  
4\. ⬜ Foraging and scarcity — \*\*NEXT\*\*  
5\. ⬜ Journal UI  
6\. ⬜ Levels and XP wiring  
7\. ⬜ Overworld and combat  
8\. ⬜ Attention, weight, treats  
9\. ⬜ Art

Step 4 is the important one: it makes the shelf dynamic and connects  
brew to the world. Until it exists, \`brew.gd\` seeds a fake inventory  
(marked \`\# TEMP\`).

\---

\#\# 4\. PROTOTYPES TO COMMIT

These were built and played in chat. They are the proof of what works —  
worth keeping even after the Godot versions exist.

| Suggested file | Proves |  
|---|---|  
| \`tools/prototypes/feast.html\` | Turn-based chase, binge-burn rhythm, doorway jam |  
| \`tools/prototypes/brew.html\` | Request matching across four archetypes |  
| \`tools/prototypes/journal.html\` | Discovery loop, persistent reference |  
| \`tools/prototypes/scarcity.html\` | Tag coverage as the real constraint |  
| \`tools/prototypes/levelup.html\` | Skill-responsive difficulty |

\---

\#\# 5\. DEV LOG

\#\#\# 2026-10-15 — Design lock  
\- Full design doc written and locked at \`docs/design.md\` v4.  
\- Three loops, four request archetypes, weight/attention economy,  
  walking bar, level curve, journal, feast format all specified.  
\- Four prototypes played and iterated. Each surfaced one real flaw that  
  was fixed before any engine work:  
  \- Hidden spec behind "surprise me" → wildcard became its own archetype  
  \- Scarcity too tight (two constraints at once) → coverage-only, plus  
    a Wellwater diluent  
  \- Feasts unplayable in real time → turn-based escape puzzle

\#\#\# 2026-10-15 — Build steps 1 and 2  
\- Repo created, made public, \`.gitignore\` for Godot 4\.  
\- Skeleton committed: \`project.godot\` with 5 autoloads and input map,  
  four autoload singletons, folder tree.  
\- Feast scene committed and running. Pure logic split from the view so  
  it's testable headless. Doorway jam is one line in \`step\_patron()\`.

\#\#\# 2026-10-15 — Build step 3  
\- Brew data layer, scoring, and scene written.  
\- Full repo audit run; one bug outstanding (see §1).

\---

\#\# 6\. CONVENTIONS

\*\*GDScript\*\*  
\- Parameters prefixed \`p\_\` — never shadow a member variable.  
\- \*\*Prefer untyped \`Array\` over \`Array\[String\]\`\*\* for literal data.  
  Type the function boundary, not the storage.  
\- Pure logic in \`RefCounted\` classes with no node dependencies  
  (\`BrewCalculator\`, \`FeastGrid\`, \`FeastController\`, \`FeastPatron\`).  
  Views subscribe via signals; nothing polls.  
\- Signals over direct calls for anything the UI reacts to.

\*\*Commits\*\*  
\- Commit a \*\*whole file set together\*\*. Half-applied sets have caused  
  both bugs so far.  
\- Write real messages — \`add wildcard scoring\`, not \`update\`. The  
  history becomes a searchable decision log.

\*\*Never commit\*\*  
\- \`.godot/\` cache, exports, build output.

\---

\#\# 7\. GODOT 4 GOTCHAS (learned the hard way)

1\. \*\*\`add\_child()\` returns \`void\`.\*\* You cannot chain  
   \`parent.add\_child(Label.new()).text \= "x"\`. Create, set, then add.  
2\. \*\*Typed arrays don't implicitly convert.\*\* Passing an untyped \`Array\`  
   literal into an \`Array\[String\]\` parameter fails at the call boundary  
   with \`Cannot convert argument N from Array to Array\`.  
3\. \*\*Parameter names shadow member names.\*\* \`func make(kind: Kind)\`  
   with a \`var kind\` member is an error, not a warning.  
4\. \*\*Stale class cache.\*\* If a script change doesn't take effect, close  
   Godot and delete \`.godot/\`. It's gitignored and regenerates.

\---

\#\# 8\. WORKING NOTES

\- The assistant can \*\*read\*\* the public repo but cannot write to it.  
  It fetches files over the web. Workflow: assistant produces complete  
  files with explicit paths → paste → commit.  
\- Ask for \*\*full files, never diffs\*\* — no manual reconciliation.  
\- When a bug appears, pasting the exact error text is fastest.  
\- The assistant can audit the repo directly, so it's worth asking for a  
  check after any batch of changes.

\---

\#\# 9\. SESSION TEMPLATE

Copy this in when starting a session:  
Resuming MOONSWILL. Repo: github.com/drinkup-productions/moonswill  
Design: docs/design.md (v4 FINAL — source of truth)  
Dev log: docs/devlog.md — read §1 RESUME HERE first.  
Doing today:  
Blocked on:  
