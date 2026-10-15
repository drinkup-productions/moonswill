extends Node
## Global run state. Autoloaded as `Game`.

signal phase_changed(phase: int)
signal day_advanced(day: int)
signal weight_changed(weight: int)
signal attention_changed(attention: int)

enum Phase { FORAGE, BREW, SERVICE, FEAST, RESOLVE }

const WEIGHT_MAX := 100
const ATTENTION_MAX := 100

var day: int = 1
var region: String = "home"
var phase: Phase = Phase.FORAGE
var weight: int = 0
var attention: int = 0
var inventory: Dictionary = {}          # String ingredient_id -> int count
var stock_today: Array[String] = []     # what was foraged today


func set_phase(p: Phase) -> void:
	phase = p
	phase_changed.emit(p)


func advance_day() -> void:
	day += 1
	stock_today.clear()
	set_phase(Phase.FORAGE)
	day_advanced.emit(day)


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


func reset_run() -> void:
	day = 1
	region = "home"
	weight = 0
	attention = 0
	inventory.clear()
	stock_today.clear()
	set_phase(Phase.FORAGE)