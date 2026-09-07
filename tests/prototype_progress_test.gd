extends SceneTree

const Progress = preload("res://scripts/prototype_progress.gd")
const TEST_SAVE := "user://fishgem_progress_test_only.json"


func _initialize() -> void:
	var progress = Progress.new()
	assert(progress.fish_catalog().size() == 6)
	for fish in progress.fish_catalog():
		assert(ResourceLoader.exists(fish.texture_path))
		fish.weight_kg = 1.0
		progress.add_catch(fish)
	for invalid in [{"id": "unknown", "weight_kg": 1.0}, {"id": "common"}, {"id": "common", "weight_kg": -1}, {"id": "common", "weight_kg": INF}]:
		progress.add_catch(invalid)
		assert(progress.sale_value(invalid) == 0)
	assert(progress.bag.size() == 6 and progress.discovered.size() == 6)
	assert(not progress.buy_upgrade("ease"), "Cannot upgrade without coins")
	assert(progress.sell_all() == 113)
	assert(progress.sell_all() == 0 and progress.coins == 113, "A catch can only be sold once")
	assert(progress.discovered.size() == 6, "Selling preserves collection")
	assert(progress.sale_value({"id": "common", "weight_kg": 2.0}) == 16)
	assert(progress.sale_value({"id": "large", "weight_kg": 2.0}) == 44, "Both species and mass determine price")
	assert(progress.sale_value({"id": "tiny", "weight_kg": 0.01}) == 1)
	assert(progress.buy_upgrade("ease") and progress.coins == 83 and progress.upgrades.ease == 1)
	assert(progress.upgrades.weight == 0 and progress.upgrades.speed == 0)
	assert(progress.upgrade_cost("ease") == 65 and progress.upgrade_cost("weight") == 30)
	assert(not progress.buy_upgrade("invalid") and progress.upgrade_cost("invalid") == 0)
	_check_random_tuning()
	_check_record_history()
	progress.add_catch({"id": "common", "weight_kg": 1.27})
	assert(progress.save_game(TEST_SAVE) == OK)
	var restored = Progress.new()
	assert(restored.load_game(TEST_SAVE) == OK)
	assert(restored.coins == 83 and restored.upgrades == progress.upgrades and restored.bag == progress.bag)
	assert(restored.discovered.common == 2 and restored.bag_value() == 10)
	assert(restored.save_game(TEST_SAVE) == OK, "Save replacement works")
	for damaged in ["{", "[]", '{"version":2,"coins":"bad"}', '{"version":2,"coins":0,"upgrades":{"ease":0,"weight":0,"speed":9},"bag":[],"discovered":{}}', '{"version":2,"coins":0,"upgrades":{"ease":0,"weight":0,"speed":0},"bag":[{"id":"common","weight_kg":"huge"}],"discovered":{}}', '{"version":1,"coins":0,"rod_level":0,"bag":["unknown"],"discovered":{}}', '{"version":1,"coins":0,"rod_level":0,"bag":[],"discovered":{"common":-1}}']:
		_write_save(damaged)
		assert(restored.load_game(TEST_SAVE) == ERR_FILE_CORRUPT)
		assert(restored.coins == 83 and restored.bag == progress.bag, "Damaged saves leave session intact")
	_write_save('{"version":1,"coins":42,"rod_level":2,"bag":["common","large"],"discovered":{"common":3,"large":1}}')
	assert(restored.load_game(TEST_SAVE) == OK)
	assert(restored.coins == 42 and restored.upgrades == {"ease":2,"weight":0,"speed":0})
	assert(restored.bag == [{"id":"common","weight_kg":1.0},{"id":"large","weight_kg":1.0}])
	assert(restored.bag_value() == 30, "Migration preserves old bag proceeds")
	assert(restored.save_game(TEST_SAVE) == OK)
	assert(Progress.new().load_game(TEST_SAVE) == OK, "Migrated saves remain readable")
	progress.coins = 3000
	for kind in ["ease", "weight", "speed"]:
		while progress.upgrades[kind] < Progress.MAX_UPGRADE_LEVEL:
			assert(progress.buy_upgrade(kind))
		assert(not progress.buy_upgrade(kind) and progress.upgrade_cost(kind) == 0)
	assert(progress.save_game(TEST_SAVE) == OK)
	assert(restored.load_game(TEST_SAVE) == OK and restored.upgrades == {"ease": 5, "weight": 5, "speed": 5})
	assert(restored.journal_complete())
	restored.discovered.common = 0
	assert(not restored.journal_complete(), "Zero catches do not count as discovery")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	print("PASS: weighted sales, independent upgrades, weight averages, wait bounds, migration, saves and corrupt data rejection")
	quit()


