extends Control
## Dev scene: roll the encounter table and poke what it produces.
## F6 on this scene.

var rng := RandomNumberGenerator.new()
var enemies: Array = []
var log_lbl: RichTextLabel


func _ready() -> void:
	rng.seed = 12345
	_build()
	_roll()


func _log(p_text: String) -> void:
	if not log_lbl.text.is_empty():
		log_lbl.text += "\n"
	log_lbl.text += p_text


func _roll() -> void:
	enemies = EncounterTable.roll(rng, Levels.level)
	_log("")
	_log("=== encounter at level %d: %d enemy(ies) ===" % [Levels.level, enemies.size()])
	for e in enemies:
		_describe(e)


func _describe(e: Combatant) -> void:
	var atk: Array[String] = []
	for a in e.attacks():
		atk.append("%s %ddmg/%dap" % [a["name"], a["damage"], a["ap"]])
	var loot := EnemyDB.roll_loot(e.def_id, rng)
	var loot_txt: Array[String] = []
	for id in loot:
		loot_txt.append("%s x%d" % [IngredientDB.get_ingredient(id).display_name, loot[id]])
	_log("  %s (%s, %s)  hp %d  ap %d  speed %d  profile %s" % [
		e.display_name, e.def_id, e.species, e.max_hp, e.ap_max, e.speed(), e.reaction_profile
	])
	_log("      attacks: %s" % ", ".join(atk))
	_log("      brews: %d   sample loot: %s" % [
		e.brews.size(), ", ".join(loot_txt) if not loot_txt.is_empty() else "—"
	])


func _apply_brew() -> void:
	if enemies.is_empty():
		_roll()
	var e: Combatant = enemies[0]
	var ids: Array = []
	for id in IngredientDB.all.keys():
		if not IngredientDB.is_diluent(id):
			ids.append(id)
	var pick: String = ids[rng.randi_range(0, ids.size() - 1)]
	var ing: Ingredient = IngredientDB.get_ingredient(pick)
	var events := e.transform.apply(ing.effect())
	var reactions := e.react_to(events)
	_log("  >> poured %s on %s" % [ing.display_name, e.display_name])
	if reactions.is_empty():
		_log("     no reaction   (silhouette now %d)" % e.transform.silhouette())
	else:
		for r in reactions:
			_log("     REACTION: %s (%d turns)   silhouette %d" % [
				r["name"], r["turns"], e.transform.silhouette()
			])


func _roll_ten() -> void:
	for _i in 10:
		_roll()


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

	var roll_btn := Button.new()
	roll_btn.text = "roll encounter"
	roll_btn.pressed.connect(_roll)
	row.add_child(roll_btn)

	var ten_btn := Button.new()
	ten_btn.text = "roll x10"
	ten_btn.pressed.connect(_roll_ten)
	row.add_child(ten_btn)

	var brew_btn := Button.new()
	brew_btn.text = "pour a random brew on enemy 1"
	brew_btn.pressed.connect(_apply_brew)
	row.add_child(brew_btn)

	var clear_btn := Button.new()
	clear_btn.text = "clear"
	clear_btn.pressed.connect(func() -> void: log_lbl.text = "")
	row.add_child(clear_btn)

	log_lbl = RichTextLabel.new()
	log_lbl.bbcode_enabled = true
	log_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(log_lbl)