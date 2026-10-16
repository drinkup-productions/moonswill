class_name Battle
extends RefCounted
## Turn-based encounter. Pure logic; a scene drives and draws it. §8
## Enemies close, strike, and use their own brews on Chugs. Reactions fire
## when a body changes, so a fight can end with no blows struck at all.

signal log_line(text: String)
signal ended(outcome: String, loot: Dictionary)

enum Outcome { ONGOING, WON, LOST, DISENGAGED }

const MAX_TURNS := 30
const ENEMY_BREW_CHANCE := 0.25
const MAX_CARRIED_BREWS := 12

var grid: BattleGrid
var player: Combatant
var enemies: Array = []
var rng: RandomNumberGenerator
var turn: int = 1
var resolved := false
var outcome: int = Outcome.ONGOING


func _init(p_grid: BattleGrid, p_player: Combatant, p_enemies: Array,
		p_rng: RandomNumberGenerator) -> void:
	grid = p_grid
	player = p_player
	enemies = p_enemies
	rng = p_rng
	_deploy()
	_attach_inventory()
	player.begin_turn()
	for e in enemies:
		e.begin_turn()
	log_line.emit("-- turn 1 --")


func _deploy() -> void:
	var cells := grid.free_cells()
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		if a.x == b.x:
			return a.y < b.y
		return a.x < b.x
	)
	if cells.is_empty():
		return
	player.cell = cells[0]
	var taken := {player.cell: true}
	var step := maxi(1, int(cells.size() / (enemies.size() + 1)))
	for i in enemies.size():
		var idx := mini(cells.size() - 1, step * (i + 1))
		while taken.has(cells[idx]) and idx < cells.size() - 1:
			idx += 1
		enemies[i].cell = cells[idx]
		taken[cells[idx]] = true


## He fights out of the same pantry he forages into. §8
func _attach_inventory() -> void:
	player.brews.clear()
	for id in Game.inventory.keys():
		if IngredientDB.is_diluent(id):
			continue
		for _i in int(Game.inventory[id]):
			if player.brews.size() >= MAX_CARRIED_BREWS:
				break
			player.brews.append(id)
		if player.brews.size() >= MAX_CARRIED_BREWS:
			break


func is_over() -> bool:
	return resolved


func occupied(p_cell: Vector2i) -> bool:
	if player.cell == p_cell:
		return true
	for e in enemies:
		if not e.is_out() and e.cell == p_cell:
			return true
	return false


func combatant_at(p_cell: Vector2i) -> Combatant:
	for e in enemies:
		if not e.is_out() and e.cell == p_cell:
			return e
	return null


func living_enemies() -> Array:
	var out: Array = []
	for e in enemies:
		if not e.is_out():
			out.append(e)
	return out


func _adjacent(a: Vector2i, b: Vector2i) -> bool:
	return absi(a.x - b.x) + absi(a.y - b.y) == 1


func can_player_act() -> bool:
	return not resolved and player.can_act()


func player_move(p_dir: Vector2i) -> bool:
	if not can_player_act():
		return false
	var to := player.cell + p_dir
	if not grid.in_bounds(to) or grid.is_blocked(to) or occupied(to):
		return false
	player.cell = to
	player.ap -= 1
	log_line.emit("Chugs steps.")
	return true


func attack_for(p_who: Combatant, p_attack_id: String) -> Dictionary:
	for a in p_who.attacks():
		if str(a["id"]) == p_attack_id:
			return a
	return {}


func player_strike(p_target: Combatant, p_attack_id: String) -> Dictionary:
	if not can_player_act():
		return {"error": "no action"}
	if p_target == null or p_target.is_out():
		return {"error": "nothing there"}
	var atk := attack_for(player, p_attack_id)
	if atk.is_empty():
		return {"error": "no such attack"}
	if not _adjacent(player.cell, p_target.cell):
		return {"error": "out of reach"}
	if player.ap < int(atk["ap"]):
		return {"error": "not enough AP"}
	player.ap -= int(atk["ap"])
	var dmg := player.roll_damage(atk, p_target)
	p_target.take_damage(dmg)
	log_line.emit("Chugs uses %s — %d to %s." % [atk["name"], dmg, p_target.display_name])
	_check_end()
	return {"damage": dmg}


## Brews are poured at any range — you hand it over or you toss it. If it
## needed adjacency, "fatten it so it cannot close" would be circular.
func player_use_brew(p_index: int, p_target: Combatant) -> Dictionary:
	if not can_player_act():
		return {"error": "no action"}
	if p_target == null or p_target.is_out():
		return {"error": "nothing there"}
	if p_index < 0 or p_index >= player.brews.size():
		return {"error": "no such brew"}
	player.ap -= 1
	var id: String = player.brews[p_index]
	player.brews.remove_at(p_index)
	Game.take_item(id, 1)
	return _pour(id, p_target)


