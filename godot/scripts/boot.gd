extends Node
## Entry point. Resumes the autosave if there is one, otherwise starts fresh.

const FORAGE_SCENE := "res://scenes/forage/forage.tscn"


func _ready() -> void:
	assert(Game != null and Save != null and Journal != null and Levels != null)

	if Save.has_save(Game.AUTOSAVE_SLOT):
		Save.load_game(Game.AUTOSAVE_SLOT)
		print("Moonswill — resumed day %d." % Game.day)
	else:
		Journal.seed_starter()
		print("Moonswill — new run. Level %d, %d searches." % [Levels.level, Levels.searches()])

	Game.start_day()   # roster and spots are rebuilt, not saved
	# Later: swap to res://scenes/main_menu.tscn here.
	get_tree().change_scene_to_file(FORAGE_SCENE)