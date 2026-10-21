class_name MapMenu
extends CanvasLayer
## The zones as a scrolling strip of cards. The cards are rebuilt on every refresh from
## the zone list and the world map, so ownership and prices are always current. The
## modal consumes every touch; buying and travelling are left to the main scene.

signal buy_pressed(zone: Zone)
signal travel_pressed(zone: Zone)

const CARD: PackedScene = preload("res://ui/zone_card.tscn")

@onready var _dim: ColorRect = %Dim
@onready var _close_button: Button = %CloseButton
@onready var _balance: Label = %Balance
@onready var _cards: HBoxContainer = %Cards


func _ready() -> void:
	hide()
	_dim.gui_input.connect(_on_dim_input)
	_close_button.pressed.connect(hide)


func show_zones(zones: Array[Zone], world: WorldMap, economy: Economy) -> void:
	_balance.text = HUD.format_money(economy.money) + " €"
	for old: Node in _cards.get_children():
		_cards.remove_child(old)
		old.queue_free()
	for zone: Zone in zones:
		var card: ZoneCard = CARD.instantiate()
		_cards.add_child(card)
		var requirement: String = ShopMenu.requirement_label(economy, zone.requires_item, zone.requires_level)
		card.show_zone(zone, world.owns(zone.id), zone.id == world.current, economy.money, requirement)
		card.buy_pressed.connect(buy_pressed.emit)
		card.travel_pressed.connect(travel_pressed.emit)


func _on_dim_input(event: InputEvent) -> void:
	_dim.accept_event()
	var click: InputEventMouseButton = event as InputEventMouseButton
	var touch: InputEventScreenTouch = event as InputEventScreenTouch
	# Close on release so the gesture that dismisses the map cannot become a tap.
	if click != null and click.button_index == MOUSE_BUTTON_LEFT and not click.pressed:
		hide()
	elif touch != null and not touch.pressed:
		hide()
