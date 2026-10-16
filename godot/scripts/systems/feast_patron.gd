class_name FeastPatron
extends RefCounted
## A patron during the feast. Design ref: §6.5
## Transformation lives in a shared Transform, so the feast and combat use
## one ladder rather than two. §6.9

enum State { WAITING, CAUGHT, ESCAPED }

var id: String = ""
var display_name: String = ""
var species: String = ""
var cell: Vector2i = Vector2i.ZERO
var transform: Transform
var willing: bool = false
var state: State = State.WAITING


func _init() -> void:
	transform = Transform.new()


## §6.5 — transformations slow escape. Willing patrons do not run.
func speed() -> int:
	if willing:
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


## Turns until this patron reaches an exit, for the planning forecast.
func turns_to_escape(grid: FeastGrid) -> int:
	var spd := speed()
	if spd <= 0:
		return 999
	var path := grid.path_to_exit(cell)
	if path.size() < 2:
		return 0
	return ceili(float(path.size() - 1) / float(spd))


## Legacy 0-100 demo scale. Derived from the old speed thresholds rather
## than tuned: 34 must land on stage 2 and 68 on stage 4, so 12/34 = 6/17.
## Points = tf * 6/17. This reproduces the old ladder by construction.
func set_legacy_transformation(p_value: int) -> void:
	transform.points["belly"] = int(round(float(p_value) * 6.0 / 17.0))