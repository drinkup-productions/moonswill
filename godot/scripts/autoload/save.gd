extends Node
## Multi-slot save/load. JSON in user://saves/. Autoloaded as `Save`.
## Slot 0 is the autosave; slots 1-3 are manual. §6.13

const SAVE_DIR := "user://saves"
const SLOT_COUNT := 3
const VERSION := 2

signal saved(slot: int)
signal loaded(slot: int)


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func _path(slot: int) -> String:
	return "%s/slot_%d.json" % [SAVE_DIR, slot]


func has_save(slot: int) -> bool:
	return FileAccess.file_exists(_path(slot))


## Header info for the slot list, without applying anything.
func slot_info(slot: int) -> Dictionary:
	if not has_save(slot):
		return {}
	var f := FileAccess.open(_path(slot), FileAccess.READ)
	if f == null:
		return {}
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	return data


func save_game(slot: int) -> bool:
	var data := {
		"version": VERSION,
		"day": Game.day,
		"moon_day": Game.moon_day,
		"region": Game.region,
		"weight": Game.weight,
		"attention": Game.attention,
		"inventory": Game.inventory,
		"affinity": Game.affinity,
		"belly_used": Game.belly_used,
		"weakened_days": Game.weakened_days,
		"feasted_this_moon": Game.feasted_this_moon,
		"level": Levels.level,
		"xp": Levels.xp,
		"journal": Journal.serialize(),
		"populations": _pack_populations(),
		"last_experiment_day": Game.last_experiment_day,
	}
	var f := FileAccess.open(_path(slot), FileAccess.WRITE)
	if f == null:
		push_error("Save failed: %s" % _path(slot))
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	saved.emit(slot)
	return true


func load_game(slot: int) -> bool:
	var data := slot_info(slot)
	if data.is_empty():
		return false

	Game.day = int(data.get("day", 1))
	Game.moon_day = int(data.get("moon_day", 1))
	Game.region = str(data.get("region", "home"))
	Game.weight = int(data.get("weight", 0))
	Game.attention = int(data.get("attention", 0))
	Game.inventory = data.get("inventory", {})
	Game.affinity = data.get("affinity", {})
	Game.belly_used = int(data.get("belly_used", 0))
	Game.weakened_days = int(data.get("weakened_days", 0))
	Game.feasted_this_moon = bool(data.get("feasted_this_moon", false))
	Game.last_experiment_day = int(data.get("last_experiment_day", -99))
	_unpack_populations(data.get("populations", {}))
	Levels.level = int(data.get("level", 1))
	Levels.xp = int(data.get("xp", 0))
	Journal.deserialize(data.get("journal", {}))
	loaded.emit(slot)
	return true


## Loading does not restore a mid-day position, so rebuild the day. Movement
## and searches reset; everything durable carries.
func load_and_resume(slot: int) -> bool:
	if not load_game(slot):
		return false
	Game.start_day()
	return true


func delete_save(slot: int) -> void:
	if has_save(slot):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_path(slot)))

func _pack_populations() -> Dictionary:
	var out := {}
	for region in Game.populations.keys():
		var arr: Array = []
		for p in Game.populations[region]:
			arr.append(p.serialize())
		out[region] = arr
	return out


func _unpack_populations(p_data: Dictionary) -> void:
	Game.populations.clear()
	for region in p_data.keys():
		var arr: Array = []
		for entry in p_data[region]:
			arr.append(Patron.from_dict(entry))
		Game.populations[region] = arr
