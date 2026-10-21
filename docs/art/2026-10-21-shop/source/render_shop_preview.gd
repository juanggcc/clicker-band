extends SceneTree
## Design-only renderer. Does not install a shop or mutate gameplay scenes.
## Godot --path game -s ../docs/art/2026-10-21-shop/source/render_shop_preview.gd

const BASE: String = "res://assets/ui/shop/v1/"
const OUT: String = "res://../docs/art/2026-10-21-shop/"
const FONT: Font = preload("res://assets/fonts/silkscreen/Silkscreen-Regular.ttf")
const CREAM: Color = Color("f6efdb")
const MUTED: Color = Color("a8b4b8")
const MINT: Color = Color("8ed8b1")
const GOLD: Color = Color("f4ca78")
const INK: Color = Color("111923")

var stage: Control
var textures: Dictionary[String, Texture2D] = {}

func _initialize() -> void:
	call_deferred("_render_all")

func texture(file: String) -> Texture2D:
	if not textures.has(file):
		var imported: Texture2D = load(BASE + file) as Texture2D
		assert(imported != null, "Missing sprite: " + file)
		textures[file] = imported
	return textures[file]

func rect(box: Rect2, tint: Color, parent: Node = stage) -> ColorRect:
	var item: ColorRect = ColorRect.new()
	item.color = tint
	item.position = box.position
	item.size = box.size
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(item)
	return item

func sprite(file: String, box: Rect2, tint: Color = Color.WHITE, parent: Node = stage) -> TextureRect:
	var item: TextureRect = TextureRect.new()
	item.texture = texture(file)
	item.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	item.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	item.position = box.position
	item.size = box.size
	item.modulate = tint
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(item)
	return item

func panel(file: String, box: Rect2, parent: Node = stage, bottom: int = 18) -> NinePatchRect:
	var item: NinePatchRect = NinePatchRect.new()
	item.texture = texture(file)
	item.patch_margin_left = 18
	item.patch_margin_top = 18
	item.patch_margin_right = 18
	item.patch_margin_bottom = bottom
	item.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	item.position = box.position
	item.size = box.size
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(item)
	return item

func text(copy: String, box: Rect2, font_size: int, tint: Color = CREAM, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, parent: Node = stage) -> Label:
	var label: Label = Label.new()
	label.text = copy
	label.position = box.position
	label.size = box.size
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	label.add_theme_color_override("font_shadow_color", Color(0.03, 0.05, 0.07, 0.6))
	label.add_theme_constant_override("shadow_offset_y", 3 if tint != INK else 0)
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func reset_stage() -> void:
	if is_instance_valid(stage):
		stage.free()
	stage = Control.new()
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(stage)

func background() -> void:
	var background_image: Image = Image.load_from_file(ProjectSettings.globalize_path("res://../workspace/reviews/2026-10-21-hud/preview-mid.png"))
	var item: TextureRect = TextureRect.new()
	item.texture = ImageTexture.create_from_image(background_image)
	item.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item.size = Vector2(1920, 1080)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(item)

