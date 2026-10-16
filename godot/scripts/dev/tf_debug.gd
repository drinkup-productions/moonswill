extends Control
## Dev scene: poke a Transform, watch the art-facing descriptor move.
## F6 on this scene. Validates the contract long before art exists.

const STEP := 6

var t: Transform
var profile := "humanoid"
var info_lbl: Label
var reaction_lbl: Label
var log_lbl: RichTextLabel


func _ready() -> void:
	t = Transform.new("bandit")
	t.crossed.connect(_on_crossed)
	_build()
	_refresh()


func _btn(parent: Node, text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.pressed.connect(cb)
	parent.add_child(b)


func _bump(amount: int) -> void:
	t.apply({"belly": amount})
	_refresh()


func _cycle_profile() -> void:
	var order := ["feral", "humanoid", "brute"]
	profile = order[(order.find(profile) + 1) % order.size()]
	_refresh()


func _on_crossed(axis: String, from_stage: int, to_stage: int) -> void:
	var r := ReactionTable.lookup(profile, axis, to_stage)
	var kind := ReactionTable.kind_name(int(r.get("kind", ReactionTable.Kind.NONE)))
	reaction_lbl.text = "crossed %s %d -> %d    reaction: %s" % [axis, from_stage, to_stage, kind]
	if not log_lbl.text.is_empty():
		log_lbl.text += "\n"
	log_lbl.text += "[%s] %s %d->%d : %s" % [profile, axis, from_stage, to_stage, kind]


func _refresh() -> void:
	var v := t.visual()
	info_lbl.text = "profile %s  |  base %d  blend %.2f  tear %d  silhouette %d (visible %d)  conceal %d" % [
		profile, v["base_stage"], v["base_blend"], v["tear"],
		v["silhouette"], v["visible_silhouette"], t.concealed_stages,
	]
	queue_redraw()


func _build() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	add_child(margin)

	var col := VBoxContainer.new()
	margin.add_child(col)

	info_lbl = Label.new()
	col.add_child(info_lbl)

	var row := HBoxContainer.new()
	col.add_child(row)
	_btn(row, "bulk +1", func() -> void: _bump(STEP))
	_btn(row, "bulk +2", func() -> void: _bump(STEP * 2))
	_btn(row, "bulk -1", func() -> void: _bump(-STEP))
	_btn(row, "conceal +1", func() -> void:
		t.concealed_stages += 1
		_refresh()
	)
	_btn(row, "conceal 0", func() -> void:
		t.concealed_stages = 0
		_refresh()
	)
	_btn(row, "cycle profile", _cycle_profile)
	_btn(row, "reset", func() -> void:
		t.points["belly"] = 0
		_refresh()
	)

	reaction_lbl = Label.new()
	col.add_child(reaction_lbl)

	log_lbl = RichTextLabel.new()
	log_lbl.bbcode_enabled = true
	log_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(log_lbl)


func _draw() -> void:
	var v := t.visual()
	var centre := Vector2(620, 380)
	var sc := 1.0 + float(v["visible_silhouette"]) * 0.22
	draw_circle(centre, 40.0 * sc, Color(0.66, 0.33, 0.97, 0.5))

	var belly := 0
	for o in v["overlays"]:
		if o["axis"] == "belly":
			belly = int(o["stage"])
	if belly > 0:
		draw_circle(centre + Vector2(0, 18 * sc), 26.0 * (1.0 + belly * 0.25), Color(0.9, 0.6, 0.3, 0.6))

	for i in v["tear"]:
		draw_arc(centre, 44.0 * sc + i * 7.0, 0.0, TAU, 32, Color(1, 0.4, 0.4), 2.0)

	var font := ThemeDB.fallback_font
	draw_string(font, centre + Vector2(-80, 96 * sc), "base %d  blend %.2f" % [v["base_stage"], v["base_blend"]], HORIZONTAL_ALIGNMENT_LEFT, -1, 14)