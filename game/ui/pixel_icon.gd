@tool
extends Control
## Tiny code-native sprites: no textures, imports, or image generation needed.
## Setting texture draws that image stretched to the control instead of the pattern.

enum Kind { ROOM, COIN, NOTE, MENU, UP, PICK }

const PATTERNS: Array = [
	[
		"000010000", "000111000", "001111100", "011111110", "110000011",
		"010000010", "010110010", "010110010", "011111110",
	],
	[
		"001111100", "011111110", "111222111", "112211211", "112121211",
		"112112211", "111222111", "011111110", "001111100",
	],
	[
		"000111110", "000100010", "000100010", "000100010", "000100010",
		"011100010", "111100110", "111001110", "010001100",
	],
	[
		"000000000", "111111111", "222222222", "000000000", "111111111",
		"222222222", "000000000", "111111111", "222222222",
	],
	[
		"000010000", "000111000", "001111100", "011111110", "111111111",
		"000111000", "000112000", "000112000", "000112000",
	],
	[
		"001111100", "011111110", "111111112", "111111112", "111111122",
		"011111120", "001111200", "000112000", "000020000",
	],
]

@export var kind: Kind = Kind.ROOM:
	set(value):
		kind = value
		queue_redraw()
@export var color: Color = Color("8ed8b1"):
	set(value):
		color = value
		queue_redraw()
@export var texture: Texture2D:
	set(value):
		texture = value
		queue_redraw()


func _draw() -> void:
	if texture != null:
		draw_texture_rect(texture, Rect2(Vector2.ZERO, size), false)
		return
	var pixel: float = maxf(1.0, floorf(minf(size.x, size.y) / 9.0))
	var origin: Vector2 = ((size - Vector2.ONE * pixel * 9.0) / 2.0).floor()
	var pattern: Array = PATTERNS[kind]
	for y: int in pattern.size():
		for x: int in pattern[y].length():
			var cell: String = pattern[y][x]
			if cell == "0":
				continue
			var tint: Color = color if cell == "1" else color.darkened(0.4)
			draw_rect(Rect2(origin + Vector2(x, y) * pixel, Vector2.ONE * pixel), tint)
