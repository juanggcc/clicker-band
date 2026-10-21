extends Node2D
## Wires the pure logic (tap speed, tiers, tempo bonus, economy, zones, recruiting) to
## the music, the puppets, the HUD and the menus.

## At 120 BPM: once a second (half notes), eighth notes, sixteenth notes.
const STRUMS_PER_BEAT: Array[float] = [0.5, 2.0, 4.0]
const INTENSITY: Array[float] = [0.3, 0.65, 1.0]
const SETTINGS_PATH: String = "user://settings.cfg"
## TEMPORARY, for playtesting: start rich and have Ren and Cham turn up within a few dozen
## taps in the park and the garage, without loading or saving progress. Set PLAYTEST to
## false before exporting a build for friends.
const PLAYTEST: bool = true
const PLAYTEST_MONEY: int = 1000000
const PLAYTEST_RECRUIT_CHANCE: float = 1.0 / 20.0
const PLAYTEST_RECRUIT_GUARANTEE: int = 60
## Where the bought pedal sits on the floor, from the protagonist's feet: just right of
## his trainers.
const PEDAL_OFFSET: Vector2 = Vector2(255, 10)
## Money changes on every tap, so it is saved on a timer as well as on every purchase,
## move and when the app leaves the foreground.
const AUTOSAVE_SEC: float = 10.0
## Purchases closer together than this count as a streak: each one chimes a semitone
## higher, up to BUY_STREAK_MAX semitones.
const BUY_STREAK_MSEC: int = 450
const BUY_STREAK_MAX: int = 7
## Bandmate ids, as in band/members/.
const REN: StringName = &"ren"
const CHAM: StringName = &"cham"

## Map order; the first zone is where the band starts.
@export var zones: Array[Zone] = []
## Shop order.
@export var shop_items: Array[ShopItem] = []
## Where progress is kept; tests point this at their own file.
@export var save_path: String = "user://save.cfg"

@onready var _music: MusicPlayer = $MusicPlayer
@onready var _buy_sound: AudioStreamPlayer = $BuySound
@onready var _background: Sprite2D = $World/Background
@onready var _protagonist: Protagonist = $World/Protagonist
@onready var _ren: Protagonist = $World/Ren
@onready var _cham: DrummerV2 = $World/Cham
@onready var _pedal: Node2D = $World/Pedal
@onready var _hud: HUD = $HUD
@onready var _shop: ShopMenu = $ShopMenu
@onready var _options: OptionsMenu = $OptionsMenu
@onready var _calibration: CalibrationMenu = $CalibrationMenu
@onready var _main_menu: MainMenu = $MainMenu
@onready var _map: MapMenu = $MapMenu
@onready var _join: JoinDialog = $JoinDialog
@onready var _fade: TravelFade = $TravelFade

var _tracker: TapTracker = TapTracker.new()
var _tiers: TempoTiers = TempoTiers.new()
var _bonus: TempoBonus = TempoBonus.new(MusicPlayer.BPM)
var _economy: Economy
var _world: WorldMap
var _recruits: Dictionary[StringName, BandRecruit] = {REN: BandRecruit.new(), CHAM: BandRecruit.new()}
var _save: SaveGame
var _buy_streak: int = 0
var _last_buy_msec: int = -100000
var _clock: float = 0.0


