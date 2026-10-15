extends Node
## XP and level curve. Autoloaded as `Levels`.
## Design ref: docs/design.md §6.16

const MAX_LEVEL := 10
const XP_FLOOR := 80

var level: int = 1
var xp: int = 0


func xp_needed(l: int = level) -> int:
	return 200 + (l - 1) * 150


func searches() -> int:
	return mini(9, 5 + ceili((level - 1) / 2.0))


func yield_per_search() -> int:
	return mini(7, 4 + int(floor((level - 1) / 2.0)))


func vat_slots() -> int:
	return 4 if level >= 4 else 3


func taste_tests_per_day() -> int:
	return 2 if level >= 5 else 1


func feast_action_points() -> int:
	var base := 6
	if level >= 9:
		base += 1
	return maxi(2, base - int(floor(Game.weight / 25.0)))


## Award XP from total satisfaction. Returns how many levels were gained.
func award(total_satisfaction: int) -> int:
	var gained: int = maxi(XP_FLOOR, total_satisfaction)
	xp += gained
	var ups := 0
	while level < MAX_LEVEL and xp >= xp_needed():
		xp -= xp_needed()
		level += 1
		ups += 1
	return ups


func reset() -> void:
	level = 1
	xp = 0