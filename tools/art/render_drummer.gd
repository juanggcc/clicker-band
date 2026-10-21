extends SceneTree
## Graphical Godot capture + numeric validation of the actual rendered rig.

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2 or args[0] != "--out":
		push_error("Supply -- --out workspace/art-jobs/.../qa/frames [--quick]")
		quit(1)
		return
	var out: String = args[1]
	if not out.is_absolute_path():
		out = ProjectSettings.globalize_path("res://..").path_join(out).simplify_path()
	DirAccess.make_dir_recursive_absolute(out)
	root.size = Vector2i(1152, 648)
	root.content_scale_size = Vector2i(1920, 1080)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	var scene: Node = load("res://art_lab/drummer_articulation.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	var errors: Array[String] = []
	var max_tip: float = 0.0
	var max_bone: float = 0.0
	var count: int = 8 if "--quick" in args else 80
	for frame: int in count:
		var beat: float = frame * 8.0 / count
		scene.call("render_at", beat)
		var diag: Dictionary = scene.left.diagnostics
		max_tip = maxf(max_tip, diag.max_tip_error)
		max_bone = maxf(max_bone, diag.max_bone_error)
		if int(diag.solver_failures) != 0:
			errors.append("Unreachable target at beat " + str(beat))
		for side: String in ["R", "L"]:
			var foot: Node2D = scene.left._feet[side]
			if foot.position.distance_to(scene.left.point(scene.left.config.heels[side])) > 0.01:
				errors.append("Heel moved at beat " + str(beat))
		await process_frame
		await process_frame
		RenderingServer.force_draw()
		if root.get_texture().get_image().save_png(out.path_join("frame-%03d.png" % frame)) != OK:
			errors.append("Could not save frame " + str(frame))
	if max_tip > 0.02 or max_bone > 0.02:
		errors.append("Rigid-chain/contact tolerance exceeded")
	var report := {"frames": count, "beats": 8, "max_tip_error_px": max_tip, "max_bone_length_error_px": max_bone, "heels_fixed": true, "errors": errors, "pass": errors.is_empty(), "note": "Checks actual Godot transforms. Does not certify anatomical/visual quality or hidden pedal geometry."}
	var file := FileAccess.open(out.path_join("checks.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print(JSON.stringify(report))
	scene.queue_free()
	await process_frame
	quit(0 if errors.is_empty() else 1)
