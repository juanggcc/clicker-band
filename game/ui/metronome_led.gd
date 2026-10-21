@tool
extends Control
## A small red amp-style LED on the 3 px grid with exactly two states: dark when off,
## bright with a halo when lit.

const CELL: float = 3.0
const PATTERN: Array[String] = [".###.", "#####", "#####", "#####", ".###."]
const OFF: Color = Color("2a1416")
const ON: Color = Color("ff5a4e")
const HALO: Color = Color(1.0, 0.353, 0.306, 0.35)

@export var lit: bool = false:
	set(value):
		if value == lit:
			return
		lit = value
		queue_redraw()


func _draw() -> void:
	var origin: Vector2 = ((size - Vector2.ONE * CELL * PATTERN.size()) / 2.0).floor()
	if lit:
		draw_rect(Rect2(origin - Vector2.ONE * CELL, Vector2.ONE * CELL * (PATTERN.size() + 2)), HALO)
	var tint: Color = ON if lit else OFF
	for y: int in PATTERN.size():
		for x: int in PATTERN[y].length():
			if PATTERN[y][x] == "#":
				var cell: Color = tint.lightened(0.35) if lit and x == 1 and y == 1 else tint
				draw_rect(Rect2(origin + Vector2(x, y) * CELL, Vector2.ONE * CELL), cell)
