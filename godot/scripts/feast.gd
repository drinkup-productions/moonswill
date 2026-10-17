extends Node2D
## Grey-box feast scene. Draws everything; no art assets required.
## Design ref: docs/design.md §6.5
## Patrons arrive already dosed — that is the whole strategy. There is no
## "willing" category; everyone rolls to freeze, and the immobilised cannot run.

const TILE := 48
const FORAGE_SCENE := "res://scenes/forage/forage.tscn"
const FREEZE_BASE := 0.45
const FREEZE_PER_STAGE := 0.07

var grid: FeastGrid
var ctrl: FeastController
var rng := RandomNumberGenerator.new()
var status: Label
var hint: Label
var busy := false
var sources := {}          # feast patron id -> the cast member behind it


func _ready() -> void:
	rng.randomize()
	grid = FeastGrid.new(FeastLayouts.BAR_MAIN)
	ctrl = FeastController.new(grid, Levels.feast_action_points())
	ctrl.chugs_cell = Vector2i(7, 7)
	_spawn_patrons()
	_roll_freeze()

	ctrl.state_changed.connect(_refresh)
	ctrl.patron_caught.connect(_on_caught)
	ctrl.patron_escaped.connect(_on_escaped)
	ctrl.feast_ended.connect(_on_ended)

	_build_hud()
	_refresh()


func _free_cells() -> Array:
	var out: Array = []
	for y in grid.h:
		for x in grid.w:
			var c := Vector2i(x, y)
			if not grid.is_blocked(c) and not grid.is_exit(c) and c != ctrl.chugs_cell:
				out.append(c)
	out.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		if a.y == b.y:
			return a.x < b.x
		return a.y < b.y
	)
	return out


func _spawn_patrons() -> void:
	var seeds: Array = Game.roster if not Game.roster.is_empty() else _demo_roster()
	var free := _free_cells()
	if free.is_empty():
		return
	var step := maxi(1, int(free.size() / maxi(1, seeds.size() + 1)))
	var taken := {}
	for i in seeds.size():
		var source: Patron = seeds[i]
		var fp := FeastPatron.new()
		fp.id = str(source.id)
		fp.display_name = str(source.name)
		fp.species = str(source.species)
		fp.transform.deserialize(source.transform.serialize())
		var idx := mini(free.size() - 1, step * (i + 1))
		while taken.has(idx) and idx < free.size() - 1:
			idx += 1
		taken[idx] = true
		fp.cell = free[idx]
		sources[fp.id] = source
		ctrl.register_patron(fp)


## Everyone rolls. The immobilised do not get to. §6.5
func _roll_freeze() -> void:
	for fp in ctrl.patrons:
		var stage := fp.transform.silhouette()
		if stage >= 5:
			fp.frozen = true
		else:
			fp.frozen = rng.randf() < (FREEZE_BASE - float(stage) * FREEZE_PER_STAGE)


func _demo_roster() -> Array:
	var out: Array = []
	var specs := [
		["Bess", "bovine", 60], ["Rill", "felinid", 20], ["Gorst", "equine", 45],
		["Nim", "human", 0], ["Pim", "lizard-folk", 85],
	]
	for s in specs:
		var p := Patron.make(str(s[0]), str(s[1]))
		p.id = "demo:%s" % str(s[0])
		p.transform.points["belly"] = int(round(float(s[2]) * 6.0 / 17.0))
		out.append(p)
	return out


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


func _speed_report() -> String:
	var parts: Array[String] = []
	for p in ctrl.patrons:
		if p.is_active():
			parts.append("%s %d%s" % [p.display_name, p.speed(), " (frozen)" if p.frozen else ""])
	return ", ".join(parts)


