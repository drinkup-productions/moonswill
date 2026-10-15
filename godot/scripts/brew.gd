extends Control
## Grey-box brew & serve. Design ref: docs/design.md §6.3, §6.15, §7.3

const MAX_SELECT := 3

var queue: Array[Dictionary] = []
var current: Dictionary = {}
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


func _start_night() -> void:
	Game.inventory = {
		"sunmelon": 6, "bogroot": 6, "emberpepper": 6, "cloudberry": 6, "ironoats": 6, "marshfig": 6, "skywort": 6, "honeycap": 6, "stoneplum": 6, "glowmoss": 6, "wellwater": 99,
		}
	queue = [
		{"name": "Rill", "species": "felinid",
			"req": PatronRequest.make(PatronRequest.Kind.SPECIFIC, '"Slimmer. Taller. Sleek."', {"height": 4, "belly": -3}, 1.2)},
		{"name": "Bess", "species": "bovine",
			"req": PatronRequest.make(PatronRequest.Kind.VAGUE, '"I want to feel... fuller. Softer."', {"belly": 5, "chest": 3}, 0.85)},
		{"name": "Gorst", "species": "equine",
			"req": PatronRequest.make(PatronRequest.Kind.SPECIFIC, '"Taller. Stronger."', {"height": 4, "muscle": 4}, 1.15)},
		{"name": "Marrow", "species": "skull-dog",
			"req": PatronRequest.make(PatronRequest.Kind.WILDCARD, '"...Whatever you have got. Surprise me."', {}, 1.0)},
	]
	served = 0
	total = 0
	selected.clear()
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
	status_lbl.text = "Patron %d of %d     total satisfaction: %d" % [served + 1, served + queue.size(), total]


func _refresh_shelf() -> void:
	for c in shelf_grid.get_children():
		c.queue_free()
	for id in Game.inventory.keys():
		var count: int = Game.inventory[id]
		if count <= 0:
			continue
		var ing: Ingredient = IngredientDB.get_ingredient(id)
		if ing == null:
			continue
		var b := Button.new()
		var known := Journal.knows_ingredient(id)
		var tags_txt := "no effect" if ing.tags.is_empty() else ", ".join(ing.tags)
		b.text = "%s  x%d\n%s%s" % [ing.display_name, count, tags_txt, "" if known else "\n?"]
		b.custom_minimum_size = Vector2(150, 62)
		b.pressed.connect(_on_pick.bind(id))
		shelf_grid.add_child(b)


func _on_pick(id: String) -> void:
	if locked or selected.size() >= MAX_SELECT:
		return
	selected.append(id)
	_refresh_vat()


func _refresh_vat() -> void:
	for c in vat_box.get_children():
		c.queue_free()
	if selected.is_empty():
		var l := Label.new()
		l.text = "empty — up to %d" % MAX_SELECT
		vat_box.add_child(l)
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

	var wanted := "no target — bold and focused" if req.kind == PatronRequest.Kind.WILDCARD else Attributes.pretty(req.want)
	result_lbl.text = "[b]wanted[/b] %s   ·   [b]got[/b] %s\n[b]Satisfaction %d[/b]\n[i]%s[/i]" % [
		wanted, Attributes.pretty(res), sc, BrewCalculator.band_line(sc, req.kind == PatronRequest.Kind.WILDCARD)
	]
	total += sc
	selected.clear()

	await get_tree().create_timer(1.4).timeout
	queue.pop_front()
	served += 1
	locked = false
	_refresh_shelf()
	_next_patron()


