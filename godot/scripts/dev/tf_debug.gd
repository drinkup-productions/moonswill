extends Control
## Dev scene: poke a Transform, watch the descriptor AND the combatant's
## derived stats move. F6 on this scene.

const STEP := 6

var t: Transform
var c: Combatant
var profile := "humanoid"
var info_lbl: Label
var combat_lbl: Label
var reaction_lbl: Label
var log_lbl: RichTextLabel


func _ready() -> void:
	t = Transform.new("bandit")
	c = Combatant.new("Bandit", "bandit")
	c.transform = t
	c.reaction_profile = profile
	c.refresh_stats()
	_build()
	_refresh()


func _btn(parent: Node, text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.pressed.connect(cb)
	parent.add_child(b)


func _bump(amount: int) -> void:
	var events := t.apply({"belly": amount})
	c.refresh_stats()
	for r in c.react_to(events):
		_log("reaction: %s (%d turns)" % [r["name"], r["turns"]])
	_refresh()


func _cycle_profile() -> void:
	var order := ["feral", "humanoid", "brute"]
	profile = order[(order.find(profile) + 1) % order.size()]
	c.reaction_profile = profile
	_refresh()


func _log(p_text: String) -> void:
	if not log_lbl.text.is_empty():
		log_lbl.text += "\n"
	log_lbl.text += p_text


func _on_crossed(axis: String, from_stage: int, to_stage: int) -> void:
	reaction_lbl.text = "crossed %s %d -> %d" % [axis, from_stage, to_stage]
	_log("[%s] %s %d -> %d" % [profile, axis, from_stage, to_stage])


func _refresh() -> void:
	var v := t.visual()
	info_lbl.text = "base %d  blend %.2f  tear %d  silhouette %d (visible %d)  conceal %d" % [
		v["base_stage"], v["base_blend"], v["tear"],
		v["silhouette"], v["visible_silhouette"], t.concealed_stages,
	]
	var slam := ""
	for a in c.attacks():
		if a["id"] == "belly_slam":
			slam = "  belly slam %d dmg / %d ap" % [a["damage"], a["ap"]]
	combat_lbl.text = "hp %d/%d   speed %d   resist %.2f%s   effects: %s" % [
		c.hp, c.max_hp, c.speed(), c.damage_resist(), slam, c.status_text(),
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
	combat_lbl = Label.new()
	col.add_child(combat_lbl)

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
		c.effects.clear()
		c.refresh_stats()
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
	var centre := Vector2(620, 400)
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

	# hp bar
	var frac := float(c.hp) / maxi(1, c.max_hp)
	draw_rect(Rect2(centre + Vector2(-60, 110 * sc), Vector2(120, 8)), Color(0.2, 0.2, 0.24))
	draw_rect(Rect2(centre + Vector2(-60, 110 * sc), Vector2(120 * frac, 8)), Color(0.85, 0.25, 0.3))

	var font := ThemeDB.fallback_font
	draw_string(font, centre + Vector2(-80, 100 * sc), "base %d  blend %.2f" % [v["base_stage"], v["base_blend"]], HORIZONTAL_ALIGNMENT_LEFT, -1, 14)