extends Node
## All ingredients. Autoloaded as `IngredientDB`.
## Wellwater has no tags: the anti-stuck valve and the diluent. §6.14

const WELLWATER := "wellwater"

var all: Dictionary = {}


func _ready() -> void:
	_add("sunmelon",    "Sunmelon",    ["sweet", "bloom"])
	_add("bogroot",     "Bogroot",     ["bog", "bitter"])
	_add("emberpepper", "Emberpepper", ["heat", "wild"])
	_add("cloudberry",  "Cloudberry",  ["sweet", "firm"])
	_add("ironoats",    "Ironoats",    ["firm", "tonic"])
	_add("marshfig",    "Marshfig",    ["bog", "rich"])
	_add("skywort",     "Skywort",     ["tonic", "wild"])
	_add("honeycap",    "Honeycap",    ["sweet", "rich"])
	_add("stoneplum",   "Stoneplum",   ["firm", "bitter"])
	_add("glowmoss",    "Glowmoss",    ["bloom", "heat"])
	_add(WELLWATER,     "Wellwater",   [])


func _add(id: String, display: String, tags: Array) -> void:
	all[id] = Ingredient.new(id, display, tags)


func get_ingredient(id: String) -> Ingredient:
	return all.get(id)


func is_diluent(id: String) -> bool:
	var i := get_ingredient(id)
	return i != null and i.tags.is_empty()