class_name EnemyDB
extends RefCounted
## Enemy definitions. Data only — nothing here knows a battle is happening.
## Design ref: docs/design.md §8

const DEFS := {
	"wolf": {
		"display": "Grey Wolf",
		"species": "wolf",
		"profile": "feral",
		"hp": 12,
		"ap": 3,
		"names": ["Grey Wolf", "Lean Wolf", "Old Wolf", "Scarred Wolf", "Pack Wolf"],
		"attacks": [
			{"id": "bite",  "name": "Bite",  "ap": 1, "damage": 4, "weight_scale": 0.0},
			{"id": "lunge", "name": "Lunge", "ap": 2, "damage": 7, "weight_scale": 0.0},
		],
		"loot_tags": ["wild", "firm"],
		"loot_min": 1,
		"loot_max": 2,
		"brew_range": [0, 1],
	},
	"bandit": {
		"display": "Bandit",
		"species": "human",          # rolled from BANDIT_SPECIES
		"profile": "",               # rolled: humanoid or brute
		"hp": 16,
		"ap": 3,
		"names": ["Rook", "Vell", "Mab", "Cray", "Oss", "Tull", "Fitch", "Sorrel"],
		"attacks": [
			{"id": "jab",    "name": "Jab",    "ap": 1, "damage": 3, "weight_scale": 0.0},
			{"id": "cudgel", "name": "Cudgel", "ap": 1, "damage": 6, "weight_scale": 0.0},
		],
		"loot_tags": ["rich", "firm"],
		"loot_min": 1,
		"loot_max": 2,
		"brew_range": [1, 2],
	},
}

const BANDIT_SPECIES := ["human", "canid", "felinid", "equine"]


## Species is flavour and reaction only for the slice; art keys off the
## def id, so one bandit art set covers every species of bandit.
static func spawn(p_def_id: String, rng: RandomNumberGenerator, p_used: Dictionary = {}) -> Combatant:
	var d: Dictionary = DEFS.get(p_def_id, {})
	if d.is_empty():
		return null

	var species := str(d["species"])
	if p_def_id == "bandit":
		species = BANDIT_SPECIES[rng.randi_range(0, BANDIT_SPECIES.size() - 1)]

	var profile := str(d["profile"])
	if profile.is_empty():
		profile = ReactionTable.profile_for(species, rng)

	var c := Combatant.new(_name_for(d, rng, p_used), species)
	c.def_id = p_def_id
	c.reaction_profile = profile
	c.max_hp = int(d["hp"])
	c.hp = c.max_hp
	c.ap_max = int(d["ap"])
	c.ap = c.ap_max
	c.attack_list = d["attacks"].duplicate(true)
	c.brews = roll_brews(rng, d["brew_range"])
	return c


static func _name_for(d: Dictionary, rng: RandomNumberGenerator, p_used: Dictionary) -> String:
	var pool: Array = d["names"]
	for _i in 6:
		var n: String = pool[rng.randi_range(0, pool.size() - 1)]
		if not p_used.has(n):
			p_used[n] = true
			return n
	var fallback: String = pool[rng.randi_range(0, pool.size() - 1)]
	p_used[fallback] = true
	return fallback


static func roll_brews(rng: RandomNumberGenerator, p_range: Array) -> Array:
	var n := rng.randi_range(int(p_range[0]), int(p_range[1]))
	var ids: Array = []
	for id in IngredientDB.all.keys():
		if not IngredientDB.is_diluent(id):
			ids.append(id)
	var out: Array = []
	for _i in n:
		out.append(ids[rng.randi_range(0, ids.size() - 1)])
	return out


## Loot comes off tags, not a fixed list, so it stays in step with brewing.
## A transformed enemy drops the same thing either way (§8).
static func roll_loot(p_def_id: String, rng: RandomNumberGenerator) -> Dictionary:
	var d: Dictionary = DEFS.get(p_def_id, {})
	if d.is_empty():
		return {}
	var pool: Array = []
	for id in IngredientDB.all.keys():
		if IngredientDB.is_diluent(id):
			continue
		for t in d["loot_tags"]:
			if IngredientDB.get_ingredient(id).tags.has(t):
				pool.append(id)
				break
	var out: Dictionary = {}
	if pool.is_empty():
		return out
	for _i in rng.randi_range(int(d["loot_min"]), int(d["loot_max"])):
		var pick: String = pool[rng.randi_range(0, pool.size() - 1)]
		out[pick] = int(out.get(pick, 0)) + 1
	return out