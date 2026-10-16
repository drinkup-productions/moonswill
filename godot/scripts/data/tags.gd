class_name Tags
extends RefCounted
## Tag -> attribute deltas. Effects are derived from tag combinations,
## never from a per-ingredient lookup. Design ref: docs/design.md §6.3

const EFFECTS := {
	"sweet":  {"belly": 1, "chest": 1},
	"bloom":  {"chest": 1},
	"firm":   {"muscle": 1},
	"bitter": {"height": 1, "belly": -1},
	"heat":   {"belly": 1, "hips": 1},
	"wild":   {"muscle": 1, "height": 1},
	"bog":    {"hips": 1, "belly": 1},
	"tonic":  {"height": 1, "muscle": 1, "belly": -1},
	"rich":   {"belly": 2},
}


static func effect_of(tag: String) -> Dictionary:
	return EFFECTS.get(tag, {})


## Which tags move a given attribute. Used by foraging to work out what a
## night's roster actually demands. §6.14
static func tags_raising(p_attr: String) -> Array:
	var out: Array = []
	for t in EFFECTS.keys():
		if int(EFFECTS[t].get(p_attr, 0)) > 0:
			out.append(t)
	return out


static func tags_lowering(p_attr: String) -> Array:
	var out: Array = []
	for t in EFFECTS.keys():
		if int(EFFECTS[t].get(p_attr, 0)) < 0:
			out.append(t)
	return out