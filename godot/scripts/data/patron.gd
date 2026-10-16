class_name Patron
extends RefCounted
## One customer. Data only — rosters are built by PatronFactory.
## Design ref: docs/design.md §7.1, §7.3, §6.11

var name: String = ""
var species: String = ""
var req: PatronRequest = null
var affinity: int = 0
var transform: Transform          # what service has done to them so far
var treat: Dictionary = {}        # what they brought, if anything
var willing: bool = false


func _init() -> void:
	transform = Transform.new()


static func make(p_name: String, p_species: String, p_req: PatronRequest) -> Patron:
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


## Regulars are willing. §6.5, §6.11
func is_willing() -> bool:
	return affinity >= 3 or willing