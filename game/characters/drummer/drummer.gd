class_name DrummerPilot
extends Node2D
## Registered cutout pilot. Fixed bone lengths; target is the wooden stick TIP.

const SKIN := "res://assets/characters/drummer/"
const KIT := "res://assets/instruments/compact-drums/"
var intensity: float = 0.65
var show_joints: bool = false
var config: Dictionary
var diagnostics: Dictionary = {}
var _body: Node2D
var _lean: Node2D
var _rig: Node2D
var _arms: Dictionary = {}
var _feet: Dictionary = {}
var _cymbals: Dictionary = {}
var _pose: Dictionary = {}
var _overlay: Node2D
var _pelvis: Vector2
var _lean_angle: float = 0.0


func _ready() -> void:
	config = JSON.parse_string(FileAccess.get_file_as_string(SKIN + "rig.json"))
	_pelvis = point(config.pelvis)
	_body = Node2D.new()
	_body.name = "Body"
	_body.position = -point(config.ground_origin)
	add_child(_body)
	_sprite(_body, SKIN + "legs_seat.png", Vector2.ZERO, 0)
	_lean = Node2D.new()
	_lean.name = "Torso"
	_lean.position = _pelvis
	_lean.z_index = 1
	_body.add_child(_lean)
	_rig = Node2D.new()
	_rig.name = "Rig"
	_rig.position = -_pelvis
	_lean.add_child(_rig)
	_sprite(_rig, SKIN + "body_core.png", Vector2.ZERO, 0)
	for side: String in ["L", "R"]:
		var data: Dictionary = config.arms[side]
		var shoulder: Vector2 = point(data.shoulder)
		var elbow: Vector2 = point(data.elbow)
		var wrist: Vector2 = point(data.wrist)
		var upper: Node2D = _part(_rig, "upper_arm_" + side, shoulder, 1)
		var forearm: Node2D = _part(_rig, "forearm_" + side, elbow, 3 if side == "L" else 6)
		var hand: Node2D = Node2D.new()
		hand.name = "Hand" + side
		hand.position = wrist
		hand.z_index = 4 if side == "L" else 7
		_rig.add_child(hand)
		_sprite(hand, SKIN + "stick_" + side + ".png", -wrist, 0)
		_sprite(hand, SKIN + "hand_" + side + ".png", -wrist, 1)
		_arms[side] = {"upper": upper, "forearm": forearm, "hand": hand,
			"shoulder": shoulder, "rest_elbow": elbow, "rest_wrist": wrist,
			"l1": shoulder.distance_to(elbow), "l2": elbow.distance_to(wrist),
			"upper_angle": (elbow - shoulder).angle(), "fore_angle": (wrist - elbow).angle(),
			"tip_relative": point(data.tip) - wrist}
		var heel: Vector2 = point(config.heels[side])
		_feet[side] = _part(_body, "shoe_" + side, heel, 1)
	_sprite(_body, KIT + "kit_fixed.png", Vector2.ZERO, 3)
	# Both hi-hat plates and the upper stand occlude the tucked snare arm;
	# the right hi-hat hand/wood remain above them.
	_sprite(_body, KIT + "hi_hat_front.png", Vector2.ZERO, 6)
	for name_: String in ["crash_ride", "hi_hat_top"]:
		var pivot: Vector2 = point(config.cymbals[name_])
		var node: Node2D = Node2D.new()
		node.name = name_.to_pascal_case()
		node.position = pivot
		node.z_index = 6 if name_ == "hi_hat_top" else 4
		_body.add_child(node)
		_sprite(node, KIT + name_ + ".png", -pivot, 0)
		_cymbals[name_] = node
	_overlay = Node2D.new()
	_overlay.name = "Joints"
	_overlay.z_index = 100
	add_child(_overlay)
	_overlay.draw.connect(_draw_overlay.bind(_overlay))
	set_rest_pose()


func point(value: Array) -> Vector2:
	return Vector2(float(value[0]), float(value[1]))


