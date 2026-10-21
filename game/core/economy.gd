class_name Economy
extends RefCounted
## Money earned per tap: 1 plus what every shop item adds per level, times a multiplier
## (tempo bonus and band size). An item's next level costs `growth` times the previous
## one, and some items need another item at a given level before they can be bought.

var money: int = 0
var items: Array[ShopItem] = []
var _levels: Dictionary[StringName, int] = {}


func _init(catalogue: Array[ShopItem] = []) -> void:
	items = catalogue


func level(id: StringName) -> int:
	return _levels.get(id, 0)


func levels() -> Dictionary[StringName, int]:
	return _levels.duplicate()


func set_level(id: StringName, value: int) -> void:
	_levels[id] = value


func find(id: StringName) -> ShopItem:
	for item: ShopItem in items:
		if item.id == id:
			return item
	return null


func per_tap() -> int:
	var total: int = 1
	for item: ShopItem in items:
		total += item.gain * level(item.id)
	return total


func earn_from_tap(multiplier: int) -> int:
	var earned: int = per_tap() * multiplier
	money += earned
	return earned


func cost(item: ShopItem) -> int:
	return roundi(item.base_cost * pow(item.growth, level(item.id)))


## True when id is empty or that item has reached at_level.
func meets(id: StringName, at_level: int) -> bool:
	return id == &"" or level(id) >= at_level


func is_unlocked(item: ShopItem) -> bool:
	return meets(item.requires_item, item.requires_level)


func can_buy(item: ShopItem) -> bool:
	return is_unlocked(item) and money >= cost(item)


func buy(item: ShopItem) -> bool:
	if not is_unlocked(item) or not spend(cost(item)):
		return false
	_levels[item.id] = level(item.id) + 1
	return true


## Takes amount from the balance if it is all there; otherwise leaves it untouched.
func spend(amount: int) -> bool:
	if money < amount:
		return false
	money -= amount
	return true
