class_name OverworldMap
extends RefCounted
## One zone. Pure data. §6.8, §6.14
## Spot tiles correspond to the day's ForageMap spots, in order.

const TREES := "#"
const WATER := "~"
const BAR := "B"
const SPOT := "S"

const HOME := [
	"################",
	"#..S.....T...S.#",
	"#....T......T..#",
	"#.T.....S......#",
	"#.......~......#",
	"#..S...~~~...S.#",
	"#......~~~.....#",
	"#.T.....S....T.#",
	"#...S......S...#",
	"#..T........T..#",
	"#....S....S....#",
	"#.......B......#",
	"################",
]

var w: int
var h: int
var tiles: Array[String] = []
var bar_cell := Vector2i.ZERO
var spot_cells: Array[Vector2i] = []


func _init(p_layout: Array = HOME) -> void:
	h = p_layout.size()
	w = p_layout[0].length()
	for y in h:
		var row: String = p_layout[y]
		assert(row.length() == w, "Layout rows must be equal length")
		tiles.append(row)
		for x in row.length():
			var cell := Vector2i(x, y)
			if row[x] == BAR:
				bar_cell = cell
			elif row[x] == SPOT:
				spot_cells.append(cell)


func in_bounds(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < w and p.y < h


func tile_at(p: Vector2i) -> String:
	return tiles[p.y][p.x]


func is_blocked(p: Vector2i) -> bool:
	var t := tile_at(p)
	return t == TREES or t == WATER


## Index into spot_cells, or -1. Doubles as an index into the day's spots.
func spot_index_at(p: Vector2i) -> int:
	return spot_cells.find(p)


func spot_cell(p_index: int) -> Vector2i:
	if p_index < 0 or p_index >= spot_cells.size():
		return Vector2i(-1, -1)
	return spot_cells[p_index]