func _check_random_tuning() -> void:
	var progress = Progress.new()
	var normal_mass := 0.0
	var upgraded_mass := 0.0
	seed(8024)
	for index in range(1000):
		var fish: Dictionary = progress.roll_fish()
		assert(fish.weight_kg > 0 and fish.weight_kg <= fish.base_weight * 1.4 + 0.005)
		normal_mass += fish.weight_kg
	progress.upgrades.weight = 3
	seed(8024)
	for index in range(1000):
		upgraded_mass += progress.roll_fish().weight_kg
	assert(upgraded_mass > normal_mass * 1.59 and upgraded_mass < normal_mass * 1.61)
	for level in range(Progress.MAX_UPGRADE_LEVEL + 1):
		progress.upgrades.speed = level
		var total_wait := 0.0
		for index in range(1000):
			var wait: float = progress.roll_wait_time()
			assert(wait >= 6.0 * pow(0.8, level) and wait <= 11.0 * pow(0.8, level))
			total_wait += wait
		assert(absf(total_wait / 1000.0 - 8.5 * pow(0.8, level)) < 0.15)


func _write_save(contents: String) -> void:
	var file := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	file.store_string(contents)
	file.close()


func _check_record_history() -> void:
	var progress = Progress.new()
	progress.add_catch({"id": "common", "weight_kg": 1.8})
	progress.add_catch({"id": "common", "weight_kg": 1.2})
	progress.add_catch({"id": "common", "weight_kg": 1.8})
	assert(progress.best_weights.common == 1.8, "Smaller and equal catches never erase a record")
	progress.sell_all()
	progress.fishing_intro_seen = true
	assert(progress.save_game(TEST_SAVE) == OK)
	var restored = Progress.new()
	assert(restored.load_game(TEST_SAVE) == OK)
	assert(restored.best_weights.common == 1.8 and restored.bag.is_empty(), "Selling and reload preserve lifetime records")
	assert(restored.fishing_intro_seen, "Acknowledged guidance persists")
	_write_save('{"version":2,"coins":0,"upgrades":{"ease":0,"weight":0,"speed":0},"bag":[{"id":"common","weight_kg":1.2},{"id":"common","weight_kg":1.9}],"discovered":{"common":4,"tiny":2}}')
	assert(restored.load_game(TEST_SAVE) == OK)
	assert(restored.best_weights.common == 1.9 and not restored.best_weights.has("tiny"), "Only known historical weights become records")
	assert(not restored.fishing_intro_seen, "Older saves can learn the new guidance")
	_write_save('{"version":1,"coins":0,"rod_level":0,"bag":["common"],"discovered":{"common":1}}')
	assert(restored.load_game(TEST_SAVE) == OK)
	assert(restored.best_weights.is_empty(), "V1 sale-compatibility weights are not measured records")
	assert(restored.save_game(TEST_SAVE) == OK)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TEST_SAVE))
	for invalid_records in [{"unknown": 1.0}, {"common": -1.0}, {"common": "heavy"}, {"common": 1001.0}]:
		var damaged := data.duplicate(true)
		damaged.best_weights = invalid_records
		_write_save(JSON.stringify(damaged))
		assert(restored.load_game(TEST_SAVE) == ERR_FILE_CORRUPT)
		assert(restored.best_weights.is_empty() and restored.bag.size() == 1, "Invalid record load leaves the live session untouched")
	data.fishing_intro_seen = "yes"
	_write_save(JSON.stringify(data))
	assert(restored.load_game(TEST_SAVE) == ERR_FILE_CORRUPT and not restored.fishing_intro_seen, "Guidance state must be a boolean")
