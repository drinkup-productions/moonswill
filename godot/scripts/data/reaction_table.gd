class_name ReactionTable
extends RefCounted
## What a character does when an axis crosses a stage. Pure data. §8
## Keyed by reaction PROFILE, not species, so two individuals of one type
## can react differently for zero extra art.

enum Kind { NONE, DISTRACTED, GUARD_DOWN, SLOWED, ENRAGED, STOP, FLEE }

const PROFILES := {
	"feral": {
		"belly": {
			2: {"kind": Kind.SLOWED, "turns": 2},
			4: {"kind": Kind.SLOWED, "turns": 99},
			5: {"kind": Kind.STOP},
		},
	},
	"humanoid": {
		"belly": {
			2: {"kind": Kind.DISTRACTED, "turns": 1},
			4: {"kind": Kind.GUARD_DOWN, "turns": 2},
		},
		"chest": {
			3: {"kind": Kind.DISTRACTED, "turns": 1},
			4: {"kind": Kind.STOP},
		},
		"hips": {
			3: {"kind": Kind.DISTRACTED, "turns": 1},
			4: {"kind": Kind.STOP},
		},
		"muscle": {
			3: {"kind": Kind.ENRAGED},
		},
	},
	## The counter-example: bulking a brute makes him dangerous.
	"brute": {
		"belly":  {3: {"kind": Kind.ENRAGED}},
		"muscle": {3: {"kind": Kind.ENRAGED}},
	},
}


## Highest threshold at or below p_stage. Returns {} for no reaction.
static func lookup(p_profile: String, p_axis: String, p_stage: int) -> Dictionary:
	var prof: Dictionary = PROFILES.get(p_profile, {})
	var axis: Dictionary = prof.get(p_axis, {})
	var best: Dictionary = {}
	var best_at := -1
	for s in axis.keys():
		if int(s) <= p_stage and int(s) > best_at:
			best_at = int(s)
			best = axis[s]
	return best


static func kind_name(p_kind: int) -> String:
	var names := Kind.keys()
	if p_kind < 0 or p_kind >= names.size():
		return "?"
	return names[p_kind]


static func profile_for(p_species: String, rng: RandomNumberGenerator) -> String:
	if p_species == "wolf" or p_species == "bear":
		return "feral"
	return "brute" if rng.randf() < 0.35 else "humanoid"