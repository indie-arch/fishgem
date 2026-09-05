extends RefCounted
## Small, provisional economy. Species names, prices and rod tuning are placeholders.

const SAVE_PATH := "user://fishgem_prototype.json"
const MAX_UPGRADE_LEVEL := 3
const UPGRADE_COSTS := [30, 65, 110]
const TEXTURE_FOLDER := "res://assets/kenney_fish-pack_2/PNG/Default/"
const FISH: Array[Dictionary] = [
	{"id": "common", "name": "Pond pal", "radius": 38, "speed": 105, "required_hits": 7, "danger_speed": 0.035, "behavior": "steady", "color": "88cbe8", "texture_path": TEXTURE_FOLDER + "fish_blue.png", "price": 8, "base_weight": 1.0},
	{"id": "fast", "name": "Zoomy friend", "radius": 32, "speed": 215, "required_hits": 8, "danger_speed": 0.045, "behavior": "fast", "color": "f6ae62", "texture_path": TEXTURE_FOLDER + "fish_orange.png", "price": 14, "base_weight": 0.8},
	{"id": "strong", "name": "Stubborn chum", "radius": 44, "speed": 100, "required_hits": 8, "danger_speed": 0.075, "behavior": "weave", "color": "a7c888", "texture_path": TEXTURE_FOLDER + "fish_green.png", "price": 18, "base_weight": 2.0},
	{"id": "tiny", "name": "Tiny rascal", "radius": 22, "speed": 130, "required_hits": 7, "danger_speed": 0.030, "behavior": "dart", "color": "ed9b9b", "texture_path": TEXTURE_FOLDER + "fish_red.png", "price": 16, "base_weight": 0.25},
	{"id": "large", "name": "Big softie", "radius": 53, "speed": 90, "required_hits": 12, "danger_speed": 0.045, "behavior": "steady", "color": "c8ac91", "texture_path": TEXTURE_FOLDER + "fish_brown.png", "price": 22, "base_weight": 4.0},
	{"id": "rare", "name": "Pink prankster", "radius": 34, "speed": 160, "required_hits": 9, "danger_speed": 0.050, "behavior": "rare", "color": "edaed5", "texture_path": TEXTURE_FOLDER + "fish_pink.png", "price": 35, "base_weight": 1.5},
]

var coins: int = 0
var upgrades: Dictionary = {"ease": 0, "weight": 0, "speed": 0}
var bag: Array[Dictionary] = []
var discovered: Dictionary = {}


func fish_catalog() -> Array[Dictionary]:
	return FISH.duplicate(true)


func fish_by_id(species_id: String) -> Dictionary:
	for fish in FISH:
		if fish.id == species_id:
			return fish.duplicate(true)
	return {}


func roll_fish() -> Dictionary:
	# Common catches are more frequent; every archetype is available from the start.
	var weighted_ids := ["common", "common", "common", "common", "fast", "fast", "strong", "tiny", "large", "rare"]
	var fish := fish_by_id(weighted_ids.pick_random())
	# Averaging two rolls makes ordinary sizes more likely than the extremes.
	var size_factor := (randf_range(0.6, 1.4) + randf_range(0.6, 1.4)) * 0.5
	fish.weight_kg = snappedf(fish.base_weight * size_factor * (1.0 + 0.2 * upgrades.weight), 0.01)
	return fish


func roll_wait_time() -> float:
	return (randf_range(6.0, 11.0) + randf_range(6.0, 11.0)) * 0.5 * pow(0.8, upgrades.speed)


func add_catch(fish: Dictionary) -> void:
	if not _valid_catch(fish):
		return
	var species_id: String = fish.id
	bag.append({"id": species_id, "weight_kg": float(fish.weight_kg)})
	discovered[species_id] = int(discovered.get(species_id, 0)) + 1


func sale_value(fish: Dictionary) -> int:
	if not _valid_catch(fish):
		return 0
	return maxi(1, roundi(fish_by_id(fish.id).price * fish.weight_kg))


func bag_value() -> int:
	var total := 0
	for fish in bag:
		total += sale_value(fish)
	return total


func sell_all() -> int:
	var earned := bag_value()
	coins += earned
	bag.clear()
	return earned


func upgrade_cost(kind: String) -> int:
	if not upgrades.has(kind) or upgrades[kind] >= MAX_UPGRADE_LEVEL:
		return 0
	return UPGRADE_COSTS[upgrades[kind]]


func buy_upgrade(kind: String) -> bool:
	var cost := upgrade_cost(kind)
	if cost <= 0 or coins < cost:
		return false
	coins -= cost
	upgrades[kind] += 1
	return true


func save_game(path: String = SAVE_PATH) -> Error:
	var temporary_path := path + ".tmp"
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify({"version": 2, "coins": coins, "upgrades": upgrades, "bag": bag, "discovered": discovered}))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		return write_error
	# Replace only after a complete write, preserving the last save if writing fails.
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary_path), ProjectSettings.globalize_path(path))


func load_game(path: String = SAVE_PATH) -> Error:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return FileAccess.get_open_error()
	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	file.close()
	if parse_error != OK or not json.data is Dictionary:
		return ERR_FILE_CORRUPT
	var data: Dictionary = json.data
	if not _valid_integer(data.get("version"), 1, 2) or not _valid_integer(data.get("coins"), 0, 1000000000):
		return ERR_FILE_CORRUPT
	if not data.get("bag") is Array or not data.get("discovered") is Dictionary:
		return ERR_FILE_CORRUPT
	var loaded_upgrades: Dictionary = {"ease": 0, "weight": 0, "speed": 0}
	if data.version == 1:
		if not _valid_integer(data.get("rod_level"), 0, MAX_UPGRADE_LEVEL):
			return ERR_FILE_CORRUPT
		loaded_upgrades.ease = int(data.rod_level)
	else:
		if not data.get("upgrades") is Dictionary:
			return ERR_FILE_CORRUPT
		for kind in loaded_upgrades:
			if not _valid_integer(data.upgrades.get(kind), 0, MAX_UPGRADE_LEVEL):
				return ERR_FILE_CORRUPT
			loaded_upgrades[kind] = int(data.upgrades[kind])
	var loaded_bag: Array[Dictionary] = []
	for entry in data.bag:
		# Earlier catches had fixed prices. One kilogram preserves their sale value.
		var fish: Variant = {"id": entry, "weight_kg": 1.0} if data.version == 1 else entry
		if not fish is Dictionary or not _valid_catch(fish):
			return ERR_FILE_CORRUPT
		loaded_bag.append({"id": fish.id, "weight_kg": float(fish.weight_kg)})
	for species_id in data.discovered:
		if not species_id is String or fish_by_id(species_id).is_empty() or not _valid_integer(data.discovered[species_id], 0, 1000000000):
			return ERR_FILE_CORRUPT
	# Validation is transactional: a damaged save never partly resets the session.
	coins = int(data.coins)
	upgrades = loaded_upgrades
	bag = loaded_bag
	discovered = data.discovered.duplicate()
	return OK


func _valid_catch(fish: Dictionary) -> bool:
	if not fish.get("id") is String or fish_by_id(fish.id).is_empty():
		return false
	var weight: Variant = fish.get("weight_kg")
	if not (weight is int or weight is float):
		return false
	return is_finite(float(weight)) and weight > 0.0 and weight <= 1000.0


func _valid_integer(value: Variant, minimum: int, maximum: int) -> bool:
	if not (value is int or value is float):
		return false
	return is_finite(float(value)) and value >= minimum and value <= maximum and float(value) == floor(float(value))
