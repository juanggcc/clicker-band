extends SceneTree
## Check the real inherited scene supplied after --scene, plus shared rig behavior.

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("FAIL: " + message)


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 4 or args[0] != "--scene" or args[2] != "--assets":
		push_error("Supply -- --scene res://characters/variant/variant.tscn --assets res://assets/characters/variant")
		quit(1)
		return
	var scene: PackedScene = load(args[1]) as PackedScene
	check(scene != null, "inherited scene loads")
	if scene == null:
		quit(1)
		return
	var rig: Protagonist = scene.instantiate() as Protagonist
	check(rig != null, "variant inherits the shared guitarist behavior")
	if rig == null:
		quit(1)
		return
	root.add_child(rig)
	await process_frame
	var arm: Polygon2D = rig.get_node("Body/Torso/Rig/ArmStrum") as Polygon2D
	check(arm.texture == rig.strum_texture, "mesh uses the variant's exported strum texture")
	var expected_folder: String = args[3]
	check(rig.strum_texture.resource_path == expected_folder.path_join("arm_strum.png"), "variant overrides the original picking arm")
	var expected_files: Dictionary[String, String] = {
		"Body/Legs": "legs.png", "Body/Torso/Rig/Core": "body_core.png",
		"Body/Torso/Rig/Guitar": "guitar.png", "Body/Torso/Rig/ArmFret": "arm_fret.png",
		"Body/Torso/Rig/Fingers": "hand_fret.png", "Body/Torso/Rig/Cuff": "strum_sleeve.png",
	}
	for node_path: String in expected_files:
		var sprite: Sprite2D = rig.get_node(node_path) as Sprite2D
		check(sprite.texture.resource_path == expected_folder.path_join(expected_files[node_path]), "variant texture selected for " + node_path)
	for grip: int in 3:
		rig.set_fret_pose(grip)
		check(rig.get_node("Body/Torso/Rig/ArmFret").position == rig.get_node("Body/Torso/Rig/Fingers").position, "arm and fingers stay together for grip %d" % grip)
	var rest: PackedVector2Array = arm.get("rest_points")
	arm.call("strum", 0.18)
	var pinned: int = 0
	var moved: int = 0
	for i: int in rest.size():
		if rest[i].y <= 389.0:
			check(rest[i].is_equal_approx(arm.polygon[i]), "upper attachment stays pinned")
			pinned += 1
		elif rest[i].distance_to(arm.polygon[i]) > 0.1:
			moved += 1
	check(pinned > 0 and moved > 0, "mesh has both pinned and moving regions")
	rig.intensity = 1.0
	rig.animate(0.1, 4.0)
	check(is_finite(rig.get_node("Body/Torso").position.y), "shared animation runs on the inherited variant")
	rig.queue_free()
	await process_frame
	print("Guitar template: %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures else 0)
