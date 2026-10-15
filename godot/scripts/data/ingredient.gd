class_name Ingredient
extends RefCounted

var id: String
var display_name: String
var tags: Array = []


func _init(p_id: String, p_name: String, p_tags: Array = []) -> void:
	id = p_id
	display_name = p_name
	tags = p_tags.duplicate()


func effect() -> Dictionary:
	var out := Attributes.zero()
	for t in tags:
		var e := Tags.effect_of(t)
		for k in e:
			out[k] += e[k]
	return out
func tags_text() -> String:
	return "no effect" if tags.is_empty() else ", ".join(PackedStringArray(tags))
