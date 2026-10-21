extends SceneTree
## Exercise low/high intensities and continuity of the actual rigid-chain solver.

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var drummer: DrummerPilot = load("res://characters/drummer/drummer.tscn").instantiate() as DrummerPilot
	root.add_child(drummer)
	var errors: Array[String] = []
	var max_step: float = 0.0
	var max_left_outward: float = 0.0
	var left_hand_z: int = (drummer._arms.L.hand as Node2D).z_index + drummer._lean.z_index
	var left_forearm_z: int = (drummer._arms.L.forearm as Node2D).z_index + drummer._lean.z_index
	var right_hand_z: int = (drummer._arms.R.hand as Node2D).z_index + drummer._lean.z_index
	var hi_hat_z: int = (drummer._cymbals.hi_hat_top as Node2D).z_index
	var hi_hat_front_z: int = (drummer.get_node("Body/HiHatFront") as Sprite2D).z_index
	if left_hand_z >= hi_hat_z or left_forearm_z >= hi_hat_z or left_hand_z >= hi_hat_front_z or right_hand_z <= hi_hat_z:
		errors.append("Hi-hat depth must be above the left arm and below the right hand")
	for intensity: float in [0.3, 0.65, 1.0]:
		drummer.intensity = intensity
		var previous: Dictionary = {}
		for sample: int in 320:
			drummer.animate(sample / 40.0)
			if int(drummer.diagnostics.solver_failures) != 0:
				errors.append("Unreachable groove target")
			if float(drummer.diagnostics.max_tip_error) > 0.02 or float(drummer.diagnostics.max_bone_error) > 0.02:
				errors.append("Tip contact or fixed-length error")
			for side: String in ["L","R"]:
				var chain: Array = drummer._pose[side]
				if side == "L":
					var outward: float = (chain[1] as Vector2).x - (chain[0] as Vector2).x
					max_left_outward = maxf(max_left_outward, outward)
					if outward > float(drummer.config.arms.L.max_outward_px) + 1.0:
						errors.append("Left elbow moved away from torso")
				if previous.has(side):
					for i: int in [1,2]:
						max_step = maxf(max_step,(chain[i] as Vector2).distance_to(previous[side][i]))
				previous[side] = chain.duplicate()
				if (drummer._feet[side] as Node2D).position.distance_to(drummer.point(drummer.config.heels[side])) > 0.01:
					errors.append("Heel pivot translated")
	if max_step > 20.0:
		errors.append("Abrupt elbow/wrist jump at 0.025-beat sampling")
	var report := {"samples":960,"intensities":[0.3,0.65,1.0],"max_joint_step_px":max_step,"max_left_elbow_outward_px":max_left_outward,"left_arm_behind_hi_hat":left_hand_z < hi_hat_z and left_hand_z < hi_hat_front_z,"pass":errors.is_empty(),"errors":errors}
	var destination: String = ProjectSettings.globalize_path("res://../art/jobs/bateria-articulacion-v01/qa/solver-checks.json")
	var file := FileAccess.open(destination,FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	drummer.queue_free()
	await process_frame
	quit(0 if errors.is_empty() else 1)
