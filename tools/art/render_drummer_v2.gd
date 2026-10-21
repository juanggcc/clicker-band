extends SceneTree
## Actual engine frames. --mobile exercises the real main scene with an isolated save.

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var mobile: bool = "--mobile" in args
	var out: String = ProjectSettings.globalize_path("res://../workspace/art-jobs/bateria-conjunto-v02/rig/qa/" + ("mobile" if mobile else "frames"))
	DirAccess.make_dir_recursive_absolute(out)
	root.size = Vector2i(844, 390) if mobile else Vector2i(1152, 648)
	root.content_scale_size = Vector2i(1920, 1080)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND if mobile else Window.CONTENT_SCALE_ASPECT_KEEP
	var scene: Node
	if mobile:
		scene = load("res://main/main.tscn").instantiate()
		scene.save_path = "user://drummer-v2-render-only.cfg"
		root.add_child(scene)
		scene.set_process(false)
		scene.get_node("MusicPlayer").stop()
		scene.get_node("World/Ren").show()
		scene.get_node("World/Cham").show()
		scene.get_node("HUD").show_money(1250)
	else:
		scene = load("res://art_lab/drummer_v2.tscn").instantiate()
		root.add_child(scene)
		scene.set_process(false)
	var count: int = 72 if not mobile else 24
	for frame: int in count:
		var beat: float = fmod(frame, 24.0) / 12.0
		var tier: int = frame / 24
		if mobile:
			var zone: String = ["bedroom", "park", "garage"][frame / 8]
			scene._show_zone(load("res://world/zones/" + zone + ".tres"))
			scene._cham.intensity = 1.0
			scene._cham.animate(beat)
			scene._protagonist.animate(beat, 2.0)
			scene._ren.animate(beat, 2.0)
			scene._hud.show_tempo(TempoTiers.Tier.MID, 3.0)
		else:
			scene.tier = tier
			scene.render_at(beat)
		await process_frame
		await process_frame
		RenderingServer.force_draw()
		var error: Error = root.get_texture().get_image().save_png(out.path_join("frame-%03d.png" % frame))
		if error != OK:
			push_error("Failed screenshot " + str(error))
			quit(1)
			return
	print("Rendered %d real Godot frames to %s" % [count, out])
	scene.queue_free()
	await process_frame
	quit()
