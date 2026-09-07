extends RefCounted
## Small, provisional economy. Species names, prices and rod tuning are placeholders.

const SAVE_PATH := "user://fishgem_prototype.json"
const MAX_UPGRADE_LEVEL := 5
const UPGRADE_COSTS := [30, 65, 110, 170, 250]
const TEXTURE_FOLDER := "res://assets/kenney_fish-pack_2/PNG/Default/"
const FISH: Array[Dictionary] = [
	{"id": "common", "name": "Pond pal", "radius": 38, "speed": 105, "required_hits": 7, "danger_speed": 0.035, "behavior": "steady", "color": "88cbe8", "texture_path": TEXTURE_FOLDER + "fish_blue.png", "price": 8, "base_weight": 1.0},
	{"id": "fast", "name": "Zoomy friend", "radius": 32, "speed": 215, "required_hits": 8, "danger_speed": 0.045, "behavior": "fast", "color": "f6ae62", "texture_path": TEXTURE_FOLDER + "fish_orange.png", "price": 14, "base_weight": 0.8},
	{"id": "strong", "name": "Stubborn chum", "radius": 44, "speed": 100, "required_hits": 8, "danger_speed": 0.075, "behavior": "weave", "color": "a7c888", "texture_path": TEXTURE_FOLDER + "fish_green.png", "price": 18, "base_weight": 2.0},
	{"id": "tiny", "name": "Tiny rascal", "radius": 22, "speed": 130, "required_hits": 7, "danger_speed": 0.030, "behavior": "dart", "color": "ed9b9b", "texture_path": TEXTURE_FOLDER + "fish_red.png", "price": 16, "base_weight": 0.25},
	{"id": "large", "name": "Big softie", "radius": 53, "speed": 90, "required_hits": 12, "danger_speed": 0.045, "behavior": "steady", "color": "c8ac91", "texture_path": TEXTURE_FOLDER + "fish_brown.png", "price": 22, "base_weight": 4.0},
	{"id": "rare", "name": "Pink prankster", "radius": 34, "speed": 160, "required_hits": 9, "danger_speed": 0.050, "behavior": "rare", "color": "edaed5", "texture_path": TEXTURE_FOLDER + "fish_pink.png", "price": 35, "base_weight": 1.5},
]
const FISHING_SPOTS := {
	"west_bank": {
		"name": "West shallows",
		"hint": "Shallow water favours Pond pals and Tiny rascals.",
		"weights": [7, 1, 1, 4, 1, 1],
	},
	"home_bank": {
		"name": "Home bank",
		"hint": "A familiar mix, with plenty of Pond pals and Zoomy friends.",
		"weights": [4, 2, 1, 1, 1, 1],
	},
	"east_bank": {
		"name": "East reach",
		"hint": "Deeper water favours Zoomy friends, Stubborn chums, Big softies and Pink pranksters.",
		"weights": [1, 4, 3, 1, 4, 3],
	},
}

var coins: int = 0
var upgrades: Dictionary = {"ease": 0, "weight": 0, "speed": 0}
var bag: Array[Dictionary] = []
var discovered: Dictionary = {}
var best_weights: Dictionary = {}
var fishing_intro_seen: bool = false


func fish_catalog() -> Array[Dictionary]:
	return FISH.duplicate(true)


func fish_by_id(species_id: String) -> Dictionary:
	for fish in FISH:
		if fish.id == species_id:
			return fish.duplicate(true)
	return {}


func roll_fish(spot_id: String = "home_bank") -> Dictionary:
	var weights: Array = FISHING_SPOTS.get(spot_id, FISHING_SPOTS.home_bank).weights
	var total_weight := 0
	for weight in weights:
		total_weight += int(weight)
	var ticket := randi_range(0, total_weight - 1)
	var fish_index := 0
	while ticket >= int(weights[fish_index]):
		ticket -= int(weights[fish_index])
		fish_index += 1
	var fish: Dictionary = FISH[fish_index].duplicate(true)
	# Averaging two rolls makes ordinary sizes more likely than the extremes.
	var size_factor := (randf_range(0.6, 1.4) + randf_range(0.6, 1.4)) * 0.5
	fish.weight_kg = snappedf(fish.base_weight * size_factor * upgrade_effect("weight", int(upgrades.weight)), 0.01)
	return fish


func roll_wait_time() -> float:
	return (randf_range(6.0, 11.0) + randf_range(6.0, 11.0)) * 0.5 * (upgrade_effect("speed", int(upgrades.speed)) / 8.5)


func add_catch(fish: Dictionary) -> void:
	if not _valid_catch(fish):
		return
	var species_id: String = fish.id
	bag.append({"id": species_id, "weight_kg": float(fish.weight_kg)})
	discovered[species_id] = int(discovered.get(species_id, 0)) + 1
	best_weights[species_id] = maxf(float(best_weights.get(species_id, 0.0)), float(fish.weight_kg))


func sale_value(fish: Dictionary) -> int:
	if not _valid_catch(fish):
		return 0
	return maxi(1, roundi(fish_by_id(fish.id).price * fish.weight_kg))


func journal_complete() -> bool:
	for fish in FISH:
		if int(discovered.get(fish.id, 0)) <= 0:
			return false
	return true


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


static func upgrade_effect(kind: String, level: int) -> float:
	level = maxi(level, 0)
	match kind:
		"ease":
			return 2.0 * level
		"weight":
			return 1.0 + 0.2 * level
		"speed":
			return 8.5 * pow(0.8, level)
	return 0.0


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
	file.store_string(JSON.stringify({"version": 3, "coins": coins, "upgrades": upgrades, "bag": bag, "discovered": discovered, "best_weights": best_weights, "fishing_intro_seen": fishing_intro_seen}))
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
	if not _valid_integer(data.get("version"), 1, 3) or not _valid_integer(data.get("coins"), 0, 1000000000):
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
	var loaded_best_weights: Dictionary = {}
	var loaded_intro_seen := false
	if data.version == 3:
		if not data.get("best_weights") is Dictionary or not data.get("fishing_intro_seen") is bool:
			return ERR_FILE_CORRUPT
		for species_id in data.best_weights:
			var record := {"id": species_id, "weight_kg": data.best_weights[species_id]}
			if not _valid_catch(record):
				return ERR_FILE_CORRUPT
			loaded_best_weights[species_id] = float(record.weight_kg)
		loaded_intro_seen = data.fishing_intro_seen
	elif data.version == 2:
		# Only surviving measured catches are known; sold catches have no weight history.
		for fish in loaded_bag:
			loaded_best_weights[fish.id] = maxf(float(loaded_best_weights.get(fish.id, 0.0)), float(fish.weight_kg))
	# V1's synthetic kilogram preserves prices, not a measured personal best.
	# Validation is transactional: a damaged save never partly resets the session.
	coins = int(data.coins)
	upgrades = loaded_upgrades
	bag = loaded_bag
	discovered = data.discovered.duplicate()
	best_weights = loaded_best_weights
	fishing_intro_seen = loaded_intro_seen
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
