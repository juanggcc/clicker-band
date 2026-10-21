extends SceneTree
## Dependency-free test runner for the pure logic in core/.
## From the repo root:
##	 /Applications/Godot.app/Contents/MacOS/Godot --headless --path game -s res://tests/run_tests.gd

var _checks: int = 0
var _failures: int = 0


func _init() -> void:
	test_tap_tracker_reads_speed_from_recent_intervals()
	test_tap_tracker_slows_down_before_the_next_tap()
	test_tap_tracker_counts_simultaneous_taps_once()
	test_tiers_follow_speed_in_both_directions()
	test_tiers_leave_a_loop_only_below_its_margin()
	test_bonus_eighths_in_time_fill_the_bar_and_turn_the_multiplier_on()
	test_bonus_judges_taps_within_a_quarter_of_the_note_gap()
	test_bonus_drains_after_a_miss_until_the_next_tap_in_time()
	test_bonus_skipped_notes_drain_and_an_empty_bar_ends_the_multiplier()
	test_bonus_slow_has_no_grid()
	test_calibration_skips_the_warmup_and_reads_taps_before_the_beat_as_early()
	test_calibration_takes_the_median_so_stray_taps_do_not_move_it()
	test_calibration_counts_down_and_ignores_taps_once_done()
	test_economy_each_item_level_adds_its_gain_per_tap_times_the_multiplier()
	test_economy_buys_levels_only_when_affordable()
	test_economy_locks_an_item_until_its_requirement_level()
	test_world_map_buys_each_zone_once_with_money()
	test_world_map_travels_only_to_owned_zones()
	test_recruit_turns_up_by_chance_or_by_the_guarantee()
	test_recruit_stops_rolling_once_joined()
	test_save_round_trip_restores_progress()
	test_save_missing_file_leaves_a_new_game()
	test_save_drops_zones_that_no_longer_exist()
	test_save_from_version_1_keeps_ren_in_the_band()
	print("%d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("FAIL: " + message)


func test_tap_tracker_reads_speed_from_recent_intervals() -> void:
	var tracker: TapTracker = TapTracker.new(1.0)
	tracker.register_tap(0.0)
	check(is_equal_approx(tracker.taps_per_second(0.0), 0.0), "one tap has no speed yet")
	tracker.register_tap(0.25)
	tracker.register_tap(0.5)
	check(is_equal_approx(tracker.taps_per_second(0.5), 4.0), "taps every 0.25 s read 4 taps/s")
	check(is_equal_approx(tracker.taps_per_second(0.6), 4.0), "the speed holds until the next tap is due")
	tracker.register_tap(0.625)
	tracker.register_tap(0.75)
	check(is_equal_approx(tracker.taps_per_second(0.75), 8.0), "two faster taps read the new speed")


func test_tap_tracker_slows_down_before_the_next_tap() -> void:
	var tracker: TapTracker = TapTracker.new(1.0)
	for i: int in 3:
		tracker.register_tap(0.25 * i)
	check(is_equal_approx(tracker.taps_per_second(1.0), 2.0), "a 0.5 s wait reads 2 taps/s")
	check(is_equal_approx(tracker.taps_per_second(1.6), 0.0), "taps older than forget_sec are dropped")


func test_tap_tracker_counts_simultaneous_taps_once() -> void:
	var tracker: TapTracker = TapTracker.new(1.0)
	tracker.register_tap(0.0)
	tracker.register_tap(0.0)
	tracker.register_tap(0.25)
	tracker.register_tap(0.26)
	check(is_equal_approx(tracker.taps_per_second(0.26), 4.0), "two fingers landing together count once")


func test_tiers_follow_speed_in_both_directions() -> void:
	var tiers: TempoTiers = TempoTiers.new(3.0, 6.0, 0.5)
	check(tiers.update(2.9) == TempoTiers.Tier.SLOW, "below mid_rate is SLOW")
	check(tiers.update(3.0) == TempoTiers.Tier.MID, "mid_rate enters MID")
	check(tiers.update(6.0) == TempoTiers.Tier.FAST, "fast_rate enters FAST")
	check(tiers.update(1.0) == TempoTiers.Tier.SLOW, "slowing a lot drops straight to SLOW")
	check(tiers.update(7.0) == TempoTiers.Tier.FAST, "speeding up a lot jumps straight to FAST")


func test_tiers_leave_a_loop_only_below_its_margin() -> void:
	var tiers: TempoTiers = TempoTiers.new(3.0, 6.0, 0.5)
	tiers.update(6.0)
	check(tiers.update(5.6) == TempoTiers.Tier.FAST, "just under fast_rate keeps FAST")
	check(tiers.update(5.4) == TempoTiers.Tier.MID, "more than the margin under drops to MID")
	check(tiers.update(2.6) == TempoTiers.Tier.MID, "just under mid_rate keeps MID")
	check(tiers.update(2.4) == TempoTiers.Tier.SLOW, "more than the margin under drops to SLOW")


## Taps every eighth note for count notes from start_beat, as the game would at 120 BPM.
func play_eighths(bonus: TempoBonus, start_beat: float, count: int) -> float:
	var beats: float = start_beat
	for i: int in count:
		bonus.update(beats * 0.5, 0.25, TempoTiers.Tier.MID)
		bonus.on_tap(beats, beats * 0.5, TempoTiers.Tier.MID)
		beats += 0.5
	return beats - 0.5


func test_bonus_eighths_in_time_fill_the_bar_and_turn_the_multiplier_on() -> void:
	var bonus: TempoBonus = TempoBonus.new(120.0, 0.25, 8.0, 2.0)
	play_eighths(bonus, 0.0, 15)
	check(not bonus.active, "15 of the 16 eighths in two bars are not enough")
	play_eighths(bonus, 7.5, 1)
	check(bonus.active and is_equal_approx(bonus.charge, 1.0), "two bars of eighths fill the bar")
	check(bonus.multiplier(TempoTiers.Tier.MID) == 2, "x2 in MID")
	check(bonus.multiplier(TempoTiers.Tier.FAST) == 4, "x4 in FAST")
	check(bonus.multiplier(TempoTiers.Tier.SLOW) == 1, "nothing in SLOW")


func test_bonus_judges_taps_within_a_quarter_of_the_note_gap() -> void:
	var bonus: TempoBonus = TempoBonus.new(120.0, 0.25, 8.0, 2.0)
	bonus.on_tap(0.12, 0.06, TempoTiers.Tier.MID)
	check(is_equal_approx(bonus.charge, 1.0 / 16.0), "60 ms after an eighth is in time")
	bonus.on_tap(0.36, 0.18, TempoTiers.Tier.MID)
	check(is_equal_approx(bonus.charge, 1.0 / 16.0), "70 ms before the next eighth is not")
	bonus.on_tap(0.44, 0.22, TempoTiers.Tier.FAST)
	check(is_equal_approx(bonus.charge, 1.0 / 16.0 + 1.0 / 32.0), "30 ms off a sixteenth is in time in FAST")
	var late: TempoBonus = TempoBonus.new(120.0, 0.25, 8.0, 2.0, 0.08)
	late.on_tap(0.16, 0.08, TempoTiers.Tier.MID)
	check(late.charge > 0.0, "tap_offset is taken off before judging")


func test_bonus_drains_after_a_miss_until_the_next_tap_in_time() -> void:
	var bonus: TempoBonus = TempoBonus.new(120.0, 0.25, 8.0, 2.0)
	var beats: float = play_eighths(bonus, 0.0, 16)
	bonus.on_tap(beats + 0.25, (beats + 0.25) * 0.5, TempoTiers.Tier.MID)
	bonus.update((beats + 0.25) * 0.5 + 0.01, 1.0, TempoTiers.Tier.MID)
	check(is_equal_approx(bonus.charge, 0.5), "a tap between notes drains half the bar in one second")
	bonus.on_tap(beats + 1.0, (beats + 1.0) * 0.5, TempoTiers.Tier.MID)
	var charge: float = bonus.charge
	bonus.update((beats + 1.0) * 0.5 + 0.1, 0.1, TempoTiers.Tier.MID)
	check(is_equal_approx(bonus.charge, charge), "the next tap in time stops the drain")
	check(bonus.active, "the multiplier stays on while the bar is not empty")


func test_bonus_skipped_notes_drain_and_an_empty_bar_ends_the_multiplier() -> void:
	var bonus: TempoBonus = TempoBonus.new(120.0, 0.25, 8.0, 2.0)
	var beats: float = play_eighths(bonus, 0.0, 16)
	bonus.update(beats * 0.5 + 0.25, 0.25, TempoTiers.Tier.MID)
	check(is_equal_approx(bonus.charge, 1.0), "the next note's window is still open")
	bonus.update(beats * 0.5 + 0.35, 0.1, TempoTiers.Tier.MID)
	check(bonus.charge < 1.0, "once it closes without a tap the bar drains")
	bonus.update(beats * 0.5 + 3.0, 2.0, TempoTiers.Tier.MID)
	check(bonus.charge == 0.0 and not bonus.active, "an empty bar ends the multiplier")


func test_bonus_slow_has_no_grid() -> void:
	var bonus: TempoBonus = TempoBonus.new(120.0, 0.25, 8.0, 2.0)
	for i: int in 16:
		bonus.on_tap(float(i), i * 0.5, TempoTiers.Tier.SLOW)
	check(bonus.charge == 0.0, "taps on the beat in SLOW charge nothing")


## One tap per beat from beat 8, each landing offsets[i] beats off its beat.
func tap_beats(calibration: TapCalibration, offsets: Array[float]) -> void:
	for i: int in offsets.size():
		calibration.add_tap(8.0 + i + offsets[i])


func test_calibration_skips_the_warmup_and_reads_taps_before_the_beat_as_early() -> void:
	var calibration: TapCalibration = TapCalibration.new(120.0, 4, 20)
	var offsets: Array[float] = [0.3, 0.3, 0.3, 0.3]
	for i: int in 20:
		offsets.append(-0.09)
	tap_beats(calibration, offsets)
	check(is_equal_approx(calibration.offset_sec(), -0.045), "taps 0.09 beats early at 120 BPM are 45 ms early")


func test_calibration_takes_the_median_so_stray_taps_do_not_move_it() -> void:
	var odd: TapCalibration = TapCalibration.new(120.0, 0, 3)
	tap_beats(odd, [0.1, -0.4, 0.06])
	check(is_equal_approx(odd.offset_sec(), 0.03), "an odd count takes the middle tap")
	var even: TapCalibration = TapCalibration.new(120.0, 0, 4)
	tap_beats(even, [0.02, 0.4, -0.45, 0.04])
	check(is_equal_approx(even.offset_sec(), 0.015), "an even count averages the middle two")


func test_calibration_counts_down_and_ignores_taps_once_done() -> void:
	var calibration: TapCalibration = TapCalibration.new(120.0, 2, 3)
	check(calibration.remaining() == 5 and not calibration.is_done(), "warm-up and samples are both counted")
	tap_beats(calibration, [0.0, 0.0, 0.02, 0.02, 0.02])
	check(calibration.remaining() == 0 and calibration.is_done(), "the last sample finishes it")
	tap_beats(calibration, [0.4, 0.4, 0.4])
	check(calibration.remaining() == 0 and is_equal_approx(calibration.offset_sec(), 0.01), "later taps change nothing")


func make_item(id: StringName, base_cost: int, growth: float, gain: int, requires: StringName = &"", at_level: int = 0) -> ShopItem:
	var item: ShopItem = ShopItem.new()
	item.id = id
	item.base_cost = base_cost
	item.growth = growth
	item.gain = gain
	item.requires_item = requires
	item.requires_level = at_level
	return item


func test_economy_each_item_level_adds_its_gain_per_tap_times_the_multiplier() -> void:
	var pick: ShopItem = make_item(&"pick", 10, 1.5, 1)
	var pedal: ShopItem = make_item(&"pedal", 10, 1.5, 5)
	var economy: Economy = Economy.new([pick, pedal])
	check(economy.earn_from_tap(1) == 1, "a tap earns 1 with no gear")
	economy.money = 1000
	economy.buy(pick)
	economy.buy(pick)
	economy.buy(pedal)
	check(economy.per_tap() == 8, "1 + 2 pick levels + 5 for one pedal level")
	var before: int = economy.money
	check(economy.earn_from_tap(4) == 32, "the multiplier applies to the whole tap")
	check(economy.money == before + 32, "money accumulates")


func test_economy_buys_levels_only_when_affordable() -> void:
	var pick: ShopItem = make_item(&"pick", 10, 1.5, 1)
	var economy: Economy = Economy.new([pick])
	economy.money = 9
	check(not economy.buy(pick), "9 € cannot buy the 10 € first level")
	check(economy.money == 9 and economy.level(&"pick") == 0, "a failed purchase changes nothing")
	economy.money = 25
	check(economy.buy(pick), "25 € buys the first level")
	check(economy.money == 15 and economy.level(&"pick") == 1, "the price is paid and the level goes up")
	check(economy.cost(pick) == 15, "each level costs growth times the previous one")
	check(economy.buy(pick) and economy.money == 0, "exact money is enough")


func test_economy_locks_an_item_until_its_requirement_level() -> void:
	var pick: ShopItem = make_item(&"pick", 1, 1.0, 1)
	var pedal: ShopItem = make_item(&"pedal", 1, 1.0, 5, &"pick", 2)
	var economy: Economy = Economy.new([pick, pedal])
	economy.money = 100
	check(not economy.is_unlocked(pedal) and not economy.buy(pedal), "the pedal is locked without pick level 2")
	check(economy.money == 100, "a locked purchase spends nothing")
	economy.buy(pick)
	check(not economy.can_buy(pedal), "pick level 1 is not enough")
	economy.buy(pick)
	check(economy.can_buy(pedal) and economy.buy(pedal), "pick level 2 unlocks the pedal")


func test_world_map_buys_each_zone_once_with_money() -> void:
	var economy: Economy = Economy.new()
	var world: WorldMap = WorldMap.new(&"bedroom")
	check(world.owns(&"bedroom") and world.current == &"bedroom", "the starting zone is owned and current")
	economy.money = 999
	check(not world.buy(&"park", 1000, economy), "999 € cannot buy a 1000 € zone")
	check(economy.money == 999 and not world.owns(&"park"), "a failed purchase changes nothing")
	economy.money = 1500
	check(world.buy(&"park", 1000, economy) and world.owns(&"park"), "1500 € buys it")
	check(economy.money == 500, "the price is paid")
	check(not world.buy(&"park", 0, economy) and economy.money == 500, "an owned zone is not bought again")


func test_world_map_travels_only_to_owned_zones() -> void:
	var economy: Economy = Economy.new()
	var world: WorldMap = WorldMap.new(&"bedroom")
	check(not world.travel(&"park"), "cannot travel to a zone not owned")
	economy.money = 1000
	world.buy(&"park", 1000, economy)
	check(world.current == &"bedroom", "buying does not move the band by itself")
	check(world.travel(&"park") and world.current == &"park", "travel to an owned zone")
	check(not world.travel(&"park"), "travelling to where you are does nothing")
	check(world.travel(&"bedroom") and world.current == &"bedroom", "owned zones can be revisited")


func test_recruit_turns_up_by_chance_or_by_the_guarantee() -> void:
	var recruit: BandRecruit = BandRecruit.new(0.01, 5)
	check(not recruit.roll(0.5), "a roll above the chance does not bring them")
	check(recruit.roll(0.005), "a roll under the chance brings them")
	for i: int in 4:
		check(not recruit.roll(0.99), "unlucky taps before the guarantee: %d" % (i + 1))
	check(recruit.roll(0.99), "the fifth tap since they last turned up is certain")


func test_recruit_stops_rolling_once_joined() -> void:
	var recruit: BandRecruit = BandRecruit.new(1.0, 5)
	recruit.join()
	check(not recruit.roll(0.0), "a joined bandmate does not turn up again")


const TEST_SAVE: String = "user://test_save.cfg"
const ZONE_IDS: Array[StringName] = [&"bedroom", &"park"]


func new_state() -> Array:
	var pick: ShopItem = make_item(&"pick", 10, 1.5, 1)
	var pedal: ShopItem = make_item(&"pedal", 10, 1.5, 5)
	var band: Dictionary[StringName, BandRecruit] = {&"ren": BandRecruit.new(), &"cham": BandRecruit.new()}
	return [Economy.new([pick, pedal]), WorldMap.new(&"bedroom"), band]


func test_save_round_trip_restores_progress() -> void:
	var save: SaveGame = SaveGame.new(TEST_SAVE)
	save.erase()
	var before: Array = new_state()
	var economy: Economy = before[0]
	var world: WorldMap = before[1]
	var band: Dictionary[StringName, BandRecruit] = before[2]
	economy.money = 1000
	economy.buy(economy.find(&"pick"))
	economy.buy(economy.find(&"pick"))
	economy.buy(economy.find(&"pedal"))
	world.buy(&"park", 100, economy)
	world.travel(&"park")
	band[&"cham"].join()
	check(save.write(economy, world, band) == OK, "the save is written")
	check(not FileAccess.file_exists(TEST_SAVE + ".tmp"), "the temporary file is renamed over the save")
	var after: Array = new_state()
	check(save.read(after[0], after[1], after[2], ZONE_IDS), "a save is found")
	var loaded: Economy = after[0]
	check(loaded.money == economy.money, "money is restored")
	check(loaded.level(&"pick") == 2 and loaded.level(&"pedal") == 1, "gear levels are restored")
	check((after[1] as WorldMap).owns(&"park") and (after[1] as WorldMap).current == &"park", "owned zones and the current zone are restored")
	var loaded_band: Dictionary[StringName, BandRecruit] = after[2]
	check(loaded_band[&"cham"].joined and not loaded_band[&"ren"].joined, "only the bandmate who joined is back in the band")
	save.erase()


func test_save_missing_file_leaves_a_new_game() -> void:
	var save: SaveGame = SaveGame.new(TEST_SAVE)
	save.erase()
	var state: Array = new_state()
	check(not save.read(state[0], state[1], state[2], ZONE_IDS), "no save, nothing to read")
	check((state[0] as Economy).money == 0 and (state[1] as WorldMap).current == &"bedroom", "the new game is untouched")


func test_save_drops_zones_that_no_longer_exist() -> void:
	var file: ConfigFile = ConfigFile.new()
	file.set_value("world", "owned", [&"bedroom", &"moon"])
	file.set_value("world", "current", &"moon")
	file.save(TEST_SAVE)
	var state: Array = new_state()
	var world: WorldMap = state[1]
	SaveGame.new(TEST_SAVE).read(state[0], world, state[2], ZONE_IDS)
	check(not world.owns(&"moon") and world.current == &"bedroom", "an unknown zone is dropped and the band stays home")
	SaveGame.new(TEST_SAVE).erase()


func test_save_from_version_1_keeps_ren_in_the_band() -> void:
	var file: ConfigFile = ConfigFile.new()
	file.set_value("meta", "version", 1)
	file.set_value("band", "bandmate_joined", true)
	file.save(TEST_SAVE)
	var state: Array = new_state()
	var band: Dictionary[StringName, BandRecruit] = state[2]
	SaveGame.new(TEST_SAVE).read(state[0], state[1], band, ZONE_IDS)
	check(band[&"ren"].joined and not band[&"cham"].joined, "the old single bandmate flag still means Ren")
	SaveGame.new(TEST_SAVE).erase()
