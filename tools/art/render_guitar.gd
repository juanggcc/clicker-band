extends SceneTree
## Render staged full-canvas guitarist layers with the real rig, without importing
## or installing them. Run with a graphical backend, not --headless.

const SCENE: PackedScene = preload("res://characters/protagonist/protagonist.tscn")
const FILES: Dictionary[String, String] = {
	"Body/Legs": "legs.png",
	"Body/Torso/Rig/Core": "body_core.png",
	"Body/Torso/Rig/ArmFret": "arm_fret.png",
	"Body/Torso/Rig/Guitar": "guitar.png",
	"Body/Torso/Rig/Fingers": "hand_fret.png",
	"Body/Torso/Rig/Cuff": "strum_sleeve.png",
}


func _initialize() -> void:
	call_deferred("_run")


func absolute_repo_path(value: String) -> String:
	if value.is_absolute_path():
		return value
	return ProjectSettings.globalize_path("res://..").path_join(value).simplify_path()


func load_png(path: String) -> Texture2D:
	var image: Image = Image.load_from_file(path)
	if image == null or image.get_size() != Vector2i(700, 900):
		push_error("Expected a 700x900 PNG: " + path)
		return null
	return ImageTexture.create_from_image(image)


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 4 or args[0] != "--skin" or args[2] != "--out":
		push_error("Usage: -- --skin path/to/exports --out path/to/qa")
		quit(1)
		return
	if DisplayServer.get_name() == "headless":
		push_error("Use a graphical backend to capture pose images.")
		quit(1)
		return
	var skin: String = absolute_repo_path(args[1])
	var destination: String = absolute_repo_path(args[3])
	if DirAccess.make_dir_recursive_absolute(destination) != OK:
		push_error("Could not create pose render directory")
		quit(1)
		return
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(700, 900)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
	root.add_child(viewport)
	var rig: Protagonist = SCENE.instantiate() as Protagonist
	for node_path: String in FILES:
		var texture: Texture2D = load_png(skin.path_join(FILES[node_path]))
		if texture == null:
			quit(1)
			return
		(rig.get_node(node_path) as Sprite2D).texture = texture
	rig.strum_texture = load_png(skin.path_join("arm_strum.png"))
	if rig.strum_texture == null:
		quit(1)
		return
	rig.position = Vector2(350, 900)
	viewport.add_child(rig)
	rig.set_process(false)
	for grip: int in 3:
		for stroke: int in [-1, 1]:
			rig.set_fret_pose(grip)
			rig.get_node("Body/Torso/Rig/ArmStrum").call("strum", stroke * 0.18)
			await process_frame
			await process_frame
			RenderingServer.force_draw()
			var file: String = destination.path_join("grip-%d-stroke-%d.png" % [grip, stroke])
			if viewport.get_texture().get_image().save_png(file) != OK:
				push_error("Could not save " + file)
				quit(1)
				return
	print("Saved six poses to ", destination)
	viewport.queue_free()
	await process_frame
	quit()
