class_name TreatFactory
extends RefCounted
## Certain patrons bring Chugs food. Mostly bovine, some canid, some human.
## The dark joke: they are fattening the thing that eats them. §6.11

const BRING_CHANCE := {
	"bovine": 0.60,
	"canid": 0.30,
	"human": 0.20,
}
const DEFAULT_CHANCE := 0.10

const DISHES := [
	"a covered dish", "a warm pie", "a slab of butter cake",
	"a jug of cream", "a honeyed loaf", "a bowl of dripping", "a wheel of soft cheese",
]


## Richer and more frequent as affinity climbs; sometimes spiked with his
## own brews, because he is a customer too. §6.11
static func roll(p_species: String, p_affinity: int, rng: RandomNumberGenerator) -> Dictionary:
	var chance: float = BRING_CHANCE.get(p_species, DEFAULT_CHANCE)
	if rng.randf() >= chance:
		return {}

	var richness := 1
	if p_affinity >= 5:
		richness += 1
	if p_affinity >= 8:
		richness += 1

	var spiked := rng.randf() < (0.10 + float(p_affinity) * 0.05)
	var extra := 0
	var brew := ""
	if spiked:
		extra = 2
		var ids: Array = []
		for id in IngredientDB.all.keys():
			if not IngredientDB.is_diluent(id):
				ids.append(id)
		if not ids.is_empty():
			brew = ids[rng.randi_range(0, ids.size() - 1)]

	return {
		"dish": DISHES[rng.randi_range(0, DISHES.size() - 1)],
		"weight": richness + extra,
		"spiked": spiked,
		"brew": brew,
	}


static func line(p_patron_name: String, p_treat: Dictionary) -> String:
	if p_treat.is_empty():
		return ""
	if bool(p_treat.get("spiked", false)) and str(p_treat.get("brew", "")) != "":
		var ing: Ingredient = IngredientDB.get_ingredient(str(p_treat["brew"]))
		return "%s sets down %s. It smells of %s." % [p_patron_name, p_treat["dish"], ing.display_name]
	return "%s sets down %s." % [p_patron_name, p_treat["dish"]]