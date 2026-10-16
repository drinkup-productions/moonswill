extends Control
## Grey-box brew & serve. Design ref: docs/design.md §6.3, §6.15, §7.3

const MAX_SELECT := 3
const FORAGE_SCENE := "res://scenes/forage/forage.tscn"

var queue: Array = []
var current: Patron = null
var selected: Array[String] = []
var served := 0
var total := 0
var locked := false
var view := "ingredient"

var status_lbl: Label
var name_lbl: Label
var species_lbl: Label
var badge_lbl: Label
var request_lbl: Label
var note_lbl: Label
var shelf_grid: GridContainer
var vat_box: HBoxContainer
var result_lbl: RichTextLabel
var journal_grid: GridContainer
var known_lbl: Label


func _ready() -> void:
	_build_ui()
	_start_night()


func _clear(parent: Node) -> void:
	for c in parent.get_children():
		parent.remove_child(c)
		c.queue_free()


func _label(parent: Node, text: String) -> Label:
	var l := Label.new()
	l.text = text
	parent.add_child(l)
	return l


func _start_night() -> void:
	# Fallback stock, only when opening brew.tscn directly with F6.
	if Game.inventory.is_empty():
		Game.inventory = {
			"sunmelon": 3, "bogroot": 3, "emberpepper": 3, "cloudberry": 3,
			"ironoats": 3, "marshfig": 3, "skywort": 3, "honeycap": 3,
			"stoneplum": 3, "glowmoss": 3, "wellwater": 99,
		}
	if Game.roster.is_empty():
		Game.start_day()

	queue = Game.roster.duplicate()
	served = 0
	total = 0
	selected.clear()
	Game.set_phase(Game.Phase.SERVICE)
	_next_patron()


func _next_patron() -> void:
	if queue.is_empty():
		_end_night()
		return
	current = queue[0]
	name_lbl.text = current.name
	species_lbl.text = current.species
	var req: PatronRequest = current.req
	badge_lbl.text = PatronRequest.LABEL[req.kind]
	request_lbl.text = req.line
	note_lbl.text = req.note
	_refresh_shelf()
	_refresh_vat()
	_refresh_status()


func _refresh_status() -> void:
	status_lbl.text = "Day %d — Patron %d of %d     total satisfaction: %d" % [
		Game.day, served + 1, served + queue.size(), total
	]


func _selected_count(id: String) -> int:
	var n := 0
	for s in selected:
		if s == id:
			n += 1
	return n


func _refresh_shelf() -> void:
	_clear(shelf_grid)
	for id in Game.inventory.keys():
		var remaining: int = Game.inventory[id] - _selected_count(id)
		if remaining <= 0:
			continue
		var ing: Ingredient = IngredientDB.get_ingredient(id)
		if ing == null:
			continue
		var b := Button.new()
		var tags_txt := ing.tags_text()
		var known := Journal.knows_ingredient(id)
		b.text = "%s  x%d\n%s%s" % [ing.display_name, remaining, tags_txt, "" if known else "\n?"]
		b.custom_minimum_size = Vector2(150, 62)
		b.pressed.connect(_on_pick.bind(id))
		shelf_grid.add_child(b)


func _on_pick(id: String) -> void:
	if locked or selected.size() >= MAX_SELECT:
		return
	if _selected_count(id) >= Game.inventory.get(id, 0):
		return
	selected.append(id)
	_refresh_shelf()
	_refresh_vat()


func _refresh_vat() -> void:
	_clear(vat_box)
	if selected.is_empty():
		_label(vat_box, "empty — up to %d" % MAX_SELECT)
		return
	for i in selected.size():
		var b := Button.new()
		b.text = IngredientDB.get_ingredient(selected[i]).display_name + " x"
		b.pressed.connect(_on_unpick.bind(i))
		vat_box.add_child(b)


func _on_unpick(index: int) -> void:
	if locked:
		return
	selected.remove_at(index)
	_refresh_shelf()
	_refresh_vat()


func _brew() -> void:
	if locked or selected.is_empty():
		return
	locked = true
	var req: PatronRequest = current.req
	var res := BrewCalculator.brew(selected, IngredientDB)
	var sc := BrewCalculator.score(res, req)

	for id in selected:
		var ing: Ingredient = IngredientDB.get_ingredient(id)
		Journal.learn_ingredient(id, ing.tags)
		Game.take_item(id, 1)

	var wanted := "NO TARGET — bold and focused" if req.is_wildcard() else Attributes.pretty(req.want)
	result_lbl.text = "[b]wanted[/b] %s   ·   [b]got[/b] %s\n[b]Satisfaction %d[/b]\n[i]%s[/i]" % [
		wanted, Attributes.pretty(res), sc,
		BrewCalculator.band_line(sc, req.is_wildcard())
	]
	total += sc
	selected.clear()
	_refresh_shelf()
	_refresh_vat()

	await get_tree().create_timer(1.4).timeout
	queue.pop_front()
	served += 1
	locked = false
	_next_patron()


