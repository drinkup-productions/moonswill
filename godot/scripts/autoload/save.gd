extends Node
## Multi-slot save/load. JSON in user://saves/. Autoloaded as `Save`.

const SAVE_DIR := "user://saves"
const SLOT_COUNT := 3
const VERSION := 1

signal saved(slot: int)
signal loaded(slot: int)


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func _path(slot: int) -> String:
	return "%s/slot_%d.json" % [SAVE_DIR, slot]


func has_save(slot: int) -> bool:
	return FileAccess.file_exists(_path(slot))


func save_game(slot: int) -> bool:
	var data := {
		"version": VERSION,
		"day": Game.day,
		"region": Game.region,
		"weight": Game.weight,
		"attention": Game.attention,
		"inventory": Game.inventory,
		"level": Levels.level,
		"xp": Levels.xp,
		"journal": Journal.serialize(),
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
	if not has_save(slot):
		return false
	var f := FileAccess.open(_path(slot), FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Corrupt save in slot %d" % slot)
		return false

	Game.day = int(data.get("day", 1))
	Game.region = str(data.get("region", "home"))
	Game.weight = int(data.get("weight", 0))
	Game.attention = int(data.get("attention", 0))
	Game.inventory = data.get("inventory", {})
	Levels.level = int(data.get("level", 1))
	Levels.xp = int(data.get("xp", 0))
	Journal.deserialize(data.get("journal", {}))
	loaded.emit(slot)
	return true


func delete_save(slot: int) -> void:
	if has_save(slot):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_path(slot)))