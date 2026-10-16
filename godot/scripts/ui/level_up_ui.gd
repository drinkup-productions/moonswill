class_name LevelUpUI
extends CanvasLayer
## The level-up beat. Shows what capability was bought, never just a number.
## Design ref: docs/design.md §6.16

signal dismissed()

var root: Control
var col: VBoxContainer
var _open := false


func _ready() -> void:
	layer = 11
	_build()
	visible = false


func is_open() -> bool:
	return _open


func open(p_reached: Array) -> void:
	_open = true
	visible = true
	_fill(p_reached)


func _close() -> void:
	_open = false
	visible = false
	dismissed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_ESCAPE]:
			_close()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		_close()
		get_viewport().set_input_as_handled()


func _fill(p_reached: Array) -> void:
	for c in col.get_children():
		col.remove_child(c)
		c.queue_free()

	var top: int = int(p_reached[p_reached.size() - 1])

	var title := Label.new()
	title.text = "LEVEL %d" % top
	col.add_child(title)

	for l in p_reached:
		var line := Label.new()
		line.text = "      — %s" % Levels.reward_text(int(l))
		col.add_child(line)

	var now := Label.new()
	now.text = "now: %d searches a day · %d per search · %d vat slots · %d taste tests a day" % [
		Levels.searches(), Levels.yield_per_search(),
		Levels.vat_slots(), Levels.taste_tests_per_day(),
	]
	col.add_child(now)

	if top >= Levels.MAX_LEVEL:
		var cap := Label.new()
		cap.text = "Level cap. Relocation resets the challenge, never your level. §6.16"
		col.add_child(cap)

	var hint := Label.new()
	hint.text = "space or click to continue"
	col.add_child(hint)


func _build() -> void:
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.03, 0.08, 0.95)
	root.add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 28)
	root.add_child(margin)

	col = VBoxContainer.new()
	margin.add_child(col)