extends SceneTree
## Integration checks for the real HUD, shop and economy, including touch isolation.
## Godot --headless --path game --log-file /tmp/clicker-ui-tests.log -s res://tests/run_ui_tests.gd
## Omit --headless and append -- --capture to save real game screenshots as well.

var _checks: int = 0
var _failures: int = 0
var _capture: bool = "--capture" in OS.get_cmdline_user_args()
const SAVE_PATH: String = "user://ui_test_save.cfg"
const SETTINGS_PATH: String = "user://ui_test_settings.cfg"


func _initialize() -> void:
	call_deferred("_run")


func check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("FAIL: " + message)


func settle() -> void:
	await process_frame
	await process_frame


func touch(at: Vector2, pressed: bool) -> void:
	var event: InputEventScreenTouch = InputEventScreenTouch.new()
	event.position = at
	event.pressed = pressed
	event.index = 0
	root.push_input(event, true)


func click(at: Vector2) -> void:
	# Deliver both native touch and mouse-compatible events, as on touch devices.
	touch(at, true)
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = at
	root.push_input(motion, true)
	for pressed: bool in [true, false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.position = at
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.pressed = pressed
		root.push_input(event, true)
	touch(at, false)
	await settle()


func capture(name: String) -> void:
	if not _capture:
		return
	await settle()
	RenderingServer.force_draw()
	var destination: String = "res://../docs/art/2026-10-21-shop/integrated-%s.png" % name
	check(root.get_texture().get_image().save_png(destination) == OK, "save " + name)


func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1920, 1080)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	SaveGame.new(SAVE_PATH).erase()
	var settings: ConfigFile = ConfigFile.new()
	settings.set_value("audio", "volume", 0.5)
	settings.save(SETTINGS_PATH)
	var game: Node = load("res://main/main.tscn").instantiate()
	# Never load or overwrite the player's own progress or settings.
	game.set("save_path", SAVE_PATH)
	game.set("settings_path", SETTINGS_PATH)
	root.add_child(game)
	# Keep tap times deterministic; timers and controls still process normally.
	game.set_process(false)
	(game.get_node("MusicPlayer") as AudioStreamPlayer).stop()
	var hud: HUD = game.get_node("HUD") as HUD
	var shop: ShopMenu = game.get_node("ShopMenu") as ShopMenu
	var options: OptionsMenu = game.get_node("OptionsMenu") as OptionsMenu
	var economy: Economy = game.get("_economy") as Economy
	# Start from an empty wallet whatever the playtest settings in main.gd.
	economy.money = 0
	game.call("_show_wallet")
	await settle()
	var menu: MainMenu = game.get_node("MainMenu") as MainMenu
	var access: Button = hud.get_node("%HomeButton") as Button
	var shop_tile: Button = menu.get_node("%ShopTile") as Button
	var close_button: Button = shop.get_node("%CloseButton") as Button
	var dot: ColorRect = hud.get_node("%HomeAvailable") as ColorRect
	check(not shop.visible and not options.visible and not menu.visible, "menus start closed")
	check(not dot.visible, "no affordability dot at zero balance")
	touch(Vector2(960, 540), true)
	touch(Vector2(960, 540), false)
	check(economy.money == 1, "playing still earns money")
	await click(access.get_global_rect().get_center())
	check(menu.visible and economy.money == 1, "the house opens the general menu without earning a tap")
	await click(shop_tile.get_global_rect().get_center())
	check(shop.visible and not menu.visible, "TIENDA opens the real shop")
	var rows: VBoxContainer = shop.get_node("%Rows") as VBoxContainer
	check(rows.get_child_count() == 2, "the shop lists the pick and the pedal")
	var pick_row: ShopRow = rows.get_child(0) as ShopRow
	var pedal_row: ShopRow = rows.get_child(1) as ShopRow
	var buy: Button = pick_row.get_node("%BuyButton") as Button
	var pedal_buy: Button = pedal_row.get_node("%BuyButton") as Button
	check(buy.disabled and buy.text == "FALTAN 24 €", "insufficient balance uses the real cost")
	check(pedal_buy.disabled and pedal_buy.text == "PÚA NV 10", "the pedal shows what unlocks it")
	await capture("shop-empty")
	await click(buy.get_global_rect().get_center())
	check(economy.money == 1 and economy.level(&"pick") == 0, "disabled purchase changes nothing")
	touch(Vector2(960, 540), true)
	touch(Vector2(960, 540), false)
	check(economy.money == 1, "touching the item never plays the game")
	await click(Vector2(300, 450))
	check(not shop.visible and economy.money == 1, "backdrop closes without earning money")

	economy.money = 63
	game.call("_show_wallet")
	check(dot.visible, "affordability indicator updates with the balance")
	await capture("hud")
	await click(access.get_global_rect().get_center())
	await click(shop_tile.get_global_rect().get_center())
	check(not buy.disabled and buy.text == "25 €", "an affordable level shows its price")
	check((shop.get_node("%Balance") as Label).text == "63 €", "shop displays the actual balance")
	await capture("shop")
	await click(buy.get_global_rect().get_center())
	check(economy.money == 38 and economy.level(&"pick") == 1, "purchase pays the price exactly once")
	check(buy.text == "38 €" and not buy.disabled, "the button shows the next price straight away")
	check((hud.get_node("%Money") as Label).text == "38 €", "HUD balance follows the purchase")
	check((pick_row.get_node("%Level") as Label).text == "NIVEL 1", "the row shows the new level")
	await capture("shop-purchased")
	await click(buy.get_global_rect().get_center())
	check(economy.money == 0 and economy.level(&"pick") == 2, "a quick second press buys the next level at 1.5 times the price")
	check(not dot.visible, "affordability dot clears when the balance is spent")
	check(buy.disabled and buy.text == "FALTAN 56 €", "with the money spent the next level is disabled")
	await click(buy.get_global_rect().get_center())
	check(economy.money == 0 and economy.level(&"pick") == 2, "a press without money buys nothing")
	await click(close_button.get_global_rect().get_center())
	check(not shop.visible and economy.money == 0, "close button consumes its touch")
	touch(Vector2(960, 540), true)
	touch(Vector2(960, 540), false)
	check(economy.money == 3, "playing after the shop uses the improved gain")

	economy.money = 1000000
	for i: int in 8:
		economy.buy(economy.find(&"pick"))
	game.call("_open_shop")
	await settle()
	check(not pedal_buy.disabled and pedal_buy.text == "1 200 €", "pick level 10 unlocks the pedal at its price")
	shop.close()
	economy.money = 3

	await click(access.get_global_rect().get_center())
	await click(shop_tile.get_global_rect().get_center())
	var escape: InputEventKey = InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	root.push_input(escape, true)
	check(not shop.visible and economy.money == 3, "Escape closes the shop without changing money")

	await click((hud.get_node("%OptionsButton") as Button).get_global_rect().get_center())
	check(options.visible and paused, "existing pause menu remains functional")

	var fader: PixelFader = options.get_node("%VolumeFader") as PixelFader
	check(fader.value == 50.0 and is_equal_approx(AudioServer.get_bus_volume_db(0), linear_to_db(0.5)), "the saved volume is loaded at start")
	var slot: Rect2 = fader.get_global_rect()
	var travel: float = slot.size.x - PixelFader.CAP.x
	await click(Vector2(slot.position.x + PixelFader.CAP.x / 2.0 + travel * 0.75, slot.get_center().y))
	check(absf(AudioServer.get_bus_volume_db(0) - linear_to_db(0.75)) < 0.2 and not AudioServer.is_bus_mute(0), "the fader sets the Master volume where it is touched")
	settings.load(SETTINGS_PATH)
	check(is_equal_approx(settings.get_value("audio", "volume", 0.0), 0.75), "the volume is saved once the fader is let go")
	await click(Vector2(slot.position.x + 3.0, slot.get_center().y))
	check(fader.value == 0.0 and AudioServer.is_bus_mute(0), "all the way down mutes the game")
	await click(Vector2(slot.end.x - 3.0, slot.get_center().y))
	check(fader.value == 100.0 and not AudioServer.is_bus_mute(0), "back up, it sounds again")
	await capture("pause-volume")

	var music: MusicPlayer = game.get_node("MusicPlayer") as MusicPlayer
	var calibration: CalibrationMenu = game.get_node("CalibrationMenu") as CalibrationMenu
	var count: Label = calibration.get_node("%Count") as Label
	var result_buttons: Control = calibration.get_node("%ResultButtons") as Control
	await click((options.get_node("%CalibrateButton") as Button).get_global_rect().get_center())
	check(calibration.visible and not options.visible and paused, "calibration opens over the paused game")
	check(music.can_process(), "only the music keeps playing during calibration")
	check(count.text == "24" and not result_buttons.visible, "calibration asks for 24 taps")
	for i: int in 3:
		touch(Vector2(960, 540), true)
		touch(Vector2(960, 540), false)
	check(count.text == "21" and economy.money == 3, "calibration taps count down and never earn money")
	await click((calibration.get_node("%CancelButton") as Button).get_global_rect().get_center())
	check(count.text == "21", "pressing a calibration button is not a beat")
	check(not calibration.visible and options.visible and paused, "cancelling returns to the pause menu")
	check(not music.can_process(), "the music pauses again with the menu")
	await click((options.get_node("%CalibrateButton") as Button).get_global_rect().get_center())
	check(count.text == "24", "reopening starts a new calibration")
	for i: int in 24:
		touch(Vector2(960, 540), true)
		touch(Vector2(960, 540), false)
	check(result_buttons.visible and count.text.ends_with(" MS"), "the last tap shows the measured offset")
	await settle()
	await click((calibration.get_node("%RepeatButton") as Button).get_global_rect().get_center())
	check(count.text == "24" and not result_buttons.visible, "repeating starts over")
	await click((calibration.get_node("%CancelButton") as Button).get_global_rect().get_center())
	await click((options.get_node("%ResumeButton") as Button).get_global_rect().get_center())
	check(not options.visible and not paused and economy.money == 3, "resuming preserves money")

	for dimensions: Vector2i in [Vector2i(1680, 720), Vector2i(1024, 768), Vector2i(854, 480)]:
		root.size = dimensions
		game.call("_open_shop")
		await settle()
		var panel: Control = shop.get_node("Margin/Panel") as Control
		check(root.get_visible_rect().encloses(panel.get_global_rect()), "shop fits %s" % dimensions)
		check(panel.get_global_rect().encloses(pedal_buy.get_global_rect()), "the last purchase button stays inside the panel at %s" % dimensions)
		if dimensions == Vector2i(854, 480):
			await capture("shop-phone")
		shop.close()
	game.queue_free()
	await settle()
	SaveGame.new(SAVE_PATH).erase()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))
	print("UI integration: %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)
