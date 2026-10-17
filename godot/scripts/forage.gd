extends Control
## Grey-box morning forage. Design ref: docs/design.md §6.14
## Contents are visible before a search is spent. Choosing is the game.

const OVERWORLD_SCENE := "res://scenes/overworld/overworld.tscn"
const BREW_SCENE := "res://scenes/brew/brew.tscn"
const EXPERIMENT_SCENE := "res://scenes/experiment/experiment.tscn"

var status_lbl: Label
var level_lbl: Label
var need_box: VBoxContainer
var cover_lbl: Label
var spot_grid: GridContainer
var pantry_lbl: RichTextLabel
var hint_lbl: Label
var open_btn: Button
var journal_ui: JournalUI
var save_ui: SaveUI
var exp_btn: Button

func _ready() -> void:
	if Game.forage == null:
		Game.start_day()
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


func _count(d: Dictionary) -> int:
	var n := 0
	for k in d:
		n += int(d[k])
	return n


func _tag_covered(t: String) -> bool:
	for id in Game.inventory.keys():
		if int(Game.inventory[id]) <= 0:
			continue
		var ing: Ingredient = IngredientDB.get_ingredient(id)
		if ing != null and ing.tags.has(t):
			return true
	return false


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


func _on_new_run() -> void:
	Save.delete_save(Game.AUTOSAVE_SLOT)
	Game.reset_run()
	_refresh()


func _on_search(p_id: int) -> void:
	if Game.searches_left <= 0:
		return
	var got := Game.forage.search(p_id)
	if got.is_empty():
		return
	Game.spend_search()
	for id in got.keys():
		Game.add_item(id, int(got[id]))
		Game.stock_today.append(id)
	hint_lbl.text = "Gathered %d." % _count(got)
	_refresh()


func _on_open() -> void:
	Game.open_the_bar()
	get_tree().change_scene_to_file(BREW_SCENE)


func _on_wander() -> void:
	get_tree().change_scene_to_file(OVERWORLD_SCENE)


func _on_move_on() -> void:
	Game.move_on()
	get_tree().change_scene_to_file(Game.next_scene())


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


func _refresh() -> void:
	status_lbl.text = "Day %d (moon %d/%d)  ·  %s  ·  %s     searches %d / %d     weight %d (stage %d, seen %d)     attention %d" % [
		Game.day, Game.moon_day, Game.MOON_DAYS,
		RegionDB.display(Game.region),
		"weakened" if Game.is_weakened() else "steady",
		Game.searches_left, Levels.searches(),
		Game.weight, Game.bulk_stage(), Game.visible_bulk(), Game.attention,
	]
	level_lbl.text = Levels.progress_text()
	_refresh_experiment()
	_refresh_customers()
	_refresh_coverage()
	_refresh_spots()
	_refresh_pantry()
	_refresh_footer()
	
func _refresh_experiment() -> void:
	if exp_btn == null:
		return
	if Game.in_experiment:
		exp_btn.text = "back to the bench"
		exp_btn.disabled = false
	elif Game.experiment_ready():
		exp_btn.text = "experiment day"
		exp_btn.disabled = false
	else:
		exp_btn.text = "experiment in %d days" % Game.experiment_cooldown_left()
		exp_btn.disabled = true


func _on_experiment() -> void:
	if not Game.in_experiment:
		Game.begin_experiment()
	get_tree().change_scene_to_file(EXPERIMENT_SCENE)

func _refresh_customers() -> void:
	_clear(need_box)
	if Game.roster.is_empty():
		_label(need_box, "Nobody booked in. Odd.")
		return
	for p in Game.roster:
		var req: PatronRequest = p.req
		var tag := "  (regular)" if p.affinity >= 3 else ""
		_label(need_box, "%s — %s — %s%s" % [p.name, p.species, PatronRequest.LABEL[req.kind], tag])
		_label(need_box, "      %s" % req.line)
		var mark_txt := "no target — bold and focused" if req.is_wildcard() else Attributes.pretty(req.want)
		_label(need_box, "      mark: %s   (%s)" % [mark_txt, req.note])