func _end_night() -> void:
	var avg := int(round(float(total) / maxi(1, served)))
	var ups := Levels.award(total)
	var msg := "Closing time. Average satisfaction: %d\n+%d xp" % [avg, maxi(Levels.XP_FLOOR, total)]
	if ups > 0:
		msg += "\nLevel %d reached — %d searches, %d per search." % [Levels.level, Levels.searches(), Levels.yield_per_search()]
	Game.add_weight(served)     # placeholder: eating adds weight (§6.10)
	Game.advance_day()
	result_lbl.text = msg
	request_lbl.text = ""
	note_lbl.text = "Journal kept. Progress kept."
	for c in shelf_grid.get_children():
		c.queue_free()
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

	status_lbl = Label.new()
	col.add_child(status_lbl)

	var card := PanelContainer.new()
	col.add_child(card)
	var card_col := VBoxContainer.new()
	card.add_child(card_col)
	var top := HBoxContainer.new()
	card_col.add_child(top)
	name_lbl = Label.new(); top.add_child(name_lbl)
	species_lbl = Label.new(); top.add_child(species_lbl)
	badge_lbl = Label.new(); top.add_child(badge_lbl)
	request_lbl = Label.new(); card_col.add_child(request_lbl)
	note_lbl = Label.new(); card_col.add_child(note_lbl)

	col.add_child(Label.new()).text = "Shelf"
	shelf_grid = GridContainer.new()
	shelf_grid.columns = 4
	col.add_child(shelf_grid)

	var vat_row := HBoxContainer.new()
	col.add_child(vat_row)
	vat_row.add_child(Label.new()).text = "Vat:"
	vat_box = HBoxContainer.new()
	vat_row.add_child(vat_box)

	var brew_btn := Button.new()
	brew_btn.text = "Brew & serve"
	brew_btn.pressed.connect(_brew)
	vat_row.add_child(brew_btn)

	var clear_btn := Button.new()
	clear_btn.text = "Clear"
	clear_btn.pressed.connect(func(): selected.clear(); _refresh_vat())
	vat_row.add_child(clear_btn)

	result_lbl = RichTextLabel.new()
	result_lbl.bbcode_enabled = true
	result_lbl.custom_minimum_size = Vector2(0, 90)
	col.add_child(result_lbl)

	var jrow := HBoxContainer.new()
	col.add_child(jrow)
	jrow.add_child(Label.new()).text = "Chugs's journal"
	known_lbl = Label.new()
	jrow.add_child(known_lbl)
	var ing_btn := Button.new(); ing_btn.text = "by ingredient"
	ing_btn.pressed.connect(func(): view = "ingredient"; _refresh_journal())
	jrow.add_child(ing_btn)
	var eff_btn := Button.new(); eff_btn.text = "by effect"
	eff_btn.pressed.connect(func(): view = "effect"; _refresh_journal())
	jrow.add_child(eff_btn)

	journal_grid = GridContainer.new()
	journal_grid.columns = 2
	col.add_child(journal_grid)
	_refresh_journal()


func _refresh_journal() -> void:
	for c in journal_grid.get_children():
		c.queue_free()
	known_lbl.text = "%d of %d known" % [Journal.known_ingredients.size(), IngredientDB.all.size() - 1]

	if view == "ingredient":
		for id in IngredientDB.all.keys():
			if IngredientDB.is_diluent(id):
				continue
			var ing: Ingredient = IngredientDB.get_ingredient(id)
			var known := Journal.knows_ingredient(id)
			var l := Label.new()
			l.text = "%s — %s" % [ing.display_name, Attributes.pretty(ing.effect()) if known else "not yet known"]
			journal_grid.add_child(l)
	else:
		for a in Attributes.LIST:
			var up: Array[String] = []
			var down: Array[String] = []
			for id in IngredientDB.all.keys():
				if not Journal.knows_ingredient(id):
					continue
				var v: int = IngredientDB.get_ingredient(id).effect()[a]
				if v > 0: up.append("%s +%d" % [id, v])
				if v < 0: down.append("%s %d" % [id, v])
			var l := Label.new()
			l.text = "%s  raise: %s | lower: %s" % [a, ", ".join(up) if up else "—", ", ".join(down) if down else "—"]
			journal_grid.add_child(l)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		get_tree().reload_current_scene()
