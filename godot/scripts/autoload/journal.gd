extends Node
## Chugs's journal. Persistent discovered knowledge. Autoloaded as `Journal`.
## Design ref: docs/design.md §6.15

signal entry_learned(kind: String, id: String)

var known_ingredients: Dictionary = {}   # String -> true
var known_tags: Dictionary = {}          # String -> true


func learn_ingredient(id: String, tags: Array) -> void:
	if known_ingredients.has(id):
		return
	known_ingredients[id] = true
	for t in tags:
		known_tags[t] = true
	entry_learned.emit("ingredient", id)


func knows_ingredient(id: String) -> bool:
	return known_ingredients.has(id)


func knows_tag(id: String) -> bool:
	return known_tags.has(id)


func serialize() -> Dictionary:
	return {
		"ingredients": known_ingredients.keys(),
		"tags": known_tags.keys(),
	}


func deserialize(data: Dictionary) -> void:
	known_ingredients.clear()
	known_tags.clear()
	for i in data.get("ingredients", []):
		known_ingredients[i] = true
	for t in data.get("tags", []):
		known_tags[t] = true


func reset() -> void:
	known_ingredients.clear()
	known_tags.clear()