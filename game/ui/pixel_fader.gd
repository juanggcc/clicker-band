class_name PixelFader
extends HSlider
## A mixing-desk fader on the 3 px grid of the pixel panels: the slot lit in mint up to
## the level, a tick every tenth and a cream cap. HSlider still handles touch and drag;
## its own track and grabber are blanked, and the blank grabber has the cap's size so
## the value follows the finger to where the cap is drawn.

const CAP: Vector2 = Vector2(30, 60)
const SLOT_HEIGHT: float = 12.0
const MINT: Color = Color("8ed8b1")


func _init() -> void:
	var blank: StyleBoxEmpty = StyleBoxEmpty.new()
	for style: StringName in [&"slider", &"grabber_area", &"grabber_area_highlight"]:
		add_theme_stylebox_override(style, blank)
	var image: Image = Image.create_empty(int(CAP.x), int(CAP.y), false, Image.FORMAT_RGBA8)
	var grabber: ImageTexture = ImageTexture.create_from_image(image)
	for icon: StringName in [&"grabber", &"grabber_highlight", &"grabber_disabled"]:
		add_theme_icon_override(icon, grabber)


func _draw() -> void:
	var travel: float = size.x - CAP.x
	var middle: float = roundf(size.y / 2.0)
	var slot: Rect2 = Rect2(CAP.x / 2.0, middle - SLOT_HEIGHT / 2.0, travel, SLOT_HEIGHT)
	for i: int in 11:
		var x: float = roundf(slot.position.x + travel * i / 10.0) - 1.0
		draw_rect(Rect2(x, slot.position.y - 15.0, 3, 9), Color("52606b"))
		draw_rect(Rect2(x, slot.end.y + 6.0, 3, 9), Color("52606b"))
	draw_rect(slot.grow(3.0), Color("111923"))
	draw_rect(slot, Color("080f17"))
	var lit: float = roundf(travel * get_as_ratio())
	draw_rect(Rect2(slot.position, Vector2(lit, SLOT_HEIGHT)), MINT)
	draw_rect(Rect2(slot.position, Vector2(lit, 3)), MINT.lightened(0.24))
	var cap: Rect2 = Rect2(Vector2(lit, middle - CAP.y / 2.0), CAP)
	draw_rect(cap, Color("111923"))
	draw_rect(cap.grow(-3.0), Color("f6efdb"))
	draw_rect(Rect2(cap.position.x + 3, cap.end.y - 9, CAP.x - 6, 6), Color("a8b4b8"))
	draw_rect(Rect2(cap.position.x + 3, middle - 1.0, CAP.x - 6, 3), MINT.darkened(0.3))
