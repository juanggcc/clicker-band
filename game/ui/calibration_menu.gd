class_name CalibrationMenu
extends CanvasLayer
## Rhythm calibration, opened from the pause menu. The player taps on every beat anywhere
## on screen and the median distance from the beat is offered for saving. Only the dim
## backdrop listens for taps, so presses on the buttons never count as beats.

signal saved(offset_sec: float)
signal closed

var music: MusicPlayer

var _calibration: TapCalibration = TapCalibration.new(MusicPlayer.BPM)

@onready var _dim: ColorRect = %Dim
@onready var _hint: Label = %Hint
@onready var _count: Label = %Count
@onready var _result_buttons: HBoxContainer = %ResultButtons
@onready var _repeat_button: Button = %RepeatButton
@onready var _save_button: Button = %SaveButton
@onready var _cancel_button: Button = %CancelButton


func _ready() -> void:
	hide()
	_dim.gui_input.connect(_on_dim_input)
	_repeat_button.pressed.connect(open)
	_save_button.pressed.connect(_save)
	_cancel_button.pressed.connect(_close)


func open() -> void:
	_calibration = TapCalibration.new(MusicPlayer.BPM)
	_refresh()
	show()


func _on_dim_input(event: InputEvent) -> void:
	# Touch only: on desktop the emulated mouse click would count every tap twice.
	var touch: InputEventScreenTouch = event as InputEventScreenTouch
	if touch == null or not touch.pressed:
		return
	_calibration.add_tap(music.beats())
	_refresh()


func _refresh() -> void:
	var done: bool = _calibration.is_done()
	_result_buttons.visible = done
	if not done:
		_count.text = str(_calibration.remaining())
		_hint.text = "TOCA EN CADA PULSO"
		return
	var ms: int = roundi(_calibration.offset_sec() * 1000.0)
	_count.text = "%+d MS" % ms
	_hint.text = (
		"TOCAS ANTES DEL PULSO" if ms < 0
		else "TOCAS DESPUÉS DEL PULSO" if ms > 0
		else "TOCAS EN EL PULSO"
	)


func _save() -> void:
	saved.emit(_calibration.offset_sec())
	_close()


func _close() -> void:
	hide()
	closed.emit()
