class_name TempoBonus
extends RefCounted
## Rewards tapping in time with the song: on every eighth note in MID and every sixteenth
## in FAST, within window_share of the gap between notes either side. Each tap in time
## charges the bar; a tap off the grid, or a skipped note, starts draining it until the
## next tap in time. A full bar turns the multiplier on (x2 in MID, x4 in FAST) until the
## bar runs empty. SLOW has no grid: the bar only drains there and pays no multiplier.

const GRID_BEATS: Array[float] = [0.0, 0.5, 0.25]
const MULTIPLIERS: Array[int] = [1, 2, 4]

var seconds_per_beat: float
var window_share: float
var fill_beats: float
var empty_sec: float
## Average seconds the player's taps land after the beat this clock reports (negative:
## before), taken off each tap before judging it. It absorbs the audio latency the driver
## does not report, touch lag and the habit of anticipating the beat.
var tap_offset: float

var charge: float = 0.0
var active: bool = false
var _draining: bool = true
var _last_hit: float = -INF


func _init(
	bpm: float = 120.0, window: float = 0.3, fill: float = 8.0, empty: float = 2.5, offset: float = 0.0
) -> void:
	seconds_per_beat = 60.0 / bpm
	window_share = window
	fill_beats = fill
	empty_sec = empty
	tap_offset = offset


## beats is the song position being heard; now is a continuous clock in seconds.
func on_tap(beats: float, now: float, tier: TempoTiers.Tier) -> void:
	var grid: float = GRID_BEATS[tier]
	if grid == 0.0:
		_draining = true
		return
	var phase: float = fposmod(beats - tap_offset / seconds_per_beat, grid)
	if minf(phase, grid - phase) > grid * window_share:
		_draining = true
		return
	# A second finger on the same note counts once.
	if now - _last_hit < grid * seconds_per_beat / 2.0:
		return
	_last_hit = now
	_draining = false
	charge = minf(charge + grid / fill_beats, 1.0)
	if charge >= 1.0:
		active = true


## Call every frame. Letting a note's window close without a tap starts the drain.
func update(now: float, delta: float, tier: TempoTiers.Tier) -> void:
	var grid_sec: float = GRID_BEATS[tier] * seconds_per_beat
	if grid_sec == 0.0 or now - _last_hit > grid_sec * (1.0 + window_share):
		_draining = true
	if _draining:
		charge = maxf(charge - delta / empty_sec, 0.0)
		if charge == 0.0:
			active = false


func multiplier(tier: TempoTiers.Tier) -> int:
	return MULTIPLIERS[tier] if active else 1