func _ready() -> void:
	_economy = Economy.new(shop_items)
	_world = WorldMap.new(zones[0].id)
	_save = SaveGame.new(save_path)
	if PLAYTEST:
		_economy.money = PLAYTEST_MONEY
		for id: StringName in _recruits:
			_recruits[id] = BandRecruit.new(PLAYTEST_RECRUIT_CHANCE, PLAYTEST_RECRUIT_GUARANTEE)
	else:
		_save.read(_economy, _world, _recruits, _zone_ids())
	_hud.tapped.connect(_on_tapped)
	_hud.menu_pressed.connect(_open_menu)
	_main_menu.shop_pressed.connect(_open_shop)
	_main_menu.map_pressed.connect(_open_map)
	_map.buy_pressed.connect(_on_zone_bought)
	_map.travel_pressed.connect(_travel_to)
	_join.accepted.connect(_on_bandmate_joined)
	_hud.options_pressed.connect(_options.open)
	_shop.buy_pressed.connect(_on_item_pressed)
	_options.calibrate_pressed.connect(_open_calibration)
	_options.reset_pressed.connect(_reset_progress)
	_options.quit_pressed.connect(_quit)
	_calibration.music = _music
	_calibration.saved.connect(_on_calibration_saved)
	_calibration.closed.connect(_close_calibration)
	_bonus.tap_offset = _load_tap_offset()
	_hud.show_thresholds(_tiers.mid_rate, _tiers.fast_rate)
	_show_zone(_current_zone())
	_show_band()
	_show_gear()
	_show_wallet()
	var autosave: Timer = Timer.new()
	autosave.wait_time = AUTOSAVE_SEC
	autosave.timeout.connect(_save_progress)
	add_child(autosave)
	autosave.start()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_CLOSE_REQUEST:
			_save_progress()
		NOTIFICATION_WM_GO_BACK_REQUEST:
			_on_back()


func _process(delta: float) -> void:
	_clock += delta
	var rate: float = _tracker.taps_per_second(_clock)
	var tier: TempoTiers.Tier = _tiers.update(rate)
	_bonus.update(_clock, delta, tier)
	_music.set_tier(tier)
	_protagonist.intensity = INTENSITY[tier]
	_protagonist.animate(_music.beats(), STRUMS_PER_BEAT[tier])
	if _ren.visible:
		_ren.intensity = INTENSITY[tier]
		_ren.animate(_music.beats(), STRUMS_PER_BEAT[tier])
	if _cham.visible:
		_cham.intensity = INTENSITY[tier]
		_cham.animate(_music.beats())
	_hud.show_tempo(tier, rate)
	_hud.show_bonus(_bonus.charge, _bonus.active, _bonus.multiplier(tier))
	_hud.show_beat(_music.beats())


func _on_tapped(at: Vector2) -> void:
	if _modal_open():
		return
	_tracker.register_tap(_clock)
	var rate: float = _tracker.taps_per_second(_clock)
	var tier: TempoTiers.Tier = _tiers.update(rate)
	_bonus.on_tap(_music.beats(), _clock, tier)
	var earned: int = _economy.earn_from_tap(_bonus.multiplier(tier) * _band_size())
	_hud.show_tempo(tier, rate)
	_hud.show_bonus(_bonus.charge, _bonus.active, _bonus.multiplier(tier))
	_show_wallet()
	_hud.spawn_floating(earned, at)
	_protagonist.on_tap()
	var newcomer: Bandmate = _current_zone().recruit
	if newcomer != null and _recruits[newcomer.id].roll(randf()):
		_join.ask(newcomer, _band_size() + 1)


func _modal_open() -> bool:
	return (
		_shop.visible or _options.visible or _main_menu.visible or _map.visible
		or _join.visible or _fade.visible
	)


## Every musician on stage multiplies what a tap earns.
func _band_size() -> int:
	var size: int = 1
	for recruit: BandRecruit in _recruits.values():
		if recruit.joined:
			size += 1
	return size


func _open_menu() -> void:
	_main_menu.show_available(_can_buy_an_item(), _can_buy_a_zone())
	_main_menu.show()


func _open_map() -> void:
	_map.show_zones(zones, _world, _economy)
	_map.show()


func _on_zone_bought(zone: Zone) -> void:
	if not _economy.meets(zone.requires_item, zone.requires_level):
		return
	if not _world.buy(zone.id, zone.price, _economy):
		return
	_play_buy_sound()
	_show_wallet()
	_travel_to(zone)


func _travel_to(zone: Zone) -> void:
	if not _world.travel(zone.id):
		return
	_save_progress()
	_map.hide()
	_fade.play(zone.title.to_upper(), _show_zone.bind(zone))


func _show_zone(zone: Zone) -> void:
	_background.texture = zone.background
	_protagonist.position = zone.protagonist_position
	_pedal.position = zone.protagonist_position + PEDAL_OFFSET
	_ren.position = zone.bassist_position
	_cham.position = zone.drummer_position
	_hud.show_place(zone)


