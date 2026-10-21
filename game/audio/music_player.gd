class_name MusicPlayer
extends AudioStreamPlayer
## Plays the guitar stems, and Ren's bass and Cham's drums once they join, sample-locked
## inside one AudioStreamSynchronized: one stem per tier for each part, crossfaded by
## tier, so switching never breaks the beat.

const BPM: float = 120.0
const SILENT_DB: float = -60.0
const FADE_SEC: float = 0.25

@export var stems: Array[AudioStream] = []
## One stem per tier like stems, each part silent until set_band() says it plays.
@export var bass_stems: Array[AudioStream] = []
@export var drum_stems: Array[AudioStream] = []

var _sync: AudioStreamSynchronized = AudioStreamSynchronized.new()
var _tier: TempoTiers.Tier = TempoTiers.Tier.SLOW
var _gains: Array[float] = []
var _bass: bool = false
var _drums: bool = false
var _fade: Tween


func _ready() -> void:
	var parts: Array[AudioStream] = stems.duplicate()
	parts.append_array(bass_stems)
	parts.append_array(drum_stems)
	_sync.stream_count = parts.size()
	for i: int in parts.size():
		var stem: AudioStream = parts[i]
		if stem is AudioStreamWAV:
			_ensure_loop(stem as AudioStreamWAV)
		_sync.set_sync_stream(i, stem)
		_gains.append(_target(i))
		_set_gain(i, _gains[i])
	stream = _sync
	play()


func set_tier(tier: TempoTiers.Tier) -> void:
	if tier == _tier:
		return
	_tier = tier
	_fade_to_targets()


func set_band(bass: bool, drums: bool) -> void:
	if bass == _bass and drums == _drums:
		return
	_bass = bass
	_drums = drums
	_fade_to_targets()


## Beats into the current pass of the loop, whole beats landing on the beat.
## Uses what the player is hearing right now: the mixer position corrected by output latency.
func beats() -> float:
	var heard: float = get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
	return maxf(heard, 0.0) * BPM / 60.0


func _fade_to_targets() -> void:
	if _fade and _fade.is_valid():
		_fade.kill()
	_fade = create_tween()
	_fade.tween_method(_crossfade.bind(_gains.duplicate()), 0.0, 1.0, FADE_SEC)


## Full gain for the current tier's stem of the guitar and of each part being played.
## Streams run guitar, bass, drums, each with one stem per tier.
func _target(index: int) -> float:
	var count: int = stems.size()
	var playing: bool = index < count or (index < 2 * count and _bass) or (index >= 2 * count and _drums)
	return 1.0 if playing and index % count == _tier else 0.0


## Equal-power crossfade on linear gains: the outgoing stems follow a cosine and the
## incoming ones a sine, so the overall loudness holds steady through the switch instead
## of dipping halfway, as a straight fade in decibels does.
func _crossfade(t: float, from: Array[float]) -> void:
	var angle: float = t * PI / 2.0
	for i: int in from.size():
		var gain: float = lerpf(from[i], 1.0, sin(angle)) if _target(i) > 0.0 else from[i] * cos(angle)
		_set_gain(i, gain)


func _set_gain(index: int, gain: float) -> void:
	_gains[index] = gain
	_sync.set_sync_stream_volume(index, maxf(linear_to_db(gain), SILENT_DB))


func _ensure_loop(wav: AudioStreamWAV) -> void:
	if wav.loop_mode == AudioStreamWAV.LOOP_DISABLED:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = int(wav.get_length() * wav.mix_rate)
