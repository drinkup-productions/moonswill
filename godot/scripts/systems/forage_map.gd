class_name ForageMap
extends RefCounted
## The day's spots. Every pool is fully visible before a search is spent —
## planning, not gambling. Design ref: docs/design.md §6.14

const THEMES := [
	{"name": "Sunny Meadow",  "tags": ["sweet", "bloom"]},
	{"name": "Bog Hollow",    "tags": ["bog", "bitter"]},
	{"name": "Ember Ridge",   "tags": ["heat", "wild"]},
	{"name": "Stone Orchard", "tags": ["firm", "bitter"]},
	{"name": "Riverbank",     "tags": ["tonic", "wild"]},
	{"name": "Old Cellar",    "tags": ["rich", "sweet"]},
	{"name": "Chalk Flats",   "tags": ["firm", "tonic"]},
	{"name": "Fogfen",        "tags": ["bog", "bloom"]},
	{"name": "Ashfall",       "tags": ["heat", "rich"]},
	{"name": "Greyhollow",    "tags": ["bitter", "bog"]},
]

const THEME_BIAS := 0.75

var spots: Array = []
var allowed: Array = []          # region palette; empty means everything


static func build(p_day: int, p_spot_count: int, p_pool_size: int,
		p_needed_tags: Array, p_db: Node, p_allowed: Array = []) -> ForageMap:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("moonswill-forage-%d-%s" % [p_day, Game.region])
	var m := ForageMap.new()
	m.allowed = p_allowed.duplicate()
	if m.allowed.is_empty():
		for id in p_db.all.keys():
			m.allowed.append(id)

	var themes: Array = THEMES.duplicate()
	_shuffle(rng, themes)
	var count := mini(p_spot_count, themes.size())
	for i in count:
		var th: Dictionary = themes[i]
		m.spots.append({
			"id": i,
			"name": th["name"],
			"tags": th["tags"].duplicate(),
			"pool": {},
			"searched": false,
		})

	for t in p_needed_tags:
		var target := m._spot_for_tag(rng, t)
		if not target.is_empty():
			m._force(rng, target, t, p_db)

	for s in m.spots:
		while m._pool_total(s) < p_pool_size:
			m._add_random(rng, s, p_db)

	return m


func spot(p_id: int) -> Dictionary:
	for s in spots:
		if s["id"] == p_id:
			return s
	return {}


func open_spots() -> Array:
	var out: Array = []
	for s in spots:
		if not s["searched"] and not s["pool"].is_empty():
			out.append(s)
	return out


func search(p_id: int) -> Dictionary:
	var s := spot(p_id)
	if s.is_empty() or s["searched"]:
		return {}
	var got: Dictionary = s["pool"]
	s["pool"] = {}
	s["searched"] = true
	return got


func _candidates(p_db: Node) -> Array:
	var out: Array = []
	for id in allowed:
		if not p_db.is_diluent(id):
			out.append(id)
	return out


func _pool_total(s: Dictionary) -> int:
	var n := 0
	for k in s["pool"]:
		n += int(s["pool"][k])
	return n


func _spot_for_tag(rng: RandomNumberGenerator, p_tag: String) -> Dictionary:
	var themed: Array = []
	for s in spots:
		if s["tags"].has(p_tag):
			themed.append(s)
	if not themed.is_empty():
		return themed[rng.randi_range(0, themed.size() - 1)]
	if spots.is_empty():
		return {}
	return spots[rng.randi_range(0, spots.size() - 1)]


func _force(rng: RandomNumberGenerator, s: Dictionary, p_tag: String, db: Node) -> void:
	var carriers: Array = []
	for id in allowed:
		if db.is_diluent(id):
			continue
		if db.get_ingredient(id).tags.has(p_tag):
			carriers.append(id)
	if carriers.is_empty():
		return
	var pick: String = carriers[rng.randi_range(0, carriers.size() - 1)]
	_bump(s, pick)


func _add_random(rng: RandomNumberGenerator, s: Dictionary, db: Node) -> void:
	var pool := _candidates(db)
	if pool.is_empty():
		return
	var themed: Array = []
	for id in pool:
		var ing: Ingredient = db.get_ingredient(id)
		for t in s["tags"]:
			if ing.tags.has(t):
				themed.append(id)
				break
	var source: Array = themed if (not themed.is_empty() and rng.randf() < THEME_BIAS) else pool
	var pick: String = source[rng.randi_range(0, source.size() - 1)]
	_bump(s, pick)


func _bump(s: Dictionary, p_id: String) -> void:
	var pool: Dictionary = s["pool"]
	pool[p_id] = mini(2, int(pool.get(p_id, 0)) + 1)


static func _shuffle(rng: RandomNumberGenerator, arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp