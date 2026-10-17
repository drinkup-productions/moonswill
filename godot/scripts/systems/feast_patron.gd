class_name FeastPatron
extends RefCounted
## A patron during the feast. Design ref: §6.5
## Frozen patrons do not run; immobilised ones cannot. There is no
## "willing" category any more.

enum State { WAITING, CAUGHT, ESCAPED }

var id: String = ""
var display_name: String = ""
var species: String = ""
var cell: Vector2i = Vector2i.ZERO
var transform: Transform
var frozen: bool = false
var state: State = State.WAITING


func _init() -> void:
	transform = Transform.new()


func speed() -> int:
	if frozen:
		return 0
	var s := transform.silhouette()
	if s >= 5:
		return 0
	if s >= 4:
		return 1
	if s >= 2:
		return 2
	return 3


func is_active() -> bool:
	return state == State.WAITING


func turns_to_escape(grid: FeastGrid) -> int:
	var spd := speed()
	if spd <= 0:
		return 999
	var path := grid.path_to_exit(cell)
	if path.size() < 2:
		return 0
	return ceili(float(path.size() - 1) / float(spd))


## Legacy 0-100 demo scale, derived so the old thresholds land where they did.
func set_legacy_transformation(p_value: int) -> void:
	transform.points["belly"] = int(round(float(p_value) * 6.0 / 17.0))