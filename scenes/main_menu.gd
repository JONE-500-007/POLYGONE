extends Control

@onready var main_panel: Control = $CenterContainer/MainPanel
@onready var play_panel: Control = $CenterContainer/PlayPanel
@onready var coop_panel: Control = $CenterContainer/CoopPanel
@onready var join_panel: Control = $CenterContainer/JoinPanel
@onready var code_edit: LineEdit = $CenterContainer/JoinPanel/CodeEdit


func _ready() -> void:
	# Main panel
	_connect_button("MainPanel/PlayButton", show_panel.bind(play_panel))
	_connect_button("MainPanel/SettingsButton", _on_settings_pressed)
	_connect_button("MainPanel/QuitButton", _on_quit_pressed)
	# Play panel
	_connect_button("PlayPanel/SoloButton", _on_solo_pressed)
	_connect_button("PlayPanel/CoopButton", show_panel.bind(coop_panel))
	_connect_button("PlayPanel/PlayBackButton", show_panel.bind(main_panel))
	# Co-op panel
	_connect_button("CoopPanel/HostButton", _on_host_pressed)
	_connect_button("CoopPanel/JoinMenuButton", show_panel.bind(join_panel))
	_connect_button("CoopPanel/CoopBackButton", show_panel.bind(play_panel))
	# Join panel
	_connect_button("JoinPanel/ConfirmJoinButton", _on_confirm_join_pressed)
	_connect_button("JoinPanel/JoinBackButton", show_panel.bind(coop_panel))

	show_panel(main_panel)


func _connect_button(path: String, callback: Callable) -> void:
	var button := $CenterContainer.get_node(path) as Button
	button.pressed.connect(callback)


# Show one panel and hide all the others.
func show_panel(panel: Control) -> void:
	for p in [main_panel, play_panel, coop_panel, join_panel]:
		p.visible = (p == panel)


func _on_solo_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/character_select.tscn")


func _on_host_pressed() -> void:
	print("Create room: not implemented yet")


func _on_confirm_join_pressed() -> void:
	var code := code_edit.text.strip_edges()
	if code.is_empty():
		print("Please enter a room code")
		return
	print("Join room: ", code, " (not implemented yet)")


func _on_settings_pressed() -> void:
	print("Settings: not implemented yet")


func _on_quit_pressed() -> void:
	get_tree().quit()
