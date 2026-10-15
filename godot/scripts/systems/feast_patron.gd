class_name FeastPatron
extends RefCounted
## A patron during the feast.

enum State { WAITING, CAUGHT, ESCAPED }

var id: String = ""
var display_name: String = ""
var species: String = ""
var cell: Vector2i = Vector2i.ZERO
var transformation: int = 0        # 0-100
var willing: bool = false
var state: State = State.WAITING


## Design ref §6.5 — transformations slow escape. Willing patrons don't run.
func speed() -> int:
	if willing:
		return 0
	if transformation >= 68:
		return 1
	if transformation >= 34:
		return 2
	return 3


func is_active() -> bool:
	return state == State.WAITING


## Turns until this patron reaches an exit, for the planning forecast.
func turns_to_escape(grid: FeastGrid) -> int:
	var spd := speed()
	if spd <= 0:
		return 999
	var path := grid.path_to_exit(cell)
	if path.size() < 2:
		return 0
	return ceili(float(path.size() - 1) / float(spd))