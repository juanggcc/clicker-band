@tool
extends Range
## Thin tempo bar under the speedometer: white while it charges, gold while the
## multiplier is on. Drawn on the HUD's 3 px grid.

const WHITE: Color = Color("f6efdb")
const GOLD: Color = Color("f4ca78")

@export var active: bool = false:
	set(value):
		active = value
		queue_redraw()


func _ready() -> void:
	value_changed.connect(_on_value_changed)
	resized.connect(queue_redraw)
	queue_redraw()


func _on_value_changed(_new_value: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("101820"))
	var track: Rect2 = Rect2(Vector2(3, 3), size - Vector2(6, 6))
	draw_rect(track, Color("34434b"))
	var ratio: float = clampf((value - min_value) / maxf(max_value - min_value, 0.001), 0.0, 1.0)
	var width: float = floorf(track.size.x * ratio / 3.0) * 3.0
	if width <= 0.0:
		return
	var tint: Color = GOLD if active else WHITE
	draw_rect(Rect2(track.position, Vector2(width, track.size.y)), tint)
	draw_rect(Rect2(track.position, Vector2(width, 3)), tint.lightened(0.3))
