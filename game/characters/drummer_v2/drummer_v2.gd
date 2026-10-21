class_name DrummerV2
extends Node2D
## Authored playing pose. Canvas-space pivots; bounded FK, no target-seeking IK.
## Skins share the drawing contract and can override the two asset directories.

@export_dir var skin_directory: String = "res://assets/characters/drummer-v2"
@export_dir var kit_directory: String = "res://assets/instruments/compact-drums-v2"
var intensity: float = 0.65
var show_joints: bool = false
var config: Dictionary = {}
var _canvas: Node2D
var _arms: Dictionary = {}
var _parts: Dictionary = {}
var _pose: Dictionary = {}
var _overlay: Node2D


func _ready() -> void:
	config = JSON.parse_string(FileAccess.get_file_as_string(skin_directory.path_join("rig.json")))
	_canvas = Node2D.new()
	_canvas.name = "Canvas"
	_canvas.position = -point(config.ground_origin)
	add_child(_canvas)
	for data: Dictionary in config.layers:
		var directory: String = kit_directory if data.owner == "kit" else skin_directory
		var sprite := Sprite2D.new()
		sprite.name = data.id
		sprite.texture = load(directory.path_join(data.id + ".png")) as Texture2D
		sprite.centered = false
		# All drawing depths are relative to this rig root, never to moving parents.
		sprite.z_index = int(data.z)
		_canvas.add_child(sprite)
		_parts[data.id] = sprite
	for side: String in ["L", "R"]:
		var arm: Dictionary = config.arms[side]
		_arms[side] = {"elbow": point(arm.elbow), "wrist": point(arm.wrist),
			"grip": point(arm.grip), "tip": point(arm.tip), "butt": point(arm.butt)}
	_overlay = Node2D.new()
	_overlay.name = "Coordinates"
	_overlay.z_index = 100
	_canvas.add_child(_overlay)
	_overlay.draw.connect(_draw_overlay)
	set_rest_pose()


func point(value: Array) -> Vector2:
	return Vector2(float(value[0]), float(value[1]))


func set_rest_pose() -> void:
	for part: Sprite2D in _parts.values():
		part.transform = Transform2D.IDENTITY
	for side: String in ["L", "R"]:
		_pose_arm(side, 0.0)
	_overlay.queue_redraw()


func animate(beats: float, mode: int = 0) -> void:
	if mode == 3:
		set_rest_pose()
		return
	var strength: float = clampf(intensity, 0.0, 1.0)
	var r_phase: float = fposmod(beats * 2.0, 1.0)
	var l_phase: float = fposmod((beats - 1.0) / 2.0, 1.0)
	_pose_arm("R", _rebound(r_phase) * lerpf(0.45, 1.0, strength))
	_pose_arm("L", _rebound(l_phase) * lerpf(0.45, 1.0, strength))
	var pivot: Vector2 = point(config.cymbals.hi_hat)
	# Only the complete upper plate moves; its hardware and lower plate stay fixed.
	var wobble: float = sin(r_phase * TAU) * exp(-r_phase * 7.0) * 0.007 * strength
	(_parts.hi_hat_top as Sprite2D).transform = around(pivot, wobble)
	_overlay.queue_redraw()


func _rebound(phase: float) -> float:
	# Both ends have zero velocity, including the loop boundary at each strike.
	if phase < 0.28:
		return smoothstep(0.0, 0.28, phase)
	return 1.0 - smoothstep(0.28, 1.0, phase)


func around(pivot: Vector2, angle: float) -> Transform2D:
	return Transform2D(angle, pivot - pivot.rotated(angle))


func _pose_arm(side: String, lift: float) -> void:
	var arm: Dictionary = _arms[side]
	var data: Dictionary = config.arms[side]
	var elbow: Vector2 = arm.elbow
	var wrist: Vector2 = arm.wrist
	var forearm_transform: Transform2D = around(elbow, deg_to_rad(float(data.rebound_forearm_deg)) * lift)
	var hand_transform: Transform2D = forearm_transform * around(wrist, deg_to_rad(float(data.rebound_wrist_deg)) * lift)
	(_parts["forearm_" + side] as Sprite2D).transform = forearm_transform
	(_parts["hand_" + side] as Sprite2D).transform = hand_transform
	# Identical transform locks the shaft in the drawn thumb/index fulcrum.
	(_parts["stick_" + side] as Sprite2D).transform = hand_transform
	_pose[side] = {"elbow": elbow, "wrist": forearm_transform * wrist,
		"grip": hand_transform * (arm.grip as Vector2),
		"tip": hand_transform * (arm.tip as Vector2),
		"butt": hand_transform * (arm.butt as Vector2), "lift": lift}


func _draw_overlay() -> void:
	if not show_joints:
		return
	for side: String in _pose:
		var arm: Dictionary = _pose[side]
		var chain: PackedVector2Array = [point(config.arms[side].shoulder), arm.elbow, arm.wrist, arm.grip, arm.tip]
		_overlay.draw_polyline(chain, Color("8ed8b1"), 2.0, true)
		for p: Vector2 in chain:
			_overlay.draw_circle(p, 4.0, Color("8ed8b1"))
	for target: Array in config.targets.values():
		_overlay.draw_circle(point(target), 6.0, Color("f4ca78"), false, 2.0, true)
	_overlay.draw_line(Vector2(80, 920), Vector2(740, 920), Color("f4ca78"), 1.0)
	_overlay.draw_circle(point(config.ground_origin), 5.0, Color("f4ca78"))
