class_name JoinDialog
extends CanvasLayer
## A musician asks to join the band. The modal consumes every touch and only closes
## through its two answers; the music keeps playing behind it.

signal accepted(bandmate: Bandmate)
signal declined(bandmate: Bandmate)

var _bandmate: Bandmate

@onready var _portrait: TextureRect = %Portrait
@onready var _speaker: Label = %Speaker
@onready var _line: Label = %Line
@onready var _effect: Label = %Effect
@onready var _accept_button: Button = %AcceptButton
@onready var _decline_button: Button = %DeclineButton


func _ready() -> void:
	hide()
	_accept_button.pressed.connect(_answer.bind(accepted))
	_decline_button.pressed.connect(_answer.bind(declined))


## multiplier is what every tap will be worth once they are in the band.
func ask(bandmate: Bandmate, multiplier: int) -> void:
	_bandmate = bandmate
	_portrait.texture = bandmate.portrait
	_speaker.text = bandmate.name.to_upper()
	_line.text = bandmate.line
	_effect.text = "%s: x%d POR TOQUE" % [bandmate.effect, multiplier]
	show()


func _answer(answer: Signal) -> void:
	hide()
	answer.emit(_bandmate)
