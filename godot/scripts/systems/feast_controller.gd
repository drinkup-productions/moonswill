class_name FeastController
extends RefCounted
## Turn-based feast resolution. Pure logic; the view drives it.
## Design ref: docs/design.md §6.5

signal patron_caught(p: FeastPatron)
signal patron_escaped(p: FeastPatron)
signal state_changed()
signal feast_ended(caught: int, escaped: int)

const BASE_TURNS := 12

var grid: FeastGrid
var patrons: Array[FeastPatron] = []
var chugs_cell: Vector2i = Vector2i.ZERO
var turns_left: int = BASE_TURNS
var ap: int = 6
var ap_max: int = 6
var resolved: bool = false
var finished: bool = false


func _init(p_grid: FeastGrid, p_action_points: int) -> void:
	grid = p_grid
	ap_max = maxi(2, p_action_points)
	ap = ap_max


func register_patron(p: FeastPatron) -> void:
	patrons.append(p)


func occupied(cell: Vector2i) -> bool:
	if cell == chugs_cell:
		return true
	for p in patrons:
		if p.is_active() and p.cell == cell:
			return true
	return false


func patron_at(cell: Vector2i) -> FeastPatron:
	for p in patrons:
		if p.is_active() and p.cell == cell:
			return p
	return null


func can_act() -> bool:
	return not resolved and not finished and ap > 0


## Chugs steps. Moving onto a patron catches them. Returns true if he moved.
func try_move(dir: Vector2i) -> bool:
	if not can_act():
		return false
	var to := chugs_cell + dir
	if not grid.in_bounds(to) or grid.is_blocked(to):
		return false

	var target := patron_at(to)
	if target != null:
		chugs_cell = to
		ap -= 1
		target.state = FeastPatron.State.CAUGHT
		patron_caught.emit(target)
		state_changed.emit()
		return true

	if occupied(to):
		return false
	chugs_cell = to
	ap -= 1
	state_changed.emit()
	return true


## Advance one patron one step along its route. Returns true if it moved.
func step_patron(p: FeastPatron) -> bool:
	if not p.is_active():
		return false
	var path := grid.path_to_exit(p.cell)
	if path.size() < 2:
		p.state = FeastPatron.State.ESCAPED
		patron_escaped.emit(p)
		return true

	var nxt := path[1]
	if occupied(nxt):
		return false          # jammed — this is the doorway tactic
	p.cell = nxt
	if grid.is_exit(p.cell):
		p.state = FeastPatron.State.ESCAPED
		patron_escaped.emit(p)
	return true


func begin_turn() -> void:
	resolved = false
	ap = ap_max
	state_changed.emit()


func end_turn() -> void:
	resolved = true
	state_changed.emit()


func finish_turn() -> void:
	if finished:
		return
	turns_left -= 1
	var caught := 0
	var escaped := 0
	var active := 0
	for p in patrons:
		match p.state:
			FeastPatron.State.CAUGHT:
				caught += 1
			FeastPatron.State.ESCAPED:
				escaped += 1
			_:
				active += 1
	if turns_left <= 0 or active == 0:
		finished = true
		feast_ended.emit(caught, escaped)


func result_line() -> String:
	var caught := 0
	var escaped := 0
	for p in patrons:
		if p.state == FeastPatron.State.CAUGHT:
			caught += 1
		elif p.state == FeastPatron.State.ESCAPED:
			escaped += 1
	if escaped == 0:
		return "Clean sweep. Chugs is stuffed."
	if caught == 0:
		return "Everyone got out. A weak month ahead."
	return "Feast over — %d eaten, %d escaped." % [caught, escaped]