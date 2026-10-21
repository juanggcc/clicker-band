extends Node2D
## Standalone art test scene. Open guitar_comparison.tscn and press F6.

const INTENSITIES: Array[float] = [0.3, 0.65, 1.0]
const STRUMS: Array[float] = [0.5, 2.0, 4.0]

@onready var _protagonist: Protagonist = $Protagonist
@onready var _cowboy: Protagonist = $Cowboy
@onready var _pause_button: Button = $Controls/Panel/Row/Pause
@onready var _level: OptionButton = $Controls/Panel/Row/Level

var _beats: float = 0.0
var _tier: int = 1
var _playing: bool = true


func _ready() -> void:
	for caption: String in ["LENTO", "MEDIO", "RÁPIDO"]:
		_level.add_item(caption)
	_level.select(_tier)
	_level.item_selected.connect(_set_tier)
	_pause_button.pressed.connect(_toggle_playing)


func _process(delta: float) -> void:
	if _playing:
		_beats += delta * 2.0
	_update_pose()


func _update_pose() -> void:
	for musician: Protagonist in [_protagonist, _cowboy]:
		musician.intensity = INTENSITIES[_tier]
		musician.animate(_beats, STRUMS[_tier])


func _set_tier(index: int) -> void:
	_tier = clampi(index, 0, 2)
	_level.select(_tier)


func _toggle_playing() -> void:
	_playing = not _playing
	_pause_button.text = "PAUSAR" if _playing else "REANUDAR"


func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_SPACE:
			_toggle_playing()
		KEY_1, KEY_2, KEY_3:
			_set_tier(key.keycode - KEY_1)
		KEY_R:
			_beats = 0.0
			_protagonist.set_fret_pose(0)
			_cowboy.set_fret_pose(0)


## Used by the deterministic visual export; ordinary playback uses _process.
func render_at(beat: float, tier: int = 1) -> void:
	_beats = beat
	_set_tier(tier)
	var grip: int = int(floor(beat / 4.0)) % 3
	_protagonist.set_fret_pose(grip)
	_cowboy.set_fret_pose(grip)
	_update_pose()
