extends SceneTree
## Asset QA and proposed menu/map compositions. No gameplay scene files are edited.

const OUT: String = "res://../docs/art/2026-10-21-menu-map/"
const JOB: String = "res://../workspace/art-jobs/parque-menu-v01/qa/"
const FONT: Font = preload("res://assets/fonts/silkscreen/Silkscreen-Regular.ttf")
const MAIN: PackedScene = preload("res://main/main.tscn")
const CREAM: Color = Color("f6efdb")
const MINT: Color = Color("8ed8b1")
const GOLD: Color = Color("f4ca78")
const MUTED: Color = Color("a8b4b8")
const INK: Color = Color("111923")

var stage: Control
var game: Node2D
var overlay: CanvasLayer


func _initialize() -> void:
	call_deferred("_run")


func texture(path: String) -> Texture2D:
	var bitmap: Image = Image.load_from_file(ProjectSettings.globalize_path("res://assets/" + path))
	assert(bitmap != null, "Missing PNG: " + path)
	return ImageTexture.create_from_image(bitmap)


func rect(box: Rect2, tint: Color) -> ColorRect:
	var item: ColorRect = ColorRect.new()
	item.position = box.position
	item.size = box.size
	item.color = tint
	stage.add_child(item)
	return item


func text(copy: String, box: Rect2, font_size: int = 30, tint: Color = CREAM, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var item: Label = Label.new()
	item.text = copy
	item.position = box.position
	item.size = box.size
	item.add_theme_font_override("font", FONT)
	item.add_theme_font_size_override("font_size", font_size)
	item.add_theme_color_override("font_color", tint)
	item.horizontal_alignment = align
	item.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stage.add_child(item)
	return item


func sprite(path: String, box: Rect2, linear: bool = false) -> TextureRect:
	var item: TextureRect = TextureRect.new()
	item.texture = texture(path)
	item.position = box.position
	item.size = box.size
	item.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	item.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if linear else CanvasItem.TEXTURE_FILTER_NEAREST
	stage.add_child(item)
	return item


func panel(box: Rect2, file: String = "panel_frame.png") -> void:
	var item: NinePatchRect = NinePatchRect.new()
	item.texture = texture("ui/shop/v1/" + file)
	item.position = box.position
	item.size = box.size
	item.patch_margin_left = 18
	item.patch_margin_top = 18
	item.patch_margin_right = 18
	item.patch_margin_bottom = 18
	item.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	stage.add_child(item)


func reset_stage() -> void:
	if stage != null:
		stage.free()
	stage = Control.new()
	stage.size = Vector2(1920, 1080)
	overlay.add_child(stage)


func atlas() -> void:
	reset_stage()
	rect(Rect2(0, 0, 1920, 1080), INK)
	text("MENÚ Y MAPA / V1", Rect2(72, 42, 1776, 90), 54)
	text("PALETA DE TIENDA / PÍXEL X3 / ALFA REAL", Rect2(72, 135, 1776, 45), 27, MUTED)
	var paths: Array[String] = ["menu/v1/icon_map.png", "menu/v1/icon_menu.png", "menu/v1/icon_settings.png", "map/v1/icon_pin.png", "map/v1/icon_place_park.png"]
	var names: Array[String] = ["MAPA", "MENÚ", "AJUSTES", "ESTÁS AQUÍ", "PARQUE"]
	for i: int in paths.size():
		var x: int = 72 + i * 360
		var px: int = 72 if i < 3 else 36
		panel(Rect2(x, 213, 336, 264))
		text(names[i], Rect2(x + 12, 225, 312, 48), 30, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
		sprite("ui/" + paths[i], Rect2(x + (336 - px) / 2, 306, px, px))
		text("%d X %d" % [px, px], Rect2(x + 12, 411, 312, 36), 24, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	var zones: Array[String] = ["bedroom", "park", "locked"]
	var zone_names: Array[String] = ["TU CUARTO", "PARQUE", "???"]
	for i: int in zones.size():
		var x: int = 72 + i * 600
		panel(Rect2(x, 525, 576, 441))
		sprite("ui/map/v1/zone_%s.png" % zones[i], Rect2(x + 96, 573, 384, 216), true)
		if i == 2:
			sprite("ui/shop/v1/icon_lock.png", Rect2(x + 270, 630, 36, 36))
			text("???", Rect2(x + 96, 678, 384, 60), 48, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
		text(zone_names[i], Rect2(x + 24, 819, 528, 60), 36, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
		text("384 X 216", Rect2(x + 24, 897, 528, 36), 24, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	text("MINIATURAS SIN MARCOS NI TEXTO / CANDADO Y RÓTULOS EN GODOT", Rect2(72, 993, 1776, 45), 24, MUTED)


func menu_mockup() -> void:
	reset_stage()
	rect(Rect2(0, 0, 1920, 1080), Color(0.03, 0.06, 0.09, 0.70))
	panel(Rect2(813, 219, 1035, 714))
	text("MENÚ", Rect2(873, 255, 846, 84), 54)
	sprite("ui/shop/v1/icon_close.png", Rect2(1752, 279, 36, 36))
	text("ELIGE QUÉ QUIERES HACER", Rect2(873, 354, 900, 45), 27, MUTED)
	var icons: Array[String] = ["shop/v1/icon_shop.png", "menu/v1/icon_map.png", "menu/v1/icon_settings.png"]
	var names: Array[String] = ["TIENDA", "MAPA", "AJUSTES"]
	for i: int in icons.size():
		var x: int = 873 + i * 309
		panel(Rect2(x, 450, 285, 318), "item_frame.png")
		sprite("ui/" + icons[i], Rect2(x + 105, 516, 72, 72))
		text(names[i], Rect2(x + 12, 651, 261, 60), 30, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	text("PROPUESTA VISUAL / TEXTOS DEL MOTOR", Rect2(873, 828, 915, 45), 24, MUTED)


func map_mockup() -> void:
	reset_stage()
	rect(Rect2(0, 0, 1920, 1080), Color(0.03, 0.06, 0.09, 0.78))
	panel(Rect2(105, 150, 1710, 786))
	sprite("ui/menu/v1/icon_map.png", Rect2(159, 192, 72, 72))
	text("MAPA", Rect2(264, 186, 1380, 84), 54)
	sprite("ui/shop/v1/icon_close.png", Rect2(1725, 210, 36, 36))
	text("ELIGE DÓNDE TOCAR", Rect2(165, 294, 1590, 45), 27, MUTED)
	var zones: Array[String] = ["bedroom", "park", "locked"]
	var names: Array[String] = ["TU CUARTO", "PARQUE", "???"]
	for i: int in zones.size():
		var x: int = 165 + i * 537
		panel(Rect2(x, 384, 516, 477), "item_frame.png")
		panel(Rect2(x + 48, 417, 420, 252), "item_slot.png")
		sprite("ui/map/v1/zone_%s.png" % zones[i], Rect2(x + 66, 435, 384, 216), true)
		text(names[i], Rect2(x + 24, 687, 468, 60), 36, CREAM if i != 2 else MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		if i == 1:
			sprite("ui/map/v1/icon_pin.png", Rect2(x + 102, 783, 36, 36))
			text("ESTÁS AQUÍ", Rect2(x + 153, 777, 324, 48), 24, MINT)
		elif i == 0:
			panel(Rect2(x + 48, 768, 420, 66), "button_primary_normal.png")
			text("IR AL CUARTO", Rect2(x + 60, 771, 396, 54), 27, INK, HORIZONTAL_ALIGNMENT_CENTER)
		else:
			sprite("ui/shop/v1/icon_lock.png", Rect2(x + 240, 492, 36, 36))
			text("???", Rect2(x + 66, 543, 384, 60), 48, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
			text("POR DESCUBRIR", Rect2(x + 24, 777, 468, 48), 24, MUTED, HORIZONTAL_ALIGNMENT_CENTER)


func save_shot(path: String) -> void:
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	assert(root.get_texture().get_image().save_png(path) == OK, "Could not save " + path)
	print("Saved ", path)


func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1920, 1080)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	overlay = CanvasLayer.new()
	overlay.layer = 100
	root.add_child(overlay)
	game = MAIN.instantiate() as Node2D
	root.add_child(game)
	game.set_process(false)
	(game.get_node("MusicPlayer") as AudioStreamPlayer).stop()
	var background: Sprite2D = game.get_node_or_null("World/Background") as Sprite2D
	if background == null:
		background = game.get_node("World/Bedroom") as Sprite2D
	background.texture = texture("backgrounds/park.png")
	var bandmate: Node2D = game.get_node_or_null("World/Bandmate") as Node2D
	if bandmate != null:
		bandmate.hide()
	var hud: HUD = game.get_node("HUD") as HUD
	var place_title: Label = hud.find_child("PlaceTitle", true, false) as Label
	if place_title == null:
		place_title = hud.get_node("Margin/PlacePanel/Row/Copy/Place") as Label
	place_title.text = "Parque"
	var place_icon: Control = hud.find_child("PlaceIcon", true, false) as Control
	if place_icon == null:
		place_icon = hud.get_node("Margin/PlacePanel/Row/Icon") as Control
	place_icon.set("texture", texture("ui/map/v1/icon_place_park.png"))
	hud.show_money(1250)
	await save_shot(OUT + "preview-park-hud.png")
	root.size = Vector2i(1600, 720)
	await save_shot(JOB + "park-hud-wide.png")
	root.size = Vector2i(1280, 720)
	reset_stage()
	# Guide is QA only: future drummer world x=1150..1500, feet y=1000.
	rect(Rect2(1150, 480, 350, 520), Color(0.56, 0.85, 0.69, 0.16))
	text("RESERVA BATERÍA", Rect2(1150, 501, 350, 60), 24, MINT, HORIZONTAL_ALIGNMENT_CENTER)
	rect(Rect2(1150, 996, 350, 4), MINT)
	await save_shot(JOB + "park-drummer-space.png")
	menu_mockup()
	await save_shot(OUT + "preview-menu.png")
	map_mockup()
	await save_shot(OUT + "preview-map.png")
	game.free()
	game = null
	atlas()
	await save_shot(OUT + "preview-sprites.png")
	quit()