func _unhandled_input(event: InputEvent) -> void:
	if busy or ctrl.finished or ctrl.resolved:
		return

	if event.is_action_pressed("confirm"):
		_end_turn()
		return

	if not ctrl.can_act():
		return

	if event.is_action_pressed("move_up"):
		_move(Vector2i.UP)
	elif event.is_action_pressed("move_down"):
		_move(Vector2i.DOWN)
	elif event.is_action_pressed("move_left"):
		_move(Vector2i.LEFT)
	elif event.is_action_pressed("move_right"):
		_move(Vector2i.RIGHT)


func _move(dir: Vector2i) -> void:
	if not ctrl.try_move(dir):
		return
	queue_redraw()
	if ctrl.ap <= 0 and not busy:
		_end_turn()


func _end_turn() -> void:
	if busy or ctrl.finished or ctrl.resolved:
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
	if sources.has(p.id):
		sources[p.id].reset_body()      # body resets, clothes come back. §6.5


func _on_escaped(p: FeastPatron) -> void:
	hint.text = "%s got away." % p.display_name


func _on_ended(caught: int, escaped: int) -> void:
	Game.register_feast_result(caught, escaped)
	hint.text = "%s   Eaten %d, escaped %d.   Press R to open tomorrow." % [
		ctrl.result_line(), caught, escaped
	]


func _refresh() -> void:
	status.text = "Turns left: %d     AP: %d/%d     speeds: %s" % [
		ctrl.turns_left, ctrl.ap, ctrl.ap_max, _speed_report()
	]
	if ctrl.ap <= 0 and not ctrl.finished and not ctrl.resolved:
		hint.text = "Out of action points — ending the turn. SPACE to end early."
	queue_redraw()


func _draw() -> void:
	for y in grid.h:
		for x in grid.w:
			var cell := Vector2i(x, y)
			var rect := Rect2(Vector2(x, y) * TILE, Vector2(TILE, TILE))
			draw_rect(rect, _tile_color(grid.tile_at(cell)))

	# escape routes, for anyone who will actually run
	for p in ctrl.patrons:
		if not p.is_active() or p.frozen:
			continue
		var path := grid.path_to_exit(p.cell)
		for step in path:
			draw_circle(Vector2(step) * TILE + Vector2(TILE, TILE) * 0.5, 3.0, Color(1, 1, 1, 0.22))

	# patrons
	for p in ctrl.patrons:
		if not p.is_active():
			continue
		var centre := Vector2(p.cell) * TILE + Vector2(TILE, TILE) * 0.5
		var radius := 12.0 + float(p.transform.silhouette()) * 2.0
		draw_circle(centre, radius, _patron_color(p))
		if p.frozen:
			draw_arc(centre, radius + 5.0, 0.0, TAU, 24, Color(0.55, 0.75, 1.0), 2.0)

	var cc := Vector2(ctrl.chugs_cell) * TILE + Vector2(TILE, TILE) * 0.5
	draw_circle(cc, 14.0 + float(Game.weight) / 14.0, Color(0.66, 0.33, 0.97))


func _tile_color(t: String) -> Color:
	match t:
		"#": return Color(0.08, 0.08, 0.10)
		"T": return Color(0.36, 0.27, 0.15)
		"D": return Color(0.09, 0.40, 0.20)
		_:   return Color(0.16, 0.16, 0.20)


func _patron_color(p: FeastPatron) -> Color:
	if p.frozen:
		return Color(0.42, 0.62, 0.88)
	match p.species:
		"bovine":      return Color(0.96, 0.62, 0.04)
		"felinid":     return Color(0.08, 0.72, 0.65)
		"equine":      return Color(0.94, 0.27, 0.27)
		"human":       return Color(0.23, 0.51, 0.96)
		"canid":       return Color(0.72, 0.46, 0.20)
		"lizard-folk": return Color(0.40, 0.72, 0.28)
		_:             return Color(0.60, 0.60, 0.65)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		if ctrl.finished:
			Game.advance_day()
			get_tree().change_scene_to_file(Game.next_scene())
		else:
			get_tree().reload_current_scene()