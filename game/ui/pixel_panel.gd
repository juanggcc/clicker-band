@tool
extends PanelContainer
## A small, reusable amplifier faceplate. Everything is drawn on a 3 px grid.

@export var accent: Color = Color("8ed8b1"):
	set(value):
		accent = value
		queue_redraw()


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	var face: Rect2 = Rect2(Vector2.ZERO, size)
	_draw_cut_rect(Rect2(Vector2(0, 6), size), Color(0.04, 0.05, 0.08, 0.65), 6.0)
	_draw_cut_rect(face, Color("111923"), 6.0)
	_draw_cut_rect(face.grow(-3.0), Color("52606b"), 6.0)
	_draw_cut_rect(face.grow(-6.0), Color("202b35"), 3.0)
	draw_rect(Rect2(12, 6, size.x - 24, 3), Color("71808a"))
	draw_rect(Rect2(18, 6, 42, 3), accent)
	for x: float in [12.0, size.x - 15.0]:
		for y: float in [15.0, size.y - 18.0]:
			draw_rect(Rect2(x, y, 3, 3), Color("71808a"))


func _draw_cut_rect(rect: Rect2, color: Color, cut: float) -> void:
	var a: Vector2 = rect.position
	var b: Vector2 = rect.end
	draw_colored_polygon(PackedVector2Array([
		Vector2(a.x + cut, a.y), Vector2(b.x - cut, a.y),
		Vector2(b.x - cut, a.y + cut), Vector2(b.x, a.y + cut),
		Vector2(b.x, b.y - cut), Vector2(b.x - cut, b.y - cut),
		Vector2(b.x - cut, b.y), Vector2(a.x + cut, b.y),
		Vector2(a.x + cut, b.y - cut), Vector2(a.x, b.y - cut),
		Vector2(a.x, a.y + cut), Vector2(a.x + cut, a.y + cut),
	]), color)
