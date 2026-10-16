extends Node2D
## Grey-box battle. Draws the arena and drives Battle. §8
## Keyboard only: this is a proving ground, not the final UI.

const TILE := 52
const ORIGIN := Vector2(40, 92)
const LOG_LINES := 9
#const FORAGE_SCENE := "res://scenes/forage/forage.tscn"
const RETURN_SCENE := "res://scenes/overworld/overworld.tscn"

var battle: Battle
var rng := RandomNumberGenerator.new()
var target_index := 0
var brew_index := 0
var busy := false
var lines: Array[String] = []

var status: Label
var hint: Label
var log_lbl: RichTextLabel


func _ready() -> void:
	rng.randomize()
	var enemies := EncounterTable.roll(rng, Levels.level)
	if enemies.is_empty():
		enemies = [EnemyDB.spawn("wolf", rng)]
	battle = Battle.new(BattleGrid.new(), Combatant.make_player(), enemies, rng)
	battle.log_line.connect(_on_log)
	battle.ended.connect(_on_ended)
	_build_hud()
	_on_log("Encountered %s." % _names(battle.enemies))
	_refresh()


func _names(p_list: Array) -> String:
	var out: Array[String] = []
	for c in p_list:
		out.append(c.display_name)
	return ", ".join(out)


func current_target() -> Combatant:
	var live := battle.living_enemies()
	if live.is_empty():
		return null
	target_index = clampi(target_index, 0, live.size() - 1)
	return live[target_index]


func _on_log(p_text: String) -> void:
	lines.append(p_text)
	while lines.size() > LOG_LINES:
		lines.pop_front()
	log_lbl.text = "\n".join(lines)


func _cycle_target() -> void:
	var live := battle.living_enemies()
	if live.is_empty():
		return
	target_index = (target_index + 1) % live.size()
	_refresh()


func _cycle_brew() -> void:
	if battle.player.brews.is_empty():
		_on_log("Nothing brewed to hand.")
		return
	brew_index = (brew_index + 1) % battle.player.brews.size()
	_refresh()


func _move(p_dir: Vector2i) -> void:
	if battle.player_move(p_dir):
		_refresh()
		_maybe_auto_end()


func _strike(p_slot: int) -> void:
	var t := current_target()
	if t == null:
		return
	var list := battle.player.attacks()
	if p_slot < 0 or p_slot >= list.size():
		return
	var res := battle.player_strike(t, str(list[p_slot]["id"]))
	if res.has("error"):
		_on_log("  %s" % res["error"])
	_refresh()
	_maybe_auto_end()


func _pour() -> void:
	var t := current_target()
	if t == null:
		return
	if battle.player.brews.is_empty():
		_on_log("  nothing in hand")
		return
	var res := battle.player_use_brew(brew_index, t)
	if res.has("error"):
		_on_log("  %s" % res["error"])
	if battle.player.brews.is_empty():
		brew_index = 0
	else:
		brew_index = clampi(brew_index, 0, battle.player.brews.size() - 1)
	_refresh()
	_maybe_auto_end()


func _maybe_auto_end() -> void:
	if not battle.is_over() and battle.player.ap <= 0 and not busy:
		_end_turn()


func _end_turn() -> void:
	if busy or battle.is_over() or battle.resolved:
		return
	busy = true
	battle.end_turn()
	await get_tree().create_timer(0.28).timeout
	busy = false
	_refresh()


func _disengage() -> void:
	if battle.is_over():
		return
	battle.disengage()
	_refresh()


func _leave() -> void:
	get_tree().change_scene_to_file(RETURN_SCENE)


func _on_ended(p_outcome: String, p_loot: Dictionary) -> void:
	if p_outcome == "won":
		var parts: Array[String] = []
		for id in p_loot:
			Game.add_item(id, int(p_loot[id]))
			parts.append("%s x%d" % [IngredientDB.get_ingredient(id).display_name, int(p_loot[id])])
		_on_log("Gathered: %s" % (", ".join(parts) if not parts.is_empty() else "nothing"))
	elif p_outcome == "knocked out":
		Game.lose_half_inventory()
		_on_log("Knocked out. Half the pack is gone.")
	else:
		_on_log("Disengaged.")
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if battle.is_over():
		if event.is_action_pressed("confirm"):
			_leave()
		return
	if busy or battle.resolved:
		return

	if event.is_action_pressed("confirm"):
		_end_turn()
		return

	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_TAB:
				_cycle_target()
				return
			KEY_Q:
				_cycle_brew()
				return
			KEY_E:
				_pour()
				return
			KEY_1, KEY_2, KEY_3:
				_strike(event.keycode - KEY_1)
				return
			KEY_ESCAPE:
				_disengage()
				return

	if not battle.can_player_act():
		return

	if event.is_action_pressed("move_up"):
		_move(Vector2i.UP)
	elif event.is_action_pressed("move_down"):
		_move(Vector2i.DOWN)
	elif event.is_action_pressed("move_left"):
		_move(Vector2i.LEFT)
	elif event.is_action_pressed("move_right"):
		_move(Vector2i.RIGHT)


