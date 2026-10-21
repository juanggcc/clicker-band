extends SceneTree
## Review assets against the real rig without installing them in the game.

func _initialize() -> void:
	call_deferred("_run")

func absolute_repo_path(value: String) -> String:
	if value.is_absolute_path():
		return value
	return ProjectSettings.globalize_path("res://..").path_join(value).simplify_path()

func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 4 or args.size() % 2 != 0:
		push_error("Usage: -- --asset PNG --out DIRECTORY [--character res://scene.tscn]")
		quit(1)
		return
	var options: Dictionary = {"--character": "res://characters/cowboy/cowboy.tscn"}
	for i: int in range(0, args.size(), 2):
		if args[i] not in ["--asset", "--out", "--character"]:
			push_error("Unknown option: " + args[i])
			quit(1)
			return
		options[args[i]] = args[i + 1]
	if not options.has("--asset") or not options.has("--out"):
		push_error("Asset and output directory are required")
		quit(1)
		return
	if DisplayServer.get_name() == "headless":
		push_error("Use a graphical backend for review captures")
		quit(1)
		return
	var destination: String = absolute_repo_path(options["--out"])
	DirAccess.make_dir_recursive_absolute(destination)
	var image: Image = Image.load_from_file(absolute_repo_path(options["--asset"]))
	if image == null or image.get_size() != Vector2i(900, 900):
		push_error("Expected registered instrument on a 900x900 canvas")
		quit(1)
		return
	var scene: PackedScene = load(options["--character"]) as PackedScene
	if scene == null:
		quit(1)
		return
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(900, 900)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var rig: Protagonist = scene.instantiate() as Protagonist
	if rig == null:
		push_error("Character must use the standing guitarist rig")
		quit(1)
		return
	rig.position = Vector2(350, 900)
	viewport.add_child(rig)
	(rig.get_node("Body/Torso/Rig/Guitar") as Sprite2D).texture = ImageTexture.create_from_image(image)
	rig.set_process(false)
	for grip: int in 3:
		for stroke: int in [-1, 1]:
			rig.set_fret_pose(grip)
			rig.get_node("Body/Torso/Rig/ArmStrum").call("strum", stroke * 0.18)
			await process_frame
			await process_frame
			RenderingServer.force_draw()
			viewport.get_texture().get_image().save_png(destination.path_join("grip-%d-stroke-%d.png" % [grip, stroke]))
	rig.set_fret_pose(0)
	rig.get_node("Body/Torso/Rig/ArmStrum").call("strum", 0.0)
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	viewport.get_texture().get_image().save_png(destination.path_join("neutral.png"))
	print("Saved instrument review to ", destination)
	viewport.queue_free()
	await process_frame
	quit()
