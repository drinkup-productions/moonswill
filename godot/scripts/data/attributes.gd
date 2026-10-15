class_name Attributes
extends RefCounted
## The transformable attributes. Design ref: docs/design.md §6.9

const LIST := ["chest", "hips", "belly", "muscle", "height"]


static func zero() -> Dictionary:
	var d := {}
	for a in LIST:
		d[a] = 0
	return d


static func pretty(v: Dictionary) -> String:
	var parts: Array[String] = []
	for a in LIST:
		if v.get(a, 0) != 0:
			parts.append("%+d %s" % [v[a], a])
	return ", ".join(parts) if not parts.is_empty() else "no effect"