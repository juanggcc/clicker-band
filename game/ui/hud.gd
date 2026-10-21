class_name HUD
extends CanvasLayer
## Screen-anchored interface. Controls use anchors, so they stick to the corners
## whatever the phone's aspect ratio. Pixel lettering and an amplifier-style meter
## share a small theme; decoration is procedural and never consumes taps.

## Any touch the GUI does not consume, one per finger. Decorative controls must use
## MOUSE_FILTER_IGNORE or they swallow the touches that land on them.
signal tapped(at: Vector2)
signal options_pressed
signal menu_pressed

const TIER_NAMES: Array[String] = ["INDIE", "ROCK", "PUNK"]
const PIXEL_THEME: Theme = preload("res://ui/pixel_theme.tres")
const PIXEL_ICON: GDScript = preload("res://ui/pixel_icon.gd")
const TIER_COLORS: Array[Color] = [Color("8ed8b1"), Color("f4ca78"), Color("f28f76")]
const FLOATING_SIZE: Vector2 = Vector2(36, 36)
## Metronome LED flashes per beat: 2 lights every eighth note, 1 only the beats.
const METRONOME_PER_BEAT: int = 2
## Share of each flash interval the LED stays lit (75 ms of an eighth at 120 BPM).
const METRONOME_ON: float = 0.3
const BONUS_GOLD: Color = Color("f4ca78")
const BONUS_IDLE: Color = Color("a8b4b8")

@onready var _money: Label = %Money
@onready var _tier: Label = %Tier
@onready var _rate: Label = %Rate
@onready var _progress: Range = %Progress
@onready var _loop: Label = %Loop
@onready var _tempo_panel: PanelContainer = %TempoPanel
@onready var _options_button: Button = %OptionsButton
@onready var _home_button: Button = %HomeButton
@onready var _home_available: ColorRect = %HomeAvailable
@onready var _place_icon: Control = %PlaceIcon
@onready var _place_eyebrow: Label = %PlaceEyebrow
@onready var _place_title: Label = %PlaceTitle
@onready var _bonus_bar: Range = %BonusBar
@onready var _metronome: Control = %Metronome
@onready var _bonus_label: Label = %BonusLabel

var _shown_tier: int = -1
var _shown_money: int = -1
var _shown_rate: String = ""
var _shown_bonus: String = ""


func _ready() -> void:
	_options_button.pressed.connect(options_pressed.emit)
	_home_button.pressed.connect(menu_pressed.emit)
	show_tempo(TempoTiers.Tier.SLOW, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	var touch: InputEventScreenTouch = event as InputEventScreenTouch
	if touch != null and touch.pressed:
		if (
			_options_button.get_global_rect().has_point(touch.position)
			or _home_button.get_global_rect().has_point(touch.position)
		):
			return
		tapped.emit(touch.position)


func show_money(money: int) -> void:
	if money == _shown_money:
		return
	_shown_money = money
	_money.text = format_money(money) + " €"


## Lights the menu button when something in it can be bought right now.
func show_menu_available(available: bool) -> void:
	_home_available.visible = available


## The zone's caption and name in the top-left panel; zones without their own icon keep
## the procedural house.
func show_place(zone: Zone) -> void:
	_place_eyebrow.text = zone.eyebrow
	_place_title.text = zone.title
	_place_icon.set("texture", zone.place_icon)


## Keep a growing balance inside its corner without changing the economy's value.
static func format_money(money: int) -> String:
	if money < 1000:
		return str(money)
	if money < 1000000:
		return "%d %03d" % [money / 1000, money % 1000]
	var divisor: float = 1000000.0
	var suffix: String = "M"
	if money >= 1000000000:
		divisor = 1000000000.0
		suffix = "mil M"
	return ("%.1f" % (floorf(money / divisor * 10.0) / 10.0)).replace(".", ",") + " " + suffix


## Speeds in taps per second at which the meter turns to the next loop's colour.
func show_thresholds(mid_rate: float, fast_rate: float) -> void:
	_progress.set("mid_rate", mid_rate)
	_progress.set("fast_rate", fast_rate)


func show_tempo(tier: TempoTiers.Tier, rate: float) -> void:
	if tier != _shown_tier:
		_shown_tier = tier
		_tier.text = TIER_NAMES[tier]
		_tier.add_theme_color_override("font_color", TIER_COLORS[tier])
		_loop.text = "LVL %d" % (tier + 1)
		_loop.add_theme_color_override("font_color", TIER_COLORS[tier])
		_tempo_panel.set("accent", TIER_COLORS[tier])
	var rate_text: String = ("%.1f taps/s" % rate).replace(".", ",")
	if rate_text != _shown_rate:
		_shown_rate = rate_text
		_rate.text = rate_text
	_progress.value = rate


## Lights the metronome LED at the start of every flash interval and keeps it dark the
## rest of the time; every flash is identical. beats is the music clock.
func show_beat(beats: float) -> void:
	var steps: float = beats * METRONOME_PER_BEAT
	_metronome.set("lit", steps - floorf(steps) < METRONOME_ON)


## charge fills the tempo bar; while active it turns gold and shows the multiplier,
## which is x1 in the loop without a grid.
func show_bonus(charge: float, active: bool, multiplier: int) -> void:
	_bonus_bar.value = charge
	var text: String = "x%d" % multiplier if active else "A TEMPO"
	if text == _shown_bonus:
		return
	_shown_bonus = text
	_bonus_bar.set("active", active)
	_bonus_label.text = text
	_bonus_label.add_theme_color_override("font_color", BONUS_GOLD if active else BONUS_IDLE)
	_bonus_label.add_theme_font_size_override("font_size", 30 if active else 24)


func spawn_floating(earned: int, at: Vector2) -> void:
	var label: Label = Label.new()
	label.text = "+%d" % earned
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 60)
	label.add_theme_color_override("font_color", TIER_COLORS[maxi(_shown_tier, 0)])
	label.add_theme_color_override("font_shadow_color", Color("111923"))
	label.add_theme_constant_override("shadow_offset_x", 3)
	var note: Control = Control.new()
	note.set_script(PIXEL_ICON)
	note.set("kind", 2)
	note.set("color", TIER_COLORS[maxi(_shown_tier, 0)])
	note.custom_minimum_size = FLOATING_SIZE
	note.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row: HBoxContainer = HBoxContainer.new()
	row.theme = PIXEL_THEME
	row.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(note)
	row.add_child(label)
	add_child(row)
	var bounds: Vector2 = get_viewport().get_visible_rect().size
	var row_size: Vector2 = row.get_combined_minimum_size()
	row.position = Vector2(
		clampf(at.x - row_size.x / 2.0, 12.0, bounds.x - row_size.x - 12.0),
		clampf(at.y - row_size.y, 12.0, bounds.y - row_size.y - 12.0)
	).round()
	var tween: Tween = create_tween().set_parallel(true)
	var rise: PropertyTweener = tween.tween_property(
		row, "position:y", maxf(12.0, row.position.y - 120.0), 0.7
	)
	rise.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(row, "modulate:a", 0.0, 0.7).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(row.queue_free)
