class_name WorldMap
extends RefCounted
## Which zones the band owns and where it is playing. A zone is bought once and can be
## visited freely after that. Pure logic over zone ids, no nodes, unit-testable.

var owned: Array[StringName] = []
var current: StringName


func _init(start: StringName) -> void:
	owned.append(start)
	current = start


func owns(id: StringName) -> bool:
	return owned.has(id)


func buy(id: StringName, price: int, economy: Economy) -> bool:
	if owns(id) or not economy.spend(price):
		return false
	owned.append(id)
	return true


func travel(id: StringName) -> bool:
	if not owns(id) or id == current:
		return false
	current = id
	return true
