class_name TempoTiers
extends RefCounted
## Picks the music loop from the current tapping speed alone, so the player moves between
## loops whenever they like: MID from mid_rate taps/s, FAST from fast_rate.
## A loop is left only once the speed falls hysteresis below its entry speed, so tapping
## right at a threshold does not flicker between loops.

enum Tier { SLOW, MID, FAST }

var mid_rate: float
var fast_rate: float
var hysteresis: float

var tier: Tier = Tier.SLOW


func _init(mid: float = 2.75, fast: float = 5.0, margin: float = 0.3) -> void:
	mid_rate = mid
	fast_rate = fast
	hysteresis = margin


## Call every frame and on every tap with the current taps per second.
func update(rate: float) -> Tier:
	var reached: Tier = _tier_at(rate)
	var kept: Tier = _tier_at(rate + hysteresis)
	if reached > tier:
		tier = reached
	elif kept < tier:
		tier = kept
	return tier


func _tier_at(rate: float) -> Tier:
	if rate >= fast_rate:
		return Tier.FAST
	if rate >= mid_rate:
		return Tier.MID
	return Tier.SLOW
