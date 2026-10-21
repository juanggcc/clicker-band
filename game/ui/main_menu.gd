class_name MainMenu
extends CanvasLayer
## The house button's menu: a grid with one tile per section. Choosing a tile hides the
## menu and asks the main scene to open that section; the backdrop and the close button
## just hide it. The modal consumes every touch.

signal shop_pressed
signal map_pressed

@onready var _dim: ColorRect = %Dim
@onready var _close_button: Button = %CloseButton
@onready var _shop_tile: Button = %ShopTile
@onready var _map_tile: Button = %MapTile
@onready var _shop_badge: ColorRect = %ShopBadge
@onready var _map_badge: ColorRect = %MapBadge


func _ready() -> void:
	hide()
	_dim.gui_input.connect(_on_dim_input)
	_close_button.pressed.connect(hide)
	_shop_tile.pressed.connect(_choose.bind(shop_pressed))
	_map_tile.pressed.connect(_choose.bind(map_pressed))


## Marks the sections where something can be bought right now.
func show_available(shop: bool, map: bool) -> void:
	_shop_badge.visible = shop
	_map_badge.visible = map


func _choose(section: Signal) -> void:
	hide()
	section.emit()


func _on_dim_input(event: InputEvent) -> void:
	_dim.accept_event()
	var click: InputEventMouseButton = event as InputEventMouseButton
	var touch: InputEventScreenTouch = event as InputEventScreenTouch
	# Close on release so the gesture that dismisses the menu cannot become a tap.
	if click != null and click.button_index == MOUSE_BUTTON_LEFT and not click.pressed:
		hide()
	elif touch != null and not touch.pressed:
		hide()
