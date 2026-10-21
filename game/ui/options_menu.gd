class_name OptionsMenu
extends CanvasLayer
## Pause menu. Opening it pauses the whole tree, music included; this layer is set to
## always process so its own buttons keep working. The sound fader sets the Master bus
## as it moves and reports the level once it is let go. Erasing the game takes a second
## press within RESET_CONFIRM_SEC.

## volume is a linear gain from 0 to 1, as set_volume() takes it.
signal volume_set(volume: float)
signal calibrate_pressed
signal reset_pressed
signal quit_pressed

const RESET_TEXT: String = "BORRAR PARTIDA"
const RESET_CONFIRM_TEXT: String = "¿SEGURO? TOCA OTRA VEZ"
const RESET_CONFIRM_SEC: float = 3.0

@onready var _resume_button: Button = %ResumeButton
@onready var _volume_fader: PixelFader = %VolumeFader
@onready var _calibrate_button: Button = %CalibrateButton
@onready var _reset_button: Button = %ResetButton
@onready var _quit_button: Button = %QuitButton

var _confirming_reset: bool = false


func _ready() -> void:
	hide()
	_resume_button.pressed.connect(close)
	_volume_fader.value_changed.connect(_apply_volume.unbind(1))
	_volume_fader.drag_ended.connect(_on_volume_released.unbind(1))
	_calibrate_button.pressed.connect(calibrate_pressed.emit)
	_reset_button.pressed.connect(_on_reset_pressed)
	_quit_button.pressed.connect(quit_pressed.emit)


func open() -> void:
	get_tree().paused = true
	show()


func close() -> void:
	get_tree().paused = false
	hide()
	_cancel_reset()


func _on_reset_pressed() -> void:
	if _confirming_reset:
		reset_pressed.emit()
		return
	_confirming_reset = true
	_reset_button.text = RESET_CONFIRM_TEXT
	get_tree().create_timer(RESET_CONFIRM_SEC).timeout.connect(_cancel_reset)


func _cancel_reset() -> void:
	_confirming_reset = false
	_reset_button.text = RESET_TEXT


## Moves the fader to a linear gain from 0 to 1 and applies it.
func set_volume(volume: float) -> void:
	_volume_fader.set_value_no_signal(volume * _volume_fader.max_value)
	_apply_volume()


## The fader is linear in amplitude: halfway is -6 dB, and all the way down mutes.
func _apply_volume() -> void:
	var volume: float = _volume_fader.get_as_ratio()
	AudioServer.set_bus_mute(0, volume <= 0.0)
	if volume > 0.0:
		AudioServer.set_bus_volume_db(0, linear_to_db(volume))


# A tap on the slot jumps the fader without a drag, so the level is reported on every
# release, moved or not.
func _on_volume_released() -> void:
	volume_set.emit(_volume_fader.get_as_ratio())
