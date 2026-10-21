class_name BandRecruit
extends RefCounted
## Whether a bandmate turns up on a tap: a small chance on every tap, and certain
## once guarantee_taps taps have gone by without them. Declining resets the count, so
## they come back later; joining ends the rolls.

var chance: float
var guarantee_taps: int
var joined: bool = false
var _taps: int = 0


func _init(per_tap: float = 1.0 / 700.0, guarantee: int = 1500) -> void:
	chance = per_tap
	guarantee_taps = guarantee


## Call on every tap where they can turn up, with a uniform random number in [0, 1).
## True means they turn up now.
func roll(random: float) -> bool:
	if joined:
		return false
	_taps += 1
	if _taps < guarantee_taps and random >= chance:
		return false
	_taps = 0
	return true


func join() -> void:
	joined = true
