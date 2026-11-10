extends Control

const ROTATE_SPEED := 1.0  # radians per second

var characters: Array[CharacterData] = [
	preload("res://data/characters/cube.tres"),
	preload("res://data/characters/sphere.tres"),
	preload("res://data/characters/pyramid.tres"),
]

@onready var model_pivot: Node3D = $PreviewContainer/PreviewViewport/PreviewWorld/ModelPivot
@onready var slot_list: Container = $Margin/Columns/MenuPanel/SlotList
@onready var description_label: Label = $Margin/Columns/MenuPanel/DescriptionLabel
@onready var play_button: Button = $Margin/Columns/MenuPanel/BottomButtons/PlayButton
@onready var back_button: Button = $Margin/Columns/MenuPanel/BottomButtons/BackButton

var _selected: CharacterData


func _ready() -> void:
	var group := ButtonGroup.new()
	var slots := slot_list.get_children()
	for i in slots.size():
		var slot := slots[i] as Button
		slot.toggle_mode = true
		slot.button_group = group
		slot.pressed.connect(_select.bind(characters[i]))

	play_button.pressed.connect(_on_play_pressed)
	back_button.pressed.connect(_on_back_pressed)

	(slots[0] as Button).button_pressed = true
	_select(characters[0])


func _process(delta: float) -> void:
	model_pivot.rotate_y(ROTATE_SPEED * delta)


func _select(character: CharacterData) -> void:
	_selected = character
	description_label.text = character.description
	for child in model_pivot.get_children():
		child.queue_free()
	if character.model_scene:
		model_pivot.add_child(character.model_scene.instantiate())


func _on_play_pressed() -> void:
	GameState.selected_character = _selected
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
