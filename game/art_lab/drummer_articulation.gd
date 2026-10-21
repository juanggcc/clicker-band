extends Node2D
## F6: Space pause, G joints, 1/2/3 intensity, 4 rest, S slow.

const DRUMMER = preload("res://characters/drummer/drummer.tscn")
var beats: float = 0.0
var playing: bool = true
var slow: bool = false
var mode: int = 0
var tier: int = 1
var left: DrummerPilot
var right: DrummerPilot
var caption: Label


func _ready() -> void:
	var background := ColorRect.new()
	background.size = Vector2(1920, 1080)
	background.color = Color("2b3034")
	background.z_index = -10
	add_child(background)
	left = DRUMMER.instantiate() as DrummerPilot
	left.position = Vector2(490, 955)
	left.scale = Vector2.ONE * 0.88
	add_child(left)
	right = DRUMMER.instantiate() as DrummerPilot
	right.position = Vector2(1430, 955)
	right.scale = Vector2.ONE * 0.88
	right.show_joints = true
	add_child(right)
	var title := Label.new()
	title.position = Vector2(70, 38)
	title.text = "BATERÍA · PRIMERA PRUEBA ARTICULADA"
	title.add_theme_font_size_override("font_size", 33)
	add_child(title)
	caption = Label.new()
	caption.position = Vector2(70, 90)
	caption.add_theme_font_size_override("font_size", 23)
	add_child(caption)
	var legend := Label.new()
	legend.position = Vector2(1030, 1000)
	legend.text = "Verde: hombro → codo → muñeca → punta\nÁmbar: golpeo y talones fijos"
	legend.add_theme_font_size_override("font_size", 21)
	add_child(legend)
	var controls := HBoxContainer.new()
	controls.position = Vector2(70, 1005)
	controls.add_theme_constant_override("separation", 12)
	add_child(controls)
	for data: Array in [["Pausa", -1], ["Suave", 0], ["Medio", 1], ["Fuerte", 2], ["Reposo", 3], ["Lento", -2]]:
		var button := Button.new()
		button.text = data[0]
		button.add_theme_font_size_override("font_size", 21)
		button.pressed.connect(_select.bind(int(data[1])))
		controls.add_child(button)
	render_at(0.0)


func _select(value: int) -> void:
	if value == -1:
		playing = not playing
	elif value == -2:
		slow = not slow
	else:
		mode = 3 if value == 3 else 0
		if value < 3:
			tier = value
		beats = 0.0


func _process(delta: float) -> void:
	if playing:
		beats += delta * (0.6 if slow else 2.0)
	render_at(beats)


func render_at(value: float) -> void:
	beats = value
	left.intensity = [0.3, 0.65, 1.0][tier]
	right.intensity = left.intensity
	left.animate(beats, mode)
	right.animate(beats, mode)
	caption.text = "120 BPM · %s · %s" % ["pose de ejecución" if mode == 3 else "hi-hat + caja · " + ["suave", "medio", "fuerte"][tier], "cámara lenta" if slow else "velocidad normal"]


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_SPACE:
			_select(-1)
		KEY_S:
			_select(-2)
		KEY_G:
			right.show_joints = not right.show_joints
		KEY_1, KEY_2, KEY_3, KEY_4:
			_select(key.keycode - KEY_1)
		KEY_R:
			beats = 0.0
