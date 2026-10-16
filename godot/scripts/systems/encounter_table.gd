class_name EncounterTable
extends RefCounted
## What shows up in the home zone. One table for the slice. §8
## Weights are relative; min_level gates the harder mixes.

const TABLE := [
	{"defs": ["wolf"],            "weight": 40, "min_level": 1},
	{"defs": ["wolf", "wolf"],    "weight": 25, "min_level": 1},
	{"defs": ["bandit"],          "weight": 25, "min_level": 1},
	{"defs": ["bandit", "wolf"],  "weight": 10, "min_level": 3},
	{"defs": ["bandit", "bandit"],"weight":  8, "min_level": 5},
]


static func roll(p_rng: RandomNumberGenerator, p_level: int) -> Array:
	var total := 0
	for e in TABLE:
		if int(e["min_level"]) <= p_level:
			total += int(e["weight"])
	if total <= 0:
		return []
	var pick := p_rng.randi_range(1, total)
	for e in TABLE:
		if int(e["min_level"]) > p_level:
			continue
		pick -= int(e["weight"])
		if pick <= 0:
			return _build(e["defs"], p_rng)
	return []


## Names are unique within an encounter, so two bandits are never both Rook.
static func _build(p_def_ids: Array, p_rng: RandomNumberGenerator) -> Array:
	var out: Array = []
	var used := {}
	for id in p_def_ids:
		var c := EnemyDB.spawn(str(id), p_rng, used)
		if c != null:
			out.append(c)
	return out