func _refresh() -> void:
	var t := current_target()
	var brew := "—"
	if not battle.player.brews.is_empty():
		var bid: String = battle.player.brews[clampi(brew_index, 0, battle.player.brews.size() - 1)]
		brew = IngredientDB.get_ingredient(bid).display_name

	status.text = "turn %d     hp %d/%d     ap %d/%d     |     target: %s     |     in hand: %s" % [
		battle.turn, battle.player.hp, battle.player.max_hp,
		battle.player.ap, battle.player.ap_max,
		t.display_name if t != null else "—", brew,
	]
	if battle.is_over():
		hint.text = "%s.     SPACE to leave." % Battle.outcome_name(battle.outcome).capitalize()
	queue_redraw()


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	status = Label.new()
	status.position = Vector2(16, 12)
	layer.add_child(status)

	hint = Label.new()
	hint.position = Vector2(16, 44)
	layer.add_child(hint)
	hint.text = "WASD move · 1/2/3 strike · Q cycle brew · E pour · TAB target · SPACE end turn · ESC disengage"

	var legend := Label.new()
	legend.position = Vector2(620, 92)
	layer.add_child(legend)
	legend.text = "ring:  red enraged · blue distracted · yellow guard down · grey slowed\nfaded: out of the fight (stopped, fled or down)"

	log_lbl = RichTextLabel.new()
	log_lbl.position = Vector2(16, 540)
	log_lbl.custom_minimum_size = Vector2(1100, 150)
	log_lbl.bbcode_enabled = true
	layer.add_child(log_lbl)


func _tile_color(p_t: String) -> Color:
	match p_t:
		"#": return Color(0.07, 0.07, 0.09)
		"R": return Color(0.28, 0.24, 0.20)
		_:   return Color(0.15, 0.15, 0.19)


func _enemy_color(p_e: Combatant) -> Color:
	if p_e.reaction_profile == "brute":
		return Color(0.80, 0.36, 0.22)
	if p_e.def_id == "wolf":
		return Color(0.58, 0.60, 0.66)
	return Color(0.55, 0.42, 0.30)


func _status_color(p_e: Combatant) -> Color:
	if p_e.effects.has(ReactionTable.Kind.ENRAGED):
		return Color(1.0, 0.30, 0.30, 0.9)
	if p_e.effects.has(ReactionTable.Kind.DISTRACTED):
		return Color(0.40, 0.65, 1.0, 0.9)
	if p_e.effects.has(ReactionTable.Kind.GUARD_DOWN):
		return Color(1.0, 0.85, 0.30, 0.9)
	return Color(0.60, 0.60, 0.60, 0.9)


func _draw() -> void:
	for y in battle.grid.h:
		for x in battle.grid.w:
			var cell := Vector2i(x, y)
			var rect := Rect2(ORIGIN + Vector2(x, y) * TILE, Vector2(TILE, TILE))
			draw_rect(rect, _tile_color(battle.grid.tile_at(cell)))

	for e in battle.enemies:
		var centre := ORIGIN + Vector2(e.cell) * TILE + Vector2(TILE, TILE) * 0.5
		var radius := 12.0 + float(e.transform.silhouette()) * 2.2
		var col := _enemy_color(e)
		if e.is_out():
			col.a = 0.32
		draw_circle(centre, radius, col)

		var frac := float(e.hp) / maxi(1, e.max_hp)
		draw_rect(Rect2(centre + Vector2(-16, -radius - 10), Vector2(32, 4)), Color(0.18, 0.18, 0.22))
		draw_rect(Rect2(centre + Vector2(-16, -radius - 10), Vector2(32.0 * frac, 4)), Color(0.85, 0.25, 0.30))

		if not e.effects.is_empty():
			draw_arc(centre, radius + 7.0, 0.0, TAU, 24, _status_color(e), 2.5)

	var t := current_target()
	if t != null:
		var tc := ORIGIN + Vector2(t.cell) * TILE + Vector2(TILE, TILE) * 0.5
		draw_arc(tc, 27.0, 0.0, TAU, 32, Color(1, 1, 1, 0.85), 2.0)

	var pc := ORIGIN + Vector2(battle.player.cell) * TILE + Vector2(TILE, TILE) * 0.5
	draw_circle(pc, 14.0 + float(Game.weight) / 16.0, Color(0.66, 0.33, 0.97))
