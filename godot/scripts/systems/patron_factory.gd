class_name PatronFactory
extends RefCounted
## Builds a night's roster. Deterministic per day, so a day is reproducible.
## Design ref: docs/design.md §7.1 (species), §7.3 (archetypes)

const WILDCARD_CHANCE := 0.17          # §7.3 — "rare, roughly 1 in 6"
const WILDCARD_LINE := "\"...Whatever you have got. Surprise me.\""

## Species is a read, not a rule. §7.1. `pos` are the attributes they
## tend to want raised, `neg` the ones they tend to want trimmed.
const SPECIES := {
	"human": {
		"pos": ["belly", "height", "muscle"],
		"neg": [],
		"names": ["Dell", "Marta", "Ovid", "Hanne", "Pike", "Sable", "Corl"],
		"lines": [
			"\"A bit more of me, if you can.\"",
			"\"Nothing drastic. Just... more.\"",
		],
	},
	"felinid": {
		"pos": ["height"],
		"neg": ["belly"],
		"names": ["Rill", "Saff", "Nim", "Quill", "Vess", "Tarrow"],
		"lines": [
			"\"Slimmer. Taller. Sleek.\"",
			"\"Trim the belly, stretch the frame.\"",
		],
	},
	"canid": {
		"pos": ["muscle", "height"],
		"neg": [],
		"names": ["Brack", "Fenn", "Hollow", "Tam", "Rusk"],
		"lines": [
			"\"Bigger. Stronger. You know how it is.\"",
			"\"I want to fill a doorway.\"",
		],
	},
	"equine": {
		"pos": ["height", "muscle"],
		"neg": [],
		"names": ["Gorst", "Orrin", "Clyde", "Hesta", "Bram"],
		"lines": [
			"\"Taller. Stronger.\"",
			"\"Make me worth the room I take up.\"",
		],
	},
	"lizard-folk": {
		"pos": ["belly", "hips"],
		"neg": [],
		"names": ["Sekk", "Varan", "Chit", "Molw", "Pim"],
		"lines": [
			"\"Cold out. Put some bulk on me.\"",
			"\"Wider. Warmer.\"",
		],
	},
	"bovine": {
		"pos": ["chest", "hips", "belly"],
		"neg": [],
		"names": ["Bess", "Hilda", "Moss", "Ferrow", "Dun"],
		"lines": [
			"\"I want to feel... fuller. Softer.\"",
			"\"More of me to bring.\"",
		],
	},
}


static func build_night(p_day: int, p_count: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("moonswill-roster-%d" % p_day)
	var out: Array = []
	var keys: Array = SPECIES.keys()
	var used := {}
	var pt := Patron.make(nm, sp, _make_request(rng, sp))
		if rng.randf() < 0.25:
			pt.affinity = 3          # a regular — willing at the feast
		out.append(pt)
	for _i in p_count:
		var sp: String = keys[rng.randi_range(0, keys.size() - 1)]
		var nm := _pick_name(rng, sp, used)
		out.append(Patron.make(nm, sp, _make_request(rng, sp)))
	return out


static func _pick_name(rng: RandomNumberGenerator, p_species: String, p_used: Dictionary) -> String:
	var pool: Array = SPECIES[p_species]["names"]
	for _i in 6:
		var n: String = pool[rng.randi_range(0, pool.size() - 1)]
		if not p_used.has(n):
			p_used[n] = true
			return n
	var fallback: String = pool[rng.randi_range(0, pool.size() - 1)]
	p_used[fallback] = true
	return fallback


static func _roll_kind(rng: RandomNumberGenerator) -> PatronRequest.Kind:
	var r := rng.randf()
	if r < WILDCARD_CHANCE:
		return PatronRequest.Kind.WILDCARD
	if r < 0.50:
		return PatronRequest.Kind.SPECIFIC
	if r < 0.80:
		return PatronRequest.Kind.VAGUE
	return PatronRequest.Kind.PROXY


static func _make_request(rng: RandomNumberGenerator, p_species: String) -> PatronRequest:
	var kind := _roll_kind(rng)
	if kind == PatronRequest.Kind.WILDCARD:
		return PatronRequest.make(kind, WILDCARD_LINE, {}, 1.0)

	var want := {}
	var slots: Array = SPECIES[p_species]["pos"].duplicate()
	var n := mini(rng.randi_range(1, 2), slots.size())
	for _i in n:
		var a: String = slots[rng.randi_range(0, slots.size() - 1)]
		slots.erase(a)
		want[a] = rng.randi_range(3, 5)

	var neg: Array = SPECIES[p_species]["neg"]
	if not neg.is_empty() and rng.randf() < 0.6:
		var d: String = neg[rng.randi_range(0, neg.size() - 1)]
		want[d] = -rng.randi_range(2, 3)

	var strict := 1.0
	match kind:
		PatronRequest.Kind.SPECIFIC:
			strict = 1.15
		PatronRequest.Kind.VAGUE:
			strict = 0.85

	return PatronRequest.make(kind, _line(rng, p_species, kind), want, strict)


static func _line(rng: RandomNumberGenerator, p_species: String, p_kind: PatronRequest.Kind) -> String:
	if p_kind == PatronRequest.Kind.PROXY:
		var others: Array = ["partner", "sister", "crewmate", "date"]
		return "\"...for my %s, not me. Same as last time.\"" % others[rng.randi_range(0, others.size() - 1)]
	var lines: Array = SPECIES[p_species]["lines"]
	return lines[rng.randi_range(0, lines.size() - 1)]