func _current_zone() -> Zone:
	for zone: Zone in zones:
		if zone.id == _world.current:
			return zone
	return zones[0]


func _can_buy_a_zone() -> bool:
	for zone: Zone in zones:
		if (
			zone.is_built() and not _world.owns(zone.id) and _economy.money >= zone.price
			and _economy.meets(zone.requires_item, zone.requires_level)
		):
			return true
	return false


func _can_buy_an_item() -> bool:
	for item: ShopItem in shop_items:
		if _economy.can_buy(item):
			return true
	return false


func _on_bandmate_joined(bandmate: Bandmate) -> void:
	_recruits[bandmate.id].join()
	_show_band()
	_save_progress()


## Who has joined plays, and is heard, in every zone.
func _show_band() -> void:
	_ren.visible = _recruits[REN].joined
	_cham.visible = _recruits[CHAM].joined
	_music.set_band(_ren.visible, _cham.visible)


func _open_shop() -> void:
	_shop.show_items(_economy)
	_shop.open()


func _on_item_pressed(item: ShopItem) -> void:
	if not _economy.buy(item):
		return
	_play_buy_sound()
	_save_progress()
	_show_wallet()
	_show_gear()
	_shop.show_items(_economy)


func _play_buy_sound() -> void:
	var now: int = Time.get_ticks_msec()
	_buy_streak = _buy_streak + 1 if now - _last_buy_msec < BUY_STREAK_MSEC else 0
	_last_buy_msec = now
	_buy_sound.pitch_scale = pow(2.0, mini(_buy_streak, BUY_STREAK_MAX) / 12.0)
	_buy_sound.play()


## Gear the band owns shows up on stage.
func _show_gear() -> void:
	_pedal.visible = _economy.level(&"pedal") > 0


func _show_wallet() -> void:
	_hud.show_money(_economy.money)
	_hud.show_menu_available(_can_buy_an_item() or _can_buy_a_zone())


## The game stays paused behind the calibration; only the music plays, on loop 1, whose
## steady pulse is what the player taps along to.
func _open_calibration() -> void:
	_options.hide()
	_music.process_mode = Node.PROCESS_MODE_ALWAYS
	_music.set_tier(TempoTiers.Tier.SLOW)
	_calibration.open()


func _close_calibration() -> void:
	_music.process_mode = Node.PROCESS_MODE_INHERIT
	_options.open()


func _on_calibration_saved(offset: float) -> void:
	_bonus.tap_offset = offset
	var settings: ConfigFile = ConfigFile.new()
	settings.load(SETTINGS_PATH)
	settings.set_value("rhythm", "tap_offset_sec", offset)
	if settings.save(SETTINGS_PATH) != OK:
		push_error("Could not save the tap offset to " + SETTINGS_PATH)


## What the player's last calibration measured; 0 until they run one.
func _load_tap_offset() -> float:
	var settings: ConfigFile = ConfigFile.new()
	settings.load(SETTINGS_PATH)
	return settings.get_value("rhythm", "tap_offset_sec", 0.0)


func _zone_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for zone: Zone in zones:
		ids.append(zone.id)
	return ids


func _save_progress() -> void:
	if PLAYTEST or _save == null:
		return
	var error: Error = _save.write(_economy, _world, _recruits)
	if error != OK:
		push_error("Could not save progress to %s: %s" % [_save.path, error_string(error)])


func _quit() -> void:
	_save_progress()
	get_tree().quit()


## Wipes the saved progress and starts over; the rhythm calibration is kept.
func _reset_progress() -> void:
	_save.erase()
	get_tree().paused = false
	get_tree().reload_current_scene()


## Android's back gesture closes whatever menu is open, or opens the pause menu. Dialogs
## that need an answer, the calibration and a zone move ignore it.
func _on_back() -> void:
	if _join.visible or _fade.visible or _calibration.visible:
		return
	if _options.visible:
		_options.close()
	elif _shop.visible:
		_shop.close()
	elif _main_menu.visible or _map.visible:
		_main_menu.hide()
		_map.hide()
	else:
		_options.open()
