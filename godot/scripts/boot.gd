extends Node
## Entry point. Validates autoloads, then hands off.

func _ready() -> void:
	assert(Game != null and Save != null and Journal != null and Levels != null)
	print("Moonswill — boot ok. Level %d, %d searches." % [
		Levels.level, Levels.searches()
	])
	Game.set_phase(Game.Phase.FORAGE)
	# Later: swap to res://scenes/main_menu.tscn here.