func _end_night() -> void:
	var avg := int(round(float(total) / maxi(1, served)))
	var ups := Levels.award(total)
	var msg := "Closing time. Average satisfaction: %d\n+%d xp" % [avg, maxi(Levels.XP_FLOOR, total)]
	if ups > 0:
		msg += "\nLevel %d reached — %d searches, %d per search." % [
			Levels.level, Levels.searches(), Levels.yield_per_search()
		]
	Game.add_weight(served)     # placeholder until the feast drives this (§6.10)
	Game.advance_day()          # builds tomorrow's roster and spots, phase -> FORAGE
	result_lbl.text = msg
	request_lbl.text = ""
	note_lbl.text = "Journal kept. Progress kept. Stock carries. Press R for the morning."
	badge_lbl.text = ""
	name_lbl.text = ""
	species_lbl.text = ""
	_clear(shelf_grid)
	_clear(vat_box)
	_refresh_status()


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 16)
	add_child(margin)

	var col := VBoxContainer.new()
	margin.add_child(col)

	status_lbl = _label(col, "")

	var card := PanelContainer.new()
	col.add_child(card)
	var card_col := VBoxContainer.new()
	card.add_child(card_col)
	var top := HBoxContainer.new()
	card_col.add_child(top)
	name_lbl = _label(top, "")
	species_lbl = _label(top, "")
	badge_lbl = _label(top, "")
	request_lbl = _label(card_col, "")
	note_lbl = _label(card_col, "")

	_label(col, "Shelf")
	shelf_grid = GridContainer.new()
	shelf_grid.columns = 4
	col.add_child(shelf_grid)

	var vat_row := HBoxContainer.new()
	col.add_child(vat_row)
	_label(vat_row, "Vat:")
	vat_box = HBoxContainer.new()
	vat_row.add_child(vat_box)

	var brew_btn := Button.new()
	brew_btn.text = "Brew & serve"
	brew_btn.pressed.connect(_brew)
	vat_row.add_child(brew_btn)

	var clear_btn := Button.new()
	clear_btn.text = "Clear"
	clear_btn.pressed.connect(func() -> void:
		selected.clear()
		_refresh_shelf()
		_refresh_vat()
	)
	vat_row.add_child(clear_btn)

	result_lbl = RichTextLabel.new()
	result_lbl.bbcode_enabled = true
	result_lbl.custom_minimum_size = Vector2(0, 90)
	col.add_child(result_lbl)

	var jrow := HBoxContainer.new()
	col.add_child(jrow)
	_label(jrow, "Chugs's journal")
	known_lbl = _label(jrow, "")
	var ing_btn := Button.new()
	ing_btn.text = "by ingredient"
	ing_btn.pressed.connect(func() -> void:
		view = "ingredient"
		_refresh_journal()
	)
	jrow.add_child(ing_btn)
	var eff_btn := Button.new()
	eff_btn.text = "by effect"
	eff_btn.pressed.connect(func() -> void:
		view = "effect"
		_refresh_journal()
	)
	jrow.add_child(eff_btn)

	journal_grid = GridContainer.new()
	journal_grid.columns = 2
	col.add_child(journal_grid)
	_refresh_journal()


func _refresh_journal() -> void:
	_clear(journal_grid)
	known_lbl.text = "%d of %d known" % [
		Journal.known_ingredients.size(), IngredientDB.all.size() - 1
	]

	if view == "ingredient":
		for id in IngredientDB.all.keys():
			if IngredientDB.is_diluent(id):
				continue
			var ing: Ingredient = IngredientDB.get_ingredient(id)
			var known := Journal.knows_ingredient(id)
			var txt := Attributes.pretty(ing.effect()) if known else "not yet known"
			_label(journal_grid, "%s — %s" % [ing.display_name, txt])
	else:
		for a in Attributes.LIST:
			var up: Array[String] = []
			var down: Array[String] = []
			for id in IngredientDB.all.keys():
				if not Journal.knows_ingredient(id):
					continue
				var v: int = IngredientDB.get_ingredient(id).effect()[a]
				if v > 0:
					up.append("%s +%d" % [id, v])
				if v < 0:
					down.append("%s %d" % [id, v])
			_label(journal_grid, "%s   raise: %s   |   lower: %s" % [
				a,
				", ".join(up) if not up.is_empty() else "—",
				", ".join(down) if not down.is_empty() else "—",
			])


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		if Game.phase == Game.Phase.FORAGE:
			get_tree().change_scene_to_file(FORAGE_SCENE)
		else:
			get_tree().reload_current_scene()
