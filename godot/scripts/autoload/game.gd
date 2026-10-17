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
const AUTOSAVE_SLOT := 0
const STEPS_PER_EXERTION := 3
const MOON_DAYS := 15           # §13
const BULK_PER_STAGE := 20
const RESET_POTION_WEIGHT := 10
const EXPERIMENT_COOLDOWN := 7

const REGIONS := ["home", "the fens", "the high downs"]

var day: int = 1
var moon_day: int = 1
var region: String = "home"
var phase: Phase = Phase.FORAGE
var weight: int = 0
var attention: int = 0
var inventory: Dictionary = {}
var stock_today: Array[String] = []

var roster: Array = []                  # tonight's arrivals, from the population
var populations: Dictionary = {}        # region -> Array[Patron], persistent
var forage: ForageMap = null
var searches_left: int = 0
var last_experiment_day: int = -99

var steps_left: int = 0
var step_count: int = 0
var overworld_cell: Vector2i = Vector2i(-1, -1)

var weakened_days: int = 0
var feasted_this_moon: bool = false

var affinity: Dictionary = {}           # patron id -> int, persists across relocations
var belly_used: int = 0

var pending_relocation := false
var moved_this_moon := false


## The cast outlives the night, the moon and the player's absence. §6.18
func population_for(p_region: String) -> Array:
	if not populations.has(p_region):
		populations[p_region] = PatronFactory.build_population(p_region)
	return populations[p_region]


func start_day() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("moonswill-night-%d-%s" % [day, region])
	roster = PatronFactory.roll_night(
		population_for(region), patron_count(), RegionDB.strictness_for(region), rng
	)
	forage = ForageMap.build(
		day, spots_offered(), Levels.yield_per_search(), needed_tags(), IngredientDB,
		RegionDB.allowed_ingredients(region, IngredientDB)
	)
	searches_left = maxi(1, Levels.searches() - (1 if weakened_days > 0 else 0))
	steps_left = steps_per_day()
	step_count = 0
	overworld_cell = Vector2i(-1, -1)
	belly_used = 0
	top_up_wellwater()
	roster_ready.emit(roster)
	set_phase(Phase.FORAGE)


func patron_count() -> int:
	return 4 if Levels.level < 3 else 5


func spots_offered() -> int:
	return Levels.searches() + 3


## Fat means fewer trips; levelling makes the burn easier. §6.10
func steps_per_day() -> int:
	return maxi(10, 42 - int(floor(float(weight) / 3.0)))


func steps_per_exertion() -> int:
	return maxi(2, 7 - int(Levels.level / 2))


func spend_step() -> bool:
	if steps_left <= 0:
		return false
	steps_left -= 1
	step_count += 1
	if step_count % steps_per_exertion() == 0:
		add_weight(-1)
	return true


func bulk_stage() -> int:
	return clampi(int(floor(float(weight) / float(BULK_PER_STAGE))), 0, 5)


func visible_bulk() -> int:
	return maxi(0, bulk_stage() - Levels.conceal_stages())


func is_full_moon() -> bool:
	return moon_day >= MOON_DAYS


func is_weakened() -> bool:
	return weakened_days > 0


func can_experiment() -> bool:
	return day - last_experiment_day >= EXPERIMENT_COOLDOWN


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


func belly_capacity() -> int:
	return 3 + bulk_stage()


func can_accept() -> bool:
	return belly_used < belly_capacity() or is_weakened()


func can_decline() -> bool:
	return not is_weakened()


func accept_treat(p_patron: Patron) -> String:
	var t: Dictionary = p_patron.treat
	if t.is_empty():
		return ""
	add_weight(int(t["weight"]))
	belly_used += 1
	raise_affinity(p_patron.id, 1)
	p_patron.affinity = int(affinity.get(p_patron.id, 0))
	var msg := "Ate %s. +%d weight. Affinity up." % [t["dish"], int(t["weight"])]
	if bool(t.get("spiked", false)):
		var ing: Ingredient = IngredientDB.get_ingredient(str(t["brew"]))
		if ing != null:
			msg += "   Spiked with %s." % ing.display_name
	return msg


func decline_treat(p_patron: Patron) -> String:
	if p_patron.treat.is_empty():
		return ""
	raise_affinity(p_patron.id, -1)
	p_patron.affinity = int(affinity.get(p_patron.id, 0))
	return "Declined %s. Affinity down." % p_patron.treat["dish"]


func raise_affinity(p_id: String, p_delta: int) -> void:
	affinity[p_id] = clampi(int(affinity.get(p_id, 0)) + p_delta, 0, 10)


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
		moved_this_moon = false
	if weakened_days > 0:
		weakened_days -= 1
	stock_today.clear()
	day_advanced.emit(day)
	daily_attention_tick()
	start_day()
	Save.save_game(AUTOSAVE_SLOT)


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


## The cast stays behind with whatever bodies they had. §6.7, §6.18
func relocate() -> void:
	region = RegionDB.next_unlocked(region, Levels.level)
	attention = 0
	pending_relocation = true
	attention_changed.emit(attention)
	relocated.emit(region)


func next_scene() -> String:
	if pending_relocation:
		return "res://scenes/relocation/relocation.tscn"
	return "res://scenes/forage/forage.tscn"


func can_move_on() -> bool:
	if moved_this_moon:
		return false
	return RegionDB.next_unlocked(region, Levels.level) != region


func move_on() -> void:
	if not can_move_on():
		return
	moved_this_moon = true
	relocate()


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
	pending_relocation = false
	moved_this_moon = false
	last_experiment_day = -99
	affinity.clear()
	populations.clear()
	belly_used = 0
	inventory.clear()
	stock_today.clear()
	Levels.reset()
	Journal.reset()
	Journal.seed_starter()
	start_day()