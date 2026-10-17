class_name CharacterDB
extends RefCounted
## Hand-authored regulars, four per region. PLACEHOLDER names — swap freely.
## Design ref: docs/design.md §6.18

const REGULARS := {
	"home": [
		{"name": "Marta", "species": "human"},
		{"name": "Bess",  "species": "bovine"},
		{"name": "Rill",  "species": "felinid"},
		{"name": "Corl",  "species": "human"},
	],
	"the fens": [
		{"name": "Sekk",  "species": "lizard-folk"},
		{"name": "Hilda", "species": "bovine"},
		{"name": "Vess",  "species": "felinid"},
		{"name": "Molw",  "species": "lizard-folk"},
	],
	"the high downs": [
		{"name": "Gorst", "species": "equine"},
		{"name": "Brack", "species": "canid"},
		{"name": "Hanne", "species": "human"},
		{"name": "Rusk",  "species": "canid"},
	],
}


static func regulars_for(p_region: String) -> Array:
	return REGULARS.get(p_region, REGULARS["home"])