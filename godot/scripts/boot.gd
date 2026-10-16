extends Node
## Entry point. Resumes the autosave if there is one, otherwise starts fresh.

const FORAGE_SCENE := "res://scenes/forage/forage.tscn"


func _ready() -> void:
	assert(Game != null and Save != null and Journal != null and Levels != null)

	if not Save.load_and_resume(Game.AUTOSAVE_SLOT):
		Journal.seed_starter()
		Game.start_day()
		print("Moonswill — new run. Level %d, %d searches." % [Levels.level, Levels.searches()])
	else:
		print("Moonswill — resumed day %d." % Game.day)

	# Later: swap to res://scenes/main_menu.tscn here.
	get_tree().change_scene_to_file(FORAGE_SCENE)