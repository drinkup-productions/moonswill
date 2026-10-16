extends Node2D
## Grey-box overworld. One zone, locked camera, no scrolling. §6.1, §6.10
## Walking is the only thing that burns weight, and the only thing that
## finds a fight. Fat means fewer steps, which is the spiral.

const TILE := 40
const ORIGIN := Vector2(24, 76)
const ENCOUNTER_CHANCE := 0.16
const ENCOUNTER_GRACE := 3

const FORAGE_SCENE := "res://scenes/forage/forage.tscn"
const BATTLE_SCENE := "res://scenes/battle/battle.tscn"

var map: OverworldMap
var rng := RandomNumberGenerator.new()
var pos := Vector2i.ZERO
var since_encounter := 0
var busy := false

var status: Label
var hint: Label


func _ready() -> void:
	rng.randomize()
	map = OverworldMap.new()
	if Game.forage == null:
		Game.start_day()
	pos = Game.overworld_cell
	if not map.in_bounds(pos) or map.is_blocked(pos):
		pos = map.bar_cell
	Game.overworld_cell = pos
	_build_hud()
	_refresh()


func _count(d: Dictionary) -> int:
	var n := 0
	for k in d:
		n += int(d[k])
	return n


func _here() -> String:
	var t := map.tile_at(pos)
	if t == map.BAR:
		return "the bar"
	var idx := map.spot_index_at(pos)
	if idx >= 0 and idx < Game.forage.spots.size():
		return Game.forage.spots[idx]["name"]
	return "open ground"


func _unhandled_input(event: InputEvent) -> void:
	if busy:
		return
	if event.is_action_pressed("confirm"):
		_return_home()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q:
			_search_here()
			return

	var dir := Vector2i.ZERO
	if event.is_action_pressed("move_up"):
		dir = Vector2i.UP
	elif event.is_action_pressed("move_down"):
		dir = Vector2i.DOWN
	elif event.is_action_pressed("move_left"):
		dir = Vector2i.LEFT
	elif event.is_action_pressed("move_right"):
		dir = Vector2i.RIGHT
	if dir != Vector2i.ZERO:
		_step(dir)


func _step(p_dir: Vector2i) -> void:
	if Game.steps_left <= 0:
		hint.text = "Out of daylight. SPACE to head back."
		return
	var to := pos + p_dir
	if not map.in_bounds(to) or map.is_blocked(to):
		return
	pos = to
	Game.overworld_cell = pos
	Game.spend_step()
	_refresh()
	if _roll_encounter():
		_enter_battle()


func _roll_encounter() -> bool:
	since_encounter += 1
	if since_encounter < ENCOUNTER_GRACE:
		return false
	if rng.randf() >= ENCOUNTER_CHANCE:
		return false
	since_encounter = 0
	return true


func _enter_battle() -> void:
	busy = true
	get_tree().change_scene_to_file(BATTLE_SCENE)


func _search_here() -> void:
	var idx := map.spot_index_at(pos)
	if idx < 0 or idx >= Game.forage.spots.size():
		hint.text = "Nothing here to dig."
		return
	var s: Dictionary = Game.forage.spots[idx]
	if Game.searches_left <= 0:
		hint.text = "No searches left today."
		return
	var got := Game.forage.search(int(s["id"]))
	if got.is_empty():
		hint.text = "%s is picked clean." % s["name"]
		return
	Game.spend_search()
	for id in got.keys():
		Game.add_item(id, int(got[id]))
		Game.stock_today.append(id)
	hint.text = "Gathered %d from %s." % [_count(got), s["name"]]
	_refresh()


func _return_home() -> void:
	Game.overworld_cell = Vector2i(-1, -1)
	get_tree().change_scene_to_file(FORAGE_SCENE)


func _refresh() -> void:
	status.text = "Day %d     steps left %d / %d     searches left %d     weight %d     attention %d     |     %s" % [
		Game.day, Game.steps_left, Game.steps_per_day(), Game.searches_left,
		Game.weight, Game.attention, _here()
	]
	if Game.steps_left <= 0:
		hint.text = "Out of daylight. SPACE to head back."
	queue_redraw()


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	status = Label.new()
	status.position = Vector2(16, 12)
	layer.add_child(status)

	hint = Label.new()
	hint.position = Vector2(16, 42)
	layer.add_child(hint)
	hint.text = "WASD / arrows to walk · Q to dig where you stand · SPACE to head back"

	var legend := Label.new()
	legend.position = Vector2(700, 76)
	layer.add_child(legend)
	legend.text = "amber: the bar · pale: a spot · dark green: trees · blue: water\nwalking burns weight, and is where fights happen"


func _tile_color(p_t: String) -> Color:
	match p_t:
		"#": return Color(0.09, 0.20, 0.13)
		"~": return Color(0.13, 0.24, 0.40)
		"B": return Color(0.62, 0.44, 0.16)
		"S": return Color(0.34, 0.38, 0.28)
		_:   return Color(0.16, 0.26, 0.16)


func _draw() -> void:
	for y in map.h:
		for x in map.w:
			var cell := Vector2i(x, y)
			var rect := Rect2(ORIGIN + Vector2(x, y) * TILE, Vector2(TILE, TILE))
			draw_rect(rect, _tile_color(map.tile_at(cell)))

	# spot markers: scouted ones show whether they are still worth a search
	for i in map.spot_cells.size():
		if i >= Game.forage.spots.size():
			continue
		var s: Dictionary = Game.forage.spots[i]
		var centre := ORIGIN + Vector2(map.spot_cells[i]) * TILE + Vector2(TILE, TILE) * 0.5
		var picked: bool = (s["pool"] as Dictionary).is_empty()
		draw_circle(centre, 11.0, Color(0.45, 0.45, 0.38) if picked else Color(0.86, 0.80, 0.50))

	# player
	var pc := ORIGIN + Vector2(pos) * TILE + Vector2(TILE, TILE) * 0.5
	draw_circle(pc, 13.0 + float(Game.weight) / 18.0, Color(0.66, 0.33, 0.97))

	var font := ThemeDB.fallback_font
	draw_string(font, ORIGIN + Vector2(4, map.h * TILE + 20),
		"steps left: %d" % Game.steps_left, HORIZONTAL_ALIGNMENT_LEFT, -1, 14)