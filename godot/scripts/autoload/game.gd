extends Node
## Global run state. Autoloaded as `Game`.

signal phase_changed(phase: int)
signal day_advanced(day: int)
signal weight_changed(weight: int)
signal attention_changed(attention: int)
signal roster_ready(roster: Array)
signal relocated(region: String)

enum Phase { FORAGE, BREW, SERVICE, FEAST, RESOLVE }

const WEIGHT_MAX := 100
const ATTENTION_MAX := 100
const WELLWATER_STOCK := 99
const AUTOSAVE_SLOT := 1
const STEPS_PER_EXERTION := 3
const MOON_DAYS := 7            # §13: the slice is one lunar week
const BULK_PER_STAGE := 20      # weight points per visible bulk stage

const REGIONS := ["home", "the downs", "the fens"]

var day: int = 1
var moon_day: int = 1
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

var steps_left: int = 0
var step_count: int = 0
var overworld_cell: Vector2i = Vector2i(-1, -1)

## Skipping a feeding is the only thing that brings attention down. §6.6
var weakened_days: int = 0
var feasted_this_moon: bool = false


func start_day() -> void:
	roster = PatronFactory.build_night(day, patron_count())
	forage = ForageMap.build(
		day, spots_offered(), Levels.yield_per_search(), needed_tags(), IngredientDB
	)
	# Weakened foraging is the price of a skipped feeding. §6.6
	searches_left = maxi(1, Levels.searches() - (1 if weakened_days > 0 else 0))
	taste_tests_left = Levels.taste_tests_per_day()
	steps_left = steps_per_day()
	step_count = 0
	overworld_cell = Vector2i(-1, -1)
	top_up_wellwater()
	roster_ready.emit(roster)
	set_phase(Phase.FORAGE)


func patron_count() -> int:
	return 4 if Levels.level < 3 else 5


func spots_offered() -> int:
	return Levels.searches() + 3


## Fat means fewer trips. The spiral, mechanised. §6.10
func steps_per_day() -> int:
	return maxi(8, 36 - int(floor(float(weight) / 3.0)))


func spend_step() -> bool:
	if steps_left <= 0:
		return false
	steps_left -= 1
	step_count += 1
	if step_count % STEPS_PER_EXERTION == 0:
		add_weight(-1)
	return true


## Weight buckets into a stage for art and attention. §6.9, §6.10
func bulk_stage() -> int:
	return clampi(int(floor(float(weight) / float(BULK_PER_STAGE))), 0, 5)


## Concealment masks a stage, and level 7 masks two. §6.10
func visible_bulk() -> int:
	return maxi(0, bulk_stage() - Levels.conceal_stages())


func is_full_moon() -> bool:
	return moon_day >= MOON_DAYS


func is_weakened() -> bool:
	return weakened_days > 0


## The sink. Costs attention, costs two days of sharp foraging, and costs
## the ability to refuse treats — which fattens him, which raises attention.
## Self-balancing. §6.6
func skip_feast() -> void:
	add_attention(-8)
	weakened_days = 2
	feasted_this_moon = false


func register_feast_result(p_caught: int, p_escaped: int) -> void:
	add_attention(p_caught * 2)
	add_weight(p_caught)
	feasted_this_moon = true


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
	moon_day += 1
	if moon_day > MOON_DAYS:
		moon_day = 1
		feasted_this_moon = false
	if weakened_days > 0:
		weakened_days -= 1
	stock_today.clear()
	day_advanced.emit(day)
	daily_attention_tick()
	start_day()
	Save.save_game(AUTOSAVE_SLOT)


## Visible weight is the passive attention source. §6.6
func daily_attention_tick() -> void:
	var v := visible_bulk()
	var rise := 0
	if v >= 4:
		rise = 3
	elif v >= 2:
		rise = 2
	elif v >= 1:
		rise = 1
	if rise > 0:
		add_attention(rise)


func add_weight(n: int) -> void:
	weight = clampi(weight + n, 0, WEIGHT_MAX)
	weight_changed.emit(weight)


func add_attention(n: int) -> void:
	attention = clampi(attention + n, 0, ATTENTION_MAX)
	attention_changed.emit(attention)
	if attention >= ATTENTION_MAX:
		relocate()


## No death, no banishment, ever. The bar simply walks. §6.7
func relocate() -> void:
	var i := REGIONS.find(region)
	region = REGIONS[(i + 1) % REGIONS.size()]
	attention = 0
	attention_changed.emit(attention)
	relocated.emit(region)


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


## Defeat costs half the pack, rounded against the player. §8
func lose_half_inventory() -> void:
	for id in inventory.keys():
		if id == "wellwater":
			continue
		var n: int = int(inventory[id])
		var keep := int(floor(float(n) / 2.0))
		if keep <= 0:
			inventory.erase(id)
		else:
			inventory[id] = keep


func reset_run() -> void:
	day = 1
	moon_day = 1
	region = "home"
	weight = 0
	attention = 0
	weakened_days = 0
	feasted_this_moon = false
	inventory.clear()
	stock_today.clear()
	Levels.reset()
	Journal.reset()
	Journal.seed_starter()
	start_day()