func _refresh_coverage() -> void:
	var parts: Array[String] = []
	for t in Game.needed_tags():
		parts.append("%s %s" % [t, "ok" if _tag_covered(t) else ".."])
	cover_lbl.text = "   ".join(parts) if not parts.is_empty() else "nothing specific tonight"


func _refresh_spots() -> void:
	_clear(spot_grid)
	for s in Game.forage.spots:
		var b := Button.new()
		var lines: Array[String] = []
		var pool: Dictionary = s["pool"]
		if pool.is_empty():
			lines.append("(picked clean)")
		else:
			for id in pool.keys():
				var ing: Ingredient = IngredientDB.get_ingredient(id)
				lines.append("%s x%d" % [ing.display_name, int(pool[id])])
		b.text = "%s\n[%s]\n%s" % [
			s["name"], ", ".join(PackedStringArray(s["tags"])), "\n".join(lines)
		]
		b.custom_minimum_size = Vector2(196, 104)
		b.disabled = s["searched"] or Game.searches_left <= 0
		b.pressed.connect(_on_search.bind(int(s["id"])))
		spot_grid.add_child(b)


func _refresh_pantry() -> void:
	var parts: Array[String] = []
	for id in Game.inventory.keys():
		var n: int = int(Game.inventory[id])
		if n <= 0:
			continue
		var ing: Ingredient = IngredientDB.get_ingredient(id)
		if ing == null:
			continue
		parts.append("%s x%d" % [ing.display_name, n])
	parts.sort()
	pantry_lbl.text = "[b]Pantry[/b]  " + (", ".join(parts) if not parts.is_empty() else "empty")


func _refresh_footer() -> void:
	var missing: Array[String] = []
	for t in Game.needed_tags():
		if not _tag_covered(t):
			missing.append(t)
	if Game.searches_left <= 0:
		hint_lbl.text = "No searches left today. Open the bar with what you have."
	elif missing.is_empty():
		hint_lbl.text = "Every needed tag is in the pantry. Leftovers carry to tomorrow."
	else:
		hint_lbl.text = "Still uncovered: %s" % ", ".join(missing)


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)

	var scroll := ScrollContainer.new()
	margin.add_child(scroll)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(col)

	var head := HBoxContainer.new()
	col.add_child(head)
	status_lbl = _label(head, "")
	level_lbl = _label(head, "")
	var j_btn := Button.new()
	j_btn.text = "journal  (J)"
	j_btn.pressed.connect(_toggle_journal)
	head.add_child(j_btn)
	var save_btn := Button.new()
	save_btn.text = "save / load  (S)"
	save_btn.pressed.connect(_toggle_save)
	head.add_child(save_btn)
	var wander_btn := Button.new()
	wander_btn.text = "wander out"
	wander_btn.pressed.connect(_on_wander)
	head.add_child(wander_btn)
	var exp_btn = Button.new()
	exp_btn.text = "experiment day"
	exp_btn.pressed.connect(_on_experiment)
	head.add_child(exp_btn)
	var move_btn := Button.new()
	move_btn.text = "move on  (once a moon)"
	move_btn.disabled = not Game.can_move_on()
	move_btn.pressed.connect(_on_move_on)
	head.add_child(move_btn)
	var new_btn := Button.new()
	new_btn.text = "new run"
	new_btn.pressed.connect(_on_new_run)
	head.add_child(new_btn)

	_label(col, "Tonight's customers")
	var card := PanelContainer.new()
	col.add_child(card)
	need_box = VBoxContainer.new()
	card.add_child(need_box)

	_label(col, "Tags tonight needs")
	cover_lbl = _label(col, "")

	_label(col, "The wilds  —  contents visible before you search")
	spot_grid = GridContainer.new()
	spot_grid.columns = 4
	col.add_child(spot_grid)

	pantry_lbl = RichTextLabel.new()
	pantry_lbl.bbcode_enabled = true
	pantry_lbl.custom_minimum_size = Vector2(0, 56)
	col.add_child(pantry_lbl)

	hint_lbl = _label(col, "")

	open_btn = Button.new()
	open_btn.text = "Open the bar ->"
	open_btn.pressed.connect(_on_open)
	col.add_child(open_btn)
