class_name Patron
extends RefCounted
## A member of the bar's standing cast. Persistent across days and moons;
## only req and treat are rolled fresh each night. §6.18, §7.1, §7.3

## Which axes tear which garment. §3
const GARMENT_AXES := {
	"shirt": ["chest", "belly"],
	"pants": ["hips", "belly"],
}

var id: String = ""               # region:name, stable across saves
var name: String = ""
var species: String = ""
var region: String = "home"
var authored: bool = false
var req: PatronRequest = null
var affinity: int = 0
var transform: Transform
var garments: Dictionary = {}     # slot -> 0 intact, 1 stretched, 2 torn
var treat: Dictionary = {}


func _init() -> void:
	transform = Transform.new()
	for slot in GARMENT_AXES.keys():
		garments[slot] = 0


static func make(p_name: String, p_species: String, p_req: PatronRequest = null) -> Patron:
	var p := Patron.new()
	p.name = p_name
	p.species = p_species
	p.req = p_req
	p.transform.species = p_species
	return p


func archetype() -> String:
	return PatronRequest.LABEL[req.kind] if req != null else "?"


func mark() -> Dictionary:
	return req.want if req != null else {}


## Tearing is driven by whatever sits under the garment. §3
func update_garments() -> void:
	for slot in garments.keys():
		var worst := 0
		for a in GARMENT_AXES.get(slot, []):
			worst = maxi(worst, transform.stage_of(a))
		if worst >= 4:
			garments[slot] = 2
		elif worst >= 2:
			garments[slot] = 1
		else:
			garments[slot] = 0


## PG-13 stretches what NSFW tears — same trigger, two presentations. §3
func garment_state(p_slot: String, p_nsfw: bool) -> String:
	var lvl := int(garments.get(p_slot, 0))
	if lvl >= 2:
		return "torn" if p_nsfw else "stretched"
	if lvl == 1:
		return "stretched"
	return "intact"


## Being eaten resets the body and puts the clothes back. §6.5
func reset_body() -> void:
	for a in transform.points.keys():
		transform.points[a] = 0
	update_garments()
	transform.changed.emit()


func serialize() -> Dictionary:
	return {
		"id": id, "name": name, "species": species, "region": region,
		"authored": authored, "affinity": affinity,
		"transform": transform.serialize(),
		"garments": garments.duplicate(),
	}


static func from_dict(p_data: Dictionary) -> Patron:
	var p := Patron.make(str(p_data.get("name", "?")), str(p_data.get("species", "human")))
	p.id = str(p_data.get("id", ""))
	p.region = str(p_data.get("region", "home"))
	p.authored = bool(p_data.get("authored", false))
	p.affinity = int(p_data.get("affinity", 0))
	p.transform.deserialize(p_data.get("transform", {}))
	for k in p_data.get("garments", {}):
		p.garments[k] = int(p_data["garments"][k])
	return p