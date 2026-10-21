extends SceneTree
## Actual 844x390 viewport, live drummer + existing HUD and four band places.

func _initialize() -> void:
	call_deferred("_run")


func _reserve(parent: Node, x: float) -> void:
	var node := Node2D.new()
	node.position = Vector2(x, 1000)
	node.modulate = Color(0.6, 0.74, 0.8, 0.65)
	parent.add_child(node)
	var torso := Polygon2D.new()
	torso.polygon = PackedVector2Array([Vector2(-70,-560),Vector2(70,-560),Vector2(105,-325),Vector2(55,-310),Vector2(62,-25),Vector2(8,-25),Vector2(0,-290),Vector2(-8,-25),Vector2(-62,-25),Vector2(-55,-310),Vector2(-105,-325)])
	torso.color = Color("263e49")
	node.add_child(torso)
	var head := Polygon2D.new()
	var points := PackedVector2Array()
	for i: int in 32:
		points.append(Vector2(cos(i * TAU / 32.0) * 56, -635 + sin(i * TAU / 32.0) * 70))
	head.polygon = points
	head.color = torso.color
	node.add_child(head)


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2 or args[0] != "--out":
		quit(1)
		return
	var out: String = ProjectSettings.globalize_path("res://..").path_join(args[1]).simplify_path()
	DirAccess.make_dir_recursive_absolute(out)
	root.size = Vector2i(844, 390)
	root.content_scale_size = Vector2i(2336, 1080)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	var stage := Node2D.new()
	root.add_child(stage)
	var bg := Sprite2D.new()
	bg.texture = load("res://assets/backgrounds/park.png")
	bg.centered = false
	bg.position = Vector2(-32, 0)
	stage.add_child(bg)
	var drummer: DrummerPilot = load("res://characters/drummer/drummer.tscn").instantiate() as DrummerPilot
	drummer.position = Vector2(1168, 930)
	drummer.scale = Vector2.ONE * 0.8
	stage.add_child(drummer)
	var musicians: Array[Protagonist] = []
	for data: Array in [["protagonist",470.0],["cowboy",1720.0]]:
		var musician: Protagonist = load("res://characters/%s/%s.tscn" % [data[0],data[0]]).instantiate() as Protagonist
		musician.position = Vector2(data[1],1000)
		musician.scale = Vector2.ONE * 0.8
		stage.add_child(musician)
		musicians.append(musician)
	_reserve(stage, 850)
	_reserve(stage, 2110)
	var hud: Node = load("res://ui/hud.tscn").instantiate()
	stage.add_child(hud)
	hud.call("show_place",load("res://world/zones/park.tres"))
	hud.call("show_money",1250)
	hud.call("show_tempo",TempoTiers.Tier.MID,3.0)
	var note := Label.new()
	note.position = Vector2(880,1010)
	note.text = "PRUEBA · 2 PLAZAS RESERVADAS"
	note.add_theme_font_size_override("font_size",21)
	note.modulate = Color("e9d9bd")
	stage.add_child(note)
	for frame: int in 32:
		var beat: float = frame / 8.0
		drummer.animate(beat)
		for musician: Protagonist in musicians:
			musician.animate(beat,2.0)
		hud.call("show_beat",beat)
		await process_frame
		await process_frame
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png(out.path_join("frame-%03d.png" % frame))
	stage.queue_free()
	await process_frame
	print("Captured 32 actual mobile frames with HUD and five places")
	quit()
