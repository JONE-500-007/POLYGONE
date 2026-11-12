extends CanvasLayer

@export var slot_scene: PackedScene
@export var slot_count := 6

@onready var weapon_row: HBoxContainer = $Root/Slots/VBox/WeaponRow
@onready var passive_row: HBoxContainer = $Root/Slots/VBox/PassiveRow
@onready var exp_bar: ProgressBar = $Root/ExpBar
@onready var level_label: Label = $Root/LevelLabel


func _ready() -> void:
	add_to_group("hud")
	_fill_row(weapon_row)
	_fill_row(passive_row)

	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var xp := player.get_node("Experience") as Experience
	xp.exp_changed.connect(_on_exp_changed)
	xp.leveled_up.connect(_on_leveled_up)
	_on_exp_changed(xp.current_exp, xp.exp_to_next)
	_on_leveled_up(xp.level)

	# Show what the player already carries (e.g. the starting weapon).
	for card in (player as Player).weapons:
		add_item(card)


func _fill_row(row: HBoxContainer) -> void:
	for i in slot_count:
		row.add_child(slot_scene.instantiate())


func _on_exp_changed(current: float, needed: float) -> void:
	exp_bar.max_value = needed
	exp_bar.value = current


func _on_leveled_up(new_level: int) -> void:
	level_label.text = "Level %d" % new_level
	
	
func add_item(card: CardData) -> void:
	var row := weapon_row if card.kind == CardData.Kind.WEAPON else passive_row
	for slot in row.get_children():
		var icon := slot.get_node("Icon") as TextureRect
		if icon.texture == null:
			icon.texture = card.icon
			return
