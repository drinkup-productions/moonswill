extends Control
## Dev scene: auto-resolve an encounter so the battle logic can be checked
## before a battle scene exists. F6 on this scene.

var rng := RandomNumberGenerator.new()
var log_lbl: RichTextLabel


func _ready() -> void:
	rng.seed = 999
	_build()
	_run()


func _log(p_text: String) -> void:
	log_lbl.text += p_text + "\n"


func _names(p_list: Array) -> String:
	var out: Array[String] = []
	for c in p_list:
		out.append("%s (%s)" % [c.display_name, c.reaction_profile])
	return ", ".join(out)


func _run() -> void:
	Game.inventory = {
		"sunmelon": 2, "bogroot": 2, "emberpepper": 2, "cloudberry": 2,
		"honeycap": 2, "marshfig": 2, "glowmoss": 2,
	}
	var enemies := EncounterTable.roll(rng, 1)
	var player := Combatant.make_player()
	var battle := Battle.new(BattleGrid.new(), player, enemies, rng)
	battle.log_line.connect(_log)
	battle.ended.connect(_on_ended)

	_log("=== encounter: %s ===" % _names(enemies))
	var guard := 0
	while not battle.is_over() and guard < 600:
		guard += 1
		_auto_player(battle)
		if battle.is_over():
			break
		battle.end_turn()


func _pick(p_battle: Battle) -> Combatant:
	var best: Combatant = null
	for e in p_battle.living_enemies():
		if best == null or e.transform.silhouette() > best.transform.silhouette():
			best = e
	return best


## Crude AI: pour if it can, strike if adjacent, otherwise close.
func _auto_player(p_battle: Battle) -> void:
	var guard := 0
	while p_battle.can_player_act() and guard < 20:
		guard += 1
		var target := _pick(p_battle)
		if target == null:
			return
		if not p_battle.player.brews.is_empty() and rng.randf() < 0.6:
			p_battle.player_use_brew(0, target)
			continue
		if p_battle._adjacent(p_battle.player.cell, target.cell):
			p_battle.player_strike(target, "punch")
			continue
		var path := p_battle.grid.path_to(p_battle.player.cell, target.cell)
		if path.size() < 2:
			return
		if not p_battle.player_move(path[1] - p_battle.player.cell):
			return


func _on_ended(p_outcome: String, p_loot: Dictionary) -> void:
	_log("=== %s ===" % p_outcome)
	var parts: Array[String] = []
	for id in p_loot:
		parts.append("%s x%d" % [IngredientDB.get_ingredient(id).display_name, p_loot[id]])
	_log("loot: %s" % (", ".join(parts) if not parts.is_empty() else "none"))


func _build() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	add_child(margin)

	var col := VBoxContainer.new()
	margin.add_child(col)

	var row := HBoxContainer.new()
	col.add_child(row)

	var run_btn := Button.new()
	run_btn.text = "run an encounter"
	run_btn.pressed.connect(func() -> void:
		log_lbl.text = ""
		_run()
	)
	row.add_child(run_btn)

	log_lbl = RichTextLabel.new()
	log_lbl.bbcode_enabled = true
	log_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(log_lbl)