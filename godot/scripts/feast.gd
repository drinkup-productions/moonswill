extends Node2D
## Grey-box feast scene. Draws everything; no art assets required.
## Design ref: docs/design.md §6.5

const TILE := 48

var grid: FeastGrid
var ctrl: FeastController
var status: Label
var hint: Label
var busy := false


func _ready() -> void:
	grid = FeastGrid.new(FeastLayouts.BAR_MAIN)
	ctrl = FeastController.new(grid, Levels.feast_action_points())
	ctrl.chugs_cell = Vector2i(7, 7)
	_spawn_patrons()

	ctrl.state_changed.connect(_refresh)
	ctrl.patron_caught.connect(_on_caught)
	ctrl.patron_escaped.connect(_on_escaped)
	ctrl.feast_ended.connect(_on_ended)

	_build_hud()
	_refresh()


func _spawn_patrons() -> void:
	var data := [
		{"id": "bess",  "name": "Bess",  "species": "bovine",      "cell": Vector2i(2, 2),  "tf": 60, "willing": false},
		{"id": "rill",  "name": "Rill",  "species": "felinid",     "cell": Vector2i(12, 2), "tf": 20, "willing": false},
		{"id": "gorst", "name": "Gorst", "species": "equine",      "cell": Vector2i(2, 5),  "tf": 45, "willing": false},
		{"id": "nim",   "name": "Nim",   "species": "human",       "cell": Vector2i(12, 5), "tf": 0,  "willing": false},
		{"id": "pim",   "name": "Pim",   "species": "lizard-folk", "cell": Vector2i(7, 4),  "tf": 85, "willing": true},
	]
	for d in data:
		var p := FeastPatron.new()
		p.id = d.id
		p.display_name = d.name
		p.species = d.species
		p.cell = d.cell
		p.transformation = d.tf
		p.willing = d.willing
		ctrl.register_patron(p)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	status = Label.new()
	status.position = Vector2(16, 12)
	layer.add_child(status)

	hint = Label.new()
	hint.position = Vector2(16, grid.h * TILE + 16)
	layer.add_child(hint)
	hint.text = "WASD / arrows to move (1 AP per step) — walk onto a patron to eat them. SPACE to end turn."


func _unhandled_input(event: InputEvent) -> void:
	if busy or not ctrl.can_act():
		return
	if event.is_action_pressed("move_up"):    _move(Vector2i.UP)
	elif event.is_action_pressed("move_down"):  _move(Vector2i.DOWN)
	elif event.is_action_pressed("move_left"):  _move(Vector2i.LEFT)
	elif event.is_action_pressed("move_right"): _move(Vector2i.RIGHT)
	elif event.is_action_pressed("confirm"):    _end_turn()


func _move(dir: Vector2i) -> void:
	if ctrl.try_move(dir):
		queue_redraw()


func _end_turn() -> void:
	if busy or ctrl.finished:
		return
	busy = true
	ctrl.end_turn()

	for p in ctrl.patrons:
		for i in p.speed():
			if not p.is_active():
				break
			ctrl.step_patron(p)
			queue_redraw()
			await get_tree().create_timer(0.07).timeout

	ctrl.finish_turn()
	busy = false
	if not ctrl.finished:
		ctrl.begin_turn()
	_refresh()


func _on_caught(p: FeastPatron) -> void:
	hint.text = "Ate %s." % p.display_name


func _on_escaped(p: FeastPatron) -> void:
	hint.text = "%s got away." % p.display_name


func _on_ended(caught: int, escaped: int) -> void:
	hint.text = "%s   Eaten %d, escaped %d. Press R to restart." % [ctrl.result_line(), caught, escaped]


func _refresh() -> void:
	status.text = "Turns left: %d     AP: %d/%d" % [ctrl.turns_left, ctrl.ap, ctrl.ap_max]
	queue_redraw()


func _draw() -> void:
	for y in grid.h:
		for x in grid.w:
			var cell := Vector2i(x, y)
			var rect := Rect2(Vector2(x, y) * TILE, Vector2(TILE, TILE))
			draw_rect(rect, _tile_color(grid.tile_at(cell)))

	# escape routes
	for p in ctrl.patrons:
		if not p.is_active() or p.willing:
			continue
		var path := grid.path_to_exit(p.cell)
		for step in path:
			draw_circle(Vector2(step) * TILE + Vector2(TILE, TILE) * 0.5, 3.0, Color(1, 1, 1, 0.22))

	# patrons
	for p in ctrl.patrons:
		if not p.is_active():
			continue
		var centre := Vector2(p.cell) * TILE + Vector2(TILE, TILE) * 0.5
		var radius := 12.0 + float(p.transformation) / 12.0
		draw_circle(centre, radius, _patron_color(p))
		if p.willing:
			draw_arc(centre, radius + 5.0, 0.0, TAU, 24, Color.WHITE, 2.0)

	# chugs
	var cc := Vector2(ctrl.chugs_cell) * TILE + Vector2(TILE, TILE) * 0.5
	draw_circle(cc, 14.0 + float(Game.weight) / 14.0, Color(0.66, 0.33, 0.97))


func _tile_color(t: String) -> Color:
	match t:
		"#": return Color(0.08, 0.08, 0.10)
		"T": return Color(0.36, 0.27, 0.15)
		"D": return Color(0.09, 0.40, 0.20)
		_:   return Color(0.16, 0.16, 0.20)


func _patron_color(p: FeastPatron) -> Color:
	if p.willing:
		return Color(0.13, 0.72, 0.45)
	match p.species:
		"bovine":  return Color(0.96, 0.62, 0.04)
		"felinid": return Color(0.08, 0.72, 0.65)
		"equine":  return Color(0.94, 0.27, 0.27)
		"human":   return Color(0.23, 0.51, 0.96)
		_:         return Color(0.60, 0.60, 0.65)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		get_tree().reload_current_scene()
