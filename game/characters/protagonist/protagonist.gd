@tool
class_name Protagonist
extends Node2D
## Fixed head/shirt artwork, pinned picking arm, and a tucked rigid fretting arm.

const Limb = preload("res://characters/protagonist/deformable_limb.gd")
## Inherited guitarist scenes override this along with their Sprite2D textures.
@export var strum_texture: Texture2D = preload("res://assets/characters/protagonist/arm_strum.png")
const FRET_OFFSETS: Array[Vector2] = [Vector2(-63, 21), Vector2(-83, 28), Vector2(-103, 35)]
const BOB_PX: float = 8.0
const TAP_DIP_PX: float = 6.0
const STRUM_RAD: float = 0.18
const DOWNSTROKE_END: float = 0.22
const BEATS_PER_GRIP: int = 4

@onready var _torso: Node2D = $Body/Torso
@onready var _arm_strum: Limb = $Body/Torso/Rig/ArmStrum
@onready var _arm_fret: Sprite2D = $Body/Torso/Rig/ArmFret
@onready var _fingers: Sprite2D = $Body/Torso/Rig/Fingers

var intensity: float = 0.3
var _torso_rest: Vector2
var _tap: float = 0.0
var _last_beat_phase: float = -1.0
var _beat_count: int = 0
var _grip: int = 0
var _previous_grip: int = 0
var _changing_grip: bool = false


func _ready() -> void:
	_torso_rest = _torso.position
	_arm_strum.configure(strum_texture, Rect2(210, 345, 195, 190))
	set_fret_pose(0)


func _process(delta: float) -> void:
	_tap = move_toward(_tap, 0.0, delta * 6.0)


## beats is the music clock in beats; strums_per_beat may be fractional (0.5 = one
## strum every two beats).
func animate(beats: float, strums_per_beat: float) -> void:
	var beat_phase: float = beats - floorf(beats)
	var phase: float = beat_phase * TAU
	var bounce: float = (1.0 - cos(phase)) * 0.5
	_torso.position = _torso_rest + Vector2(0.0, BOB_PX * bounce * intensity + TAP_DIP_PX * _tap)
	# All upper-body parts lean together, without opening a neck seam.
	_torso.rotation = sin(phase - 0.5) * 0.008 * intensity
	var cycle: float = fposmod(beats * strums_per_beat, 1.0)
	var sweep: float
	if cycle < DOWNSTROKE_END:
		sweep = lerpf(-1.0, 1.0, smoothstep(0.0, DOWNSTROKE_END, cycle))
	else:
		sweep = lerpf(1.0, -1.0, smoothstep(DOWNSTROKE_END, 1.0, cycle))
	_arm_strum.strum(sweep * STRUM_RAD * (0.4 + 0.6 * intensity))
	_update_grip(beat_phase)


func _update_grip(beat_phase: float) -> void:
	if _last_beat_phase >= 0.0 and beat_phase < _last_beat_phase - 0.5:
		_beat_count += 1
		if _beat_count % BEATS_PER_GRIP == 0:
			_previous_grip = _grip
			_grip = (_grip + 1) % FRET_OFFSETS.size()
			_changing_grip = true
	_last_beat_phase = beat_phase
	var offset: Vector2 = FRET_OFFSETS[_grip]
	if _changing_grip:
		offset = FRET_OFFSETS[_previous_grip].lerp(offset, smoothstep(0.0, 0.35, beat_phase))
		if beat_phase >= 0.35:
			_changing_grip = false
	_apply_fret_offset(offset)


## Select a grip for authoring, or for a future song-specific chord sequence.
func set_fret_pose(index: int) -> void:
	_grip = posmod(index, FRET_OFFSETS.size())
	_previous_grip = _grip
	_changing_grip = false
	_beat_count = 0
	_last_beat_phase = -1.0
	_apply_fret_offset(FRET_OFFSETS[_grip])


func _apply_fret_offset(offset: Vector2) -> void:
	_arm_fret.position = offset
	_fingers.position = offset


func on_tap() -> void:
	_tap = 1.0
