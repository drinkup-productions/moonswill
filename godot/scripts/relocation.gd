extends Node2D
## The bar stands up on four furry legs and walks. A scene, not a menu. §6.7

const FORAGE_SCENE := "res://scenes/forage/forage.tscn"

const RISE_END := 1.6
const WALK_END := 5.0
const READY := 6.0

var t := 0.0
var phase := 0
var scroll := 0.0
var label: Label
var hint: Label
var destination := ""


func _ready() -> void:
	destination = RegionDB.display(Game.region)
	var layer := CanvasLayer.new()
	add_child(layer)

	label = Label.new()
	label.position = Vector2(48, 48)
	layer.add_child(label)

	hint = Label.new()
	hint.position = Vector2(48, 660)
	layer.add_child(hint)


func _process(delta: float) -> void:
	t += delta
	if t < RISE_END:
		phase = 0
		label.text = "The bar stands up."
	elif t < WALK_END:
		phase = 1
		scroll += delta * 120.0
		label.text = "Four furry legs, and a long way to go."
	else:
		phase = 2
		label.text = "It settles in %s." % destination
		hint.text = "SPACE to go on"

	if t >= READY:
		hint.text = "SPACE to go on"
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if t < READY:
		return
	if event.is_action_pressed("confirm"):
		Game.pending_relocation = false
		get_tree().change_scene_to_file(FORAGE_SCENE)


func _draw() -> void:
	var ground := 430.0
	draw_rect(Rect2(0, ground, 1280, 290), Color(0.10, 0.14, 0.12))

	# scrolling ground marks, so the walk reads as movement
	var marks := int(scroll / 90.0) + 10
	for i in marks:
		var x := float(i) * 90.0 - fmod(scroll, 90.0)
		draw_rect(Rect2(x, ground + 40, 42, 6), Color(0.14, 0.20, 0.16))

	var lift := 0.0
	if phase == 0:
		lift = (1.0 - t / RISE_END) * 46.0
	var bob := 0.0
	if phase == 1:
		bob = sin(t * 7.0) * 7.0

	var body := Rect2(540, ground - 170 - lift + bob, 200, 140)
	draw_rect(body, Color(0.52, 0.36, 0.16))
	draw_rect(Rect2(body.position + Vector2(14, 14), Vector2(58, 46)), Color(0.86, 0.72, 0.30))
	draw_rect(Rect2(body.position + Vector2(128, 14), Vector2(58, 46)), Color(0.86, 0.72, 0.30))

	# four legs
	for i in 4:
		var lx := 552.0 + float(i) * 56.0
		var swing := 0.0
		if phase == 1:
			swing = sin(t * 7.0 + float(i) * PI * 0.5) * 16.0
		draw_line(Vector2(lx, body.position.y + 140), Vector2(lx + swing, ground + 14), Color(0.36, 0.26, 0.14), 9.0)
		draw_circle(Vector2(lx + swing, ground + 14), 8.0, Color(0.20, 0.16, 0.12))