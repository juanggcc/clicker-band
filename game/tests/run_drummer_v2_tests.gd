extends SceneTree

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var drummer: DrummerV2 = load("res://characters/drummer_v2/drummer_v2.tscn").instantiate()
	root.add_child(drummer)
	var errors: Array[String] = []
	var max_joint_step: float = 0.0
	var max_grip_error: float = 0.0
	var max_contact_error: float = 0.0
	var max_bone_error: float = 0.0
	var min_tip_clearance: float = INF
	for strength: float in [0.0, 0.3, 0.65, 1.0]:
		drummer.intensity = strength
		var previous: Dictionary = {}
		for sample: int in 1921:
			var beats: float = sample / 240.0
			drummer.animate(beats)
			for side: String in ["R", "L"]:
				var pose: Dictionary = drummer._pose[side]
				var arm: Dictionary = drummer._arms[side]
				var hand: Sprite2D = drummer._parts["hand_" + side]
				var stick: Sprite2D = drummer._parts["stick_" + side]
				max_grip_error = maxf(max_grip_error, (hand.transform * (arm.grip as Vector2)).distance_to(stick.transform * (arm.grip as Vector2)))
				max_bone_error = maxf(max_bone_error, absf((pose.elbow as Vector2).distance_to(pose.wrist) - (arm.elbow as Vector2).distance_to(arm.wrist)))
				max_bone_error = maxf(max_bone_error, absf((pose.grip as Vector2).distance_to(pose.tip) - (arm.grip as Vector2).distance_to(arm.tip)))
				min_tip_clearance = minf(min_tip_clearance, (arm.tip as Vector2).y - (pose.tip as Vector2).y)
				if float(pose.lift) == 0.0:
					max_contact_error = maxf(max_contact_error, (pose.tip as Vector2).distance_to(arm.tip))
				if previous.has(side):
					max_joint_step = maxf(max_joint_step, (pose.wrist as Vector2).distance_to(previous[side].wrist))
				previous[side] = pose.duplicate()
				if not hand.transform.get_scale().is_equal_approx(Vector2.ONE):
					errors.append("Per-part stretch")
			# The only animated kit part must not move fixed hardware or the feet.
			for name_: String in ["body_core", "kit_hardware", "crash"]:
				if not (drummer._parts[name_] as Sprite2D).transform.is_equal_approx(Transform2D.IDENTITY):
					errors.append("Fixed body/hardware moved")
	if max_contact_error > 0.01 or max_grip_error > 0.01 or max_bone_error > 0.01:
		errors.append("Contact, grip or rigid length failed")
	if max_joint_step > 2.0 or min_tip_clearance < -0.01:
		errors.append("Discontinuous motion or tip below its head")
	# Check the actual sprite depth, including the complete ancestors.
	drummer.z_index = -12
	for name_: String in drummer._parts:
		var sprite: Sprite2D = drummer._parts[name_]
		var depth: int = sprite.z_index + drummer.z_index
		if depth <= -20 or depth >= 0:
			errors.append("Drummer must be above background and below foreground musicians")
		if sprite.texture.get_size() != Vector2(800, 1000):
			errors.append("Trimmed or wrongly sized part")
	for side: String in ["L", "R"]:
		if drummer._parts["stick_" + side].z_index >= drummer._parts["hand_" + side].z_index:
			errors.append("Wood must pass under the gripping fingers")
	drummer.set_rest_pose()
	for sprite: Sprite2D in drummer._parts.values():
		if not sprite.transform.is_equal_approx(Transform2D.IDENTITY):
			errors.append("Rest pose does not reconstruct source coordinates")
	var report: Dictionary = {"pass": errors.is_empty(), "samples": 7684, "intensities": [0, 0.3, 0.65, 1], "max_grip_error_px": max_grip_error, "max_contact_error_px": max_contact_error, "max_rigid_length_error_px": max_bone_error, "max_wrist_step_px": max_joint_step, "min_tip_clearance_px": min_tip_clearance, "errors": errors}
	var destination: String = ProjectSettings.globalize_path("res://../workspace/art-jobs/bateria-conjunto-v02/rig/qa/runtime-checks.json")
	DirAccess.make_dir_recursive_absolute(destination.get_base_dir())
	FileAccess.open(destination, FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print(JSON.stringify(report))
	drummer.queue_free()
	await process_frame
	quit(0 if errors.is_empty() else 1)