func _pour(p_id: String, p_target: Combatant) -> Dictionary:
	var ing: Ingredient = IngredientDB.get_ingredient(p_id)
	if ing == null:
		return {}
	var events := p_target.transform.apply(ing.effect())
	var reactions := p_target.react_to(events)
	log_line.emit("%s is dosed with %s." % [p_target.display_name, ing.display_name])
	for r in reactions:
		log_line.emit("   %s %s." % [p_target.display_name, _reaction_line(int(r["kind"]))])
	_check_end()
	return {"events": events, "reactions": reactions}


static func _reaction_line(p_kind: int) -> String:
	match p_kind:
		ReactionTable.Kind.DISTRACTED: return "is distracted and loses a turn"
		ReactionTable.Kind.GUARD_DOWN:  return "drops their guard"
		ReactionTable.Kind.SLOWED:      return "slows down"
		ReactionTable.Kind.ENRAGED:     return "gets angry, and hits harder"
		ReactionTable.Kind.STOP:        return "stops fighting and enjoys it"
		ReactionTable.Kind.FLEE:        return "runs"
	return "reacts"


func end_turn() -> void:
	if resolved:
		return
	_enemy_phase()
	if resolved:
		return
	turn += 1
	for e in enemies:
		e.tick_effects()
		e.begin_turn()
	player.tick_effects()
	player.begin_turn()
	if turn > MAX_TURNS:
		_finish(Outcome.DISENGAGED)
		return
	log_line.emit("-- turn %d --" % turn)
	_check_end()


func _enemy_phase() -> void:
	for e in enemies:
		if resolved:
			return
		if e.is_out():
			continue
		_enemy_act(e)


func _enemy_act(p_enemy: Combatant) -> void:
	if p_enemy.is_stunned():
		log_line.emit("%s is distracted." % p_enemy.display_name)
		return
	for _i in p_enemy.speed():
		if p_enemy.is_out() or resolved:
			return
		if _adjacent(p_enemy.cell, player.cell):
			break
		var path := grid.path_to(p_enemy.cell, player.cell)
		if path.size() < 2:
			break
		var nxt: Vector2i = path[1]
		if occupied(nxt) and nxt != player.cell:
			break                      # jammed behind a body
		p_enemy.cell = nxt
	if not _adjacent(p_enemy.cell, player.cell):
		return
	if not p_enemy.brews.is_empty() and rng.randf() < ENEMY_BREW_CHANCE:
		var idx := rng.randi_range(0, p_enemy.brews.size() - 1)
		var id: String = p_enemy.brews[idx]
		p_enemy.brews.remove_at(idx)
		_pour(id, player)
		return
	_enemy_strike(p_enemy)


func _enemy_strike(p_enemy: Combatant) -> void:
	var list := p_enemy.attacks()
	if list.is_empty():
		return
	var atk: Dictionary = list[rng.randi_range(0, list.size() - 1)]
	var dmg := p_enemy.roll_damage(atk, player)
	player.take_damage(dmg)
	log_line.emit("%s uses %s — %d to Chugs." % [p_enemy.display_name, atk["name"], dmg])
	_check_end()


func disengage() -> void:
	if resolved:
		return
	_finish(Outcome.DISENGAGED)


func _check_end() -> void:
	if resolved:
		return
	if player.is_down():
		_finish(Outcome.LOST)
		return
	if living_enemies().is_empty():
		_finish(Outcome.WON)


func _finish(p_outcome: int) -> void:
	resolved = true
	outcome = p_outcome
	var loot := {}
	if p_outcome == Outcome.WON:
		for e in enemies:
			for id in EnemyDB.roll_loot(e.def_id, rng):
				loot[id] = int(loot.get(id, 0)) + 1
	ended.emit(outcome_name(p_outcome), loot)


static func outcome_name(p_outcome: int) -> String:
	match p_outcome:
		Outcome.WON:        return "won"
		Outcome.LOST:       return "knocked out"
		Outcome.DISENGAGED: return "disengaged"
	return "ongoing"


func summary() -> String:
	var parts: Array[String] = []
	for e in enemies:
		var st: String = e.status_text()
		parts.append("%s %d/%d%s" % [
			e.display_name, e.hp, e.max_hp,
			"" if st == "—" else " [%s]" % st,
		])
	return "turn %d   hp %d/%d   ap %d/%d   |   %s" % [
		turn, player.hp, player.max_hp, player.ap, player.ap_max, ", ".join(parts)
	]
