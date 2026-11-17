extends CanvasLayer

const MY_ID := 1  # switch to multiplayer.get_unique_id() when online is added

@onready var root: Control = $Root
var _is_open := false


func _ready() -> void:
	root.hide()
	var b := $Root/Center/Buttons
	b.get_node("ReturntoGameButton").pressed.connect(_close)
	b.get_node("SettingsButton").pressed.connect(_on_settings_pressed)
	b.get_node("MainMenuButton").pressed.connect(_on_main_menu_pressed)
	b.get_node("QuitButton").pressed.connect(_on_quit_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	# Ignore Esc while the level-up cards are open (avoids fighting over pausing/unpausing)
	var level_up := get_tree().get_first_node_in_group("level_up")
	if level_up != null and level_up.is_open():
		return
	if _is_open:
		_close()
	else:
		_open()
	get_viewport().set_input_as_handled()


func _open() -> void:
	_is_open = true
	root.show()
	GameState.set_player_paused(MY_ID, true)


func _close() -> void:
	_is_open = false
	root.hide()
	GameState.set_player_paused(MY_ID, false)


func _on_settings_pressed() -> void:
	print("Settings: not implemented yet")


func _on_main_menu_pressed() -> void:
	GameState.paused_players.clear()
	get_tree().paused = false  # must unpause before changing scene, otherwise the main menu stays frozen
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
