class_name FeastGrid
extends RefCounted
## Tile grid + BFS pathing for the feast. Pure logic, no nodes.

const WALL := "#"
const FLOOR := "."
const TABLE := "T"
const EXIT := "D"

var w: int
var h: int
var tiles: Array[String] = []
var exits: Array[Vector2i] = []


func _init(layout: Array) -> void:
	h = layout.size()
	w = layout[0].length()
	for y in h:
		var row: String = layout[y]
		assert(row.length() == w, "Layout rows must be equal length")
		tiles.append(row)
		for x in row.length():
			if row[x] == EXIT:
				exits.append(Vector2i(x, y))


func in_bounds(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < w and p.y < h


func tile_at(p: Vector2i) -> String:
	return tiles[p.y][p.x]


func is_blocked(p: Vector2i) -> bool:
	var t := tile_at(p)
	return t == WALL or t == TABLE


func is_exit(p: Vector2i) -> bool:
	return tile_at(p) == EXIT


## BFS to the nearest exit. Returned path includes the start tile.
## Returns [] if no route exists.
func path_to_exit(from: Vector2i) -> Array[Vector2i]:
	var queue: Array[Vector2i] = [from]
	var came_from := {}
	var seen := {from: true}
	var goal := Vector2i(-1, -1)

	while not queue.is_empty():
		var cur: Vector2i = queue.pop_front()
		if is_exit(cur) and cur != from:
			goal = cur
			break
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var nxt: Vector2i = cur + d
			if not in_bounds(nxt) or is_blocked(nxt) or seen.has(nxt):
				continue
			seen[nxt] = true
			came_from[nxt] = cur
			queue.append(nxt)

	if goal == Vector2i(-1, -1):
		return []

	var path: Array[Vector2i] = []
	var cur := goal
	while cur != from:
		path.push_front(cur)
		cur = came_from[cur]
	path.push_front(from)
	return path