@tool
extends Range
## Speedometer in taps per second from 0 to max_value in 24 cells, a third per loop:
## 0 to mid_rate, mid_rate to fast_rate, fast_rate to max_value, linear inside each third.
## The loop thresholds therefore always fall on a cell boundary, and the unlit cells
## already show where the next loop starts; a cell lights once the speed reaches it.
## The lit part climbs towards the speed at a steady RISE_PER_SEC of the bar and eases
## down quickly, so a couple of taps barely move it and steady tapping fills it gradually.

const SEGMENTS: int = 24
const CELLS_PER_LOOP: int = 8
const RISE_PER_SEC: float = 1.0
const FALL_SEC: float = 0.1
const LOOP_COLORS: Array[Color] = [Color("8ed8b1"), Color("f4ca78"), Color("f28f76")]

@export var mid_rate: float = 2.75:
	set(value):
		mid_rate = value
		queue_redraw()
@export var fast_rate: float = 5.0:
	set(value):
		fast_rate = value
		queue_redraw()

var _shown: float = 0.0


func _ready() -> void:
	resized.connect(queue_redraw)
	queue_redraw()


func _process(delta: float) -> void:
	var target: float = _reach_of(value)
	var shown: float = target
	if not Engine.is_editor_hint():
		if target > _shown:
			shown = minf(_shown + RISE_PER_SEC * delta, target)
		else:
			shown = lerpf(_shown, target, 1.0 - exp(-delta / FALL_SEC))
	if absf(shown - _shown) > 0.0005:
		_shown = shown
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("101820"))
	draw_rect(Rect2(0, 0, size.x, 3), Color("080f17"))
	var cell_width: float = floorf((size.x - 12.0) / SEGMENTS)
	var left: float = floorf((size.x - cell_width * SEGMENTS) / 2.0)
	var lit: int = 0 if _shown <= 0.005 else mini(floori(_shown * SEGMENTS + 0.001) + 1, SEGMENTS)
	for i: int in SEGMENTS:
		var tint: Color = LOOP_COLORS[i / CELLS_PER_LOOP]
		var rect: Rect2 = Rect2(left + i * cell_width, 6, cell_width - 3, size.y - 12)
		draw_rect(rect, tint if i < lit else tint.darkened(0.7))
		if i < lit:
			draw_rect(Rect2(rect.position, Vector2(rect.size.x, 3)), tint.lightened(0.24))
			draw_rect(Rect2(rect.position + Vector2(0, rect.size.y - 3), Vector2(rect.size.x, 3)), tint.darkened(0.25))


## Where a speed sits along the bar, 0 to 1: each loop gets a third, linear inside it.
func _reach_of(rate: float) -> float:
	if rate < mid_rate:
		return maxf(rate, 0.0) / mid_rate / 3.0
	if rate < fast_rate:
		return (1.0 + (rate - mid_rate) / (fast_rate - mid_rate)) / 3.0
	return minf((2.0 + (rate - fast_rate) / maxf(max_value - fast_rate, 0.001)) / 3.0, 1.0)
