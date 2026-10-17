class_name PatronFactory
extends RefCounted
## Builds a region's standing cast, and rolls tonight's arrivals from it.
## Design ref: docs/design.md §6.18, §7.1 (species), §7.3 (archetypes)

const WILDCARD_CHANCE := 0.17          # §7.3 — "rare, roughly 1 in 6"
const WILDCARD_LINE := "\"...Whatever you have got. Surprise me.\""
const POP_PER_REGION := 8

const SPECIES := {
	"human": {
		"pos": ["belly", "height", "muscle"], "neg": [],
		"names": ["Dell", "Ovid", "Pike", "Sable", "Corl", "Nim"],
		"lines": ["\"A bit more of me, if you can.\"", "\"Nothing drastic. Just... more.\""],
	},
	"felinid": {
		"pos": ["height"], "neg": ["belly"],
		"names": ["Saff", "Nim", "Quill", "Tarrow", "Vess"],
		"lines": ["\"Slimmer. Taller. Sleek.\"", "\"Trim the belly, stretch the frame.\""],
	},
	"canid": {
		"pos": ["muscle", "height"], "neg": [],
		"names": ["Fenn", "Hollow", "Tam", "Rusk", "Brack"],
		"lines": ["\"Bigger. Stronger. You know how it is.\"", "\"I want to fill a doorway.\""],
	},
	"equine": {
		"pos": ["height", "muscle"], "neg": [],
		"names": ["Orrin", "Clyde", "Hesta", "Bram", "Gorst"],
		"lines": ["\"Taller. Stronger.\"", "\"Make me worth the room I take up.\""],
	},
	"lizard-folk": {
		"pos": ["belly", "hips"], "neg": [],
		"names": ["Varan", "Chit", "Molw", "Sekk"],
		"lines": ["\"Cold out. Put some bulk on me.\"", "\"Wider. Warmer.\""],
	},
	"bovine": {
		"pos": ["chest", "hips", "belly"], "neg": [],
		"names": ["Hilda", "Moss", "Ferrow", "Dun", "Bess"],
		"lines": ["\"I want to feel... fuller. Softer.\"", "\"More of me to bring.\""],
	},
}


## Four authored regulars plus four procedural randoms. Deterministic per
## region, so a save's cast is stable.
static func build_population(p_region: String) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("moonswill-pop-%s" % p_region)
	var out: Array = []
	var used := {}

	for entry in CharacterDB.regulars_for(p_region):
		var p := Patron.make(str(entry["name"]), str(entry["species"]))
		p.id = "%s:%s" % [p_region, p.name]
		p.region = p_region
		p.authored = true
		p.affinity = int(Game.affinity.get(p.id, 0))
		used[p.name] = true
		out.append(p)

	var keys: Array = RegionDB.species_for(p_region)
	var guard := 0
	while out.size() < POP_PER_REGION and guard < 80:
		guard += 1
		var sp: String = keys[rng.randi_range(0, keys.size() - 1)]
		var nm := _pick_name(rng, sp, used)
		var p := Patron.make(nm, sp)
		p.id = "%s:%s" % [p_region, nm]
		p.region = p_region
		p.affinity = int(Game.affinity.get(p.id, 0))
		out.append(p)

	return out


## Tonight's arrivals: four or five, drawn from the whole cast, with fresh
## requests. Bodies, affinity and garments come from the population. §6.18
static func roll_night(p_population: Array, p_count: int, p_strictness: float,
		p_rng: RandomNumberGenerator) -> Array:
	var pool := p_population.duplicate()
	_shuffle(p_rng, pool)
	var out: Array = []
	for i in mini(p_count, pool.size()):
		var p: Patron = pool[i]
		p.req = _make_request(p_rng, p.species, p_strictness)
		p.treat = TreatFactory.roll(p.species, p.affinity, p_rng)
		out.append(p)
	return out


static func _pick_name(rng: RandomNumberGenerator, p_species: String, p_used: Dictionary) -> String:
	var pool: Array = SPECIES[p_species]["names"]
	for _i in 8:
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


static func _make_request(rng: RandomNumberGenerator, p_species: String,
		p_strictness: float = 0.0) -> PatronRequest:
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
	strict += p_strictness

	return PatronRequest.make(kind, _line(rng, p_species, kind), want, strict)


static func _line(rng: RandomNumberGenerator, p_species: String, p_kind: PatronRequest.Kind) -> String:
	if p_kind == PatronRequest.Kind.PROXY:
		var others: Array = ["partner", "sister", "crewmate", "date"]
		return "\"...for my %s, not me. Same as last time.\"" % others[rng.randi_range(0, others.size() - 1)]
	var lines: Array = SPECIES[p_species]["lines"]
	return lines[rng.randi_range(0, lines.size() - 1)]


static func _shuffle(rng: RandomNumberGenerator, arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp