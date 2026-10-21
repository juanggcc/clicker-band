class_name TravelFade
extends CanvasLayer
## Fades to black with a caption, runs the scene swap while the screen is dark and fades
## back. The shade consumes touches while it is up, so no tap lands mid-move.

const FADE_SEC: float = 0.35
const HOLD_SEC: float = 0.5

@onready var _shade: ColorRect = %Shade
@onready var _caption: Label = %Caption


func _ready() -> void:
	hide()


func play(caption: String, swap: Callable) -> void:
	_caption.text = caption
	_shade.modulate.a = 0.0
	show()
	var tween: Tween = create_tween()
	tween.tween_property(_shade, "modulate:a", 1.0, FADE_SEC)
	tween.tween_callback(swap)
	tween.tween_interval(HOLD_SEC)
	tween.tween_property(_shade, "modulate:a", 0.0, FADE_SEC)
	tween.tween_callback(hide)
