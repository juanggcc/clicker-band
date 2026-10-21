class_name ShopItem
extends Resource
## One piece of gear sold in levels in the shop, edited in the inspector (one .tres per
## item in shop/items/). Each level adds `gain` euros to every tap; the next level costs
## `growth` times the last one.

@export var id: StringName
@export var title: String = ""
## Used where space is short, such as requirement labels ("PÚA NV 10").
@export var short_name: String = ""
@export_multiline var description: String = ""
@export var art: Texture2D
@export var base_cost: int = 10
@export var growth: float = 1.5
@export var gain: int = 1
## Another item and the level it must reach before this one can be bought; empty id for
## items available from the start.
@export var requires_item: StringName
@export var requires_level: int = 0
