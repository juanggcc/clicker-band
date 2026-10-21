extends SceneTree
## Godot --path game -s ../tools/art/capture_guitar_comparison.gd -- --out workspace/art-jobs/cowboy-piloto-v01/qa/comparison


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 2 or args[0] != "--out" or DisplayServer.get_name() == "headless":
		push_error("Use a graphical backend and supply -- --out directory")
		quit(1)
		return
	var destination: String = args[1]
	if not destination.is_absolute_path():
		destination = ProjectSettings.globalize_path("res://..").path_join(destination).simplify_path()
	if DirAccess.make_dir_recursive_absolute(destination) != OK:
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1920, 1080)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	var scene: Node = load("res://art_lab/guitar_comparison.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	for frame: int in 48:
		scene.call("render_at", frame / 12.0, 1)
		await process_frame
		await process_frame
		RenderingServer.force_draw()
		var file: String = destination.path_join("frame-%02d.png" % frame)
		if root.get_texture().get_image().save_png(file) != OK:
			quit(1)
			return
	print("Saved comparison and 48 animation frames to ", destination)
	scene.queue_free()
	await process_frame
	quit()
