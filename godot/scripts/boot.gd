extends Node
## Entry point. Validates autoloads, builds the first day, hands off to forage.

const FORAGE_SCENE := "res://scenes/forage/forage.tscn"


func _ready() -> void:
	assert(Game != null and Save != null and Journal != null and Levels != null)
	print("Moonswill — boot ok. Level %d, %d searches, %d patrons tonight." % [
		Levels.level, Levels.searches(), Game.patron_count()
	])
	Game.start_day()
	# Later: swap to res://scenes/main_menu.tscn here.
	get_tree().change_scene_to_file(FORAGE_SCENE)