func shop_access() -> void:
	panel("panel_frame.png", Rect2(1716, 864, 156, 168))
	sprite("icon_shop.png", Rect2(1758, 888, 72, 72))
	text("TIENDA", Rect2(1731, 981, 126, 30), 24, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	rect(Rect2(1845, 876, 9, 9), MINT)

func shop(state: String = "available") -> void:
	background()
	shop_access()
	rect(Rect2(0, 0, 1920, 1080), Color(0.035, 0.055, 0.08, 0.72))
	# Deliberate right-side composition; the musician remains visible on the left.
	rect(Rect2(813, 108, 1068, 888), Color(0.02, 0.03, 0.05, 0.38))
	panel("panel_frame.png", Rect2(804, 96, 1068, 888))
	rect(Rect2(855, 102, 69, 3), MINT)
	for x: int in [819, 1854]:
		for y: int in [114, 963]:
			rect(Rect2(x, y, 3, 3), Color("71808a"))
	sprite("icon_shop_active.png", Rect2(855, 147, 48, 48))
	text("TIENDA", Rect2(924, 126, 570, 81), 60)
	text("AFINA TU EQUIPO", Rect2(855, 216, 540, 39), 30, MUTED)
	panel("button_secondary.png", Rect2(1755, 132, 72, 72))
	sprite("icon_close.png", Rect2(1773, 150, 36, 36))
	var balance: String = "12 €" if state == "unaffordable" else ("12 400 €" if state == "purchased" else "12 450 €")
	sprite("icon_coin.png", Rect2(1449, 216, 36, 36))
	text(balance, Rect2(1503, 198, 324, 69), 40, GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	rect(Rect2(855, 285, 966, 3), Color("52606b"))
	text("MEJORAS", Rect2(855, 309, 660, 45), 30)
	text("01", Rect2(1731, 309, 90, 45), 30, MINT, HORIZONTAL_ALIGNMENT_RIGHT)

	panel("item_frame.png", Rect2(855, 375, 966, 399))
	panel("item_slot.png", Rect2(885, 405, 246, 249))
	sprite("pick_upgrade.png", Rect2(900, 420, 216, 219))
	text("NIVEL 1" if state == "purchased" else "NIVEL 0 > 1", Rect2(885, 678, 246, 48), 24, MINT if state == "purchased" else MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	text("PÚA DE ENSAYO", Rect2(1167, 399, 624, 75), 50)
	text("Un ataque más preciso.\nMás por cada toque.", Rect2(1167, 480, 618, 96), 30, MUTED)
	rect(Rect2(1167, 606, 618, 63), INK)
	rect(Rect2(1167, 606, 3, 63), MINT)
	text("+1 € POR TOQUE", Rect2(1191, 612, 570, 51), 30, MINT)
	text("GANANCIA BASE", Rect2(1167, 699, 282, 36), 24, MUTED)
	text("1 €", Rect2(1464, 690, 90, 51), 30, MUTED)
	sprite("icon_arrow.png", Rect2(1575, 705, 24, 24), MINT)
	text("2 €", Rect2(1623, 690, 162, 51), 40, CREAM, HORIZONTAL_ALIGNMENT_RIGHT)

	text("MEJORA APLICADA" if state == "purchased" else "PRÓXIMA MEJORA", Rect2(885, 801, 444, 36), 24, MUTED)
	text("+1 €" if state == "purchased" else "50 €", Rect2(885, 840, 396, 78), 60, GOLD)
	var file: String = "button_primary_disabled.png" if state == "unaffordable" else "button_primary_normal.png"
	panel(file, Rect2(1365, 819, 420, 105), stage, 24)
	if state == "unaffordable":
		text("FALTAN 38 €", Rect2(1392, 837, 366, 57), 30, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	elif state == "purchased":
		sprite("icon_check.png", Rect2(1404, 852, 36, 36), INK / MINT)
		text("MEJORADA", Rect2(1455, 831, 303, 75), 40, INK, HORIZONTAL_ALIGNMENT_CENTER)
	else:
		text("MEJORAR", Rect2(1395, 831, 312, 75), 40, INK, HORIZONTAL_ALIGNMENT_CENTER)
		sprite("icon_arrow.png", Rect2(1725, 858, 24, 24), INK)
	text("LA MEJORA SE APLICA A CADA TOQUE.", Rect2(855, 936, 966, 30), 24, MUTED)

func atlas() -> void:
	rect(Rect2(0, 0, 1920, 1080), INK)
	text("TIENDA / SPRITES", Rect2(72, 45, 1776, 90), 60)
	text("MISMA PALETA. MISMO PÍXEL. LISTOS PARA GODOT.", Rect2(72, 141, 1776, 45), 30, MUTED)
	panel("panel_frame.png", Rect2(72, 234, 510, 456))
	text("ACCESO A TIENDA", Rect2(108, 258, 438, 48), 30, MUTED)
	sprite("icon_shop.png", Rect2(198, 330, 252, 252))
	text("SILUETA / 24 X 24", Rect2(108, 618, 438, 36), 24, MINT, HORIZONTAL_ALIGNMENT_CENTER)
	panel("panel_frame.png", Rect2(621, 234, 1227, 456))
	panel("item_slot.png", Rect2(663, 276, 351, 354))
	sprite("pick_upgrade.png", Rect2(678, 291, 321, 324))
	text("PÚA DE ENSAYO", Rect2(1080, 294, 696, 84), 50)
	text("OBJETO / MEJORA 01", Rect2(1080, 384, 696, 48), 30, MUTED)
	text("ÁMBAR + CREMA\nBORDE OSCURO\nPNG TRANSPARENTE", Rect2(1080, 480, 696, 126), 30, GOLD)
	var variants: Array[String] = ["normal", "hover", "pressed", "disabled"]
	var names: Array[String] = ["NORMAL", "ACTIVO", "PULSADO", "SIN SALDO"]
	for i: int in 4:
		var x: int = 72 + i * 453
		text(names[i], Rect2(x, 747, 417, 45), 30, MUTED)
		panel("button_primary_%s.png" % variants[i], Rect2(x, 819, 417, 102), stage, 24)
		text("MEJORAR", Rect2(x + 24, 831, 369, 75), 40, MUTED if i == 3 else INK, HORIZONTAL_ALIGNMENT_CENTER)
	text("TEXTOS Y PRECIOS SE DIBUJAN EN EL MOTOR.", Rect2(72, 990, 1776, 36), 24, MUTED)

func save_shot(file: String) -> void:
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	var error: Error = root.get_texture().get_image().save_png(OUT + file)
	assert(error == OK, "Could not save design preview: " + file)
	print("Saved ", file)

func _render_all() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1920, 1080)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	reset_stage()
	background()
	shop_access()
	await save_shot("preview-shop-access.png")
	for state: String in ["available", "unaffordable", "purchased"]:
		reset_stage()
		shop(state)
		await save_shot("preview-shop-%s.png" % state)
	reset_stage()
	atlas()
	await save_shot("preview-sprites.png")
	stage.queue_free()
	await process_frame
	quit()
