class_name JournalUI
extends CanvasLayer
## Chugs's notebook. Diegetic, persistent, two views. §6.15
## An overlay, so opening it never costs the scene beneath its state.

signal closed()

var root: Control
var body: VBoxContainer
var count_lbl: Label
var status_lbl: Label
var view := "ingredient"
var _open := false


func _ready() -> void:
	layer = 10
	_build()
	visible = false


func is_open() -> bool:
	return _open


func open() -> void:
	_open = true
	visible = true
	_refresh()


func close() -> void:
	_open = false
	visible = false
	closed.emit()


func _clear(parent: Node) -> void:
	for c in parent.get_children():
		parent.remove_child(c)
		c.queue_free()


func _on_close() -> void:
	close()


func _on_taste(id: String) -> void:
	status_lbl.text = Game.taste(id)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_J or event.keycode == KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()


func _refresh() -> void:
	count_lbl.text = "     %d of %d known  " % [
		Journal.known_count(), Journal.total_ingredients()
	]
	_clear(body)
	if view == "ingredient":
		_ingredient_view()
	else:
		_effect_view()


func _ingredient_view() -> void:
	for id in IngredientDB.all.keys():
		if IngredientDB.is_diluent(id):
			continue
		var ing: Ingredient = IngredientDB.get_ingredient(id)
		var known := Journal.knows_ingredient(id)
		var held: int = int(Game.inventory.get(id, 0))

		var row := HBoxContainer.new()
		body.add_child(row)

		var name_l := Label.new()
		name_l.text = "%s   [%s]" % [ing.display_name, ing.tags_text()]
		name_l.custom_minimum_size = Vector2(280, 0)
		row.add_child(name_l)

		var eff_l := Label.new()
		eff_l.text = Attributes.pretty(ing.effect()) if known else "not yet known"
		eff_l.custom_minimum_size = Vector2(320, 0)
		row.add_child(eff_l)

		var held_l := Label.new()
		held_l.text = "x%d" % held if held > 0 else "—"
		held_l.custom_minimum_size = Vector2(48, 0)
		row.add_child(held_l)

		
func _effect_view() -> void:
	var note := Label.new()
	note.text = "Reverse lookup. Only what Chugs has actually learned."
	body.add_child(note)
	for a in Attributes.LIST:
		var up: Array[String] = []
		var down: Array[String] = []
		for id in IngredientDB.all.keys():
			if not Journal.knows_ingredient(id):
				continue
			var ing: Ingredient = IngredientDB.get_ingredient(id)
			var v: int = ing.effect()[a]
			if v > 0:
				up.append("%s +%d" % [ing.display_name, v])
			if v < 0:
				down.append("%s %d" % [ing.display_name, v])
		var l := Label.new()
		l.text = "%-8s raise: %-42s | lower: %s" % [
			a,
			", ".join(up) if not up.is_empty() else "—",
			", ".join(down) if not down.is_empty() else "—",
		]
		body.add_child(l)


func _build() -> void:
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.04, 0.06, 0.95)
	root.add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 16)
	root.add_child(margin)

	var col := VBoxContainer.new()
	margin.add_child(col)

	var head := HBoxContainer.new()
	col.add_child(head)
	var title := Label.new()
	title.text = "Chugs's journal"
	head.add_child(title)
	count_lbl = Label.new()
	head.add_child(count_lbl)
	var close_btn := Button.new()
	close_btn.text = "close  (J)"
	close_btn.pressed.connect(_on_close)
	head.add_child(close_btn)

	var tabs := HBoxContainer.new()
	col.add_child(tabs)
	var tab_ing := Button.new()
	tab_ing.text = "by ingredient"
	tab_ing.pressed.connect(func() -> void:
		view = "ingredient"
		_refresh()
	)
	tabs.add_child(tab_ing)
	var tab_eff := Button.new()
	tab_eff.text = "by effect"
	tab_eff.pressed.connect(func() -> void:
		view = "effect"
		_refresh()
	)
	tabs.add_child(tab_eff)

	status_lbl = Label.new()
	col.add_child(status_lbl)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
