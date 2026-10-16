class_name SaveUI
extends CanvasLayer
## Manual save and load. Three slots plus the autosave. §6.13
## An overlay, like the journal, so opening it costs nothing.

signal closed()

const FORAGE_SCENE := "res://scenes/forage/forage.tscn"

var root: Control
var body: VBoxContainer
var status_lbl: Label
var _open := false


func _ready() -> void:
	layer = 12
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


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_S or event.keycode == KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()


func _clear(parent: Node) -> void:
	for c in parent.get_children():
		parent.remove_child(c)
		c.queue_free()


func _name_of(p_slot: int) -> String:
	return "the autosave" if p_slot == Game.AUTOSAVE_SLOT else "slot %d" % p_slot


func _on_save(p_slot: int) -> void:
	var ok := Save.save_game(p_slot)
	status_lbl.text = ("Saved to %s." % _name_of(p_slot)) if ok else "Save failed."
	_refresh()


func _on_load(p_slot: int) -> void:
	if not Save.load_and_resume(p_slot):
		status_lbl.text = "Could not load %s." % _name_of(p_slot)
		_refresh()
		return
	get_tree().change_scene_to_file(FORAGE_SCENE)


func _on_delete(p_slot: int) -> void:
	Save.delete_save(p_slot)
	status_lbl.text = "%s cleared." % _name_of(p_slot).capitalize()
	_refresh()


func _label_for(p_slot: int) -> String:
	var head := "AUTOSAVE" if p_slot == Game.AUTOSAVE_SLOT else "SLOT %d" % p_slot
	if not Save.has_save(p_slot):
		return "%s      empty" % head
	var info := Save.slot_info(p_slot)
	return "%s      day %d  ·  moon %d/%d  ·  level %d  ·  weight %d  ·  attention %d" % [
		head, int(info.get("day", 1)), int(info.get("moon_day", 1)), Game.MOON_DAYS,
		int(info.get("level", 1)), int(info.get("weight", 0)), int(info.get("attention", 0)),
	]


func _refresh() -> void:
	_clear(body)
	for slot in [Game.AUTOSAVE_SLOT, 1, 2, 3]:
		var row := HBoxContainer.new()
		body.add_child(row)

		var l := Label.new()
		l.text = _label_for(slot)
		l.custom_minimum_size = Vector2(470, 0)
		row.add_child(l)

		var save_btn := Button.new()
		save_btn.text = "save"
		save_btn.pressed.connect(_on_save.bind(slot))
		row.add_child(save_btn)

		var load_btn := Button.new()
		load_btn.text = "load"
		load_btn.disabled = not Save.has_save(slot)
		load_btn.pressed.connect(_on_load.bind(slot))
		row.add_child(load_btn)

		var del_btn := Button.new()
		del_btn.text = "delete"
		del_btn.disabled = not Save.has_save(slot)
		del_btn.pressed.connect(_on_delete.bind(slot))
		row.add_child(del_btn)


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
	margin.add_theme_constant_override("margin_top", 20)
	root.add_child(margin)

	var col := VBoxContainer.new()
	margin.add_child(col)

	var head := HBoxContainer.new()
	col.add_child(head)
	var title := Label.new()
	title.text = "Save and load"
	head.add_child(title)
	var close_btn := Button.new()
	close_btn.text = "close  (S)"
	close_btn.pressed.connect(close)
	head.add_child(close_btn)

	var note := Label.new()
	note.text = "Loading restarts the day, so steps and searches reset. Stock, journal, level, weight and affinity all carry."
	col.add_child(note)

	body = VBoxContainer.new()
	col.add_child(body)

	status_lbl = Label.new()
	col.add_child(status_lbl)