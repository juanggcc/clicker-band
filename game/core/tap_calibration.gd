class_name TapCalibration
extends RefCounted
## Measures how far a player's taps land from the beat they hear. They tap along to the
## quarter notes; the first few taps are dropped while they lock on, and the median of
## the rest becomes TempoBonus.tap_offset, so the odd stray tap does not move it.

var seconds_per_beat: float
var warmup_taps: int
var sample_taps: int
var _taps: int = 0
var _samples: Array[float] = []


func _init(bpm: float = 120.0, warmup: int = 4, samples: int = 20) -> void:
	seconds_per_beat = 60.0 / bpm
	warmup_taps = warmup
	sample_taps = samples


## beats is the song position heard at the tap, as MusicPlayer.beats() reports it.
func add_tap(beats: float) -> void:
	if is_done():
		return
	_taps += 1
	if _taps > warmup_taps:
		# Measured from the nearest beat: a tap just before beat 8 is early, not late.
		_samples.append(fposmod(beats + 0.5, 1.0) - 0.5)


func remaining() -> int:
	return warmup_taps + sample_taps - _taps


func is_done() -> bool:
	return remaining() == 0


## Median distance from the beat in seconds, negative when taps land early. Call once done.
func offset_sec() -> float:
	var sorted: Array[float] = _samples.duplicate()
	sorted.sort()
	var middle: int = sorted.size() / 2
	var median: float = (
		sorted[middle] if sorted.size() % 2 == 1
		else (sorted[middle - 1] + sorted[middle]) / 2.0
	)
	return median * seconds_per_beat
