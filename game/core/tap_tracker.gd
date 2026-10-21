class_name TapTracker
extends RefCounted
## Estimates how fast the player is tapping right now from the last few taps only, so a
## change of speed shows within two taps. Between taps the speed holds until the wait
## outgrows the current interval, then falls as 1 / wait, so slowing down or stopping
## shows before the next tap. Pure logic, no nodes, unit-testable.

const RECENT_TAPS: int = 3
## Taps closer than this (two fingers landing together) count once for the speed.
const MIN_INTERVAL_SEC: float = 0.05

var forget_sec: float
var _taps: Array[float] = []


func _init(forget: float = 1.0) -> void:
	forget_sec = forget


func register_tap(now: float) -> void:
	_prune(now)
	if not _taps.is_empty() and now - _taps[-1] < MIN_INTERVAL_SEC:
		return
	_taps.append(now)
	if _taps.size() > RECENT_TAPS:
		_taps.remove_at(0)


func taps_per_second(now: float) -> float:
	_prune(now)
	if _taps.size() < 2:
		return 0.0
	var intervals: int = _taps.size() - 1
	var rate: float = intervals / (_taps[-1] - _taps[0])
	var wait: float = now - _taps[-1]
	return minf(rate, 1.0 / wait) if wait > 0.0 else rate


## Taps older than forget_sec no longer describe the current speed.
func _prune(now: float) -> void:
	while not _taps.is_empty() and now - _taps[0] > forget_sec:
		_taps.remove_at(0)
