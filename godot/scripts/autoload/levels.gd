extends Node
## XP and level curve. Autoloaded as `Levels`.
## Design ref: docs/design.md §6.16 — levels buy capability, never volume.
## No XP is ever paid for eating. Leveling is purely a brewing measure.

signal level_gained(level: int)

const MAX_LEVEL := 10
const XP_FLOOR := 80            # a bad night still progresses

const BASE_SEARCHES := 5
const BASE_YIELD := 4
const BASE_VAT := 3
const BASE_TASTE := 1
const BASE_CONCEAL := 1
const BASE_FEAST_AP := 6

## §6.16's reward table, verbatim. One row per level. Nothing is derived
## from a formula, so the doc and the code cannot drift apart.
const REWARDS := {
	2:  {"text": "+1 search per day",              "search": 1},
	3:  {"text": "+1 ingredient per search",       "yield": 1},
	4:  {"text": "a fourth vat slot",              "vat": 1},
	5:  {"text": "a second taste test per day",    "taste": 1},
	6:  {"text": "+1 search per day",              "search": 1},
	7:  {"text": "conceal one extra weight stage", "conceal": 1},
	8:  {"text": "+1 ingredient per search",       "yield": 1},
	9:  {"text": "+1 feast action point",          "feast_ap": 1},
	10: {"text": "a new recipe family",            "recipe": 1},
}

var level: int = 1
var xp: int = 0


func xp_needed(p_level: int = level) -> int:
	return 180 + (p_level - 1) * 120


## Sum of one reward key across every level already reached.
func _bonus(key: String) -> int:
	var n := 0
	for l in REWARDS.keys():
		if int(l) <= level:
			n += int(REWARDS[l].get(key, 0))
	return n


func searches() -> int:
	return BASE_SEARCHES + _bonus("search")


func yield_per_search() -> int:
	return BASE_YIELD + _bonus("yield")


func vat_slots() -> int:
	return BASE_VAT + _bonus("vat")


func taste_tests_per_day() -> int:
	return BASE_TASTE + _bonus("taste")


## Weight stages hidden by loose clothing. Consumed by §6.10 when it lands.
func conceal_stages() -> int:
	return BASE_CONCEAL + _bonus("conceal")


func recipe_family_unlocked() -> bool:
	return _bonus("recipe") > 0


## Fat is a tank build, not a penalty — but it costs action points. §6.10
func feast_action_points() -> int:
	var base := BASE_FEAST_AP + _bonus("feast_ap")
	return maxi(2, base - int(floor(Game.weight / 25.0)))


func reward_text(p_level: int) -> String:
	if not REWARDS.has(p_level):
		return "nothing"
	return REWARDS[p_level]["text"]


func progress_text() -> String:
	if level >= MAX_LEVEL:
		return "Lv %d (max)" % level
	return "Lv %d — %d/%d xp" % [level, xp, xp_needed()]


## Pays XP on total satisfaction. Returns the levels actually reached, so
## the caller can announce each one. §6.16
func award(total_satisfaction: int) -> Array:
	xp += maxi(XP_FLOOR, total_satisfaction)
	var reached: Array = []
	while level < MAX_LEVEL and xp >= xp_needed():
		xp -= xp_needed()
		level += 1
		reached.append(level)
		level_gained.emit(level)
	return reached


func reset() -> void:
	level = 1
	xp = 0