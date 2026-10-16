class_name RegionDB
extends RefCounted
## Regions. Each has a home species pool and an available tag palette, so
## moving genuinely changes what is on the shelf. §6.7, §6.8

const REGIONS := {
	"home": {
		"display": "the near downs",
		"species": ["human", "bovine", "felinid"],
		"tags": ["sweet", "bloom", "firm", "bitter", "bog"],
		"strictness": 0.0,
		"unlock_level": 1,
	},
	"the fens": {
		"display": "the fens",
		"species": ["lizard-folk", "bovine", "felinid"],
		"tags": ["bog", "rich", "tonic", "bitter", "heat"],
		"strictness": 0.05,
		"unlock_level": 4,
	},
	"the high downs": {
		"display": "the high downs",
		"species": ["equine", "canid", "human"],
		"tags": ["wild", "heat", "firm", "tonic", "rich"],
		"strictness": 0.10,
		"unlock_level": 7,
	},
}

const ORDER := ["home", "the fens", "the high downs"]


static func get_region(p_id: String) -> Dictionary:
	return REGIONS.get(p_id, REGIONS["home"])


static func display(p_id: String) -> String:
	return str(get_region(p_id)["display"])


static func species_for(p_id: String) -> Array:
	return (get_region(p_id)["species"] as Array).duplicate()


static func strictness_for(p_id: String) -> float:
	return float(get_region(p_id)["strictness"])


## Ingredient ids whose tags intersect the region palette. Wellwater always.
static func allowed_ingredients(p_id: String, db: Node) -> Array:
	var tags: Array = get_region(p_id)["tags"]
	var out: Array = []
	for id in db.all.keys():
		if db.is_diluent(id):
			out.append(id)
			continue
		var ing: Ingredient = db.get_ingredient(id)
		for t in ing.tags:
			if tags.has(t):
				out.append(id)
				break
	return out


static func unlocked(p_id: String, p_level: int) -> bool:
	return p_level >= int(get_region(p_id)["unlock_level"])


## The next region along the spine that this level can reach.
static func next_unlocked(p_current: String, p_level: int) -> String:
	var i := ORDER.find(p_current)
	if i < 0:
		i = 0
	for step in range(1, ORDER.size()):
		var candidate: String = ORDER[(i + step) % ORDER.size()]
		if unlocked(candidate, p_level):
			return candidate
	return p_current