extends Control
## The bench. Chugs experiments on himself. Free, infinite reset potion, no
## timer and no belly cost — the price is the foraging day. §6.10, §6.12

const BREW_SCENE := "res://scenes/brew/brew.tscn"
const FORAGE_SCENE := "res://scenes/forage/forage.tscn"

var status_lbl: Label
var level_lbl: Label
var body_lbl: RichTextLabel
var figure: Control
var torso: ColorRect
var belly_over: ColorRect
var head: ColorRect
var shelf_grid: GridContainer
var vat_box: HBoxContainer
var result_lbl: RichTextLabel
var hint_lbl: Label
var journal_ui: JournalUI
var save_ui: SaveUI

var selected: Array[String] = []


func _ready() -> void:
	if not Game.in_experiment:
		Game.begin_experiment()
	_build_ui()
	_refresh()


func _clear(parent: Node) -> void:
	for c in parent.get_children():
		parent.remove_child(c)
		c.queue_free()


func _label(parent: Node, text: String) -> Label:
	var l := Label.new()
	l.text = text
	parent.add_child(l)
	return l


func _selected_count(id: String) -> int:
	var n := 0
	for s in selected:
		if s == id:
			n += 1
	return n


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


func _ensure_save() -> void:
	if save_ui == null:
		save_ui = SaveUI.new()
		add_child(save_ui)


func _toggle_save() -> void:
	_ensure_save()
	if save_ui.is_open():
		save_ui.close()
	else:
		save_ui.open()


func _refresh() -> void:
	status_lbl.text = "Day %d (moon %d/%d)  ·  the bench  ·  weight %d  ·  permanent %d pts  ·  drinks %d  ·  searches banked %d" % [
		Game.day, Game.moon_day, Game.MOON_DAYS,
		Game.weight, Game.chugs_perm(), Game.chugs_drinks, Game.banked_searches,
	]
	level_lbl.text = Levels.progress_text()
	_refresh_body()
	_refresh_shelf()
	_refresh_vat()


func _refresh_body() -> void:
	var vis: Dictionary = Game.chugs_visual()
	var s: int = int(vis["silhouette"])
	var perm: int = Game.chugs_perm()
	var box := figure.custom_minimum_size
	var w := 76.0 + float(s) * 34.0
	var h := 132.0 + float(s) * 20.0
	var cx := box.x * 0.5
	var floor_y := box.y - 16.0

	torso.size = Vector2(w, h)
	torso.position = Vector2(cx - w * 0.5, floor_y - h)
	torso.color = Color(0.62, 0.60, 0.66)

	head.size = Vector2(46, 46)
	head.position = Vector2(cx - 23.0, floor_y - h - 50.0)
	head.color = Color(0.72, 0.70, 0.76)

	var pstage := perm / Transform.PER_STAGE
	var bw := w * (0.42 + 0.13 * float(mini(pstage, 5)))
	var bh := h * 0.36
	belly_over.size = Vector2(bw, bh)
	belly_over.position = Vector2(cx - bw * 0.5, floor_y - bh)
	belly_over.color = Color(0.86, 0.62, 0.42) if perm > 0 else Color(0.52, 0.50, 0.56)

	var flavor: Array[String] = []
	for k in vis["flavor"].keys():
		if bool(vis["flavor"][k]):
			flavor.append(str(k))

	body_lbl.text = "[b]Chugs[/b]   weight stage [b]%d[/b]  ·  permanent stage [b]%d[/b]  ·  total stage [b]%d[/b]\n[i]tear %d   base anchor %d (blend %.2f)%s[/i]" % [
		Game.bulk_stage(), pstage, s,
		int(vis["tear"]), int(vis["base_stage"]), float(vis["base_blend"]),
		"" if flavor.is_empty() else "   flavor: " + ", ".join(flavor),
	]


func _refresh_shelf() -> void:
	_clear(shelf_grid)
	for id in Game.inventory.keys():
		var remaining: int = int(Game.inventory[id]) - _selected_count(id)
		if remaining <= 0:
			continue
		var ing: Ingredient = IngredientDB.get_ingredient(id)
		if ing == null:
			continue
		var b := Button.new()
		var mark := "  [full]" if Journal.knows_full(id) else ("" if Journal.knows_ingredient(id) else "  ?")
		b.text = "%s  x%d\n%s%s" % [ing.display_name, remaining, ing.tags_text(), mark]
		b.custom_minimum_size = Vector2(160, 62)
		b.pressed.connect(_on_pick.bind(id))
		shelf_grid.add_child(b)


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


