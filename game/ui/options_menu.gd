class_name OptionsMenu
extends CanvasLayer
## Pause menu. Opening it pauses the whole tree, music included; this layer is set to
## always process so its own buttons keep working. Erasing the game takes a second press
## within RESET_CONFIRM_SEC.

signal calibrate_pressed
signal reset_pressed
signal quit_pressed

const RESET_TEXT: String = "BORRAR PARTIDA"
const RESET_CONFIRM_TEXT: String = "¿SEGURO? TOCA OTRA VEZ"
const RESET_CONFIRM_SEC: float = 3.0

@onready var _resume_button: Button = %ResumeButton
@onready var _sound_button: Button = %SoundButton
@onready var _calibrate_button: Button = %CalibrateButton
@onready var _reset_button: Button = %ResetButton
@onready var _quit_button: Button = %QuitButton

var _confirming_reset: bool = false


func _ready() -> void:
	hide()
	_resume_button.pressed.connect(close)
	_sound_button.pressed.connect(_toggle_sound)
	_calibrate_button.pressed.connect(calibrate_pressed.emit)
	_reset_button.pressed.connect(_on_reset_pressed)
	_quit_button.pressed.connect(quit_pressed.emit)
	_show_sound()


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


func _toggle_sound() -> void:
	AudioServer.set_bus_mute(0, not AudioServer.is_bus_mute(0))
	_show_sound()


func _show_sound() -> void:
	_sound_button.text = "SONIDO: NO" if AudioServer.is_bus_mute(0) else "SONIDO: SÍ"
