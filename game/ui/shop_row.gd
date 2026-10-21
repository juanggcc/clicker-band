class_name ShopRow
extends PanelContainer
## One item in the shop list: art, name, level, what each level adds and the buy button.
## A locked item shows its requirement on the button. The button never waits after a
## purchase, so repeated presses keep buying while the money lasts.

signal buy_pressed(item: ShopItem)

const ARROW: Texture2D = preload("res://assets/ui/shop/v1/icon_arrow.png")
const LOCK: Texture2D = preload("res://assets/ui/shop/v1/icon_lock.png")
const LOCKED_ART: Color = Color(1, 1, 1, 0.35)

var item: ShopItem

@onready var _art: TextureRect = %Art
@onready var _lock: TextureRect = %Lock
@onready var _name: Label = %Name
@onready var _level: Label = %Level
@onready var _description: Label = %Description
@onready var _effect: Label = %Effect
@onready var _button: Button = %BuyButton


func _ready() -> void:
	_button.pressed.connect(func() -> void: buy_pressed.emit(item))


## requirement is the text for a locked item, such as "PÚA NV 10".
func show_item(shown: ShopItem, economy: Economy, requirement: String) -> void:
	item = shown
	var unlocked: bool = economy.is_unlocked(item)
	_art.texture = item.art
	_art.modulate = Color.WHITE if unlocked else LOCKED_ART
	_lock.visible = not unlocked
	_name.text = item.title
	_level.text = "NIVEL %d" % economy.level(item.id)
	_description.text = item.description
	_effect.text = "+%d € / TOQUE POR NIVEL" % item.gain
	var cost: int = economy.cost(item)
	if not unlocked:
		_set_button(requirement, LOCK, true)
	elif economy.money < cost:
		_set_button("FALTAN %s €" % HUD.format_money(cost - economy.money), null, true)
	else:
		_set_button(HUD.format_money(cost) + " €", ARROW, false)


func _set_button(text: String, icon: Texture2D, disabled: bool) -> void:
	_button.text = text
	_button.icon = icon
	_button.disabled = disabled
