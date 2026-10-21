class_name ShopMenu
extends CanvasLayer
## A pixel amplifier-style shop listing every item as a row. The modal consumes touches;
## only the purchase signal reaches the economy, which remains owned by the main scene.

signal buy_pressed(item: ShopItem)

const ROW: PackedScene = preload("res://ui/shop_row.tscn")

@onready var _dim: ColorRect = %Dim
@onready var _close_button: Button = %CloseButton
@onready var _balance: Label = %Balance
@onready var _count: Label = %Count
@onready var _rows: VBoxContainer = %Rows


func _ready() -> void:
	hide()
	_dim.gui_input.connect(_on_dim_input)
	_close_button.pressed.connect(close)


func open() -> void:
	show()


func close() -> void:
	hide()


## What still has to be reached before something can be bought, such as "PÚA NV 10";
## empty once it is met.
static func requirement_label(economy: Economy, id: StringName, at_level: int) -> String:
	if economy.meets(id, at_level):
		return ""
	return "%s NV %d" % [economy.find(id).short_name.to_upper(), at_level]


func show_items(economy: Economy) -> void:
	_balance.text = HUD.format_money(economy.money) + " €"
	_count.text = "%02d" % economy.items.size()
	if _rows.get_child_count() != economy.items.size():
		for old: Node in _rows.get_children():
			_rows.remove_child(old)
			old.queue_free()
		for i: int in economy.items.size():
			var row: ShopRow = ROW.instantiate()
			_rows.add_child(row)
			row.buy_pressed.connect(buy_pressed.emit)
	for i: int in economy.items.size():
		var item: ShopItem = economy.items[i]
		var row: ShopRow = _rows.get_child(i)
		row.show_item(item, economy, requirement_label(economy, item.requires_item, item.requires_level))


func _on_dim_input(event: InputEvent) -> void:
	_dim.accept_event()
	var click: InputEventMouseButton = event as InputEventMouseButton
	var touch: InputEventScreenTouch = event as InputEventScreenTouch
	# Close on release so the gesture that dismisses the modal cannot become a tap.
	if click != null and click.button_index == MOUSE_BUTTON_LEFT and not click.pressed:
		close()
	elif touch != null and not touch.pressed:
		close()


func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
