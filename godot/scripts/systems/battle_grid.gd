class_name BattleGrid
extends RefCounted
## Small arena for an encounter. Pure logic.
## Mirrors FeastGrid's tile language and adds path_to(), which combat needs
## and the feast does not. Unifying the two is a later job.

const WALL := "#"
const ROCK := "R"

const ARENA := [
	"##########",
	"#........#",
	"#..R..R..#",
	"#........#",
	"#........#",
	"#..R..R..#",
	"#........#",
	"##########",
]

var w: int
var h: int
var tiles: Array[String] = []


func _init(p_layout: Array = ARENA) -> void:
	h = p_layout.size()
	w = p_layout[0].length()
	for y in h:
		var row: String = p_layout[y]
		assert(row.length() == w, "Layout rows must be equal length")
		tiles.append(row)


func in_bounds(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < w and p.y < h


func tile_at(p: Vector2i) -> String:
	return tiles[p.y][p.x]


func is_blocked(p: Vector2i) -> bool:
	var t := tile_at(p)
	return t == WALL or t == ROCK


func free_cells() -> Array:
	var out: Array = []
	for y in h:
		for x in w:
			var c := Vector2i(x, y)
			if not is_blocked(c):
				out.append(c)
	return out


## BFS. Returned path includes the start tile. [] if unreachable.
func path_to(p_from: Vector2i, p_to: Vector2i) -> Array[Vector2i]:
	if p_from == p_to:
		return [p_from]
	var queue: Array[Vector2i] = [p_from]
	var came_from := {}
	var seen := {p_from: true}
	var found := false
	while not queue.is_empty():
		var node: Vector2i = queue.pop_front()
		if node == p_to:
			found = true
			break
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var nxt: Vector2i = node + d
			if not in_bounds(nxt) or is_blocked(nxt) or seen.has(nxt):
				continue
			seen[nxt] = true
			came_from[nxt] = node
			queue.append(nxt)
	if not found:
		return []
	var path: Array[Vector2i] = []
	var back := p_to
	while back != p_from:
		path.push_front(back)
		back = came_from[back]
	path.push_front(p_from)
	return path


func distance(p_from: Vector2i, p_to: Vector2i) -> int:
	var p := path_to(p_from, p_to)
	return 0 if p.is_empty() else p.size() - 1