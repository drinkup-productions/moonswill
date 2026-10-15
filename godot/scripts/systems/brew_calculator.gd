class_name BrewCalculator
extends RefCounted
## Pure scoring. No nodes. Design ref: docs/design.md §7.3

const WILD_MIN_MAG := 6
const WILD_MAX_MAG := 14
const WILD_MAX_TOUCHED := 3
const DIST_WEIGHT := 7
const SIDE_WEIGHT := 2


static func brew(ids: Array[String], db: Node) -> Dictionary:
	var out := Attributes.zero()
	for id in ids:
		var ing: Ingredient = db.get_ingredient(id)
		if ing == null:
			continue
		var e := ing.effect()
		for k in Attributes.LIST:
			out[k] += e[k]
	return out


static func score(res: Dictionary, req: PatronRequest) -> int:
	if req.kind == PatronRequest.Kind.WILDCARD:
		return _score_wildcard(res)
	return _score_target(res, req.want, req.strictness)


static func _score_target(res: Dictionary, want: Dictionary, strictness: float) -> int:
	var dist := 0
	var side := 0
	for a in Attributes.LIST:
		if want.has(a):
			dist += absi(res[a] - want[a])
		else:
			side += absi(res[a])
	var raw := 100.0 - (float(dist) * DIST_WEIGHT + float(side) * SIDE_WEIGHT) * strictness
	return clampi(int(round(raw)), 0, 100)


static func _score_wildcard(res: Dictionary) -> int:
	var mag := 0
	var net := 0
	var touched := 0
	var has_pos := false
	var has_neg := false
	for a in Attributes.LIST:
		var v: int = res[a]
		mag += absi(v)
		net += v
		if absi(v) >= 1:
			touched += 1
		if v > 0:
			has_pos = true
		if v < 0:
			has_neg = true

	var s := 100.0
	if mag < WILD_MIN_MAG:
		s -= float(WILD_MIN_MAG - mag) * 8.0
	if mag > WILD_MAX_MAG:
		s -= float(mag - WILD_MAX_MAG) * 5.0
	s -= float(maxi(0, touched - WILD_MAX_TOUCHED)) * 11.0
	if has_pos and has_neg:
		s -= 12.0
	if absi(net) < 4:
		s -= 18.0
	return clampi(int(round(s)), 0, 100)


static func band_line(score_value: int, wildcard: bool) -> String:
	if wildcard:
		if score_value >= 90: return 'Stares at themself. "...Do that again sometime."'
		if score_value >= 75: return '"Now THAT is something."'
		if score_value >= 55: return '"Huh. Different."'
		if score_value >= 35: return '"Bit of a muddle, that one."'
		return '"...Did it even do anything?"'
	if score_value >= 90: return 'Beams. "Perfect. Exactly what I wanted."'
	if score_value >= 75: return '"That is lovely, thank you."'
	if score_value >= 55: return '"Hm. Close enough, I suppose."'
	if score_value >= 35: return '"Not quite what I pictured."'
	return '"...Is this right? Never mind."'