func _sprite(parent: Node, file: String, offset: Vector2, z: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = file.get_file().get_basename().to_pascal_case()
	sprite.texture = load(file) as Texture2D
	sprite.centered = false
	sprite.position = offset
	sprite.z_index = z
	parent.add_child(sprite)
	return sprite


func _part(parent: Node, file: String, pivot: Vector2, z: int) -> Node2D:
	var node := Node2D.new()
	node.name = file.to_pascal_case()
	node.position = pivot
	node.z_index = z
	parent.add_child(node)
	_sprite(node, SKIN + file + ".png", -pivot, 0)
	return node


func set_rest_pose() -> void:
	_lean_angle = 0.0
	_lean.rotation = 0.0
	_pose.clear()
	for side: String in ["L", "R"]:
		var arm: Dictionary = _arms[side]
		(arm.upper as Node2D).rotation = 0.0
		(arm.forearm as Node2D).position = arm.rest_elbow
		(arm.forearm as Node2D).rotation = 0.0
		(arm.hand as Node2D).position = arm.rest_wrist
		(arm.hand as Node2D).rotation = 0.0
		(_feet[side] as Node2D).rotation = 0.0
		_pose[side] = [arm.shoulder, arm.rest_elbow, arm.rest_wrist, point(config.arms[side].tip)]
	for name_: String in _cymbals:
		(_cymbals[name_] as Node2D).rotation = 0.0
		(_cymbals[name_] as Node2D).position = point(config.cymbals[name_])
	_overlay.queue_redraw()


## First validated groove only. Other drum keyposes need alternate arm drawings.
func animate(beats: float, mode: int = 0) -> void:
	if mode == 3:
		set_rest_pose()
		return
	_lean_angle = sin(beats * PI) * 0.005 * intensity
	_lean.rotation = _lean_angle
	var right_name: String = "hi_hat"
	var left_name: String = "snare"
	var r_phase: float = fposmod(beats * 2.0, 1.0)
	var l_phase: float = fposmod((beats - 1.0) / 2.0, 1.0)
	var r_lift: float = _rebound(r_phase) * (24.0 + 12.0 * intensity)
	var l_lift: float = _rebound(l_phase) * (23.0 + 12.0 * intensity)
	var right_target: Vector2 = point(config.targets[right_name]) + Vector2(0, -r_lift)
	var left_target: Vector2 = point(config.targets[left_name]) + Vector2(0, -l_lift)
	diagnostics = {"max_tip_error": 0.0, "max_bone_error": 0.0, "solver_failures": 0, "right_target": right_name, "left_target": left_name}
	_pose_arm("R", right_target)
	_pose_arm("L", left_target)
	var kick_phase: float = fposmod(beats / 2.0, 1.0)
	(_feet.R as Node2D).rotation = -0.035 * exp(-kick_phase * 22.0) * intensity
	(_feet.L as Node2D).rotation = 0.025 * sin(beats * PI) * intensity
	var crash: Node2D = _cymbals.crash_ride
	crash.rotation = sin(r_phase * TAU * 2.0) * exp(-r_phase * 4.0) * 0.025 * intensity if right_name == "crash_ride" else 0.0
	var hi_hat: Node2D = _cymbals.hi_hat_top
	hi_hat.position = point(config.cymbals.hi_hat_top) + Vector2(0, -2.5 * maxf(0.0, -sin(beats * PI)))
	hi_hat.rotation = sin(r_phase * TAU) * exp(-r_phase * 7.0) * 0.008 if right_name == "hi_hat" else 0.0
	_overlay.queue_redraw()


func _rebound(phase: float) -> float:
	if phase < 0.35:
		return sin(phase / 0.35 * PI * 0.5)
	return 1.0 - smoothstep(0.35, 1.0, phase)


func _to_local_canvas(value: Vector2) -> Vector2:
	return _pelvis + (value - _pelvis).rotated(-_lean_angle)


func _to_canvas(value: Vector2) -> Vector2:
	return _pelvis + (value - _pelvis).rotated(_lean_angle)


func _pose_arm(side: String, canvas_target: Vector2) -> void:
	var arm: Dictionary = _arms[side]
	var target: Vector2 = _to_local_canvas(canvas_target)
	var shoulder: Vector2 = arm.shoulder
	var l1: float = arm.l1
	var l2: float = arm.l2
	var tip_relative: Vector2 = arm.tip_relative
	var best_cost: float = INF
	var best: Array = []
	# Search rigid hand orientation, then solve exact two-bone IK in both bends.
	# No per-part scale and no nearest-target teleport/clamp are used.
	for i: int in 360:
		var angle: float = -PI + i * TAU / 360.0
		var wrist: Vector2 = target - tip_relative.rotated(angle)
		var distance: float = shoulder.distance_to(wrist)
		if distance >= l1 + l2 - 0.1 or distance <= absf(l1 - l2) + 0.1:
			continue
		var alpha: float = acos(clampf((l1 * l1 + distance * distance - l2 * l2) / (2.0 * l1 * distance), -1.0, 1.0))
		for bend: float in [-1.0, 1.0]:
			var upper_angle: float = (wrist - shoulder).angle() + bend * alpha
			var elbow: Vector2 = shoulder + Vector2.from_angle(upper_angle) * l1
			if side == "L":
				var max_outward: float = float(config.arms.L.max_outward_px)
				if elbow.x < shoulder.x - 12.0 or elbow.x > shoulder.x + max_outward or elbow.y < shoulder.y + 75.0:
					continue
			var fore_angle: float = (wrist - elbow).angle()
			var wrist_bend: float = absf(wrapf(angle - (fore_angle - float(arm.fore_angle)), -PI, PI))
			var cost: float = wrist_bend * wrist_bend * 5.0
			cost += pow(maxf(0.0, shoulder.y - elbow.y - 30.0) / 60.0, 2.0)
			cost += absf(wrapf(upper_angle - float(arm.upper_angle), -PI, PI)) * 0.13
			# Keep a small bend rather than locking a fully extended elbow.
			cost += pow(distance / (l1 + l2), 8.0) * 0.18
			if side == "L":
				var hint: Vector2 = point(config.arms.L.elbow_hint)
				cost += elbow.distance_squared_to(hint) / 1600.0 * 0.5
			if cost < best_cost:
				best_cost = cost
				best = [elbow, wrist, angle, upper_angle, fore_angle]
	if best.is_empty():
		diagnostics.solver_failures += 1
		return
	var elbow: Vector2 = best[0]
	var wrist: Vector2 = best[1]
	var hand_angle: float = best[2]
	(arm.upper as Node2D).rotation = float(best[3]) - float(arm.upper_angle)
	(arm.forearm as Node2D).position = elbow
	(arm.forearm as Node2D).rotation = float(best[4]) - float(arm.fore_angle)
	(arm.hand as Node2D).position = wrist
	(arm.hand as Node2D).rotation = hand_angle
	var tip: Vector2 = wrist + tip_relative.rotated(hand_angle)
	diagnostics.max_tip_error = maxf(diagnostics.max_tip_error, _to_canvas(tip).distance_to(canvas_target))
	diagnostics.max_bone_error = maxf(diagnostics.max_bone_error, absf(shoulder.distance_to(elbow) - l1))
	diagnostics.max_bone_error = maxf(diagnostics.max_bone_error, absf(elbow.distance_to(wrist) - l2))
	_pose[side] = [_to_canvas(shoulder), _to_canvas(elbow), _to_canvas(wrist), _to_canvas(tip)]


func _draw_overlay(overlay: Node2D) -> void:
	if not show_joints or config.is_empty():
		return
	overlay.draw_set_transform(-point(config.ground_origin))
	for side: String in _pose:
		var chain: Array = _pose[side]
		for i: int in range(chain.size() - 1):
			overlay.draw_line(chain[i], chain[i + 1], Color("87e0c0"), 2.0, true)
		for value: Vector2 in chain:
			overlay.draw_circle(value, 4.0, Color("87e0c0"))
	for name_: String in config.targets:
		overlay.draw_circle(point(config.targets[name_]), 5.0, Color("f1c774"), false, 2.0, true)
	for side: String in config.heels:
		overlay.draw_circle(point(config.heels[side]), 5.0, Color("f1c774"), false, 2.0, true)