func _on_pick(id: String) -> void:
	if selected.size() >= Levels.vat_slots():
		return
	if _selected_count(id) >= int(Game.inventory.get(id, 0)):
		return
	selected.append(id)
	_refresh_shelf()
	_refresh_vat()


func _on_unpick(index: int) -> void:
	selected.remove_at(index)
	_refresh_shelf()
	_refresh_vat()


## Drinking is permanent. The bench is also the only place magnitudes become
## known, which is what the experiment buys you. §6.12, §6.15
func _drink() -> void:
	if selected.is_empty():
		return
	var res := BrewCalculator.brew(selected, IngredientDB)
	var before := Game.chugs_stage()
	for id in selected:
		var ing: Ingredient = IngredientDB.get_ingredient(id)
		Journal.learn_full(id, ing.tags)
		Game.take_item(id, 1)
	var events := Game.spike_chugs(res)
	Game.chugs_drinks += 1
	var after := Game.chugs_stage()
	selected.clear()

	var lines: Array[String] = []
	for e in events:
		lines.append("%s stage %d -> %d" % [str(e["axis"]), int(e["from"]), int(e["to"])])
	result_lbl.text = "[b]drank[/b] %s\n[i]%s[/i]\nbulk stage %d -> %d" % [
		Attributes.pretty(res),
		", ".join(lines) if not lines.is_empty() else "no threshold crossed",
		before, after,
	]
	hint_lbl.text = "It sticks. Only the potion takes it back."
	_refresh()


func _on_reset() -> void:
	if not Game.reset_chugs():
		return
	result_lbl.text = "Reset potion. Base body, weight -%d. Still on the clock — reset as often as you like." % Game.RESET_POTION_WEIGHT
	hint_lbl.text = "Reset potion is free and bottomless down here."
	_refresh()


func _on_service() -> void:
	Game.end_experiment()
	get_tree().change_scene_to_file(BREW_SCENE)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if (journal_ui != null and journal_ui.is_open()) \
				or (save_ui != null and save_ui.is_open()):
			return
		if event.keycode == KEY_J:
			_toggle_journal()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_S:
			_toggle_save()
			get_viewport().set_input_as_handled()


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 12)
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
	var s_btn := Button.new()
	s_btn.text = "save / load  (S)"
	s_btn.pressed.connect(_toggle_save)
	head.add_child(s_btn)

	var mid := HBoxContainer.new()
	mid.add_theme_constant_override("separation", 24)
	col.add_child(mid)

	var left := VBoxContainer.new()
	mid.add_child(left)
	figure = Control.new()
	figure.custom_minimum_size = Vector2(320, 300)
	left.add_child(figure)
	torso = ColorRect.new()
	figure.add_child(torso)
	belly_over = ColorRect.new()
	figure.add_child(belly_over)
	head = ColorRect.new()
	figure.add_child(head)
	body_lbl = RichTextLabel.new()
	body_lbl.bbcode_enabled = true
	body_lbl.custom_minimum_size = Vector2(320, 64)
	left.add_child(body_lbl)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_child(right)

	_label(right, "Pantry — what he drinks, he keeps")
	shelf_grid = GridContainer.new()
	shelf_grid.columns = 3
	right.add_child(shelf_grid)

	var vat_row := HBoxContainer.new()
	right.add_child(vat_row)
	_label(vat_row, "Dose:")
	vat_box = HBoxContainer.new()
	vat_row.add_child(vat_box)

	var drink_btn := Button.new()
	drink_btn.text = "Drink"
	drink_btn.pressed.connect(_drink)
	vat_row.add_child(drink_btn)

	var clear_btn := Button.new()
	clear_btn.text = "Clear"
	clear_btn.pressed.connect(func() -> void:
		selected.clear()
		_refresh_shelf()
		_refresh_vat()
	)
	vat_row.add_child(clear_btn)

	var reset_btn := Button.new()
	reset_btn.text = "Reset potion  (free, infinite)"
	reset_btn.pressed.connect(_on_reset)
	right.add_child(reset_btn)

	var serve_btn := Button.new()
	serve_btn.text = "Walk into service ->"
	serve_btn.pressed.connect(_on_service)
	right.add_child(serve_btn)

	result_lbl = RichTextLabel.new()
	result_lbl.bbcode_enabled = true
	result_lbl.custom_minimum_size = Vector2(0, 84)
	col.add_child(result_lbl)

	hint_lbl = _label(col, "Pick a dose, drink it, watch him. Nothing here costs a timer or a belly.")
