extends Node
## Global run state. Autoloaded as `Game`.

signal phase_changed(phase: int)
signal day_advanced(day: int)
signal weight_changed(weight: int)
signal attention_changed(attention: int)
signal roster_ready(roster: Array)

enum Phase { FORAGE, BREW, SERVICE, FEAST, RESOLVE }

const WEIGHT_MAX := 100
const ATTENTION_MAX := 100
const WELLWATER_STOCK := 99
const AUTOSAVE_SLOT := 1

var day: int = 1
var region: String = "home"
var phase: Phase = Phase.FORAGE
var weight: int = 0
var attention: int = 0
var inventory: Dictionary = {}          # String ingredient_id -> int count
var stock_today: Array[String] = []     # what was foraged today

var roster: Array = []                  # Array[Patron] — tonight's customers
var forage: ForageMap = null            # today's spots
var searches_left: int = 0
var taste_tests_left: int = 0


## Builds a fresh day: roster, spots, search budget. Called by boot and by
## advance_day. Autoload order puts IngredientDB last, so this must not run
## from _ready(). §6.14
func start_day() -> void:
	roster = PatronFactory.build_night(day, patron_count())
	forage = ForageMap.build(
		day, spots_offered(), Levels.yield_per_search(), needed_tags(), IngredientDB
	)
	searches_left = Levels.searches()
	taste_tests_left = Levels.taste_tests_per_day()
	top_up_wellwater()
	roster_ready.emit(roster)
	set_phase(Phase.FORAGE)


func patron_count() -> int:
	return 4 if Levels.level < 3 else 5


## Always offer more spots than searches, so choosing is the game. §6.14
func spots_offered() -> int:
	return Levels.searches() + 3


## Every tag that would move a requested attribute. Wildcards want nothing
## in particular. Two patrons wanting the same tag is the puzzle. §6.14
func needed_tags() -> Array:
	var out: Array = []
	if roster.is_empty():
		return out
	for p in roster:
		if p.req == null or p.req.is_wildcard():
			continue
		for a in p.req.want.keys():
			var v: int = int(p.req.want[a])
			var ts: Array = Tags.tags_raising(a) if v > 0 else Tags.tags_lowering(a)
			for t in ts:
				if not out.has(t):
					out.append(t)
	return out


## Targeted discovery. Costs one unit and one of the day's taste tests.
## Chugs reverts to his state at the start of the test, so nothing sticks —
## patron-applied effects are not covered and remain permanent. §6.4
func taste(id: String) -> String:
	if Journal.knows_ingredient(id):
		return "Already in the journal."
	if taste_tests_left <= 0:
		return "No taste tests left today."
	if not has_item(id, 1):
		return "None in the pantry."
	take_item(id, 1)
	taste_tests_left -= 1
	var ing: Ingredient = IngredientDB.get_ingredient(id)
	Journal.learn_ingredient(id, ing.tags)
	return "Tasted %s — %s" % [ing.display_name, Attributes.pretty(ing.effect())]


func can_taste(id: String) -> bool:
	return taste_tests_left > 0 and not Journal.knows_ingredient(id) and has_item(id, 1)


func top_up_wellwater() -> void:
	inventory["wellwater"] = maxi(int(inventory.get("wellwater", 0)), WELLWATER_STOCK)


func spend_search() -> bool:
	if searches_left <= 0:
		return false
	searches_left -= 1
	return true


func open_the_bar() -> void:
	set_phase(Phase.SERVICE)


func set_phase(p: Phase) -> void:
	phase = p
	phase_changed.emit(p)


func advance_day() -> void:
	day += 1
	stock_today.clear()
	day_advanced.emit(day)
	start_day()
	Save.save_game(AUTOSAVE_SLOT)


func add_weight(n: int) -> void:
	weight = clampi(weight + n, 0, WEIGHT_MAX)
	weight_changed.emit(weight)


func add_attention(n: int) -> void:
	attention = clampi(attention + n, 0, ATTENTION_MAX)
	attention_changed.emit(attention)
	if attention >= ATTENTION_MAX:
		relocate()


func relocate() -> void:
	attention = 0
	attention_changed.emit(attention)
	# Region selection handled by the region system (not yet built).


func add_item(id: String, n: int = 1) -> void:
	inventory[id] = inventory.get(id, 0) + n


func take_item(id: String, n: int = 1) -> bool:
	if inventory.get(id, 0) < n:
		return false
	inventory[id] -= n
	if inventory[id] <= 0:
		inventory.erase(id)
	return true


func has_item(id: String, n: int = 1) -> bool:
	return inventory.get(id, 0) >= n


## Wipes the run, the level, and the journal. Fresh save, fresh discovery.
func reset_run() -> void:
	day = 1
	region = "home"
	weight = 0
	attention = 0
	inventory.clear()
	stock_today.clear()
	Levels.reset()
	Journal.reset()
	Journal.seed_starter()
	start_day()