class_name ZoneCard
extends PanelContainer
## One zone on the map: picture, name, blurb and what can be done there. The zone where
## the band plays shows ESTÁS AQUÍ; an owned zone offers IR; a built zone not owned yet
## shows what it still requires, then COMPRAR at its price; a zone not built yet is "???"
## with only its blurb.

signal buy_pressed(zone: Zone)
signal travel_pressed(zone: Zone)

const LOCK: Texture2D = preload("res://assets/ui/shop/v1/icon_lock.png")

var _zone: Zone
var _owned: bool = false

@onready var _picture: TextureRect = %Picture
@onready var _unknown: Label = %Unknown
@onready var _lock: TextureRect = %Lock
@onready var _name: Label = %Name
@onready var _blurb: Label = %Blurb
@onready var _here: HBoxContainer = %Here
@onready var _action: Button = %Action


func _ready() -> void:
	_action.pressed.connect(_on_action_pressed)


## requirement is what the zone still needs, such as "PEDAL NV 5"; empty once met.
func show_zone(zone: Zone, owned: bool, here: bool, money: int, requirement: String) -> void:
	_zone = zone
	_owned = owned
	var built: bool = zone.is_built()
	_picture.texture = (zone.thumbnail if zone.thumbnail != null else zone.background) if built else null
	_unknown.visible = not built
	_lock.visible = built and not owned
	_name.text = zone.title if built else "???"
	_blurb.text = zone.blurb
	_here.visible = here
	_action.visible = not here
	_action.icon = null
	if not built:
		_action.text = "PRONTO"
		_action.disabled = true
	elif owned:
		_action.text = "IR"
		_action.disabled = false
	elif requirement != "":
		_action.text = requirement
		_action.icon = LOCK
		_action.disabled = true
	elif money >= zone.price:
		_action.text = "COMPRAR %s €" % HUD.format_money(zone.price)
		_action.disabled = false
	else:
		_action.text = "FALTAN %s €" % HUD.format_money(zone.price - money)
		_action.disabled = true


func _on_action_pressed() -> void:
	if _owned:
		travel_pressed.emit(_zone)
	else:
		buy_pressed.emit(_zone)
