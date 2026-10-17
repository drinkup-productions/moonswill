class_name Transform
extends RefCounted
## One character's transformation state. Pure data, no nodes. §6.9
## ART CONTRACT: art reads visual() and nothing else.

signal changed()
signal crossed(p_axis: String, p_from: int, p_to: int)

const AXES := ["belly"]                                    # slice: bulk only
const ALL_AXES := ["chest", "hips", "belly", "muscle", "height"]
const FLAVOR := ["tail", "scales", "horns"]
const STAGE_MAX := 5
const PER_STAGE := 6          # one full vat is about one stage — matches §6.3

## Base bodies art actually draws. Between anchors the base is crossfaded,
## which is the smear. Adding an axis costs overlays, never a new body set.
const ANCHORS := [0, 2, 4, 5]

var species := ""
var points := {}              # String axis -> int, may go negative
var flavor := {}              # String -> bool
var concealed_stages := 1     # §6.10; level 7 sets 2

## Contribution from outside the brew, folded into every read. Chugs's weight
## sits here so his silhouette is points + weight without art ever needing a
## second call. Patrons leave it empty and behave exactly as before. §6.10
var bonus := {}


func _init(p_species: String = "") -> void:
	species = p_species
	for a in ALL_AXES:
		points[a] = 0
	for f in FLAVOR:
		flavor[f] = false


## The only thing stage reads ever look at.
func effective(p_axis: String) -> int:
	return int(points.get(p_axis, 0)) + int(bonus.get(p_axis, 0))


func set_bonus(p_axis: String, p_value: int) -> void:
	if int(bonus.get(p_axis, 0)) == p_value:
		return
	bonus[p_axis] = p_value
	changed.emit()


## Returns the threshold crossings, so a reaction can be looked up without
## Transform knowing anything about combat. §8
func apply(p_deltas: Dictionary) -> Array:
	var events: Array = []
	for a in p_deltas:
		if not points.has(a):
			continue
		var before := stage_of(a)
		points[a] += int(p_deltas[a])
		var after := stage_of(a)
		if after != before:
			events.append({"axis": a, "from": before, "to": after})
			crossed.emit(a, before, after)
	if not events.is_empty():
		changed.emit()
	return events


func stage_of(p_axis: String) -> int:
	return clampi(effective(p_axis) / PER_STAGE, 0, STAGE_MAX)


func silhouette() -> int:
	var m := 0
	for a in AXES:
		m = maxi(m, stage_of(a))
	return m


func visible_stage(p_axis: String) -> int:
	return maxi(0, stage_of(p_axis) - concealed_stages)


func visible_silhouette() -> int:
	var m := 0
	for a in AXES:
		m = maxi(m, visible_stage(a))
	return m


func tear_level() -> int:
	return clampi(silhouette() - 2, 0, 2)


func set_flavor(p_key: String, p_on: bool = true) -> void:
	if flavor.has(p_key):
		flavor[p_key] = p_on
		changed.emit()


## Back to the base body. Points and flavor only — the bonus is not the
## potion's business, weight is. §6.12
func clear_points() -> void:
	for a in points.keys():
		points[a] = 0
	for f in flavor.keys():
		flavor[f] = false
	changed.emit()


## THE ONLY ART-FACING CALL.
func visual() -> Dictionary:
	var s := silhouette()
	var base := 0
	var blend := 0.0
	for i in ANCHORS.size():
		if s >= ANCHORS[i]:
			base = i
	for i in range(ANCHORS.size() - 1):
		if s >= ANCHORS[i] and s < ANCHORS[i + 1]:
			base = i
			blend = float(s - ANCHORS[i]) / float(ANCHORS[i + 1] - ANCHORS[i])
			break
	var overlays: Array = []
	for a in AXES:
		var vs := visible_stage(a)
		if vs > 0:
			overlays.append({"axis": a, "stage": vs})
	return {
		"species": species,
		"base_stage": base,
		"base_blend": blend,
		"overlays": overlays,
		"tear": tear_level(),
		"flavor": flavor.duplicate(),
		"silhouette": s,
		"visible_silhouette": visible_silhouette(),
		"axes": _stage_map(false),
		"visible_axes": _stage_map(true),
	}


func _stage_map(p_visible: bool) -> Dictionary:
	var out := {}
	for a in ALL_AXES:
		out[a] = visible_stage(a) if p_visible else stage_of(a)
	return out


func serialize() -> Dictionary:
	return {
		"species": species,
		"points": points.duplicate(),
		"flavor": flavor.duplicate(),
		"concealed_stages": concealed_stages,
		"bonus": bonus.duplicate(),
	}


func deserialize(p_data: Dictionary) -> void:
	species = str(p_data.get("species", species))
	for k in p_data.get("points", {}):
		points[k] = int(p_data["points"][k])
	for k in p_data.get("flavor", {}):
		flavor[k] = bool(p_data["flavor"][k])
	for k in p_data.get("bonus", {}):
		bonus[k] = int(p_data["bonus"][k])
	concealed_stages = int(p_data.get("concealed_stages", 1))
	changed.emit()
