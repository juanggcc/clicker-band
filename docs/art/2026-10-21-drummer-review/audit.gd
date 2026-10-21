extends SceneTree
## Read-only inspection of the current pilot. Run with -- --out /absolute/report.json.


func _initialize() -> void:
	call_deferred("_run")


func _xy(p: Vector2) -> Array:
	return [p.x, p.y]


func _effective_z(item: CanvasItem) -> int:
	var result: int = item.z_index
	var current: CanvasItem = item
	while current.z_as_relative:
		var parent: CanvasItem = current.get_parent() as CanvasItem
		if parent == null:
			break
		result += parent.z_index
		current = parent
	return result


func _sprites(node: Node, rows: Array) -> void:
	if node is Sprite2D:
		rows.append({"node": str(node.get_path()), "effective_z": _effective_z(node),
			"texture": node.texture.resource_path})
	for child: Node in node.get_children():
		_sprites(child, rows)


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2 or args[0] != "--out":
		push_error("Supply -- --out /absolute/report.json")
		quit(1)
		return
	var drummer: DrummerPilot = load("res://characters/drummer/drummer.tscn").instantiate() as DrummerPilot
	root.add_child(drummer)
	var report: Dictionary = {"engine": Engine.get_version_info().string,
		"scope": "Current v1 pilot; measurements do not certify visual quality",
		"rest_geometry": {}, "samples": 960, "solver_failures": 0,
		"max_tip_error_px": 0.0, "max_bone_error_px": 0.0,
		"angle_ranges_deg": {}, "simultaneous_impact_beat_1": {}, "sprites": []}
	for side: String in ["R", "L"]:
		var data: Dictionary = drummer.config.arms[side]
		var arm: Dictionary = drummer._arms[side]
		report.rest_geometry[side] = {"upper_arm_px": arm.l1, "forearm_px": arm.l2,
			"wrist_to_tip_px": drummer.point(data.wrist).distance_to(drummer.point(data.tip)),
			"grip_to_tip_px": drummer.point(data.grip).distance_to(drummer.point(data.tip)),
			"tip_to_strike_target_px": drummer.point(data.tip).distance_to(
				drummer.point(drummer.config.targets["hi_hat" if side == "R" else "snare"]))}
		report.angle_ranges_deg[side] = {"stick_screen_min": INF, "stick_screen_max": -INF,
			"hand_relative_to_forearm_change_min": INF, "hand_relative_to_forearm_change_max": -INF}
	for intensity: float in [0.3, 0.65, 1.0]:
		drummer.intensity = intensity
		for sample: int in 320:
			drummer.animate(sample / 40.0)
			report.solver_failures += int(drummer.diagnostics.solver_failures)
			report.max_tip_error_px = maxf(report.max_tip_error_px, drummer.diagnostics.max_tip_error)
			report.max_bone_error_px = maxf(report.max_bone_error_px, drummer.diagnostics.max_bone_error)
			for side: String in ["R", "L"]:
				var arm: Dictionary = drummer._arms[side]
				var data: Dictionary = drummer.config.arms[side]
				var hand: Node2D = arm.hand
				var forearm: Node2D = arm.forearm
				var stick: Vector2 = (drummer.point(data.tip) - drummer.point(data.grip)).rotated(hand.rotation + drummer._lean_angle)
				var stick_angle: float = rad_to_deg(stick.angle())
				var relative_change: float = rad_to_deg(wrapf(hand.rotation - forearm.rotation, -PI, PI))
				var ranges: Dictionary = report.angle_ranges_deg[side]
				ranges.stick_screen_min = minf(ranges.stick_screen_min, stick_angle)
				ranges.stick_screen_max = maxf(ranges.stick_screen_max, stick_angle)
				ranges.hand_relative_to_forearm_change_min = minf(ranges.hand_relative_to_forearm_change_min, relative_change)
				ranges.hand_relative_to_forearm_change_max = maxf(ranges.hand_relative_to_forearm_change_max, relative_change)
	drummer.intensity = 0.65
	drummer.animate(1.0)
	for side: String in ["R", "L"]:
		var arm: Dictionary = drummer._arms[side]
		var hand: Node2D = arm.hand
		var data: Dictionary = drummer.config.arms[side]
		var grip: Vector2 = drummer._to_canvas(hand.position + (drummer.point(data.grip) - drummer.point(data.wrist)).rotated(hand.rotation))
		var pose: Array = drummer._pose[side]
		report.simultaneous_impact_beat_1[side] = {"shoulder": _xy(pose[0]), "elbow": _xy(pose[1]),
			"wrist": _xy(pose[2]), "grip": _xy(grip), "tip": _xy(pose[3])}
	_sprites(drummer, report.sprites)
	var file := FileAccess.open(args[1], FileAccess.WRITE)
	if file == null:
		push_error("Cannot write report")
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("Read-only audit: %s samples, %s failures; report: %s" % [report.samples, report.solver_failures, args[1]])
	drummer.queue_free()
	await process_frame
	quit(0)
