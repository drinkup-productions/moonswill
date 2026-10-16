class_name Patron
extends RefCounted
## One customer. Data only — rosters are built by PatronFactory.
## Design ref: docs/design.md §7.1, §7.3

var name: String = ""
var species: String = ""
var req: PatronRequest = null
var affinity: int = 0
var willing: bool = false


static func make(p_name: String, p_species: String, p_req: PatronRequest) -> Patron:
	var p := Patron.new()
	p.name = p_name
	p.species = p_species
	p.req = p_req
	return p


func archetype() -> String:
	return PatronRequest.LABEL[req.kind] if req != null else "?"


## Attributes this request is judged against. Empty for a wildcard.
func mark() -> Dictionary:
	return req.want if req != null else {}