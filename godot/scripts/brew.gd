extends Control
## Grey-box brew & serve. Design ref: docs/design.md §6.3, §6.15, §6.16, §7.3

const FORAGE_SCENE := "res://scenes/forage/forage.tscn"

var queue: Array = []
var current: Patron = null
var selected: Array[String] = []
var served := 0
var total := 0
var locked := false
var journal_ui: JournalUI
var level_up_ui: LevelUpUI

var status_lbl: Label
var level_lbl: Label
var name_lbl: Label
var species_lbl: Label
var badge_lbl: Label
var request_lbl: Label
var note_lbl: Label
var shelf_grid: GridContainer
var vat_box: HBoxContainer
var result_lbl: RichTextLabel


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


func _ensure_journal() -> void:
	if journal_ui == null:
		journal_ui = JournalUI.new()
		add_child(journal_ui)


func _toggle_journal() -> void:
	_ensure_journal()
	if journal_ui.is_open():
		journal_ui.close()
	else:
		journal_ui.open()


func _show_level_up(reached: Array) -> void:
	if level_up_ui == null:
		level_up_ui = LevelUpUI.new()
		add_child(level_up_ui)
	level_up_ui.open(reached)


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
	level_lbl.text = Levels.progress_text()


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
	if locked or selected.size() >= Levels.vat_slots():
		return
	if _selected_count(id) >= Game.inventory.get(id, 0):
		return
	selected.append(id)
	_refresh_shelf()
	_refresh_vat()


func _refresh_vat() -> void:
	_clear(vat_box)
	if selected.is_empty():
		_label(vat_box, "empty — up to %d" % Levels.vat_slots())
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
	var paid := maxi(Levels.XP_FLOOR, total)      # floored: a bad night still moves
	var reached := Levels.award(total)
	var msg := "Closing time. Average satisfaction: %d\n+%d xp" % [avg, paid]

	Game.add_weight(served)     # placeholder until the feast drives this (§6.10)
	Game.advance_day()          # builds tomorrow at the new level, autosaves

	result_lbl.text = msg
	request_lbl.text = ""
	note_lbl.text = "Journal kept. Progress kept. Stock carries. Press R for the morning."
	badge_lbl.text = ""
	name_lbl.text = ""
	species_lbl.text = ""
	_clear(shelf_grid)
	_clear(vat_box)
	_refresh_status()

	if not reached.is_empty():
		_show_level_up(reached)


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 16)
	add_child(margin)

	var col := VBoxContainer.new()
	margin.add_child(col)

	var head := HBoxContainer.new()
	col.add_child(head)
	status_lbl = _label(head, "")
	level_lbl = _label(head, "")
	var j_btn := Button.new()
	j_btn.text = "journal  (J)"
	j_btn.pressed.connect(_toggle_journal)
	head.add_child(j_btn)

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


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if journal_ui != null and journal_ui.is_open():
			return
		if level_up_ui != null and level_up_ui.is_open():
			return
		if event.keycode == KEY_J:
			_toggle_journal()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_R:
			if Game.phase == Game.Phase.FORAGE:
				get_tree().change_scene_to_file(FORAGE_SCENE)
			else:
				get_tree().reload_current_scene()