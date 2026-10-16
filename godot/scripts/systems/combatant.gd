class_name Combatant
extends RefCounted
## Anything that can fight. Pure data; a scene drives the turn loop. §8
## Fat is resilience through damage resistance and heavier attacks, not a
## bigger HP pool. It costs speed and action points. A tank build is
## legitimate and slow.

signal hp_changed(p_hp: int)
signal downed()

const BASE_HP := 14
const BASE_AP := 3

const PLAYER_ATTACKS := [
	{"id": "punch",      "name": "Punch",      "ap": 1, "damage": 4, "weight_scale": 0.0},
	{"id": "claw",       "name": "Claw",       "ap": 1, "damage": 6, "weight_scale": 0.0},
	{"id": "belly_slam", "name": "Belly Slam", "ap": 2, "damage": 5, "weight_scale": 1.6},
]

var display_name := ""
var species := ""
var def_id := ""               # "" for the player
var reaction_profile := "feral"
var transform: Transform
var is_player := false
var cell: Vector2i = Vector2i.ZERO
var max_hp := BASE_HP
var hp := BASE_HP
var ap_max := BASE_AP
var ap := BASE_AP
var attack_list: Array = []
var brews: Array = []          # ingredient ids carried, used as combat items
var effects := {}              # ReactionTable.Kind -> turns remaining


func _init(p_name: String = "", p_species: String = "") -> void:
	display_name = p_name
	species = p_species
	transform = Transform.new(p_species)
	max_hp = BASE_HP
	hp = BASE_HP
	ap_max = BASE_AP
	ap = BASE_AP
	attack_list = PLAYER_ATTACKS.duplicate(true)


static func make_player() -> Combatant:
	var c := Combatant.new("Chugs", "skull-dog")
	c.is_player = true
	c.transform.concealed_stages = Levels.conceal_stages()
	c.transform.points["belly"] = int(round(float(Game.weight) * 0.3))
	c.refresh_stats()
	return c


static func make_enemy(p_name: String, p_species: String, rng: RandomNumberGenerator) -> Combatant:
	var c := Combatant.new(p_name, p_species)
	c.reaction_profile = ReactionTable.profile_for(p_species, rng)
	c.brews = _spawn_brews(rng, rng.randi_range(1, 2))
	c.refresh_stats()
	return c


static func _spawn_brews(rng: RandomNumberGenerator, p_count: int) -> Array:
	var ids: Array = []
	for id in IngredientDB.all.keys():
		if not IngredientDB.is_diluent(id):
			ids.append(id)
	var out: Array = []
	for _i in p_count:
		out.append(ids[rng.randi_range(0, ids.size() - 1)])
	return out


## HP is fixed; bulk never moves it. Only the player's action points are
## weight-derived. Resilience lives in damage_resist() and attacks(). §6.10
func refresh_stats() -> void:
	if is_player:
		ap_max = maxi(1, BASE_AP - int(floor(float(Game.weight) / 34.0)))
		ap = mini(ap, ap_max)
	hp = mini(hp, max_hp)
	hp_changed.emit(hp)


func speed() -> int:
	var s := transform.silhouette()
	var base := 3
	if s >= 5:
		base = 0
	elif s >= 4:
		base = 1
	elif s >= 2:
		base = 2
	if effects.has(ReactionTable.Kind.SLOWED):
		base = maxi(0, base - 1)
	if effects.has(ReactionTable.Kind.ENRAGED):
		base += 1
	return base


func damage_resist() -> float:
	var r := float(transform.silhouette()) * 0.08
	if effects.has(ReactionTable.Kind.GUARD_DOWN):
		r *= 0.5
	return r


## Weight raises Belly Slam damage and its cost. Power that is slow.
func attacks() -> Array:
	var out: Array = []
	for a in attack_list:
		var entry: Dictionary = a.duplicate()
		if float(entry["weight_scale"]) > 0.0:
			var s := transform.silhouette()
			entry["damage"] = int(round(float(entry["damage"]) + float(entry["weight_scale"]) * s))
			entry["ap"] = int(entry["ap"]) + int(s / 3)
		out.append(entry)
	return out


## Damage dealt BY this combatant TO p_target. The target's resistance
## applies, not the attacker's — an armoured victim shrugs it off.
func roll_damage(p_attack: Dictionary, p_target: Combatant) -> int:
	var d := int(p_attack["damage"])
	if effects.has(ReactionTable.Kind.ENRAGED):
		d = int(round(float(d) * 1.5))
	return maxi(1, d - int(round(float(d) * p_target.damage_resist())))


func is_down() -> bool:
	return hp <= 0


func is_out() -> bool:
	return is_down() or effects.has(ReactionTable.Kind.STOP) or effects.has(ReactionTable.Kind.FLEE)


func is_stunned() -> bool:
	return effects.has(ReactionTable.Kind.DISTRACTED)


func can_act() -> bool:
	return not is_out() and not is_stunned() and ap > 0


func take_damage(p_amount: int) -> void:
	hp = maxi(0, hp - p_amount)
	hp_changed.emit(hp)
	if hp == 0:
		downed.emit()


func heal(p_amount: int) -> void:
	hp = mini(max_hp, hp + p_amount)
	hp_changed.emit(hp)


func apply_effect(p_kind: int, p_turns: int = 1) -> void:
	effects[p_kind] = maxi(int(effects.get(p_kind, 0)), p_turns)


func tick_effects() -> void:
	for k in effects.keys():
		if k == ReactionTable.Kind.STOP or k == ReactionTable.Kind.FLEE:
			continue
		effects[k] = int(effects[k]) - 1
		if int(effects[k]) <= 0:
			effects.erase(k)


## Applies reactions from Transform crossings. Returns them so the battle
## log can say what happened. §8
func react_to(p_events: Array) -> Array:
	var out: Array = []
	for e in p_events:
		if int(e["to"]) <= int(e["from"]):
			continue
		var r := ReactionTable.lookup(reaction_profile, str(e["axis"]), int(e["to"]))
		if r.is_empty():
			continue
		var kind := int(r.get("kind", ReactionTable.Kind.NONE))
		if kind == ReactionTable.Kind.NONE:
			continue
		var turns := int(r.get("turns", 1))
		apply_effect(kind, turns)
		out.append({"kind": kind, "name": ReactionTable.kind_name(kind), "turns": turns})
	return out


func begin_turn() -> void:
	ap = ap_max


func status_text() -> String:
	var parts: Array[String] = []
	for k in effects.keys():
		parts.append("%s (%d)" % [ReactionTable.kind_name(int(k)), int(effects[k])])
	return ", ".join(parts) if not parts.is_empty() else "—"
