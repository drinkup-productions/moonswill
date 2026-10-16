extends Node
## Chugs's journal. Persistent discovered knowledge. Autoloaded as `Journal`.
## Design ref: docs/design.md §6.15

signal entry_learned(kind: String, id: String)

## What a fresh save already knows, so the notebook starts about a third
## filled rather than empty. §6.15
const STARTER := ["sunmelon", "bogroot", "ironoats"]

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


func known_count() -> int:
	return known_ingredients.size()


func total_ingredients() -> int:
	return maxi(1, IngredientDB.all.size() - 1)   # wellwater has no effect


## Called on a brand-new run only. Loaded saves carry their own journal.
func seed_starter() -> void:
	for id in STARTER:
		var ing: Ingredient = IngredientDB.get_ingredient(id)
		if ing != null:
			learn_ingredient(id, ing.tags)


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