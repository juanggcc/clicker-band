class_name SaveGame
extends RefCounted
## The player's progress on disk: money, gear levels, owned zones, the current zone and
## which bandmates have joined. Writes go to a temporary file that is then renamed
## over the save, so a process killed mid-write leaves the previous save whole.

const VERSION: int = 2

var path: String


func _init(save_path: String = "user://save.cfg") -> void:
	path = save_path


func write(economy: Economy, world: WorldMap, band: Dictionary[StringName, BandRecruit]) -> Error:
	var file: ConfigFile = ConfigFile.new()
	file.set_value("meta", "version", VERSION)
	file.set_value("economy", "money", economy.money)
	file.set_value("economy", "levels", economy.levels())
	file.set_value("world", "owned", world.owned)
	file.set_value("world", "current", world.current)
	var joined: Array[StringName] = []
	for id: StringName in band:
		if band[id].joined:
			joined.append(id)
	file.set_value("band", "joined", joined)
	var temp: String = path + ".tmp"
	var error: Error = file.save(temp)
	if error != OK:
		return error
	return DirAccess.rename_absolute(temp, path)


## Restores the saved progress into the given state and returns true, or returns false
## and leaves it untouched when there is no save. Zones not in zone_ids are dropped.
func read(economy: Economy, world: WorldMap, band: Dictionary[StringName, BandRecruit], zone_ids: Array[StringName]) -> bool:
	var file: ConfigFile = ConfigFile.new()
	if file.load(path) != OK:
		return false
	economy.money = maxi(int(file.get_value("economy", "money", 0)), 0)
	var levels: Dictionary = file.get_value("economy", "levels", {})
	for item: ShopItem in economy.items:
		economy.set_level(item.id, maxi(int(levels.get(item.id, 0)), 0))
	for id: Variant in file.get_value("world", "owned", []):
		var zone: StringName = StringName(str(id))
		if zone_ids.has(zone) and not world.owns(zone):
			world.owned.append(zone)
	var current: StringName = StringName(str(file.get_value("world", "current", world.current)))
	if world.owns(current):
		world.current = current
	var joined: Array[StringName] = []
	for id: Variant in file.get_value("band", "joined", []):
		joined.append(StringName(str(id)))
	# Version 1 saves only knew Ren, under a flag of their own.
	if file.get_value("band", "bandmate_joined", false):
		joined.append(&"ren")
	for id: StringName in band:
		if joined.has(id):
			band[id].join()
	return true


func erase() -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
