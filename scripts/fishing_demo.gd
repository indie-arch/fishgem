extends Control
## Isolated mechanic preview. These fish settings are tuning placeholders.

const FISH = preload("res://scripts/prototype_progress.gd").FISH

var _minigame: Control
var _menu: VBoxContainer
var _selector: OptionButton
var _result: Label
var _start_button: Button


func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color("263f3b")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override("separation", 18)
	center.add_child(_menu)
	var title := Label.new()
	title.text = "FISHGEM  /  fishing sketch"
	title.add_theme_font_size_override("font_size", 30)
	_menu.add_child(title)
	var instructions := Label.new()
	instructions.text = "Click the swimming fish to reel it in.\nRed chases your catch marker. Misses help red.\nEscape leaves an encounter.\n\nSix placeholder fish to try:"
	instructions.add_theme_font_size_override("font_size", 20)
	_menu.add_child(instructions)
	_selector = OptionButton.new()
	for fish in FISH:
		_selector.add_item(fish.name)
	_selector.custom_minimum_size.y = 44
	_menu.add_child(_selector)
	_start_button = Button.new()
	_start_button.text = "Cast / try again"
	_start_button.custom_minimum_size.y = 50
	_start_button.pressed.connect(_start)
	_menu.add_child(_start_button)
	_result = Label.new()
	_result.text = "Prototype tuning — no catches saved."
	_menu.add_child(_result)
	_minigame = preload("res://scenes/fishing_minigame.tscn").instantiate()
	add_child(_minigame)
	_minigame.caught.connect(func(fish: Dictionary): _show_result("Caught %s! Lovely." % fish.name))
	_minigame.escaped.connect(func(): _show_result("It slipped away. Have another go!"))
	_minigame.cancelled.connect(func(): _show_result("Back on the bank."))
	_selector.grab_focus()


func _start() -> void:
	_menu.hide()
	_minigame.start_fishing(FISH[_selector.selected])


func _show_result(message: String) -> void:
	_result.text = message
	_menu.show()
	_start_button.grab_focus()
